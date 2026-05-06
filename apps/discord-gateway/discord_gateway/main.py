"""Thin Discord review-card gateway.

This dependency-light adapter posts pending review cards to one configured
Discord channel. Interaction callbacks/buttons are the next adapter layer; the
API review decision endpoint is already implemented.
"""

from __future__ import annotations

import asyncio
import json
import os
import platform
import threading
import time
from urllib.error import URLError
from urllib.request import Request, urlopen

import websockets
from websockets.exceptions import ConnectionClosed


def validate_config() -> list[str]:
    missing = []
    for key in [
        "DISCORD_BOT_TOKEN",
        "DISCORD_OWNER_USER_ID",
        "DISCORD_APPROVAL_CHANNEL_ID",
        "LIFEOS_API_BASE_URL",
    ]:
        if not os.getenv(key):
            missing.append(key)
    return missing


def get_json(url: str) -> dict[str, object]:
    with urlopen(url, timeout=20) as response:  # noqa: S310
        return json.loads(response.read().decode("utf-8"))


def post_discord_message(token: str, channel_id: str, content: str) -> None:
    request = Request(
        f"https://discord.com/api/v10/channels/{channel_id}/messages",
        data=json.dumps({"content": content[:1900]}).encode("utf-8"),
        headers={
            "Authorization": f"Bot {token}",
            "Content-Type": "application/json",
            "User-Agent": "LifeOS-vNext (https://lifeos.local, 0.1)",
        },
        method="POST",
    )
    with urlopen(request, timeout=20):  # noqa: S310
        return


def env_flag(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def format_review_card(item: dict[str, object]) -> str:
    return "\n".join(
        [
            f"Review needed: {item.get('title')}",
            "",
            str(item.get("body_md") or ""),
            "",
            f"review_id: {item.get('id')}",
            f"agent: {item.get('proposed_by_agent_id')}",
            f"risk: {item.get('risk_level')}",
            "",
            "Decide in WebUI or POST /api/reviews/{review_id}/decision.",
        ]
    )


def review_poller(token: str, channel_id: str, api_base: str, dry_run: bool, post_existing: bool) -> None:
    posted: set[str] = set()
    print(
        f"discord-gateway review posting enabled api_base={api_base} dry_run={dry_run}",
        flush=True,
    )

    if not post_existing:
        try:
            payload = get_json(f"{api_base}/api/reviews?status=pending&limit=100")
            posted = {
                str(item.get("id"))
                for item in payload.get("items", [])
                if isinstance(item, dict) and item.get("id")
            }
            print(f"discord-gateway skipped existing pending reviews count={len(posted)}", flush=True)
        except (OSError, URLError, TimeoutError, KeyError, ValueError) as exc:
            print(f"discord-gateway startup sync error: {exc}", flush=True)

    while True:
        try:
            payload = get_json(f"{api_base}/api/reviews?status=pending&limit=20")
            for item in payload.get("items", []):
                if not isinstance(item, dict):
                    continue
                review_id = str(item.get("id"))
                if review_id in posted:
                    continue
                if dry_run:
                    print(f"discord-gateway dry-run would post review_id={review_id}", flush=True)
                else:
                    post_discord_message(token, channel_id, format_review_card(item))
                posted.add(review_id)
            time.sleep(15)
        except (OSError, URLError, TimeoutError, KeyError, ValueError) as exc:
            print(f"discord-gateway error: {exc}", flush=True)
            time.sleep(15)


async def heartbeat_loop(websocket: websockets.ClientConnection, interval_seconds: float, seq: dict[str, int | None]) -> None:
    while True:
        await asyncio.sleep(interval_seconds)
        await websocket.send(json.dumps({"op": 1, "d": seq["value"]}))


async def run_discord_gateway(token: str) -> None:
    gateway_url = "wss://gateway.discord.gg/?v=10&encoding=json"

    while True:
        seq: dict[str, int | None] = {"value": None}
        heartbeat_task: asyncio.Task[None] | None = None
        try:
            async with websockets.connect(gateway_url, ping_interval=None, close_timeout=5) as websocket:
                print("discord-gateway websocket connected", flush=True)
                async for raw_message in websocket:
                    payload = json.loads(raw_message)
                    op = payload.get("op")
                    data = payload.get("d")
                    sequence = payload.get("s")
                    if sequence is not None:
                        seq["value"] = int(sequence)

                    if op == 10 and isinstance(data, dict):
                        heartbeat_interval = float(data["heartbeat_interval"]) / 1000
                        if heartbeat_task is not None:
                            heartbeat_task.cancel()
                        heartbeat_task = asyncio.create_task(
                            heartbeat_loop(websocket, heartbeat_interval, seq)
                        )
                        identify = {
                            "op": 2,
                            "d": {
                                "token": token,
                                "intents": 0,
                                "properties": {
                                    "os": platform.system().lower(),
                                    "browser": "lifeos-vnext",
                                    "device": "lifeos-vnext",
                                },
                                "presence": {
                                    "since": None,
                                    "activities": [{"name": "LifeOS review queue", "type": 3}],
                                    "status": "online",
                                    "afk": False,
                                },
                            },
                        }
                        await websocket.send(json.dumps(identify))
                        continue

                    if op == 0 and payload.get("t") == "READY" and isinstance(data, dict):
                        print(
                            f"discord-gateway websocket ready session_id={data.get('session_id')}",
                            flush=True,
                        )
                        continue

                    if op == 7:
                        print("discord-gateway websocket reconnect requested", flush=True)
                        break

                    if op == 9:
                        print("discord-gateway websocket invalid session", flush=True)
                        break

        except (OSError, TimeoutError, ConnectionClosed, json.JSONDecodeError) as exc:
            print(f"discord-gateway websocket error: {exc}", flush=True)
        finally:
            if heartbeat_task is not None:
                heartbeat_task.cancel()
        await asyncio.sleep(5)


def main() -> None:
    missing = validate_config()
    if missing:
        print(f"discord-gateway config missing: {', '.join(missing)}", flush=True)
        while True:
            time.sleep(60)

    token = os.environ["DISCORD_BOT_TOKEN"]
    channel_id = os.environ["DISCORD_APPROVAL_CHANNEL_ID"]
    api_base = os.getenv("LIFEOS_API_BASE_URL", "http://api:8000")
    dry_run = env_flag("LIFEOS_GATEWAY_DRY_RUN")
    post_existing = env_flag("DISCORD_POST_EXISTING_ON_STARTUP")

    poller = threading.Thread(
        target=review_poller,
        args=(token, channel_id, api_base, dry_run, post_existing),
        daemon=True,
    )
    poller.start()
    asyncio.run(run_discord_gateway(token))


if __name__ == "__main__":
    main()
