import pytest

from lifeos_api.services.conversation_action_planner import (
    interpret_proposal_follow_up,
    plan_conversation_turn,
    revise_proposal_draft,
)


@pytest.mark.asyncio
async def test_explicit_low_risk_task_executes_now() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="create a task to send invoice tomorrow",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "execute_now"
    assert plan.proposals[0].type == "task.create"
    assert plan.proposals[0].draft["command"]["command_type"] == "life_item.create"
    assert plan.proposals[0].draft["command"]["payload"]["title"] == "send invoice"


@pytest.mark.asyncio
async def test_explicit_low_risk_reminder_executes_now() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="remind me tomorrow at 9 to call the dentist",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "execute_now"
    assert plan.proposals[0].type == "reminder.create"
    assert plan.proposals[0].draft["command"]["command_type"] == "job.create"
    assert plan.proposals[0].draft["command"]["payload"]["schedule_type"] == "one_time"


@pytest.mark.asyncio
async def test_implicit_need_creates_inline_proposal() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="I need to take my suit to the ironing shop before the wedding",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "propose_inline"
    assert plan.proposals[0].requires_confirmation is True
    assert plan.proposals[0].draft["explicit"] is False


def test_follow_up_yes_approves_latest_pending_proposal() -> None:
    follow_up = interpret_proposal_follow_up(
        "do it",
        [{"id": "aprop_1"}, {"id": "aprop_2"}],
        timezone="Africa/Casablanca",
    )

    assert follow_up.kind == "approve"
    assert follow_up.proposal_indexes == [1]


def test_follow_up_revises_pending_proposal() -> None:
    follow_up = interpret_proposal_follow_up(
        "make pickup Saturday morning",
        [{"id": "aprop_1"}],
        timezone="Africa/Casablanca",
    )

    assert follow_up.kind == "revise"
    assert follow_up.proposal_indexes == [0]
    assert follow_up.revision_text == "make pickup Saturday morning"


def test_revision_updates_task_due_date() -> None:
    revised = revise_proposal_draft(
        {
            "proposal_type": "task.create",
            "command": {"command_type": "life_item.create", "payload": {"title": "pickup suit"}},
        },
        revision_text="make pickup Saturday morning",
        timezone="Africa/Casablanca",
    )

    assert revised["command"]["payload"]["due_at"].endswith("09:00:00+01:00")


@pytest.mark.asyncio
async def test_advice_question_does_not_mutate_state() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="give me a cheap high protein dinner idea",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "answer_only"
    assert plan.proposals == []


@pytest.mark.asyncio
async def test_memory_preference_requires_formal_review() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="I prefer evening reminders",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "formal_review"
    assert plan.proposals[0].type == "memory_candidate.create"
    assert plan.proposals[0].formal_review_required is True


@pytest.mark.asyncio
async def test_recurring_job_requires_formal_review() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="every Friday remind me to review expenses",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "formal_review"
    assert plan.proposals[0].type == "job.create_recurring"


@pytest.mark.asyncio
async def test_destructive_request_requires_formal_review() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="delete all old task files",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
    )

    assert plan.mode == "formal_review"
    assert plan.proposals[0].risk == "destructive"


@pytest.mark.asyncio
async def test_invalid_llm_json_fails_closed() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="make pickup Saturday morning",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
        llm_plan_json='{"mode": "execute_now"}',
    )

    assert plan.mode == "clarify"
    assert plan.proposals == []


@pytest.mark.asyncio
async def test_provider_cannot_answer_only_memory_preference() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="I prefer evening reminders",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
        llm_plan_json='{"mode":"answer_only","assistant_reply":"Got it, I will remember that.","proposals":[]}',
    )

    assert plan.mode == "formal_review"
    assert plan.proposals[0].type == "memory_candidate.create"


@pytest.mark.asyncio
async def test_provider_task_payload_is_sanitized_before_execution() -> None:
    plan = await plan_conversation_turn(
        agent_name="orchestrator",
        user_message="create a task to send TEST invoice tomorrow",
        session_id="sess_1",
        source="discord",
        recent_context=[],
        state_packet=None,
        timezone="Africa/Casablanca",
        llm_plan_json=(
            '{"mode":"execute_now","assistant_reply":"Sure, created.",'
            '"proposals":[{"type":"task.create","summary":"Create task","confidence":0.95,'
            '"risk":"low","requires_confirmation":false,"formal_review_required":false,'
            '"draft":{"explicit":true,"proposal_type":"task.create","command":{"command_type":"life_item.create",'
            '"payload":{"description":"Send TEST invoice","due_at":"2025-01-01"}}}}]}'
        ),
    )

    payload = plan.proposals[0].draft["command"]["payload"]
    assert plan.mode == "execute_now"
    assert payload["title"] == "send TEST invoice"
    assert payload["due_at"].startswith("2026-")
