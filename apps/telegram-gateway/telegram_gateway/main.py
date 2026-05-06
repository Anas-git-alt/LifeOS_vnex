"""Thin Telegram raw-capture gateway.

Uses Telegram's HTTP Bot API directly so the gateway remains dependency-light.
It only captures owner text messages and forwards them to the LifeOS API.
"""

from __future__ import annotations

import json
import os
import time
from urllib.error import URLError
from urllib.request import Request, urlopen


def validate_config() -> list[str]:
    missing = []
    for key in ["TELEGRAM_BOT_TOKEN", "TELEGRAM_OWNER_USER_ID", "LIFEOS_API_BASE_URL"]:
        if not os.getenv(key):
            missing.append(key)
    return missing


def post_json(url: str, payload: dict[str, object]) -> dict[str, object]:
    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urlopen(request, timeout=20) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def get_json(url: str) -> dict[str, object]:
    with urlopen(url, timeout=35) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def send_message(token: str, chat_id: int, text: str) -> None:
    post_json(f"https://api.telegram.org/bot{token}/sendMessage", {"chat_id": chat_id, "text": text})


def forward_capture(api_base: str, message: dict[str, object]) -> str:
    text = str(message.get("text") or message.get("caption") or "")
    response = post_json(
        f"{api_base}/api/captures",
        {
            "source_platform": "telegram",
            "external_message_id": str(message.get("message_id")),
            "external_thread_id": None,
            "capture_kind": "text" if text else "mixed",
            "raw_text": text,
            "metadata": {"telegram_chat_id": message.get("chat", {}).get("id")},
        },
    )
    return str(response.get("review_item_id", response.get("capture", {}).get("id", "captured")))


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
                chat = message.get("chat", {})
                if not isinstance(chat, dict):
                    continue
                review_or_capture_id = forward_capture(api_base, message)
                send_message(token, int(chat["id"]), f"Captured. Review item: {review_or_capture_id}")
        except (OSError, URLError, TimeoutError, KeyError, ValueError) as exc:
            print(f"telegram-gateway error: {exc}", flush=True)
            time.sleep(10)


if __name__ == "__main__":
    main()
