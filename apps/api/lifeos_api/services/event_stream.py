"""In-process status event stream placeholder."""

from collections import deque
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

from lifeos_core.ids import new_id


@dataclass(frozen=True)
class StatusEvent:
    event_type: str
    title: str
    run_id: str | None = None
    visibility: str = "web_only"
    detail: dict[str, Any] = field(default_factory=dict)
    id: str = field(default_factory=lambda: new_id("evt"))
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))


class EventStream:
    """Tiny bounded event buffer until Redis/NATS-backed fanout is added."""

    def __init__(self, maxlen: int = 500) -> None:
        self._events: deque[StatusEvent] = deque(maxlen=maxlen)

    def append(self, event: StatusEvent) -> None:
        self._events.append(event)

    def recent(self) -> list[StatusEvent]:
        return list(self._events)
