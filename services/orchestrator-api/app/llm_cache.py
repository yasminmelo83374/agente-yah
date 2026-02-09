import hashlib
from datetime import datetime
from sqlalchemy.orm import Session

from .models import LLMCache


def _hash_key(model: str, prompt: str, system: str) -> str:
    raw = f"{model}::{system}::{prompt}".encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def get_cached(db: Session, model: str, prompt: str, system: str) -> str | None:
    key = _hash_key(model, prompt, system)
    record = db.get(LLMCache, key)
    if not record:
        return None
    return record.response


def save_cached(db: Session, model: str, prompt: str, system: str, response: str) -> None:
    key = _hash_key(model, prompt, system)
    record = LLMCache(key=key, response=response, created_at=datetime.utcnow())
    db.merge(record)
    db.commit()
