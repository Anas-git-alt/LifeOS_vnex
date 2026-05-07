"""Persistence and execution helpers for conversational action proposals."""

from __future__ import annotations

from datetime import timedelta
from typing import Any

from sqlalchemy import desc, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings
from lifeos_api.db.models import AgentRun, AgentSession, LifeItem, Message, PendingActionProposal, ReviewItem
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.command_bus import CommandBus, CommandRequest, CommandResult
from lifeos_api.services.conversation_action_planner import (
    ConversationActionProposal,
    ConversationTurnPlan,
    revise_proposal_draft,
)
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now

OPEN_PROPOSAL_STATUSES = {"pending", "revised"}


async def open_pending_action_proposals(
    session: AsyncSession,
    *,
    session_id: str | None,
    limit: int = 5,
) -> list[PendingActionProposal]:
    if not session_id:
        return []
    now = utc_now()
    rows = (
        await session.scalars(
            select(PendingActionProposal)
            .where(PendingActionProposal.session_id == session_id)
            .where(PendingActionProposal.status.in_(OPEN_PROPOSAL_STATUSES))
            .where(or_(PendingActionProposal.expires_at.is_(None), PendingActionProposal.expires_at > now))
            .order_by(PendingActionProposal.created_at)
            .limit(limit)
        )
    ).all()
    return list(rows)


async def persist_inline_proposals(
    session: AsyncSession,
    *,
    plan: ConversationTurnPlan,
    agent_session: AgentSession,
    user_message: Message,
    source: str,
) -> list[PendingActionProposal]:
    now = utc_now()
    rows: list[PendingActionProposal] = []
    for proposal in plan.proposals:
        row = PendingActionProposal(
            id=new_id("aprop"),
            session_id=agent_session.id,
            source_message_id=user_message.id,
            source=source,
            agent_name=agent_session.agent_id or "orchestrator",
            proposal_type=proposal.type,
            summary=proposal.summary,
            draft_json=proposal.draft,
            risk_level=proposal.risk,
            status="pending",
            created_at=now,
            expires_at=now + timedelta(hours=24),
            last_revised_at=None,
            executed_command_id=None,
            review_item_id=None,
        )
        session.add(row)
        rows.append(row)
    await session.flush()
    for row in rows:
        await create_audit_event(
            session,
            actor_type="agent",
            actor_id=agent_session.agent_id or "orchestrator",
            event_type="action_proposal.created",
            entity_type="pending_action_proposal",
            entity_id=row.id,
            summary=f"Created inline proposal: {row.summary}",
            after_json=proposal_to_public_dict(row),
            metadata_json={"source_message_id": user_message.id},
        )
    return rows


async def create_formal_reviews_for_plan(
    session: AsyncSession,
    *,
    run: AgentRun,
    plan: ConversationTurnPlan,
    source_message: Message,
) -> list[ReviewItem]:
    now = utc_now()
    reviews: list[ReviewItem] = []
    for proposal in plan.proposals:
        command = dict(proposal.draft.get("command") or {"command_type": "none", "payload": {}})
        payload = dict(command.get("payload") or {})
        _attach_message_evidence(payload, source_message)
        review = ReviewItem(
            id=new_id("rev"),
            kind=_review_kind(proposal),
            title=proposal.summary[:200],
            body_md=_formal_review_body(proposal, source_message),
            source_capture_id=None,
            source_uri=f"message:{source_message.id}",
            proposed_by_agent_id=run.active_agent_id or "orchestrator",
            assigned_agent_id="approval-manager",
            priority="normal",
            confidence=proposal.confidence,
            risk_level=proposal.risk,
            sensitivity="normal" if proposal.risk not in {"sensitive", "destructive"} else proposal.risk,
            proposed_action_json={"command_type": command.get("command_type", "none"), "payload": payload},
            validation_json={
                "reason": proposal.reason,
                "conversation_proposal_type": proposal.type,
                "source_message_id": source_message.id,
            },
            status="pending",
            expires_at=None,
            snoozed_until=None,
            created_at=now,
            updated_at=now,
        )
        session.add(review)
        reviews.append(review)
    await session.flush()
    for review in reviews:
        await create_status_event(
            session,
            run_id=run.id,
            event_type="formal_review_created",
            title=f"Formal review created: {review.title}",
            visibility="discord_compact",
            detail_json={"review_item_id": review.id, "risk_level": review.risk_level},
        )
    return reviews


