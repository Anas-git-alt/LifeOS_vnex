#!/usr/bin/env python3
"""Validate the LifeOS vNext Phase 0 scaffold."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ModuleNotFoundError:  # pragma: no cover - keeps the script helpful pre-install
    yaml = None  # type: ignore[assignment]


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_PATHS = [
    "README.md",
    "AGENTS.md",
    "docker-compose.yml",
    ".env.example",
    "apps/api/lifeos_api/main.py",
    "apps/web/package.json",
    "configs/providers.yaml",
    "configs/tools.yaml",
    "configs/policies.yaml",
    "configs/discord.yaml",
    "configs/telegram.yaml",
    "vault/README.md",
]

REQUIRED_ENV_KEYS = [
    "LIFEOS_ENV",
    "LIFEOS_TIMEZONE",
    "DATABASE_URL",
    "REDIS_URL",
    "DISCORD_BOT_TOKEN",
    "DISCORD_OWNER_USER_ID",
    "DISCORD_APPROVAL_CHANNEL_ID",
    "TELEGRAM_BOT_TOKEN",
    "TELEGRAM_OWNER_USER_ID",
    "OPENROUTER_API_KEY_1",
    "NVIDIA_NIM_API_KEY_1",
]


def read_yaml(path: Path) -> dict[str, Any]:
    if yaml is None:
        raise RuntimeError("PyYAML is not installed; install project dependencies or run in Docker.")
    payload = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise ValueError(f"{path} must contain a YAML mapping")
    return payload


def check_required_paths() -> list[str]:
    errors = []
    for rel in REQUIRED_PATHS:
        if not (ROOT / rel).exists():
            errors.append(f"missing required path: {rel}")
    return errors


def check_env_example() -> list[str]:
    errors = []
    env_text = (ROOT / ".env.example").read_text(encoding="utf-8")
    for key in REQUIRED_ENV_KEYS:
        if f"{key}=" not in env_text:
            errors.append(f".env.example missing {key}")
    return errors


def check_yaml_configs() -> list[str]:
    errors = []
    if yaml is None:
        return ["PyYAML missing; YAML config syntax was not checked"]

    for path in sorted((ROOT / "configs").glob("**/*.yaml")):
        try:
            data = read_yaml(path)
        except Exception as exc:  # noqa: BLE001 - doctor should report all config problems
            errors.append(f"{path.relative_to(ROOT)} failed to parse: {exc}")
            continue
        if data.get("version") != 1:
            errors.append(f"{path.relative_to(ROOT)} must declare version: 1")

    providers = read_yaml(ROOT / "configs/providers.yaml")
    for provider_name, provider in providers.get("providers", {}).items():
        if provider.get("enabled") and not provider.get("type"):
            errors.append(f"provider {provider_name} missing type")

    agents = []
    for path in sorted((ROOT / "configs/agents").glob("*.yaml")):
        data = read_yaml(path)
        agents.append(data.get("id"))
        for key in ["id", "display_name", "domain", "role", "autonomy_level"]:
            if key not in data:
                errors.append(f"{path.relative_to(ROOT)} missing {key}")
    if "work.generic" not in agents:
        errors.append("Generic Work Agent config missing")
    if "approval-manager" not in agents:
        errors.append("Approval Manager config missing")

    return errors


def check_vault_shape() -> list[str]:
    errors = []
    required_dirs = [
        "vault/raw",
        "vault/ledger",
        "vault/memory/review",
        "vault/memory/curated",
        "vault/wiki",
        "vault/state",
        "vault/reports",
        "vault/artifacts",
        "vault/manifests",
        "vault/system/dead-letter",
    ]
    for rel in required_dirs:
        if not (ROOT / rel).is_dir():
            errors.append(f"missing vault directory: {rel}")
    return errors


def check_live_env() -> list[str]:
    warnings = []
    for key in ["DISCORD_BOT_TOKEN", "TELEGRAM_BOT_TOKEN", "OPENROUTER_API_KEY_1", "NVIDIA_NIM_API_KEY_1"]:
        if not os.getenv(key):
            warnings.append(f"{key} is not set in the current shell")
    return warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--strict", action="store_true", help="Treat warnings as failures.")
    args = parser.parse_args()

    errors = []
    warnings = []

    errors.extend(check_required_paths())
    errors.extend(check_env_example())
    errors.extend(check_yaml_configs())
    errors.extend(check_vault_shape())
    warnings.extend(check_live_env())

    if warnings:
        print("Warnings:")
        for warning in warnings:
            print(f"  - {warning}")

    if errors:
        print("Errors:")
        for error in errors:
            print(f"  - {error}")
        return 1

    if args.strict and warnings:
        return 1

    print("LifeOS doctor: scaffold and configs look good.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
