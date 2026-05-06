#!/usr/bin/env python3
"""Manual Discord checks for LifeOS.

Default mode is read-only. Use --send-delete to post one test message to
bot-testing and delete it after a short delay.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

import yaml


ROOT = Path(__file__).resolve().parents[1]
API_BASE = "https://discord.com/api/v10"


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
                "User-Agent": "LifeOS-vNext Discord manual test",
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


def load_channel_name(key: str) -> str:
    config = yaml.safe_load((ROOT / "configs" / "discord.yaml").read_text(encoding="utf-8"))
    return str(config["channels"][key]["name"])


def find_channel_id(client: DiscordClient, guild_id: str, name: str) -> str:
    payload = client.request("GET", f"/guilds/{guild_id}/channels")
    if not isinstance(payload, list):
        raise DiscordError("guild channels response was not a list")
    for channel in payload:
        if isinstance(channel, dict) and channel.get("name") == name and channel.get("type") == 0:
            return str(channel["id"])
    raise DiscordError(f"#{name} not found")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--channel", default="bot_testing", help="configs/discord.yaml channel key.")
    parser.add_argument("--send-delete", action="store_true", help="Send one test message, then delete it.")
    parser.add_argument("--delete-after", type=int, default=5, help="Seconds before deleting sent test message.")
    args = parser.parse_args()

    env_file = read_env_file(ROOT / ".env")
    token = env_value("DISCORD_BOT_TOKEN", env_file)
    guild_id = env_value("DISCORD_GUILD_ID", env_file)
    if not token or not guild_id:
        print("Missing required env: DISCORD_BOT_TOKEN, DISCORD_GUILD_ID")
        return 2

    client = DiscordClient(token)
    me = client.request("GET", "/users/@me")
    if not isinstance(me, dict) or not me.get("id"):
        raise DiscordError("Discord auth failed")
    channel_name = load_channel_name(args.channel)
    channel_id = env_value(f"DISCORD_{args.channel.upper()}_CHANNEL_ID", env_file)
    if not channel_id:
        channel_id = find_channel_id(client, guild_id, channel_name)

    channel = client.request("GET", f"/channels/{channel_id}")
    if not isinstance(channel, dict):
        raise DiscordError("Discord channel read failed")
    print(f"OK auth bot_id={me['id']}")
    print(f"OK channel #{channel.get('name')} id={channel_id}")

    if not args.send_delete:
        print("Mode: read-only. No message sent.")
        return 0

    content = f"LifeOS Discord manual test {datetime.now(timezone.utc).isoformat(timespec='seconds')}"
    message = client.request("POST", f"/channels/{channel_id}/messages", {"content": content})
    if not isinstance(message, dict) or not message.get("id"):
        raise DiscordError("message send returned unexpected payload")
    message_id = str(message["id"])
    print(f"SENT message_id={message_id}")
    time.sleep(max(args.delete_after, 0))
    client.request("DELETE", f"/channels/{channel_id}/messages/{message_id}")
    print(f"DELETED message_id={message_id}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except DiscordError as exc:
        print(f"Error: {exc}")
        sys.exit(1)
