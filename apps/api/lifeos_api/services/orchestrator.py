"""Deterministic capture routing and draft generation.

This is the executable Phase 4/5 spine. It deliberately avoids pretending to be
an LLM; providers can later replace the draft step while preserving the same
review-gated contracts.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any


AMOUNT_RE = re.compile(r"(?P<currency>MAD|USD|EUR|€|\$)?\s*(?P<amount>\d+(?:[.,]\d{1,2})?)", re.I)
PRAYERS = {"fajr", "dhuhr", "asr", "maghrib", "isha"}


@dataclass(frozen=True)
class Draft:
    agent_id: str
    domain: str
    sensitivity: str
    intent_labels: list[str]
    confidence: float
    risk_level: str
    title: str
    body_md: str
    proposed_action: dict[str, Any]
    needs_review: bool = True
    missing_context: list[dict[str, Any]] | None = None


def draft_from_capture(*, capture_id: str, raw_text: str | None, platform: str) -> Draft:
    text = (raw_text or "").strip()
    lower = text.lower()

    if _looks_like_job(lower):
        return _job_draft(capture_id, text)
    if _looks_like_finance(lower):
        return _finance_draft(capture_id, text)
    if _looks_like_prayer(lower):
        return _prayer_draft(capture_id, text, platform)
    if _looks_like_health(lower):
        return _health_draft(capture_id, text)
    if _looks_like_family(lower):
        return _family_draft(capture_id, text)
    if _looks_like_work(lower):
        return _work_draft(capture_id, text)
    if _looks_like_research(lower):
        return _research_draft(capture_id, text)
    return _memory_draft(capture_id, text)


def _looks_like_finance(lower: str) -> bool:
    return any(token in lower for token in ["spent", "paid", "expense", "income", "salary", "mad", "usd", "eur", "$", "€"])


def _looks_like_work(lower: str) -> bool:
    return any(token in lower for token in ["work", "task", "todo", "submit", "deadline", "blocker", "hr", "workday"])


def _looks_like_health(lower: str) -> bool:
    return any(token in lower for token in ["sleep", "water", "gym", "workout", "walk", "meal", "health", "energy"])


def _looks_like_family(lower: str) -> bool:
    return any(token in lower for token in ["family", "wife", "parents", "mother", "father", "call my", "visit"])


def _looks_like_prayer(lower: str) -> bool:
    return any(prayer in lower for prayer in PRAYERS) or "prayer" in lower


def _looks_like_research(lower: str) -> bool:
    return any(token in lower for token in ["research", "find sources", "investigate", "compare", "summarize"])


def _looks_like_job(lower: str) -> bool:
    return any(token in lower for token in ["every day", "every weekday", "daily at", "weekly", "remind me every"])


def _work_draft(capture_id: str, text: str) -> Draft:
    title = _compact_title(text, fallback="Work task")
    return Draft(
        agent_id="work.generic",
        domain="work",
        sensitivity="normal",
        intent_labels=["task", "work"],
        confidence=0.76,
        risk_level="durable_state_mutation",
        title="Work task candidate",
        body_md=f"AI draft from capture:\n\n> {text}\n\nProposed work task: **{title}**",
        proposed_action={
            "command_type": "life_item.create",
            "risk_level": "durable_state_mutation",
            "payload": {
                "domain": "work",
                "item_type": "task",
                "title": title,
                "description_md": text,
                "priority": "normal",
                "status": "open",
                "source_capture_id": capture_id,
            },
        },
    )


def _finance_draft(capture_id: str, text: str) -> Draft:
    match = AMOUNT_RE.search(text)
    amount = float(match.group("amount").replace(",", ".")) if match else 0
    currency_token = (match.group("currency") if match else None) or "MAD"
    currency = {"€": "EUR", "$": "USD"}.get(currency_token.upper(), currency_token.upper())
    missing = [] if amount else [{"field": "amount", "question": "What amount should be recorded?"}]
    return Draft(
        agent_id="finance",
        domain="finance",
        sensitivity="finance",
        intent_labels=["finance", "expense"],
        confidence=0.74 if amount else 0.45,
        risk_level="finance_mutation",
        title="Finance entry candidate",
        body_md=f"Parsed finance capture:\n\n> {text}\n\nAmount: **{amount or 'unclear'} {currency}**",
        proposed_action={
            "command_type": "finance_entry.create",
            "risk_level": "finance_mutation",
            "payload": {
                "entry_type": "expense",
                "amount": amount,
                "currency": currency,
                "category": "uncategorized",
                "note_md": text,
                "source_capture_id": capture_id,
            },
        },
        missing_context=missing,
    )


def _health_draft(capture_id: str, text: str) -> Draft:
    log_type = "water" if "water" in text.lower() else "health_note"
    return Draft(
        agent_id="health-fitness",
        domain="health",
        sensitivity="health",
        intent_labels=["health_log"],
        confidence=0.78,
        risk_level="durable_state_mutation",
        title="Health log candidate",
        body_md=f"Proposed health log from:\n\n> {text}",
        proposed_action={
            "command_type": "daily_log.create",
            "risk_level": "durable_state_mutation",
            "payload": {
                "domain": "health",
                "log_type": log_type,
                "value": {"text": text},
                "source_capture_id": capture_id,
                "confidence": 0.78,
            },
        },
    )


def _prayer_draft(capture_id: str, text: str, platform: str) -> Draft:
    lower = text.lower()
    prayer = next((item for item in PRAYERS if item in lower), "fajr")
    status = "on_time" if "on time" in lower else "late" if "late" in lower else "unknown"
    return Draft(
        agent_id="deen-prayer",
        domain="deen",
        sensitivity="normal",
        intent_labels=["prayer_log"],
        confidence=0.82,
        risk_level="durable_state_mutation",
        title="Prayer log candidate",
        body_md=f"Proposed prayer log: **{prayer}** as **{status}**.",
        proposed_action={
            "command_type": "prayer_log.create",
            "risk_level": "durable_state_mutation",
            "payload": {
                "prayer": prayer,
                "status": status,
                "source_platform": platform,
                "source_capture_id": capture_id,
            },
        },
    )


def _family_draft(capture_id: str, text: str) -> Draft:
    return Draft(
        agent_id="family-commitments",
        domain="family",
        sensitivity="family",
        intent_labels=["commitment", "family"],
        confidence=0.72,
        risk_level="durable_state_mutation",
        title="Family commitment candidate",
        body_md=f"Sensitive family/personal commitment draft:\n\n> {text}",
        proposed_action={
            "command_type": "life_item.create",
            "risk_level": "durable_state_mutation",
            "payload": {
                "domain": "family",
                "item_type": "commitment",
                "title": _compact_title(text, fallback="Family commitment"),
                "description_md": text,
                "priority": "normal",
                "status": "open",
                "source_capture_id": capture_id,
            },
        },
    )


def _research_draft(capture_id: str, text: str) -> Draft:
    return Draft(
        agent_id="research",
        domain="research",
        sensitivity="normal",
        intent_labels=["research_topic"],
        confidence=0.8,
        risk_level="durable_state_mutation",
        title="Research queue candidate",
        body_md=f"Proposed research item:\n\n> {text}",
        proposed_action={
            "command_type": "life_item.create",
            "risk_level": "durable_state_mutation",
            "payload": {
                "domain": "research",
                "item_type": "task",
                "title": _compact_title(text, fallback="Research topic"),
                "description_md": text,
                "priority": "normal",
                "status": "open",
                "source_capture_id": capture_id,
            },
        },
    )


def _job_draft(capture_id: str, text: str) -> Draft:
    return Draft(
        agent_id="daily-planner",
        domain="planning",
        sensitivity="normal",
        intent_labels=["automation", "reminder"],
        confidence=0.7,
        risk_level="durable_state_mutation",
        title="Automation/job candidate",
        body_md=f"Proposed scheduled job from:\n\n> {text}",
        proposed_action={
            "command_type": "job.create",
            "risk_level": "durable_state_mutation",
            "payload": {
                "name": _compact_title(text, fallback="Scheduled reminder"),
                "description_md": text,
                "schedule_type": "natural_language",
                "schedule": {"source_text": text},
                "target_agent_id": "daily-planner",
                "command": {"type": "notify", "text": text},
                "source_capture_id": capture_id,
            },
        },
    )


def _memory_draft(capture_id: str, text: str) -> Draft:
    statement = text or "Empty capture"
    return Draft(
        agent_id="memory-curator",
        domain="memory",
        sensitivity="normal",
        intent_labels=["memory_candidate"],
        confidence=0.62,
        risk_level="durable_memory_write",
        title="Memory candidate",
        body_md=f"Possible durable memory candidate:\n\n> {statement}",
        proposed_action={
            "command_type": "memory_fact.create",
            "risk_level": "durable_memory_write",
            "payload": {
                "fact_kind": "note",
                "domain": "planning",
                "statement_md": statement,
                "confidence": 0.62,
                "sensitivity": "normal",
                "evidence_refs": [{"kind": "raw_capture", "id": capture_id}],
            },
        },
    )


def _compact_title(text: str, *, fallback: str) -> str:
    stripped = " ".join(text.split())
    if not stripped:
        return fallback
    return stripped[:80].rstrip()
