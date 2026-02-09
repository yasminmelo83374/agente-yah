from pydantic import BaseModel
import os


class Settings(BaseModel):
    database_url: str = os.getenv(
        "DATABASE_URL", "postgresql+psycopg2://agent:agent@localhost:5432/agent_platform"
    )
    celery_broker_url: str = os.getenv("CELERY_BROKER_URL", "redis://localhost:6379/0")
    celery_result_backend: str = os.getenv("CELERY_RESULT_BACKEND", "redis://localhost:6379/1")
    default_actor_id: str = os.getenv("DEFAULT_ACTOR_ID", "owner")
    mac_runner_url: str | None = os.getenv("MAC_RUNNER_URL")
    mac_runner_token: str | None = os.getenv("MAC_RUNNER_TOKEN")
    gemini_api_key: str | None = os.getenv("GEMINI_API_KEY")
    gemini_model: str | None = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    openai_api_key: str | None = os.getenv("OPENAI_API_KEY")
    openai_transcribe_model: str | None = os.getenv(
        "OPENAI_TRANSCRIBE_MODEL", "gpt-4o-mini-transcribe"
    )


settings = Settings()