async def execute_action_proposal(
    session: AsyncSession,
    settings: Settings,
    proposal: PendingActionProposal,
    *,
    actor_type: str,
    actor_id: str,
) -> CommandResult:
    if proposal.status not in OPEN_PROPOSAL_STATUSES:
        raise ValueError(f"Proposal is not open: {proposal.status}")
    if proposal.risk_level != "low":
        raise ValueError("Only low-risk inline proposals can be executed from conversation follow-up.")

    command = await command_request_from_proposal(
        session,
        proposal,
        actor_type=actor_type,
        actor_id=actor_id,
    )
    proposal.status = "approved"
    result = await CommandBus(session, settings).apply(command)
    proposal.executed_command_id = result.state_change_id
    proposal.status = "executed" if _status_value(result.status) == "applied" else "failed"
    await create_audit_event(
        session,
        actor_type=actor_type,
        actor_id=actor_id,
        event_type="action_proposal.executed",
        entity_type="pending_action_proposal",
        entity_id=proposal.id,
        summary=f"Executed proposal: {proposal.summary}",
        after_json=proposal_to_public_dict(proposal),
        metadata_json={"state_change_id": result.state_change_id},
    )
    return result


async def command_request_from_proposal(
    session: AsyncSession,
    proposal: PendingActionProposal,
    *,
    actor_type: str,
    actor_id: str,
) -> CommandRequest:
    draft = dict(proposal.draft_json or {})
    command = dict(draft.get("command") or {})
    command_type = str(command.get("command_type") or "")
    payload = dict(command.get("payload") or {})
    if not command_type:
        raise ValueError("Proposal has no executable command.")

    if proposal.proposal_type == "task.complete":
        item = await _find_life_item_for_completion(session, draft)
        if item is None:
            raise ValueError("I could not find a matching open task to mark done.")
        payload["item_id"] = item.id

    source_message = await session.get(Message, proposal.source_message_id) if proposal.source_message_id else None
    if source_message is not None:
        _attach_message_evidence(payload, source_message)

    return CommandRequest(
        command_type=command_type,
        payload=payload,
        actor_type=actor_type,
        actor_id=actor_id,
    )


async def reject_action_proposal(session: AsyncSession, proposal: PendingActionProposal) -> None:
    if proposal.status in OPEN_PROPOSAL_STATUSES:
        proposal.status = "rejected"
        await session.flush()
        await create_audit_event(
            session,
            actor_type="user",
            actor_id="owner",
            event_type="action_proposal.rejected",
            entity_type="pending_action_proposal",
            entity_id=proposal.id,
            summary=f"Rejected proposal: {proposal.summary}",
            after_json=proposal_to_public_dict(proposal),
        )


async def revise_action_proposal(
    session: AsyncSession,
    proposal: PendingActionProposal,
    *,
    revision_text: str,
    timezone: str,
) -> PendingActionProposal:
    if proposal.status not in OPEN_PROPOSAL_STATUSES:
        raise ValueError(f"Proposal is not open: {proposal.status}")
    proposal.draft_json = revise_proposal_draft(
        proposal.draft_json,
        revision_text=revision_text,
        timezone=timezone,
    )
    proposal.summary = _revised_summary(proposal.summary, revision_text)
    proposal.status = "revised"
    proposal.last_revised_at = utc_now()
    await session.flush()
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="action_proposal.revised",
        entity_type="pending_action_proposal",
        entity_id=proposal.id,
        summary=f"Revised proposal: {proposal.summary}",
        after_json=proposal_to_public_dict(proposal),
        metadata_json={"revision_text": revision_text},
    )
    return proposal


async def get_action_proposal(session: AsyncSession, proposal_id: str) -> PendingActionProposal | None:
    return await session.get(PendingActionProposal, proposal_id)


async def list_action_proposals(
    session: AsyncSession,
    *,
    status: str | None = None,
    limit: int = 50,
) -> list[PendingActionProposal]:
    stmt = select(PendingActionProposal).order_by(desc(PendingActionProposal.created_at)).limit(limit)
    if status:
        stmt = stmt.where(PendingActionProposal.status == status)
    return list((await session.scalars(stmt)).all())


