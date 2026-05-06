"""SQLAlchemy models for the LifeOS operational store."""

from datetime import datetime
from typing import Any

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    display_name: Mapped[str] = mapped_column(Text, nullable=False)
    timezone: Mapped[str] = mapped_column(Text, nullable=False, default="Africa/Casablanca")
    locale: Mapped[str | None] = mapped_column(Text)
    role: Mapped[str] = mapped_column(String(32), nullable=False, default="owner")


class Channel(Base, TimestampMixin):
    __tablename__ = "channels"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    platform: Mapped[str] = mapped_column(String(32), nullable=False)
    external_channel_id: Mapped[str | None] = mapped_column(Text)
    guild_id: Mapped[str | None] = mapped_column(Text)
    name: Mapped[str | None] = mapped_column(Text)
    purpose: Mapped[str] = mapped_column(String(64), nullable=False)
    default_agent_id: Mapped[str | None] = mapped_column(String(128))
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)


class RawCapture(Base, TimestampMixin):
    """Immutable raw evidence pointer."""

    __tablename__ = "raw_captures"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    source_platform: Mapped[str] = mapped_column(String(32), nullable=False)
    source_channel_id: Mapped[str | None] = mapped_column(ForeignKey("channels.id"))
    source_external_message_id: Mapped[str | None] = mapped_column(String(255))
    source_thread_id: Mapped[str | None] = mapped_column(String(255))
    source_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    capture_kind: Mapped[str] = mapped_column(String(32), nullable=False)
    raw_text: Mapped[str | None] = mapped_column(Text)
    raw_uri: Mapped[str] = mapped_column(Text, nullable=False)
    content_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    sensitivity: Mapped[str] = mapped_column(String(32), nullable=False, default="normal")
    received_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    review_items: Mapped[list["ReviewItem"]] = relationship(back_populates="source_capture")
    interpretations: Mapped[list["CaptureInterpretation"]] = relationship(back_populates="capture")
    attachments: Mapped[list["CaptureAttachment"]] = relationship(back_populates="capture")


class CaptureAttachment(Base):
    __tablename__ = "capture_attachments"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    capture_id: Mapped[str] = mapped_column(ForeignKey("raw_captures.id"), nullable=False)
    kind: Mapped[str] = mapped_column(String(32), nullable=False)
    original_filename: Mapped[str | None] = mapped_column(Text)
    mime_type: Mapped[str | None] = mapped_column(Text)
    storage_uri: Mapped[str] = mapped_column(Text, nullable=False)
    content_hash: Mapped[str | None] = mapped_column(String(128))
    extracted_text_uri: Mapped[str | None] = mapped_column(Text)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    capture: Mapped[RawCapture] = relationship(back_populates="attachments")


class CaptureInterpretation(Base):
    __tablename__ = "capture_interpretations"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    capture_id: Mapped[str] = mapped_column(ForeignKey("raw_captures.id"), nullable=False)
    agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    intent_labels: Mapped[list[str]] = mapped_column(JSON, nullable=False)
    draft_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    confidence: Mapped[float] = mapped_column(Numeric, nullable=False)
    missing_context: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False, default=list)
    risk_level: Mapped[str] = mapped_column(String(64), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    capture: Mapped[RawCapture] = relationship(back_populates="interpretations")


class ReviewItem(Base, TimestampMixin):
    __tablename__ = "review_items"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    kind: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    body_md: Mapped[str] = mapped_column(Text, nullable=False)
    source_capture_id: Mapped[str | None] = mapped_column(ForeignKey("raw_captures.id"))
    source_uri: Mapped[str | None] = mapped_column(Text)
    proposed_by_agent_id: Mapped[str | None] = mapped_column(String(128))
    assigned_agent_id: Mapped[str | None] = mapped_column(String(128))
    priority: Mapped[str] = mapped_column(String(32), nullable=False, default="normal")
    confidence: Mapped[float | None] = mapped_column(Numeric)
    risk_level: Mapped[str] = mapped_column(String(64), nullable=False)
    sensitivity: Mapped[str] = mapped_column(String(32), nullable=False, default="normal")
    proposed_action_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    validation_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    snoozed_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    source_capture: Mapped[RawCapture | None] = relationship(back_populates="review_items")
    decisions: Mapped[list["ReviewDecision"]] = relationship(back_populates="review_item")
    bindings: Mapped[list["ReviewBinding"]] = relationship(back_populates="review_item")


class ReviewBinding(Base):
    __tablename__ = "review_bindings"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    review_item_id: Mapped[str] = mapped_column(ForeignKey("review_items.id"), nullable=False)
    platform: Mapped[str] = mapped_column(String(32), nullable=False)
    channel_id: Mapped[str | None] = mapped_column(ForeignKey("channels.id"))
    external_message_id: Mapped[str | None] = mapped_column(Text)
    external_thread_id: Mapped[str | None] = mapped_column(Text)
    card_version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    review_item: Mapped[ReviewItem] = relationship(back_populates="bindings")


class ReviewDecision(Base):
    __tablename__ = "review_decisions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    review_item_id: Mapped[str] = mapped_column(ForeignKey("review_items.id"), nullable=False)
    user_id: Mapped[str | None] = mapped_column(String(64))
    decision: Mapped[str] = mapped_column(String(32), nullable=False)
    decision_text: Mapped[str | None] = mapped_column(Text)
    decision_payload: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    source_platform: Mapped[str] = mapped_column(String(32), nullable=False)
    source_external_message_id: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)

    review_item: Mapped[ReviewItem] = relationship(back_populates="decisions")


