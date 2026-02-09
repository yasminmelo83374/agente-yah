import json

from sqlalchemy.orm import Session

from .models import AuditEvent, SystemState

KILL_SWITCH_KEY = "kill_switch"


def _get_state(db: Session, key: str, default: str) -> str:
    record = db.get(SystemState, key)
    if not record:
        record = SystemState(key=key, value=default)
        db.add(record)
        db.commit()
        db.refresh(record)
    return record.value


def get_kill_switch(db: Session) -> bool:
    value = _get_state(db, KILL_SWITCH_KEY, "off")
    return value == "on"


def set_kill_switch(db: Session, enabled: bool, actor_id: str) -> None:
    record = db.get(SystemState, KILL_SWITCH_KEY)
    if not record:
        record = SystemState(key=KILL_SWITCH_KEY, value="off")
        db.add(record)

    record.value = "on" if enabled else "off"
    db.add(
        AuditEvent(
            event_type="kill_switch",
            actor_id=actor_id,
            payload=json.dumps({"enabled": enabled}),
        )
    )
    db.commit()
