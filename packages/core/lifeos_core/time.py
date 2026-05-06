"""Time helpers."""

from datetime import datetime
from zoneinfo import ZoneInfo

from lifeos_core.compat import UTC


def utc_now() -> datetime:
    return datetime.now(UTC)


def local_now(timezone: str = "Africa/Casablanca") -> datetime:
    return datetime.now(ZoneInfo(timezone))
