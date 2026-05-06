"""Capture API contracts."""

from datetime import datetime

from pydantic import BaseModel, Field

from lifeos_core.compat import StrEnum
from lifeos_core.time import utc_now


class CaptureKind(StrEnum):
    text = "text"
    voice = "voice"
    image = "image"
    file = "file"
    link = "link"
    screenshot = "screenshot"
    mixed = "mixed"


class CaptureCreate(BaseModel):
    source_platform: str = Field(description="discord, telegram, web, job, or api")
    source_channel_id: str | None = None
    external_message_id: str | None = None
    external_thread_id: str | None = None
    capture_kind: CaptureKind = CaptureKind.text
    raw_text: str | None = None
    received_at: datetime = Field(default_factory=utc_now)
    sensitivity: str = "normal"
    metadata: dict[str, object] = Field(default_factory=dict)
