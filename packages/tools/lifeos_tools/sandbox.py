"""Sandbox contract placeholders."""

from dataclasses import dataclass, field


@dataclass(frozen=True)
class SandboxPolicy:
    mode: str = "docker"
    allowed_paths: list[str] = field(default_factory=list)
    allowed_commands: list[str] = field(default_factory=list)
    blocked_patterns: list[str] = field(default_factory=list)
