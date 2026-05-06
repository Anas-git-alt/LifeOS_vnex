"""Time helpers."""

from datetime import UTC, datetime
from zoneinfo import ZoneInfo


def utc_now() -> datetime:
    return datetime.now(UTC)


def local_now(timezone: str = "Africa/Casablanca") -> datetime:
    return datetime.now(ZoneInfo(timezone))