class StateChange(Base):
    __tablename__ = "state_changes"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    review_item_id: Mapped[str | None] = mapped_column(ForeignKey("review_items.id"))
    command_type: Mapped[str] = mapped_column(String(128), nullable=False)
    command_payload: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    applied_by: Mapped[str] = mapped_column(String(64), nullable=False)
    before_snapshot_uri: Mapped[str | None] = mapped_column(Text)
    after_snapshot_uri: Mapped[str | None] = mapped_column(Text)
    error_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    applied_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Agent(Base, TimestampMixin):
    __tablename__ = "agents"

    id: Mapped[str] = mapped_column(String(128), primary_key=True)
    display_name: Mapped[str] = mapped_column(Text, nullable=False)
    domain: Mapped[str] = mapped_column(String(64), nullable=False)
    registry_uri: Mapped[str] = mapped_column(Text, nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    autonomy_level: Mapped[str] = mapped_column(String(64), nullable=False, default="review_gated")
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)


class AgentSession(Base, TimestampMixin):
    __tablename__ = "agent_sessions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    channel_id: Mapped[str | None] = mapped_column(ForeignKey("channels.id"))
    title: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="active")
    memory_scope: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str | None] = mapped_column(ForeignKey("agent_sessions.id"))
    run_id: Mapped[str | None] = mapped_column(String(64))
    role: Mapped[str] = mapped_column(String(32), nullable=False)
    content_md: Mapped[str | None] = mapped_column(Text)
    content_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    source_platform: Mapped[str | None] = mapped_column(String(32))
    source_external_message_id: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class AgentRun(Base, TimestampMixin):
    __tablename__ = "agent_runs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    session_id: Mapped[str | None] = mapped_column(ForeignKey("agent_sessions.id"))
    root_capture_id: Mapped[str | None] = mapped_column(ForeignKey("raw_captures.id"))
    initiating_user_id: Mapped[str | None] = mapped_column(String(64))
    orchestrator_agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    active_agent_id: Mapped[str | None] = mapped_column(String(128))
    status: Mapped[str] = mapped_column(String(64), nullable=False)
    status_summary: Mapped[str | None] = mapped_column(Text)
    provider_used: Mapped[str | None] = mapped_column(String(64))
    model_used: Mapped[str | None] = mapped_column(String(128))
    cost_usd: Mapped[float | None] = mapped_column(Numeric)
    token_usage_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    trace_id: Mapped[str | None] = mapped_column(String(128))
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class StatusEventRow(Base):
    __tablename__ = "status_events"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    run_id: Mapped[str | None] = mapped_column(ForeignKey("agent_runs.id"))
    event_type: Mapped[str] = mapped_column(String(128), nullable=False)
    visibility: Mapped[str] = mapped_column(String(32), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    detail_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class Handoff(Base, TimestampMixin):
    __tablename__ = "handoffs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    parent_run_id: Mapped[str | None] = mapped_column(ForeignKey("agent_runs.id"))
    from_agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    to_agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    task_md: Mapped[str] = mapped_column(Text, nullable=False)
    context_refs: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False, default=list)
    expected_output_schema: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    visibility: Mapped[str] = mapped_column(String(32), nullable=False, default="web")
    discord_summary_posted: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class Tool(Base, TimestampMixin):
    __tablename__ = "tools"

    id: Mapped[str] = mapped_column(String(128), primary_key=True)
    display_name: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    risk_level: Mapped[str] = mapped_column(String(64), nullable=False)
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    schema_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)


