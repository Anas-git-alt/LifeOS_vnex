"""Thin Telegram capture/command gateway."""

from __future__ import annotations

import json
import os
import time
from urllib.error import URLError
from urllib.request import Request, urlopen


def validate_config() -> list[str]:
    return [
        key
        for key in ["TELEGRAM_BOT_TOKEN", "TELEGRAM_OWNER_USER_ID", "LIFEOS_API_BASE_URL"]
        if not os.getenv(key)
    ]


def post_json(url: str, payload: dict[str, object]) -> dict[str, object]:
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=30) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def get_json(url: str) -> dict[str, object]:
    with urlopen(url, timeout=35) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def send_message(token: str, chat_id: int, text: str) -> None:
    post_json(
        f"https://api.telegram.org/bot{token}/sendMessage",
        {"chat_id": chat_id, "text": text[:3900]},
    )


def forward_capture(api_base: str, message: dict[str, object], text_override: str | None = None) -> dict[str, object]:
    text = str(text_override if text_override is not None else message.get("text") or message.get("caption") or "")
    kind = capture_kind(message)
    return post_json(
        f"{api_base}/api/captures",
        {
            "source_platform": "telegram",
            "external_message_id": str(message.get("message_id")),
            "external_thread_id": None,
            "capture_kind": kind,
            "raw_text": text,
            "metadata": {
                "telegram_chat_id": _chat_id(message),
                "owner_authenticated": True,
                "attachment_stub": attachment_stub(message),
            },
        },
    )


def capture_kind(message: dict[str, object]) -> str:
    if message.get("voice"):
        return "voice"
    if message.get("photo"):
        return "image"
    if message.get("document"):
        return "file"
    if message.get("caption") and (message.get("video") or message.get("audio")):
        return "mixed"
    return "text"


def attachment_stub(message: dict[str, object]) -> dict[str, object]:
    if message.get("voice"):
        return {"kind": "voice", "transcription": "not_implemented"}
    if message.get("document"):
        doc = message.get("document")
        return doc if isinstance(doc, dict) else {"kind": "file"}
    if message.get("photo"):
        photos = message.get("photo")
        return {"kind": "image", "count": len(photos) if isinstance(photos, list) else 1}
    return {}


def map_capture_reply(response: dict[str, object]) -> str:
    route = response.get("route", {})
    decision = route.get("decision") if isinstance(route, dict) else None
    if decision == "raw_only":
        return "Captured. I saved it as raw context. No approval needed."
    if decision == "auto_apply":
        return str(response.get("message") or "Done.")
    if decision == "review_required":
        title = route.get("domain") if isinstance(route, dict) else "review"
        return f"Captured. Review needed in Discord: {response.get('message') or title}"
    if decision == "ask_clarification":
        return "I need one detail; I asked in Discord."
    agent = route.get("agent_id") if isinstance(route, dict) else None
    if agent:
        return f"Captured and routed to {agent}. I'll ask in Discord if anything needs review."
    return str(response.get("message") or "Captured.")


def handle_command(api_base: str, message: dict[str, object], text: str) -> str:
    if text == "/help":
        return "\n".join(["/capture <text>", "/ask <message>", "/today", "/status", "/help"])
    if text == "/status":
        readiness = get_json(f"{api_base}/api/readiness")
        return f"API: {readiness.get('status')}"
    if text == "/today":
        today = get_json(f"{api_base}/api/today")
        tasks = today.get("tasks", [])
        lines = [str(today.get("focus", "Today"))]
        if isinstance(tasks, list):
            lines.extend(f"- {item.get('title')}" for item in tasks[:8] if isinstance(item, dict))
        return "\n".join(lines)
    if text.startswith("/ask "):
        response = post_json(
            f"{api_base}/api/ask",
            {
                "source_platform": "telegram",
                "source_external_message_id": str(message.get("message_id")),
                "message": text.removeprefix("/ask ").strip(),
            },
        )
        return str(response.get("answer") or "Asked.")
    if text.startswith("/capture "):
        response = forward_capture(api_base, message, text.removeprefix("/capture ").strip())
        return map_capture_reply(response)
    return ""


def _chat_id(message: dict[str, object]) -> object:
    chat = message.get("chat", {})
    return chat.get("id") if isinstance(chat, dict) else None


def main() -> None:
    missing = validate_config()
    if missing:
        print(f"telegram-gateway config missing: {', '.join(missing)}", flush=True)
        while True:
            time.sleep(60)

    token = os.environ["TELEGRAM_BOT_TOKEN"]
    owner_id = int(os.environ["TELEGRAM_OWNER_USER_ID"])
    api_base = os.getenv("LIFEOS_API_BASE_URL", "http://api:8000")
    offset = 0
    print("telegram-gateway polling enabled", flush=True)

    while True:
        try:
            payload = get_json(
                f"https://api.telegram.org/bot{token}/getUpdates?timeout=25&offset={offset}"
            )
            for update in payload.get("result", []):
                if not isinstance(update, dict):
                    continue
                offset = int(update.get("update_id", offset)) + 1
                message = update.get("message") or update.get("edited_message")
                if not isinstance(message, dict):
                    continue
                sender = message.get("from", {})
                if not isinstance(sender, dict) or int(sender.get("id", 0)) != owner_id:
                    continue
                chat_id = _chat_id(message)
                if chat_id is None:
                    continue
                text = str(message.get("text") or "")
                if text.startswith("/"):
                    reply = handle_command(api_base, message, text.strip())
                    if reply:
                        send_message(token, int(chat_id), reply)
                    continue
                if not text and message.get("voice"):
                    send_message(token, int(chat_id), "Voice captured. Transcription is not enabled yet.")
                response = forward_capture(api_base, message)
                send_message(token, int(chat_id), map_capture_reply(response))
        except (OSError, URLError, TimeoutError, KeyError, ValueError) as exc:
            print(f"telegram-gateway error: {exc}", flush=True)
            time.sleep(10)


if __name__ == "__main__":
    main()
