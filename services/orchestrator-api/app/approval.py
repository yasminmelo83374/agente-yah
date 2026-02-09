from .models import Job


def can_approve(job: Job, actor_id: str) -> bool:
    return actor_id == job.actor_id


def apply_approval(job: Job) -> None:
    job.confirmations_done += 1
    if job.confirmations_done >= job.required_confirmations:
        job.status = "queued"
    else:
        job.status = "waiting_second_confirmation"