class ToolPermission(Base, TimestampMixin):
    __tablename__ = "tool_permissions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    tool_id: Mapped[str] = mapped_column(String(128), nullable=False)
    effect: Mapped[str] = mapped_column(String(32), nullable=False)
    mode: Mapped[str] = mapped_column(String(32), nullable=False, default="read_only")
    scopes: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    requires_approval_when: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)


class ToolCall(Base):
    __tablename__ = "tool_calls"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    run_id: Mapped[str | None] = mapped_column(ForeignKey("agent_runs.id"))
    agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    tool_id: Mapped[str] = mapped_column(String(128), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    input_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    output_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    redacted_input_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    redacted_output_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    approval_review_item_id: Mapped[str | None] = mapped_column(ForeignKey("review_items.id"))
    error_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class ProviderCallLog(Base):
    __tablename__ = "provider_call_logs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    run_id: Mapped[str | None] = mapped_column(ForeignKey("agent_runs.id"))
    agent_id: Mapped[str | None] = mapped_column(String(128))
    provider_id: Mapped[str] = mapped_column(String(64), nullable=False)
    model: Mapped[str] = mapped_column(Text, nullable=False)
    key_label: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    input_tokens: Mapped[int | None] = mapped_column(Integer)
    output_tokens: Mapped[int | None] = mapped_column(Integer)
    cost_usd: Mapped[float | None] = mapped_column(Numeric)
    error_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class MemoryCandidate(Base, TimestampMixin):
    __tablename__ = "memory_candidates"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    source_capture_id: Mapped[str | None] = mapped_column(ForeignKey("raw_captures.id"))
    proposed_by_agent_id: Mapped[str] = mapped_column(String(128), nullable=False)
    candidate_kind: Mapped[str] = mapped_column(String(64), nullable=False)
    statement_md: Mapped[str] = mapped_column(Text, nullable=False)
    evidence_refs: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False, default=list)
    confidence: Mapped[float] = mapped_column(Numeric, nullable=False)
    sensitivity: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    review_item_id: Mapped[str | None] = mapped_column(ForeignKey("review_items.id"))


class MemoryFact(Base, TimestampMixin):
    __tablename__ = "memory_facts"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    fact_kind: Mapped[str] = mapped_column(String(64), nullable=False)
    statement_md: Mapped[str] = mapped_column(Text, nullable=False)
    domain: Mapped[str] = mapped_column(String(64), nullable=False)
    confidence: Mapped[float] = mapped_column(Numeric, nullable=False)
    sensitivity: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    source_candidate_id: Mapped[str | None] = mapped_column(ForeignKey("memory_candidates.id"))
    evidence_refs: Mapped[list[dict[str, Any]]] = mapped_column(JSON, nullable=False, default=list)
    vault_uri: Mapped[str] = mapped_column(Text, nullable=False)


class VaultIndexEntry(Base, TimestampMixin):
    __tablename__ = "vault_index_entries"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    vault_uri: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    content_hash: Mapped[str] = mapped_column(String(128), nullable=False)
    index_kind: Mapped[str] = mapped_column(String(64), nullable=False)
    domain: Mapped[str | None] = mapped_column(String(64))
    sensitivity: Mapped[str] = mapped_column(String(32), nullable=False)
    indexed_text: Mapped[str | None] = mapped_column(Text)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)


class LifeItem(Base, TimestampMixin):
    __tablename__ = "life_items"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    domain: Mapped[str] = mapped_column(String(64), nullable=False)
    item_type: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description_md: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    priority: Mapped[str] = mapped_column(String(32), nullable=False, default="normal")
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    source_capture_id: Mapped[str | None] = mapped_column(ForeignKey("raw_captures.id"))
    approved_state_change_id: Mapped[str | None] = mapped_column(ForeignKey("state_changes.id"))
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)


