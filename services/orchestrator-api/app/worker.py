from celery import Celery

from .config import settings

celery_app = Celery(
    "agent_platform",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
    include=["app.tasks"],
)

celery_app.conf.task_track_started = True
