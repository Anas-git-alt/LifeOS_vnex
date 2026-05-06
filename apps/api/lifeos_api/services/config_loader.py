"""YAML config loader."""

from functools import lru_cache
from pathlib import Path
from typing import Any

import yaml


ROOT = Path(__file__).resolve().parents[4]


@lru_cache
def load_config(name: str) -> dict[str, Any]:
    return yaml.safe_load((ROOT / "configs" / name).read_text(encoding="utf-8")) or {}


@lru_cache
def load_agent_config(agent_file: str) -> dict[str, Any]:
    return yaml.safe_load((ROOT / "configs" / "agents" / agent_file).read_text(encoding="utf-8")) or {}
