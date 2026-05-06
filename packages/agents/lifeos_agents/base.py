"""Base contracts for LifeOS agents."""

from dataclasses import dataclass, field
from typing import Any


@dataclass(frozen=True)
class AgentTask:
    task_type: str
    summary: str
    context_refs: list[dict[str, Any]] = field(default_factory=list)
    constraints: dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class AgentDraft:
    agent_id: str
    summary_md: str
    confidence: float
    proposed_actions: list[dict[str, Any]] = field(default_factory=list)
    needs_review: bool = True
