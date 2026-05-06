"""Tool registry loader."""

from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml


@dataclass(frozen=True)
class ToolConfig:
    id: str
    display_name: str
    category: str
    risk_level: str
    raw: dict[str, Any]


def load_tool_config(path: Path | str = "configs/tools.yaml") -> list[ToolConfig]:
    data = yaml.safe_load(Path(path).read_text(encoding="utf-8")) or {}
    tools = data.get("tools", {})
    return [
        ToolConfig(
            id=tool_id,
            display_name=payload["display_name"],
            category=payload["category"],
            risk_level=payload["risk_level"],
            raw=payload,
        )
        for tool_id, payload in sorted(tools.items())
    ]
