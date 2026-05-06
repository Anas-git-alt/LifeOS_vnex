#!/usr/bin/env python3
"""Create or verify the LifeOS Discord channel structure.

Default mode is read-only planning. Use --apply to create missing categories and
channels. Existing Discord channels are never deleted. Use --sync-existing to
move existing channels under their configured categories and update topics.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import yaml


ROOT = Path(__file__).resolve().parents[1]
API_BASE = "https://discord.com/api/v10"

CATEGORY_TYPE = 4
TEXT_TYPE = 0

VIEW_CHANNEL = 1 << 10
SEND_MESSAGES = 1 << 11
EMBED_LINKS = 1 << 14
ATTACH_FILES = 1 << 15
READ_MESSAGE_HISTORY = 1 << 16
ADD_REACTIONS = 1 << 6

OWNER_ALLOW = VIEW_CHANNEL | SEND_MESSAGES | READ_MESSAGE_HISTORY | ADD_REACTIONS
BOT_ALLOW = OWNER_ALLOW | EMBED_LINKS | ATTACH_FILES


class DiscordError(RuntimeError):
    pass


def read_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def env_value(name: str, file_values: dict[str, str]) -> str:
    return os.getenv(name) or file_values.get(name, "")


def load_config() -> dict[str, Any]:
    payload = yaml.safe_load((ROOT / "configs" / "discord.yaml").read_text(encoding="utf-8"))
    if not isinstance(payload, dict):
        raise DiscordError("configs/discord.yaml must be a mapping")
    return payload


class DiscordClient:
    def __init__(self, token: str) -> None:
        self.token = token

    def request(self, method: str, path: str, payload: dict[str, Any] | None = None) -> Any:
        data = json.dumps(payload).encode("utf-8") if payload is not None else None
        request = Request(
            f"{API_BASE}{path}",
            data=data,
            headers={
                "Authorization": f"Bot {self.token}",
                "Content-Type": "application/json",
                "User-Agent": "LifeOS-vNext Discord setup",
            },
            method=method,
        )
        try:
            with urlopen(request, timeout=20) as response:  # noqa: S310
                body = response.read().decode("utf-8")
                return json.loads(body) if body else None
        except HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise DiscordError(f"{method} {path} failed HTTP {exc.code}: {detail}") from exc
        except (OSError, URLError, TimeoutError) as exc:
            raise DiscordError(f"{method} {path} failed: {exc}") from exc

    def me(self) -> dict[str, Any]:
        payload = self.request("GET", "/users/@me")
        if not isinstance(payload, dict) or not payload.get("id"):
            raise DiscordError("Discord /users/@me returned unexpected payload")
        return payload

    def guild_channels(self, guild_id: str) -> list[dict[str, Any]]:
        payload = self.request("GET", f"/guilds/{guild_id}/channels")
        if not isinstance(payload, list):
            raise DiscordError("Discord guild channels response was not a list")
        return [item for item in payload if isinstance(item, dict)]

    def create_channel(self, guild_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        created = self.request("POST", f"/guilds/{guild_id}/channels", payload)
        if not isinstance(created, dict) or not created.get("id"):
            raise DiscordError("Discord create channel returned unexpected payload")
        return created

    def modify_channel(self, channel_id: str, payload: dict[str, Any]) -> dict[str, Any]:
        updated = self.request("PATCH", f"/channels/{channel_id}", payload)
        if not isinstance(updated, dict) or not updated.get("id"):
            raise DiscordError("Discord modify channel returned unexpected payload")
        return updated


def permission_overwrites(guild_id: str, owner_id: str, bot_id: str) -> list[dict[str, str | int]]:
    return [
        {"id": guild_id, "type": 0, "deny": str(VIEW_CHANNEL), "allow": "0"},
        {"id": owner_id, "type": 1, "allow": str(OWNER_ALLOW), "deny": "0"},
        {"id": bot_id, "type": 1, "allow": str(BOT_ALLOW), "deny": "0"},
    ]


def channel_key(channel: dict[str, Any]) -> tuple[int, str]:
    return int(channel.get("type", -1)), str(channel.get("name", ""))


def format_env_block(channel_ids: dict[str, str]) -> str:
    lines = ["# Discord channel IDs generated from configs/discord.yaml"]
    for key in sorted(channel_ids):
        lines.append(f"{key}={channel_ids[key]}")
    return "\n".join(lines)


def write_env_values(path: Path, values: dict[str, str]) -> None:
    existing = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    seen: set[str] = set()
    output: list[str] = []
    for line in existing:
        if "=" not in line or line.strip().startswith("#"):
            output.append(line)
            continue
        key, _value = line.split("=", 1)
        stripped_key = key.strip()
        if stripped_key in values:
            output.append(f"{stripped_key}={values[stripped_key]}")
            seen.add(stripped_key)
        else:
            output.append(line)
    missing = [key for key in sorted(values) if key not in seen]
    if missing:
        if output and output[-1].strip():
            output.append("")
        output.append("# Discord channel IDs")
        output.extend(f"{key}={values[key]}" for key in missing)
    path.write_text("\n".join(output) + "\n", encoding="utf-8")


def plan_or_apply(apply: bool, sync_existing: bool, write_env: bool) -> int:
    config = load_config()
    env_file = read_env_file(ROOT / ".env")
    token = env_value("DISCORD_BOT_TOKEN", env_file)
    owner_id = env_value("DISCORD_OWNER_USER_ID", env_file)
    guild_id = env_value("DISCORD_GUILD_ID", env_file)

    missing = [
        name
        for name, value in [
            ("DISCORD_BOT_TOKEN", token),
            ("DISCORD_OWNER_USER_ID", owner_id),
            ("DISCORD_GUILD_ID", guild_id),
        ]
        if not value
    ]
    if missing:
        print(f"Missing required env: {', '.join(missing)}")
        return 2

    client = DiscordClient(token)
    bot_id = str(client.me()["id"])
    channels = client.guild_channels(guild_id)
    existing = {channel_key(channel): channel for channel in channels}

    overwrites = permission_overwrites(guild_id, owner_id, bot_id)
    category_ids: dict[str, str] = {}
    channel_ids: dict[str, str] = {}

    print("LifeOS Discord structure")
    if apply and sync_existing:
        mode = "APPLY create missing + sync existing placement/topic"
    elif apply:
        mode = "APPLY create missing only"
    else:
        mode = "PLAN read-only"
    print(f"Mode: {mode}")

    for category_id, category in config.get("categories", {}).items():
        name = str(category["name"])
        found = existing.get((CATEGORY_TYPE, name))
        if found:
            category_ids[category_id] = str(found["id"])
            print(f"OK   category {name}")
            continue
        print(f"MISS category {name}")
        if apply:
            created = client.create_channel(
                guild_id,
                {
                    "name": name,
                    "type": CATEGORY_TYPE,
                    "position": int(category.get("position", 50)),
                    "permission_overwrites": overwrites,
                },
            )
            category_ids[category_id] = str(created["id"])
            print(f"ADD  category {name}")

    for channel_id, channel in config.get("channels", {}).items():
        name = str(channel["name"])
        env_name = str(channel.get("env") or f"DISCORD_{channel_id.upper()}_CHANNEL_ID")
        found = existing.get((TEXT_TYPE, name))
        if found:
            channel_ids[env_name] = str(found["id"])
            updates: dict[str, Any] = {}
            parent_key = channel.get("category")
            parent_id = category_ids.get(str(parent_key)) if parent_key else None
            if parent_id and str(found.get("parent_id") or "") != parent_id:
                updates["parent_id"] = parent_id
            topic = channel.get("topic")
            if topic and str(found.get("topic") or "") != str(topic):
                updates["topic"] = str(topic)
            if updates and apply and sync_existing:
                client.modify_channel(str(found["id"]), updates)
                print(f"SYNC #{name} -> {env_name}")
            elif updates:
                print(f"NEED #{name} -> {env_name} sync={', '.join(updates)}")
            else:
                print(f"OK   #{name} -> {env_name}")
            continue
        print(f"MISS #{name} -> {env_name}")
        if apply:
            payload: dict[str, Any] = {
                "name": name,
                "type": TEXT_TYPE,
                "permission_overwrites": overwrites,
            }
            topic = channel.get("topic")
            if topic:
                payload["topic"] = str(topic)
            parent_key = channel.get("category")
            if parent_key:
                parent_id = category_ids.get(str(parent_key))
                if not parent_id:
                    raise DiscordError(f"category {parent_key} missing for #{name}")
                payload["parent_id"] = parent_id
            created = client.create_channel(guild_id, payload)
            channel_ids[env_name] = str(created["id"])
            print(f"ADD  #{name} -> {env_name}")

    if channel_ids:
        print()
        print(format_env_block(channel_ids))

    if write_env and channel_ids:
        if not apply:
            print("SKIP .env write: use --apply with --write-env")
        else:
            write_env_values(ROOT / ".env", channel_ids)
            print()
            print("Updated .env channel IDs.")

    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="Create missing Discord categories/channels.")
    parser.add_argument(
        "--sync-existing",
        action="store_true",
        help="With --apply, move existing channels under configured categories and update topics.",
    )
    parser.add_argument("--write-env", action="store_true", help="Write discovered channel IDs into .env.")
    args = parser.parse_args()

    try:
        return plan_or_apply(apply=args.apply, sync_existing=args.sync_existing, write_env=args.write_env)
    except DiscordError as exc:
        print(f"Error: {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