class DailyLog(Base):
    __tablename__ = "daily_logs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    local_date: Mapped[str] = mapped_column(String(10), nullable=False)
    domain: Mapped[str] = mapped_column(String(64), nullable=False)
    log_type: Mapped[str] = mapped_column(String(64), nullable=False)
    value_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    source_capture_id: Mapped[str | None] = mapped_column(ForeignKey("raw_captures.id"))
    review_item_id: Mapped[str | None] = mapped_column(ForeignKey("review_items.id"))
    confidence: Mapped[float | None] = mapped_column(Numeric)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class FinanceEntry(Base, TimestampMixin):
    __tablename__ = "finance_entries"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    local_date: Mapped[str] = mapped_column(String(10), nullable=False)
    entry_type: Mapped[str] = mapped_column(String(32), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric, nullable=False)
    currency: Mapped[str] = mapped_column(String(8), nullable=False, default="MAD")
    category: Mapped[str] = mapped_column(String(64), nullable=False)
    note_md: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    source_capture_id: Mapped[str | None] = mapped_column(ForeignKey("raw_captures.id"))
    review_item_id: Mapped[str | None] = mapped_column(ForeignKey("review_items.id"))


class PrayerLog(Base, TimestampMixin):
    __tablename__ = "prayer_logs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    local_date: Mapped[str] = mapped_column(String(10), nullable=False)
    prayer: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    source_platform: Mapped[str | None] = mapped_column(String(32))
    source_external_message_id: Mapped[str | None] = mapped_column(Text)


class Job(Base, TimestampMixin):
    __tablename__ = "jobs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    description_md: Mapped[str | None] = mapped_column(Text)
    schedule_type: Mapped[str] = mapped_column(String(32), nullable=False)
    schedule_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    timezone: Mapped[str] = mapped_column(Text, nullable=False, default="Africa/Casablanca")
    target_agent_id: Mapped[str | None] = mapped_column(String(128))
    command_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False)
    approval_policy: Mapped[str] = mapped_column(String(64), nullable=False, default="ask_for_mutations")
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_by_user_id: Mapped[str | None] = mapped_column(ForeignKey("users.id"))


class JobRun(Base):
    __tablename__ = "job_runs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    job_id: Mapped[str] = mapped_column(ForeignKey("jobs.id"), nullable=False)
    run_id: Mapped[str | None] = mapped_column(ForeignKey("agent_runs.id"))
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    output_summary_md: Mapped[str | None] = mapped_column(Text)
    error_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class Notification(Base):
    __tablename__ = "notifications"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    target_platform: Mapped[str] = mapped_column(String(32), nullable=False)
    target_channel_id: Mapped[str | None] = mapped_column(ForeignKey("channels.id"))
    notification_type: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    body_md: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False)
    related_run_id: Mapped[str | None] = mapped_column(ForeignKey("agent_runs.id"))
    related_review_item_id: Mapped[str | None] = mapped_column(ForeignKey("review_items.id"))
    external_message_id: Mapped[str | None] = mapped_column(Text)
    error_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class DeadLetterItem(Base):
    __tablename__ = "dead_letter_items"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    source_kind: Mapped[str] = mapped_column(String(64), nullable=False)
    source_id: Mapped[str | None] = mapped_column(String(64))
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    payload_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    vault_uri: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="open")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class AuditEvent(Base):
    __tablename__ = "audit_events"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    actor_type: Mapped[str] = mapped_column(String(32), nullable=False)
    actor_id: Mapped[str] = mapped_column(String(128), nullable=False)
    event_type: Mapped[str] = mapped_column(String(128), nullable=False)
    entity_type: Mapped[str] = mapped_column(String(128), nullable=False)
    entity_id: Mapped[str] = mapped_column(String(128), nullable=False)
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    before_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    after_json: Mapped[dict[str, Any] | None] = mapped_column(JSON)
    metadata_json: Mapped[dict[str, Any]] = mapped_column(JSON, nullable=False, default=dict)
    trace_id: Mapped[str | None] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
