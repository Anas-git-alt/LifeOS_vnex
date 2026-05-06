"""Raw capture handler contracts for Telegram."""

from dataclasses import dataclass


@dataclass(frozen=True)
class TelegramCapture:
    external_message_id: str
    capture_kind: str
    raw_text: str | None = None
