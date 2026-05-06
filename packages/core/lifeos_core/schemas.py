"""Dependency-light dataclass contracts shared by services."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any


@dataclass(frozen=True)
class EvidenceRef:
    kind: str
    id: str
    uri: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class AuditRef:
    actor_type: str
    actor_id: str
    trace_id: str | None = None
    created_at: datetime | None = None