def proposal_to_public_dict(row: PendingActionProposal) -> dict[str, Any]:
    return {
        "id": row.id,
        "session_id": row.session_id,
        "source_message_id": row.source_message_id,
        "source": row.source,
        "agent_name": row.agent_name,
        "type": row.proposal_type,
        "summary": row.summary,
        "draft": row.draft_json,
        "risk": row.risk_level,
        "status": row.status,
        "created_at": row.created_at.isoformat(),
        "expires_at": row.expires_at.isoformat() if row.expires_at else None,
        "last_revised_at": row.last_revised_at.isoformat() if row.last_revised_at else None,
        "executed_command_id": row.executed_command_id,
        "review_item_id": row.review_item_id,
    }


def planner_proposal_to_public_dict(proposal: ConversationActionProposal) -> dict[str, Any]:
    return {
        "type": proposal.type,
        "summary": proposal.summary,
        "draft": proposal.draft,
        "risk": proposal.risk,
        "status": "planned",
        "confidence": proposal.confidence,
        "requires_confirmation": proposal.requires_confirmation,
        "formal_review_required": proposal.formal_review_required,
        "reason": proposal.reason,
    }


def _attach_message_evidence(payload: dict[str, Any], message: Message) -> None:
    refs = [{"kind": "message", "id": message.id, "session_id": message.session_id, "run_id": message.run_id}]
    if "metadata" in payload or payload.get("domain") or payload.get("item_type"):
        metadata = dict(payload.get("metadata") or {})
        metadata["evidence_refs"] = [*metadata.get("evidence_refs", []), *refs]
        payload["metadata"] = metadata
    elif "schedule" in payload:
        schedule = dict(payload.get("schedule") or {})
        schedule["evidence_refs"] = [*schedule.get("evidence_refs", []), *refs]
        payload["schedule"] = schedule
    elif "evidence_refs" in payload:
        payload["evidence_refs"] = [*payload.get("evidence_refs", []), *refs]
    else:
        payload["evidence_refs"] = [*payload.get("evidence_refs", []), *refs]


async def _find_life_item_for_completion(session: AsyncSession, draft: dict[str, Any]) -> LifeItem | None:
    lookup = dict(draft.get("lookup") or {})
    query = str(lookup.get("title_contains") or "").strip().lower()
    if not query:
        return None
    rows = (
        await session.scalars(
            select(LifeItem)
            .where(LifeItem.status.in_(["open", "pending", "todo"]))
            .order_by(desc(LifeItem.updated_at))
            .limit(50)
        )
    ).all()
    for row in rows:
        if query in row.title.lower():
            return row
    tokens = [token for token in query.split() if len(token) > 2]
    for row in rows:
        title = row.title.lower()
        if tokens and all(token in title for token in tokens):
            return row
    return None


def _formal_review_body(proposal: ConversationActionProposal, source_message: Message) -> str:
    if proposal.type == "memory_candidate.create":
        lead = "This looks like a preference worth remembering, but memory needs approval before it becomes durable."
    elif proposal.type == "job.create_recurring":
        lead = "This would create a recurring automation, so it is waiting for approval before activation."
    elif proposal.risk == "destructive":
        lead = "This could be destructive, so it is waiting here instead of running."
    else:
        lead = "This crossed the review threshold, so LifeOS paused before acting."
    return "\n".join(
        [
            lead,
            "",
            f"Proposal: {proposal.summary}",
            f"Risk: `{proposal.risk}`",
            f"Reason: {proposal.reason or 'Policy requires review.'}",
            "",
            "Source message:",
            f"> {(source_message.content_md or '').strip()[:1000]}",
        ]
    )


def _review_kind(proposal: ConversationActionProposal) -> str:
    if proposal.type.startswith("memory"):
        return "memory"
    if proposal.type.startswith("job") or proposal.type.startswith("reminder"):
        return "planning"
    if proposal.type.startswith("file") or proposal.type.startswith("terminal"):
        return "system"
    return "conversation_action"


def _revised_summary(summary: str, revision_text: str) -> str:
    revision = " ".join(revision_text.split())
    if not revision:
        return summary
    return f"{summary} (revised: {revision[:80]})"


def _status_value(value: object) -> str:
    return str(getattr(value, "value", value))
