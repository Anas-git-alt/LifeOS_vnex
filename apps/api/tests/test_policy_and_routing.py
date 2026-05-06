import json

import pytest

from lifeos_api.services.agentic_router import _draft_from_provider_json
from lifeos_api.db.models import AgentSession
from lifeos_api.services.agent_runtime import _fallback_plan, _smalltalk_plan
from lifeos_api.services.orchestrator import draft_from_capture
from lifeos_api.services.policy_engine import decide_capture_action


def test_random_note_routes_raw_only() -> None:
    draft = draft_from_capture(capture_id="cap_1", raw_text="random thought: learn Rust later", platform="telegram")
    decision = decide_capture_action(
        action=draft.proposed_action,
        confidence=draft.confidence,
        sensitivity=draft.sensitivity,
        autonomy_mode="review_gated",
        owner_authenticated=True,
        intent_labels=draft.intent_labels,
    )

    assert draft.intent_labels == ["raw_note"]
    assert decision.decision == "raw_only"


def test_finance_still_requires_review() -> None:
    draft = draft_from_capture(capture_id="cap_1", raw_text="I spent 40 MAD on lunch", platform="telegram")
    decision = decide_capture_action(
        action=draft.proposed_action,
        confidence=draft.confidence,
        sensitivity=draft.sensitivity,
        autonomy_mode="safe",
        owner_authenticated=True,
        intent_labels=draft.intent_labels,
    )

    assert draft.agent_id == "finance"
    assert decision.decision == "review_required"


def test_balanced_allows_explicit_prayer_log() -> None:
    draft = draft_from_capture(capture_id="cap_1", raw_text="fajr done", platform="discord")
    decision = decide_capture_action(
        action=draft.proposed_action,
        confidence=draft.confidence,
        sensitivity=draft.sensitivity,
        autonomy_mode="balanced",
        owner_authenticated=True,
        intent_labels=draft.intent_labels,
    )

    assert decision.decision == "auto_apply"


def test_balanced_allows_low_risk_life_item() -> None:
    decision = decide_capture_action(
        action={
            "command_type": "life_item.create",
            "risk_level": "reversible_internal_write",
            "payload": {"title": "Draft note"},
        },
        confidence=0.82,
        sensitivity="normal",
        autonomy_mode="balanced",
        owner_authenticated=True,
        intent_labels=["session_action"],
    )

    assert decision.decision == "auto_apply"


def test_contextual_fallback_can_create_autonomous_session_action() -> None:
    plan = _fallback_plan(
        AgentSession(id="sess_1", agent_id="orchestrator", title="Test", status="active"),
        "File this as a low-risk project note",
    )

    assert plan.kind == "autonomous_action"
    assert plan.proposed_action["command_type"] == "life_item.create"
    assert plan.risk_level == "reversible_internal_write"


def test_contextual_fallback_asks_for_ambiguous_action() -> None:
    plan = _fallback_plan(
        AgentSession(id="sess_1", agent_id="orchestrator", title="Test", status="active"),
        "Move this to the important stuff and handle it",
    )

    assert plan.kind == "clarification"
    assert plan.clarifying_questions


def test_smalltalk_does_not_create_state_plan() -> None:
    plan = _smalltalk_plan(
        AgentSession(id="sess_1", agent_id="orchestrator", title="Test", status="active"),
        "hey",
    )

    assert plan is not None
    assert plan.kind == "direct"
    assert plan.agent_id == "orchestrator"
    assert plan.proposed_action == {}
    assert "I am here" in str(plan.final_message_md)


def test_provider_json_builds_draft() -> None:
    payload = {
        "agent_id": "work.generic",
        "domain": "work",
        "intent_labels": ["task"],
        "confidence": 0.83,
        "sensitivity": "normal",
        "risk_level": "durable_state_mutation",
        "needs_review": True,
        "title": "Submit HR paper",
        "body_md": "Draft",
        "proposed_action": {
            "command_type": "life_item.create",
            "risk_level": "durable_state_mutation",
            "payload": {"title": "Submit HR paper"},
        },
        "missing_context": [],
    }

    draft = _draft_from_provider_json("cap_1", json.dumps(payload), "submit HR paper Monday")

    assert draft.agent_id == "work.generic"
    assert draft.proposed_action["payload"]["source_capture_id"] == "cap_1"


def test_invalid_provider_json_rejected() -> None:
    with pytest.raises(ValueError):
        _draft_from_provider_json("cap_1", json.dumps({"agent_id": "work.generic"}), "x")
