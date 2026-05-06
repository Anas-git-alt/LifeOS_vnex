from discord_gateway.main import (
    format_chat_response,
    format_review_card,
    parse_legacy_command,
    parse_lifeos_command,
)
from telegram_gateway.main import map_capture_reply


def test_discord_slash_parser() -> None:
    payload = {
        "options": [
            {
                "name": "capture",
                "options": [{"name": "text", "value": "submit HR paper Monday"}],
            }
        ]
    }

    parsed = parse_lifeos_command(payload)

    assert parsed == {"name": "capture", "options": {"text": "submit HR paper Monday"}}


def test_discord_new_session_parser() -> None:
    payload = {
        "options": [
            {
                "name": "new",
                "options": [
                    {"name": "agent", "value": "research"},
                    {"name": "iteration_cap", "value": 5},
                ],
            }
        ]
    }

    parsed = parse_lifeos_command(payload)

    assert parsed == {"name": "new", "options": {"agent": "research", "iteration_cap": 5}}


def test_discord_legacy_parser() -> None:
    assert parse_legacy_command("!capture submit HR paper Monday") == {
        "name": "capture",
        "text": "submit HR paper Monday",
    }
    assert parse_legacy_command("!help") == {"name": "help", "text": ""}


def test_discord_chat_response_is_compact() -> None:
    text = format_chat_response(
        {
            "answer": "Done.\n\nWhat I did:\n- Added a note.",
            "run_id": "run_1",
            "status": "completed",
        }
    )

    assert "What I did" in text
    assert "`run`: run_1" in text


def test_discord_review_card_has_buttons() -> None:
    card = format_review_card(
        {
            "id": "rev_1",
            "title": "Finance entry",
            "body_md": "40 MAD lunch",
            "risk_level": "finance_mutation",
            "status": "pending",
        }
    )
    custom_ids = [
        component["custom_id"]
        for row in card["components"]
        for component in row["components"]
    ]

    assert "lifeos:review:approve:rev_1" in custom_ids
    assert "lifeos:review:correct:rev_1" in custom_ids


def test_telegram_reply_mapping() -> None:
    assert "No approval needed" in map_capture_reply({"route": {"decision": "raw_only"}})
    assert "Review needed in Discord" in map_capture_reply(
        {"route": {"decision": "review_required", "domain": "finance"}, "message": "Finance entry"}
    )
