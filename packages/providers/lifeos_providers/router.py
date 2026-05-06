"""Provider router skeleton.

This module captures the routing policy shape. The executable model call
adapters will be added after the review loop and run tracing are in place.
"""

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class ProviderChoice:
    provider: str
    model: str
    fallback_allowed: bool
    raw: dict[str, Any]


class ProviderRouter:
    def __init__(self, config_path: Path | str = "configs/providers.yaml") -> None:
        self.config_path = Path(config_path)
        self.config = yaml.safe_load(self.config_path.read_text(encoding="utf-8")) or {}

    def choose_for_agent(self, agent_id: str) -> ProviderChoice:
        agent_models = self.config.get("agent_models", {})
        if agent_id not in agent_models:
            raise KeyError(f"No provider config for agent {agent_id!r}")

        raw = agent_models[agent_id]
        primary = raw["primary"]
        return ProviderChoice(
            provider=primary["provider"],
            model=primary["model"],
            fallback_allowed=bool(raw.get("fallback_allowed", True)),
            raw=raw,
        )
