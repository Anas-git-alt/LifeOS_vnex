"""Review and approval API contracts."""

from datetime import datetime

from pydantic import BaseModel, Field

from lifeos_core.compat import StrEnum


class ReviewStatus(StrEnum):
    draft = "draft"
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
    needs_clarification = "needs_clarification"
    corrected = "corrected"
    snoozed = "snoozed"
    expired = "expired"
    applied = "applied"
    failed = "failed"
    cancelled = "cancelled"


class ReviewDecisionKind(StrEnum):
    approve = "approve"
    reject = "reject"
    clarify = "clarify"
    correct = "correct"
    snooze = "snooze"
    done = "done"


class ReviewItemCreate(BaseModel):
    kind: str
    title: str
    body_md: str
    source_capture_id: str | None = None
    proposed_by_agent_id: str | None = None
    risk_level: str
    sensitivity: str = "normal"
    proposed_action_json: dict[str, object]
    expires_at: datetime | None = None


class ReviewDecisionCreate(BaseModel):
    decision: ReviewDecisionKind
    decision_text: str | None = None
    decision_payload: dict[str, object] = Field(default_factory=dict)
    source_platform: str
    source_external_message_id: str | None = None
