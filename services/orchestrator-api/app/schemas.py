from datetime import datetime
from pydantic import BaseModel, Field


class CommandRequest(BaseModel):
    source: str = Field(default="cli", description="Canal: cli, whatsapp, painel")
    text: str = Field(min_length=1)
    actor_id: str = Field(default="owner")


class CommandResponse(BaseModel):
    job_id: int
    status: str
    risk_level: str
    worker_type: str
    required_confirmations: int
    message: str
    assistant_message: str = ""


class ApprovalRequest(BaseModel):
    actor_id: str = "owner"


class KillSwitchRequest(BaseModel):
    enabled: bool
    actor_id: str = "owner"


class ControlStatusResponse(BaseModel):
    kill_switch_enabled: bool


class JobResponse(BaseModel):
    id: int
    source: str
    text: str
    actor_id: str
    risk_level: str
    worker_type: str
    required_confirmations: int
    confirmations_done: int
    status: str
    explanation: str
    proposed_fix: str
    assistant_message: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class JobStepResponse(BaseModel):
    id: int
    job_id: int
    title: str
    action: str
    status: str
    output: str
    created_at: datetime

    class Config:
        from_attributes = True


class AuditEventResponse(BaseModel):
    id: int
    event_type: str
    actor_id: str
    payload: str
    created_at: datetime

    class Config:
        from_attributes = True
