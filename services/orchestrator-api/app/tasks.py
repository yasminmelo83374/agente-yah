from .worker import celery_app
from .database import SessionLocal
from .models import Job
from .audit import log_event
from .mac_runner import MacRunnerError, send_to_mac_runner
from .command_parser import parse_command
from .playbooks import build_playbook
from .step_runner import complete_all_steps, start_first_step
from .state import get_kill_switch


def _auto_fix(job: Job) -> None:
    # Estrategia inicial de auto-correcao para falhas textuais.
    # Na proxima fase isso sera substituido por diagnostico real com logs/testes.
    lowered = job.text.lower()
    if "erro" in lowered or "bug" in lowered or "falha" in lowered:
        job.explanation = (
            "Identifiquei um pedido relacionado a erro/bug. "
            "No MVP, o agente registra explicacao e plano de correcao automatica."
        )
        job.proposed_fix = (
            "Plano: reproduzir erro, localizar causa raiz, aplicar patch, "
            "validar com testes e liberar com rollback pronto."
        )


@celery_app.task(name="execute_job")
def execute_job(job_id: int) -> str:
    db = SessionLocal()
    try:
        job = db.get(Job, job_id)
        if not job:
            return "job_not_found"

        if get_kill_switch(db):
            job.status = "blocked_kill_switch"
            db.commit()
            return "blocked_kill_switch"

        job.status = "running"
        db.commit()
        log_event(db, "job_started", job.actor_id, {"job_id": job.id})
        start_first_step(db, job.id)

        if job.risk_level == "safe":
            try:
                parsed = parse_command(job.text)
                if parsed.shell_command:
                    result = send_to_mac_runner(job.id, parsed.shell_command, job.risk_level)
                else:
                    result = send_to_mac_runner(job.id, job.text, job.risk_level)
                job.status = "completed"
                job.explanation = f"Execucao local realizada. log={result.get('log_path')}"
                db.commit()
                complete_all_steps(db, job.id, output=job.explanation)
                log_event(db, "job_completed", job.actor_id, {"job_id": job.id, "runner": True})
                return "completed"
            except MacRunnerError as exc:
                job.explanation = f"Runner local falhou: {exc}"
                db.commit()
                log_event(db, "job_runner_failed", job.actor_id, {"job_id": job.id, "error": str(exc)})

        playbook = build_playbook(job.worker_type, job.text)
        job.explanation = playbook.explanation
        job.proposed_fix = playbook.proposed_fix
        _auto_fix(job)
        job.status = "completed"
        db.commit()
        complete_all_steps(db, job.id, output=job.explanation)
        log_event(db, "job_completed", job.actor_id, {"job_id": job.id, "runner": False})
        return "completed"
    except Exception as exc:  # pragma: no cover - fallback defensivo
        job = db.get(Job, job_id)
        if job:
            job.status = "failed"
            job.explanation = f"Falha na execucao: {exc}"
            db.commit()
            log_event(db, "job_failed", job.actor_id, {"job_id": job.id, "error": str(exc)})
        return "failed"
    finally:
        db.close()
