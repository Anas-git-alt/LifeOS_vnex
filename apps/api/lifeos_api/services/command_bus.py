"""Audited command bus for state mutations."""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import (
    DailyLog,
    FinanceEntry,
    Job,
    LifeItem,
    MemoryFact,
    PrayerLog,
    StateChange,
    ToolCall,
)
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.status_events import create_status_event
from lifeos_api.services.vault import VaultWriter
from lifeos_core.compat import StrEnum
from lifeos_core.ids import new_id
from lifeos_core.time import local_now, utc_now


class CommandStatus(StrEnum):
    planned = "planned"
    applied = "applied"
    failed = "failed"
    rolled_back = "rolled_back"


class CommandRequest(BaseModel):
    command_type: str
    payload: dict[str, Any]
    source_review_item_id: str | None = None
    actor_type: str = "system"
    actor_id: str = "lifeos-api"
    idempotency_key: str | None = None


class CommandResult(BaseModel):
    state_change_id: str = Field(default_factory=lambda: new_id("stchg"))
    command_type: str
    status: CommandStatus
    audit_event_id: str | None = None
    entity_type: str | None = None
    entity_id: str | None = None
    created_at: datetime = Field(default_factory=utc_now)


class CommandBus:
    """Command bus used by the Approval Manager and API endpoints."""

    def __init__(self, session: AsyncSession, settings: Settings) -> None:
        self.session = session
        self.settings = settings
        self.vault = VaultWriter(settings)

    async def plan(self, command: CommandRequest) -> CommandResult:
        state_change = StateChange(
            id=new_id("stchg"),
            review_item_id=command.source_review_item_id,
            command_type=command.command_type,
            command_payload=command.payload,
            status=CommandStatus.planned,
            applied_by=command.actor_id,
            before_snapshot_uri=None,
            after_snapshot_uri=None,
            error_json=None,
            created_at=utc_now(),
            applied_at=None,
        )
        self.session.add(state_change)
        audit = await create_audit_event(
            self.session,
            actor_type=command.actor_type,
            actor_id=command.actor_id,
            event_type="state_change.planned",
            entity_type="state_change",
            entity_id=state_change.id,
            summary=f"Planned {command.command_type}",
            after_json=command.payload,
        )
        return CommandResult(
            state_change_id=state_change.id,
            command_type=command.command_type,
            status=CommandStatus.planned,
            audit_event_id=audit.id,
        )

    async def apply(self, command: CommandRequest) -> CommandResult:
        state_change = StateChange(
            id=new_id("stchg"),
            review_item_id=command.source_review_item_id,
            command_type=command.command_type,
            command_payload=command.payload,
            status=CommandStatus.planned,
            applied_by=command.actor_id,
            before_snapshot_uri=None,
            after_snapshot_uri=None,
            error_json=None,
            created_at=utc_now(),
            applied_at=None,
        )
        self.session.add(state_change)
        await self.session.flush()

        entity_type = "state_change"
        entity_id = state_change.id
        try:
            entity_type, entity_id = await self._apply_payload(command, state_change.id)
            state_change.status = CommandStatus.applied
            state_change.applied_at = utc_now()
            state_change.after_snapshot_uri = self._state_snapshot_uri(entity_type)
            audit = await create_audit_event(
                self.session,
                actor_type=command.actor_type,
                actor_id=command.actor_id,
                event_type="state_change.applied",
                entity_type=entity_type,
                entity_id=entity_id,
                summary=f"Applied {command.command_type}",
                after_json=command.payload,
                metadata_json={"state_change_id": state_change.id},
            )
            await create_status_event(
                self.session,
                event_type="state_change.applied",
                title=f"Applied {command.command_type}",
                visibility="discord_compact",
                detail_json={"entity_type": entity_type, "entity_id": entity_id},
            )
            return CommandResult(
                state_change_id=state_change.id,
                command_type=command.command_type,
                status=CommandStatus.applied,
                audit_event_id=audit.id,
                entity_type=entity_type,
                entity_id=entity_id,
            )
        except Exception as exc:  # noqa: BLE001 - command bus records failure payload
            state_change.status = CommandStatus.failed
            state_change.error_json = {"type": type(exc).__name__, "message": str(exc)}
            audit = await create_audit_event(
                self.session,
                actor_type=command.actor_type,
                actor_id=command.actor_id,
                event_type="state_change.failed",
                entity_type="state_change",
                entity_id=state_change.id,
                summary=f"Failed {command.command_type}: {exc}",
                after_json=command.payload,
            )
            return CommandResult(
                state_change_id=state_change.id,
                command_type=command.command_type,
                status=CommandStatus.failed,
                audit_event_id=audit.id,
                entity_type=entity_type,
                entity_id=entity_id,
            )

    async def _apply_payload(self, command: CommandRequest, state_change_id: str) -> tuple[str, str]:
        payload = command.payload
        now = utc_now()

        if command.command_type == "life_item.create":
            item = LifeItem(
                id=new_id("item"),
                domain=str(payload.get("domain", "planning")),
                item_type=str(payload.get("item_type", "task")),
                title=str(payload["title"]),
                description_md=payload.get("description_md"),
                status=str(payload.get("status", "open")),
                priority=str(payload.get("priority", "normal")),
                due_at=_parse_dt(payload.get("due_at")),
                scheduled_at=_parse_dt(payload.get("scheduled_at")),
                source_capture_id=payload.get("source_capture_id"),
                approved_state_change_id=state_change_id,
                metadata_json=dict(payload.get("metadata", {})),
                created_at=now,
                updated_at=now,
            )
            self.session.add(item)
            self.vault.write_state_snapshot(name="tasks", body_md=f"# Tasks\n\n- [{item.status}] {item.title}\n")
            return "life_item", item.id

        if command.command_type == "life_item.update":
            item_id = str(payload["item_id"])
            item = await self.session.get(LifeItem, item_id)
            if item is None:
                raise ValueError(f"Life item not found: {item_id}")
            updates = dict(payload.get("updates", {}))
            allowed = {
                "domain",
                "item_type",
                "title",
                "description_md",
                "status",
                "priority",
                "due_at",
                "scheduled_at",
                "metadata_json",
            }
            for key, value in updates.items():
                if key not in allowed:
                    raise ValueError(f"Unsupported life_item.update field: {key}")
                if key in {"due_at", "scheduled_at"}:
                    setattr(item, key, _parse_dt(value))
                elif key == "metadata_json":
                    item.metadata_json = dict(value or {})
                else:
                    setattr(item, key, value)
            item.updated_at = now
            self.vault.write_state_snapshot(name="tasks", body_md=f"# Tasks\n\n- [{item.status}] {item.title}\n")
            return "life_item", item.id

        if command.command_type == "finance_entry.create":
            entry = FinanceEntry(
                id=new_id("fin"),
                local_date=str(payload.get("local_date") or local_now(self.settings.timezone).date()),
                entry_type=str(payload.get("entry_type", "expense")),
                amount=float(payload["amount"]),
                currency=str(payload.get("currency", "MAD")),
                category=str(payload.get("category", "uncategorized")),
                note_md=payload.get("note_md"),
                status=str(payload.get("status", "approved")),
                source_capture_id=payload.get("source_capture_id"),
                review_item_id=command.source_review_item_id,
                created_at=now,
                updated_at=now,
            )
            self.session.add(entry)
            return "finance_entry", entry.id

        if command.command_type == "daily_log.create":
            log = DailyLog(
                id=new_id("log"),
                user_id=payload.get("user_id"),
                local_date=str(payload.get("local_date") or local_now(self.settings.timezone).date()),
                domain=str(payload.get("domain", "health")),
                log_type=str(payload.get("log_type", "note")),
                value_json=dict(payload.get("value", payload.get("value_json", {}))),
                source_capture_id=payload.get("source_capture_id"),
                review_item_id=command.source_review_item_id,
                confidence=payload.get("confidence"),
                created_at=now,
            )
            self.session.add(log)
            return "daily_log", log.id

        if command.command_type == "prayer_log.create":
            log = PrayerLog(
                id=new_id("prayer"),
                user_id=payload.get("user_id"),
                local_date=str(payload.get("local_date") or local_now(self.settings.timezone).date()),
                prayer=str(payload["prayer"]),
                status=str(payload.get("status", "unknown")),
                source_platform=payload.get("source_platform"),
                source_external_message_id=payload.get("source_external_message_id"),
                created_at=now,
                updated_at=now,
            )
            self.session.add(log)
            return "prayer_log", log.id

        if command.command_type == "memory_fact.create":
            fact_id = new_id("mem")
            domain = str(payload.get("domain", "global"))
            statement = str(payload["statement_md"])
            vault_uri = self.vault.write_memory_fact(
                fact_id=fact_id,
                domain=domain if domain != "global" else "planning",
                statement_md=statement,
            )
            fact = MemoryFact(
                id=fact_id,
                fact_kind=str(payload.get("fact_kind", "fact")),
                statement_md=statement,
                domain=domain,
                confidence=float(payload.get("confidence", 0.8)),
                sensitivity=str(payload.get("sensitivity", "normal")),
                status="active",
                source_candidate_id=payload.get("source_candidate_id"),
                evidence_refs=list(payload.get("evidence_refs", [])),
                vault_uri=vault_uri,
                created_at=now,
                updated_at=now,
            )
            self.session.add(fact)
            return "memory_fact", fact.id

        if command.command_type == "job.create":
            job = Job(
                id=new_id("job"),
                name=str(payload["name"]),
                description_md=payload.get("description_md"),
                schedule_type=str(payload.get("schedule_type", "one_time")),
                schedule_json=dict(payload.get("schedule", payload.get("schedule_json", {}))),
                timezone=str(payload.get("timezone", self.settings.timezone)),
                target_agent_id=payload.get("target_agent_id"),
                command_json=dict(payload.get("command", payload.get("command_json", {}))),
                approval_policy=str(payload.get("approval_policy", "ask_for_mutations")),
                enabled=bool(payload.get("enabled", True)),
                created_by_user_id=payload.get("created_by_user_id"),
                created_at=now,
                updated_at=now,
            )
            self.session.add(job)
            return "job", job.id

        if command.command_type == "tool_call.approve":
            tool_call_id = str(payload.get("tool_call_id", "approved_tool_request"))
            tool_call = await self.session.get(ToolCall, tool_call_id)
            if tool_call is not None:
                tool_call.status = "succeeded"
                tool_call.started_at = tool_call.started_at or now
                tool_call.finished_at = now
                tool_call.output_json = {
                    "mode": "approved",
                    "message": "Approval recorded. Executor handoff can run this command.",
                }
                tool_call.redacted_output_json = tool_call.output_json
            return "tool_call", tool_call_id

        raise ValueError(f"Unsupported command_type: {command.command_type}")

    def _state_snapshot_uri(self, entity_type: str) -> str | None:
        mapping = {
            "life_item": "state/tasks.md",
            "finance_entry": "wiki/domains/finance.md",
            "daily_log": "state/habits.md",
            "prayer_log": "wiki/domains/deen.md",
            "memory_fact": "memory/curated",
            "job": "state/reminders.md",
        }
        return mapping.get(entity_type)


def _parse_dt(value: Any) -> datetime | None:
    if value in (None, ""):
        return None
    if isinstance(value, datetime):
        return value
    if isinstance(value, str):
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    raise TypeError(f"Cannot parse datetime from {value!r}")
