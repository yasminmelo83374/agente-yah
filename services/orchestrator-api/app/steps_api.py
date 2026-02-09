from sqlalchemy.orm import Session

from .steps import JobStep


def create_steps(db: Session, job_id: int, steps: list[tuple[str, str]]) -> None:
    for title, action in steps:
        db.add(JobStep(job_id=job_id, title=title, action=action, status="planned"))
    db.commit()


def list_steps(db: Session, job_id: int) -> list[JobStep]:
    return (
        db.query(JobStep)
        .filter(JobStep.job_id == job_id)
        .order_by(JobStep.id.asc())
        .all()
    )
