"""Python compatibility helpers used by local scripts/tests."""

from datetime import datetime, timezone
from enum import Enum

UTC = getattr(__import__("datetime"), "UTC", timezone.utc)

try:  # Python 3.11+
    from enum import StrEnum as StrEnum
except ImportError:  # pragma: no cover - Python 3.10 fallback

    class StrEnum(str, Enum):
        def __str__(self) -> str:
            return str(self.value)


__all__ = ["StrEnum", "UTC", "datetime"]
