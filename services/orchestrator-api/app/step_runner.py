from sqlalchemy.orm import Session

from .steps import JobStep


def mark_step(db: Session, step_id: int, status: str, output: str = "") -> None:
    step = db.get(JobStep, step_id)
    if not step:
        return
    step.status = status
    if output:
        step.output = output
    db.commit()


def start_first_step(db: Session, job_id: int) -> JobStep | None:
    step = (
        db.query(JobStep)
        .filter(JobStep.job_id == job_id)
        .order_by(JobStep.id.asc())
        .first()
    )
    if not step:
        return None
    step.status = "running"
    db.commit()
    return step


def complete_all_steps(db: Session, job_id: int, output: str = "") -> None:
    steps = db.query(JobStep).filter(JobStep.job_id == job_id).all()
    for step in steps:
        step.status = "completed"
        if output:
            step.output = output
    db.commit()
