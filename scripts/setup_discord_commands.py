#!/usr/bin/env python3
"""Register LifeOS Discord slash commands or dry-run readiness."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "apps" / "discord-gateway"))

from discord_gateway.main import register_commands, validate_config  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    missing = [key for key in validate_config() if key != "DISCORD_APPROVAL_CHANNEL_ID"]
    if missing:
        print(f"missing: {', '.join(missing)}")
        return 1
    result = register_commands(os.environ["DISCORD_BOT_TOKEN"], dry_run=args.dry_run)
    print(result)
    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    raise SystemExit(main())
