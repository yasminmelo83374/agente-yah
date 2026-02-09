import os

from fastapi import Depends, FastAPI, HTTPException, UploadFile, File
from sqlalchemy.orm import Session

from .approval import apply_approval, can_approve
from .audit import log_event
from .database import Base, engine, get_db
from .config import settings
from .logger import logger
from .models import Job
from .policy import classify_command
from .router import route_command
from .planner import build_steps
from .steps_api import create_steps, list_steps
from .llm_client import LLMError, generate_reply
from .llm_cache import get_cached, save_cached
from .schemas import (
    ApprovalRequest,
    CommandRequest,
    CommandResponse,
    AuditEventResponse,
    ControlStatusResponse,
    JobResponse,
    KillSwitchRequest,
    JobStepResponse,
)
from .state import get_kill_switch, set_kill_switch
from .tasks import execute_job
from .audit_api import list_audit
from .transcribe import TranscribeError, transcribe_audio

app = FastAPI(title="Agent Platform Orchestrator", version="0.1.0")


@app.on_event("startup")
def startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/llm/health")
def llm_health() -> dict[str, str]:
    return {
        "gemini_key_set": "yes" if settings.gemini_api_key else "no",
        "gemini_model": settings.gemini_model or "unset",
    }


@app.post("/transcribe")
def transcribe(file: UploadFile = File(...)) -> dict[str, str]:
    filename = file.filename or "audio"
    suffix = os.path.splitext(filename)[1] or ".bin"
    tmp_path = f"/tmp/upload_{filename}{suffix}"
    with open(tmp_path, "wb") as f:
        f.write(file.file.read())
    try:
        text = transcribe_audio(tmp_path, file.content_type)
        return {"text": text}
    except TranscribeError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/commands", response_model=CommandResponse)
def create_command(payload: CommandRequest, db: Session = Depends(get_db)) -> CommandResponse:
    # Classifica risco e cria job com status inicial adequado.
    policy = classify_command(payload.text)
    route = route_command(payload.text)
    status = "queued" if policy.required_confirmations == 0 else "waiting_approval"

    if policy.required_confirmations == 0 and get_kill_switch(db):
        status = "blocked_kill_switch"

    assistant_message = ""
    system_prompt = (
        "Voce e um assistente humano, direto e empatico. Fale simples, sem bajular. "
        "Confirme entendimento antes de agir e proponha um plano curto (2-4 passos). "
        "Se faltar informacao critica, pergunte apenas 1 coisa. "
        "Finalize a resposta com uma pergunta curta de confirmacao. "
        "Responda em portugues do Brasil, sem cortar frases."
    )
    model_id = settings.gemini_model or "gemini-2.5-flash"
    try:
        cached = get_cached(db, model_id, payload.text, system_prompt)
        if cached:
            assistant_message = cached
        else:
            assistant_message = generate_reply(payload.text, system_prompt)
            save_cached(db, model_id, payload.text, system_prompt, assistant_message)
    except LLMError as exc:
        logger.warning("LLM error: %s", exc)
        assistant_message = "Entendi. Vou cuidar disso agora e te atualizo em seguida."

    job = Job(
        source=payload.source,
        text=payload.text,
        actor_id=payload.actor_id,
        risk_level=policy.risk_level,
        required_confirmations=policy.required_confirmations,
        confirmations_done=0,
        worker_type=route.worker_type,
        status=status,
        assistant_message=assistant_message,
    )
    db.add(job)
    db.commit()
    db.refresh(job)

    steps = build_steps(job.worker_type, job.text)
    create_steps(db, job.id, [(step.title, step.action) for step in steps])

    # Sem aprovacao exigida, envia direto para execucao assincrona.
    if policy.required_confirmations == 0 and job.status != "blocked_kill_switch":
        execute_job.delay(job.id)

    message = "Job criado e enviado para execucao."
    if policy.required_confirmations > 0:
        message = (
            f"Job criado e aguardando aprovacao ({policy.required_confirmations} confirmacao(oes))."
        )
    if job.status == "blocked_kill_switch":
        message = "Kill switch ativo. Job criado, mas bloqueado para execucao."

    log_event(
        db,
        "job_created",
        payload.actor_id,
        {"job_id": job.id, "risk_level": job.risk_level, "status": job.status},
    )

    return CommandResponse(
        job_id=job.id,
        status=job.status,
        risk_level=job.risk_level,
        worker_type=job.worker_type,
        required_confirmations=job.required_confirmations,
        message=message,
        assistant_message=assistant_message,
    )


@app.post("/approvals/{job_id}", response_model=JobResponse)
def approve_job(job_id: int, payload: ApprovalRequest, db: Session = Depends(get_db)) -> JobResponse:
    # Aplica confirmacao e libera execucao quando atingir o minimo exigido.
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job nao encontrado")

    if job.status not in {"waiting_approval", "waiting_second_confirmation"}:
        raise HTTPException(status_code=400, detail="Job nao esta aguardando aprovacao")

    if not can_approve(job, payload.actor_id):
        raise HTTPException(status_code=403, detail="Ator sem permissao para aprovar")

    apply_approval(job)
    db.commit()
    db.refresh(job)

    if job.status == "queued" and not get_kill_switch(db):
        execute_job.delay(job.id)
    elif job.status == "queued":
        job.status = "blocked_kill_switch"
        db.commit()

    log_event(
        db,
        "job_approved",
        payload.actor_id,
        {
            "job_id": job.id,
            "confirmations_done": job.confirmations_done,
            "required_confirmations": job.required_confirmations,
            "status": job.status,
        },
    )

    return job


@app.get("/control", response_model=ControlStatusResponse)
def control_status(db: Session = Depends(get_db)) -> ControlStatusResponse:
    return ControlStatusResponse(kill_switch_enabled=get_kill_switch(db))


@app.post("/control/kill-switch", response_model=ControlStatusResponse)
def toggle_kill_switch(
    payload: KillSwitchRequest, db: Session = Depends(get_db)
) -> ControlStatusResponse:
    set_kill_switch(db, payload.enabled, payload.actor_id)
    return ControlStatusResponse(kill_switch_enabled=payload.enabled)


@app.get("/jobs", response_model=list[JobResponse])
def list_jobs(db: Session = Depends(get_db)) -> list[JobResponse]:
    jobs = db.query(Job).order_by(Job.id.desc()).limit(100).all()
    return jobs


@app.get("/jobs/{job_id}", response_model=JobResponse)
def get_job(job_id: int, db: Session = Depends(get_db)) -> JobResponse:
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job nao encontrado")
    return job


@app.get("/jobs/{job_id}/steps", response_model=list[JobStepResponse])
def get_job_steps(job_id: int, db: Session = Depends(get_db)) -> list[JobStepResponse]:
    job = db.get(Job, job_id)
    if not job:
        raise HTTPException(status_code=404, detail="Job nao encontrado")
    return list_steps(db, job_id)


@app.get("/audit", response_model=list[AuditEventResponse])
def list_audit_events(db: Session = Depends(get_db)) -> list[AuditEventResponse]:
    return list_audit(db)
