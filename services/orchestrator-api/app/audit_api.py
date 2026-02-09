from sqlalchemy.orm import Session

from .models import AuditEvent


def list_audit(db: Session, limit: int = 100) -> list[AuditEvent]:
    return db.query(AuditEvent).order_by(AuditEvent.id.desc()).limit(limit).all()
