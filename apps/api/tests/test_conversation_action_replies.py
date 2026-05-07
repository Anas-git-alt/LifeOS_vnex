from types import SimpleNamespace

from lifeos_api.services.agent_runtime import (
    _answer_only_reply,
    _approved_reply,
    _formal_review_reply,
    _inline_proposal_reply,
    _is_model_identity_question,
    _use_local_conversation_planner_first,
)
from lifeos_api.services.conversation_action_planner import ConversationActionProposal


def test_test_ping_does_not_sound_like_generic_chat() -> None:
    assert _use_local_conversation_planner_first("test 2") is True
    assert "Test ping received" in _answer_only_reply("Hey! How can I assist?", "test 2")


def test_model_question_is_answered_by_runtime_not_provider_hallucination() -> None:
    assert _is_model_identity_question("what model are you using") is True
    assert _is_model_identity_question("what provider are you using") is True


def test_inline_proposal_reply_is_human_and_specific() -> None:
    row = SimpleNamespace(
        summary="Create task: pick up dry cleaning",
        draft_json={"command": {"payload": {"title": "pick up dry cleaning"}}},
    )

    reply = _inline_proposal_reply([row])

    assert "staged it" in reply
    assert "pick up dry cleaning" in reply
    assert "Create adds it" in reply


def test_approved_reply_names_completed_task() -> None:
    row = SimpleNamespace(
        proposal_type="task.complete",
        summary="Mark task done: TESTFIX invoice",
        draft_json={"command": {"payload": {"updates": {"status": "done"}}}},
    )

    reply = _approved_reply([row], [{"command_type": "life_item.update"}])

    assert "TESTFIX invoice" in reply
    assert "complete" in reply


def test_formal_review_reply_explains_why() -> None:
    proposal = ConversationActionProposal(
        type="job.create_recurring",
        summary="Create recurring reminder",
        confidence=0.8,
        risk="medium",
        requires_confirmation=True,
        formal_review_required=True,
        draft={},
    )

    reply = _formal_review_reply([proposal], ["rev_1"])

    assert "recurring automation" in reply
    assert "rev_1" in reply
