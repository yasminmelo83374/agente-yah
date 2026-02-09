import json
from typing import Any

from sqlalchemy.orm import Session

from .models import AuditEvent


def log_event(db: Session, event_type: str, actor_id: str, payload: dict[str, Any]) -> None:
    db.add(
        AuditEvent(
            event_type=event_type,
            actor_id=actor_id,
            payload=json.dumps(payload, ensure_ascii=False),
        )
    )
    db.commit()
