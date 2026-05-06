"""Agent registry loader."""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class AgentConfig:
    id: str
    display_name: str
    domain: str
    role: str
    enabled: bool
    autonomy_level: str
    raw: dict[str, Any] = field(repr=False)


def load_agent_configs(config_dir: Path | str = "configs/agents") -> list[AgentConfig]:
    root = Path(config_dir)
    configs: list[AgentConfig] = []
    for path in sorted(root.glob("*.yaml")):
        data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
        configs.append(
            AgentConfig(
                id=data["id"],
                display_name=data["display_name"],
                domain=data["domain"],
                role=data["role"],
                enabled=bool(data.get("enabled", True)),
                autonomy_level=data.get("autonomy_level", "review_gated"),
                raw=data,
            )
        )
    return configs
