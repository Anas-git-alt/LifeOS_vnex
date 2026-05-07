"""Thin Discord command/review gateway."""

from __future__ import annotations

import asyncio
import json
import os
import platform
import threading
import time
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen

from discord_gateway.api_client import LifeOSApiClient

DISCORD_API = "https://discord.com/api/v10"
DECISIONS = {"approve", "reject", "correct", "clarify", "snooze", "done"}
USER_AGENT = "LifeOS-vNext (https://lifeos.local, 0.1)"


def validate_config() -> list[str]:
    return [
        key
        for key in [
            "DISCORD_BOT_TOKEN",
            "DISCORD_OWNER_USER_ID",
            "DISCORD_APPROVAL_CHANNEL_ID",
            "LIFEOS_API_BASE_URL",
        ]
        if not os.getenv(key)
    ]


def env_flag(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def discord_request(token: str, method: str, path: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
    data = None if payload is None else json.dumps(payload).encode("utf-8")
    request = Request(
        f"{DISCORD_API}{path}",
        data=data,
        headers={
            "Authorization": f"Bot {token}",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT,
        },
        method=method,
    )
    with urlopen(request, timeout=25) as response:  # noqa: S310
        raw = response.read().decode("utf-8")
        return json.loads(raw) if raw else {}


def post_discord_message(token: str, channel_id: str, payload: dict[str, Any]) -> dict[str, Any]:
    return discord_request(token, "POST", f"/channels/{channel_id}/messages", payload)


def add_reaction(token: str, channel_id: str, message_id: str, emoji: str) -> None:
    encoded = quote(emoji)
    discord_request(token, "PUT", f"/channels/{channel_id}/messages/{message_id}/reactions/{encoded}/@me")


def create_discord_thread(token: str, channel_id: str, title: str) -> dict[str, Any]:
    return discord_request(
        token,
        "POST",
        f"/channels/{channel_id}/threads",
        {"name": title[:100] or "LifeOS session", "type": 11, "auto_archive_duration": 1440},
    )


def respond_interaction(
    token: str,
    interaction_id: str,
    interaction_token: str,
    payload: dict[str, Any],
) -> None:
    request = Request(
        f"{DISCORD_API}/interactions/{interaction_id}/{interaction_token}/callback",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bot {token}",
            "Content-Type": "application/json",
            "User-Agent": USER_AGENT,
        },
        method="POST",
    )
    with urlopen(request, timeout=15):  # noqa: S310
        return


def edit_interaction_response(
    application_id: str,
    interaction_token: str,
    payload: dict[str, Any],
) -> None:
    request = Request(
        f"{DISCORD_API}/webhooks/{application_id}/{interaction_token}/messages/@original",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "User-Agent": USER_AGENT},
        method="PATCH",
    )
    with urlopen(request, timeout=15):  # noqa: S310
        return


def register_commands(token: str, dry_run: bool = False) -> dict[str, Any]:
    app_id = os.getenv("DISCORD_APPLICATION_ID")
    if not app_id:
        app = discord_request(token, "GET", "/oauth2/applications/@me")
        app_id = str(app.get("id") or "")
    if not app_id:
        return {"ok": False, "status": "missing_application_id"}

    guild_id = os.getenv("DISCORD_GUILD_ID")
    path = (
        f"/applications/{app_id}/guilds/{guild_id}/commands"
        if guild_id
        else f"/applications/{app_id}/commands"
    )
    commands = [lifeos_command_payload()]
    if dry_run:
        return {"ok": True, "status": "dry_run", "path": path, "commands": commands}
    result = discord_request(token, "PUT", path, commands)
    return {"ok": True, "status": "registered", "path": path, "count": len(result) if isinstance(result, list) else 1}


def lifeos_command_payload() -> dict[str, Any]:
    text_option = {"type": 3, "name": "text", "description": "Text", "required": True}
    message_option = {"type": 3, "name": "message", "description": "Message", "required": True}
    agent_option = {"type": 3, "name": "agent", "description": "Agent id", "required": True}
    optional_agent_option = {"type": 3, "name": "agent", "description": "Agent id", "required": False}
    title_option = {"type": 3, "name": "title", "description": "Session title", "required": False}
    iteration_option = {"type": 4, "name": "iteration_cap", "description": "Max agent iterations", "required": False}
    visibility_option = {
        "type": 3,
        "name": "visibility",
        "description": "Session visibility",
        "required": False,
        "choices": [{"name": item, "value": item} for item in ["private", "discord_compact", "web_full"]],
    }
    provider_option = {"type": 3, "name": "provider", "description": "Provider id", "required": True}
    model_option = {"type": 3, "name": "model", "description": "Model name", "required": True}
    mode_option = {
        "type": 3,
        "name": "mode",
        "description": "Autonomy mode",
        "required": True,
        "choices": [{"name": item, "value": item} for item in ["safe", "balanced", "review_gated", "manual"]],
    }
    return {
        "name": "lifeos",
        "description": "LifeOS control surface",
        "options": [
            {"type": 1, "name": "help", "description": "Show commands"},
            {
                "type": 1,
                "name": "new",
                "description": "Start a new agent session",
                "options": [optional_agent_option, title_option, iteration_option, visibility_option],
            },
            {
                "type": 1,
                "name": "thread",
                "description": "Create or bind a Discord thread to an agent session",
                "options": [optional_agent_option, title_option, iteration_option],
            },
            {"type": 1, "name": "agent", "description": "Show or switch session agent", "options": [optional_agent_option]},
            {"type": 1, "name": "iterations", "description": "Show or set iteration cap", "options": [iteration_option]},
            {"type": 1, "name": "cancel", "description": "Cancel active session run"},
            {"type": 1, "name": "status", "description": "Show health/provider status"},
            {"type": 1, "name": "capture", "description": "Capture text", "options": [text_option]},
            {"type": 1, "name": "today", "description": "Show today state"},
            {"type": 1, "name": "reviews", "description": "Show pending reviews"},
            {"type": 1, "name": "ask", "description": "Ask LifeOS", "options": [message_option]},
            {"type": 1, "name": "agents", "description": "Show agents"},
            {"type": 1, "name": "providers", "description": "Show providers/models"},
            {
                "type": 1,
                "name": "model",
                "description": "Set agent model",
                "options": [agent_option, provider_option, model_option],
            },
            {
                "type": 1,
                "name": "autonomy",
                "description": "Set agent autonomy",
                "options": [agent_option, mode_option],
            },
            {"type": 1, "name": "sync", "description": "Sync YAML bootstrap defaults into DB"},
        ],
    }


def format_review_card(item: dict[str, object]) -> dict[str, Any]:
    content = "\n".join(
        [
            f"**Review needed:** {item.get('title')}",
            "",
            str(item.get("body_md") or "")[:1200],
            "",
            f"`review_id`: {item.get('id')}",
            f"`agent`: {item.get('proposed_by_agent_id')}",
            f"`risk`: {item.get('risk_level')}",
            f"`status`: {item.get('status')}",
        ]
    )
    return {"content": content[:1900], "components": review_components(str(item.get("id")))}


def review_components(review_id: str) -> list[dict[str, Any]]:
    def button(label: str, emoji: str, decision: str, style: int) -> dict[str, Any]:
        return {
            "type": 2,
            "style": style,
            "label": label,
            "emoji": {"name": emoji},
            "custom_id": f"lifeos:review:{decision}:{review_id}",
        }

    return [
        {
            "type": 1,
            "components": [
                button("Approve", "✅", "approve", 3),
                button("Reject", "❌", "reject", 4),
                button("Correct", "✏️", "correct", 2),
                button("Clarify", "❓", "clarify", 2),
                button("Snooze", "💤", "snooze", 2),
            ],
        },
        {"type": 1, "components": [button("Done", "✅", "done", 3)]},
    ]


def review_poller(token: str, channel_id: str, client: LifeOSApiClient, dry_run: bool, post_existing: bool) -> None:
    posted: set[str] = set()
    if not post_existing:
        try:
            payload = client.get("/api/reviews?status=pending&limit=100")
            posted = {
                str(item.get("id"))
                for item in payload.get("items", [])
                if isinstance(item, dict) and item.get("id")
            }
        except (OSError, URLError, TimeoutError, KeyError, ValueError) as exc:
            print(f"discord-gateway startup sync error: {exc}", flush=True)

    while True:
        try:
            payload = client.get("/api/reviews?status=pending&limit=20")
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
            time.sleep(10)
        except (OSError, URLError, TimeoutError, KeyError, ValueError) as exc:
            print(f"discord-gateway poll error: {exc}", flush=True)
            time.sleep(10)


async def heartbeat_loop(websocket: Any, interval_seconds: float, seq: dict[str, int | None]) -> None:
    while True:
        await asyncio.sleep(interval_seconds)
        await websocket.send(json.dumps({"op": 1, "d": seq["value"]}))


async def run_discord_gateway(token: str, client: LifeOSApiClient) -> None:
    import websockets
    from websockets.exceptions import ConnectionClosed

    gateway_url = "wss://gateway.discord.gg/?v=10&encoding=json"
    owner_id = os.environ["DISCORD_OWNER_USER_ID"]
    message_intents = env_flag("DISCORD_ENABLE_LEGACY_COMMANDS", True)
    intents = 0
    if message_intents:
        intents = 512 | 4096 | 32768

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
                        heartbeat_task = await _identify(websocket, token, data, seq, heartbeat_task, intents)
                        continue

                    if op == 0 and isinstance(data, dict):
                        event = str(payload.get("t"))
                        if event == "READY":
                            print(f"discord-gateway ready session_id={data.get('session_id')}", flush=True)
                        elif event == "INTERACTION_CREATE":
                            threading.Thread(
                                target=handle_interaction,
                                args=(token, client, data, owner_id),
                                daemon=True,
                            ).start()
                        elif event == "MESSAGE_CREATE":
                            threading.Thread(
                                target=handle_message,
                                args=(token, client, data, owner_id),
                                daemon=True,
                            ).start()
                        continue

                    if op in {7, 9}:
                        print(f"discord-gateway reconnect op={op}", flush=True)
                        break
        except (OSError, TimeoutError, ConnectionClosed, json.JSONDecodeError) as exc:
            print(f"discord-gateway websocket error: {exc}", flush=True)
        finally:
            if heartbeat_task is not None:
                heartbeat_task.cancel()
        await asyncio.sleep(5)


async def _identify(
    websocket: Any,
    token: str,
    hello: dict[str, Any],
    seq: dict[str, int | None],
    heartbeat_task: asyncio.Task[None] | None,
    intents: int,
) -> asyncio.Task[None]:
    if heartbeat_task is not None:
        heartbeat_task.cancel()
    task = asyncio.create_task(heartbeat_loop(websocket, float(hello["heartbeat_interval"]) / 1000, seq))
    await websocket.send(
        json.dumps(
            {
                "op": 2,
                "d": {
                    "token": token,
                    "intents": intents,
                    "properties": {
                        "os": platform.system().lower(),
                        "browser": "lifeos-vnext",
                        "device": "lifeos-vnext",
                    },
                    "presence": {
                        "since": None,
                        "activities": [{"name": "LifeOS commands", "type": 3}],
                        "status": "online",
                        "afk": False,
                    },
                },
            }
        )
    )
    return task


def handle_interaction(token: str, client: LifeOSApiClient, data: dict[str, Any], owner_id: str) -> None:
    interaction_id = str(data["id"])
    interaction_token = str(data["token"])
    kind = int(data.get("type", 0))
    app_id = str(data.get("application_id") or os.getenv("DISCORD_APPLICATION_ID") or "")
    acknowledged = False

    print(
        f"discord-gateway interaction received kind={kind} id={interaction_id} channel={data.get('channel_id')}",
        flush=True,
    )

    try:
        if not _is_owner(data, owner_id):
            respond_interaction(token, interaction_id, interaction_token, ephemeral("Not authorized."))
            acknowledged = True
            return

        # Slash command.
        if kind == 2:
            respond_interaction(token, interaction_id, interaction_token, {"type": 5})
            acknowledged = True

            try:
                text = handle_slash(token, client, data)
            except Exception as exc:  # noqa: BLE001
                text = f"LifeOS failed: {exc}"
                print(f"discord-gateway slash error: {exc}", flush=True)

            try:
                edit_interaction_response(app_id, interaction_token, {"content": text[:1900]})
            except Exception as exc:  # noqa: BLE001
                print(f"discord-gateway slash delivery fallback: {exc}", flush=True)
                channel_id = data.get("channel_id")
                if channel_id:
                    post_discord_message(
                        token,
                        str(channel_id),
                        {"content": f"{text[:1800]}\n\n(delivery fallback: {exc})"},
                    )
            return

        # Button/component.
        if kind == 3:
            payload = handle_component(data)

            # Correct/clarify need to open a modal immediately.
            if payload["type"] == "modal":
                respond_interaction(token, interaction_id, interaction_token, payload["payload"])
                acknowledged = True
                return

            # Acknowledge Discord immediately, then do LifeOS work.
            respond_interaction(
                token,
                interaction_id,
                interaction_token,
                ephemeral(
                    f"Processing {'proposal' if payload['type'] == 'proposal_decision' else 'review'} "
                    f"{payload['decision']}..."
                ),
            )
            acknowledged = True

            try:
                if payload["type"] == "proposal_decision":
                    result = client.post(
                        f"/api/action-proposals/{quote(str(payload['proposal_id']))}/decision",
                        payload["payload"],
                    )
                    text = f"Proposal {payload['decision']}: {result.get('status')}"
                else:
                    result = client.post(
                        f"/api/reviews/{quote(str(payload['review_id']))}/decision",
                        payload["payload"],
                    )
                    text = f"Review {payload['decision']}: {result.get('status')}"
            except Exception as exc:  # noqa: BLE001
                text = f"LifeOS decision failed: {exc}"
                print(f"discord-gateway decision error: {exc}", flush=True)

            channel_id = data.get("channel_id")
            if channel_id:
                try:
                    post_discord_message(token, str(channel_id), {"content": text[:1900]})
                except Exception as exc:  # noqa: BLE001
                    print(f"discord-gateway review result post error: {exc}", flush=True)
            return

        # Modal submit.
        if kind == 5:
            respond_interaction(token, interaction_id, interaction_token, {"type": 5})
            acknowledged = True

            try:
                text = handle_modal(client, data)
            except Exception as exc:  # noqa: BLE001
                text = f"LifeOS modal failed: {exc}"
                print(f"discord-gateway modal error: {exc}", flush=True)

            try:
                edit_interaction_response(app_id, interaction_token, {"content": text[:1900]})
            except Exception as exc:  # noqa: BLE001
                print(f"discord-gateway modal delivery fallback: {exc}", flush=True)
                channel_id = data.get("channel_id")
                if channel_id:
                    post_discord_message(token, str(channel_id), {"content": text[:1900]})
            return

    except Exception as exc:  # noqa: BLE001
        print(f"discord-gateway interaction error: {exc}", flush=True)
        if not acknowledged:
            try:
                respond_interaction(
                    token,
                    interaction_id,
                    interaction_token,
                    ephemeral(f"LifeOS failed: {exc}"),
                )
            except Exception as ack_exc:  # noqa: BLE001
                print(f"discord-gateway interaction ack error: {ack_exc}", flush=True)

def handle_slash(token: str, client: LifeOSApiClient, data: dict[str, Any]) -> str:
    command = parse_lifeos_command(data.get("data", {}))
    name = command["name"]
    options = command["options"]
    if name == "help":
        return help_text()
    if name == "new":
        response = client.post(
            "/api/sessions",
            {
                "source_platform": "discord",
                "external_channel_id": str(data.get("channel_id")),
                "external_thread_id": _thread_id(data),
                "external_message_id": str(data.get("id")),
                "agent_id": options.get("agent") or "orchestrator",
                "title": options.get("title") or "LifeOS session",
                "iteration_cap": options.get("iteration_cap"),
                "visibility": options.get("visibility") or "private",
                "user_id": _user_id(data),
                "metadata": {"created_from": "discord_slash_new"},
            },
        )
        session = response.get("session", {}) if isinstance(response, dict) else {}
        return format_session_created(session, thread_id=_thread_id(data))
    if name == "thread":
        title = str(options.get("title") or "LifeOS session")
        channel_id = str(data.get("channel_id"))
        thread_id = _thread_id(data)
        created_thread = None
        if thread_id is None:
            try:
                created_thread = create_discord_thread(token, channel_id, title)
                thread_id = str(created_thread.get("id"))
            except Exception:  # noqa: BLE001 - fallback to channel binding
                thread_id = channel_id
        response = client.post(
            "/api/sessions",
            {
                "source_platform": "discord",
                "external_channel_id": channel_id,
                "external_thread_id": thread_id,
                "external_message_id": str(data.get("id")),
                "agent_id": options.get("agent") or "orchestrator",
                "title": title,
                "iteration_cap": options.get("iteration_cap"),
                "visibility": "discord_compact",
                "user_id": _user_id(data),
                "metadata": {"created_from": "discord_slash_thread"},
            },
        )
        session = response.get("session", {}) if isinstance(response, dict) else {}
        return format_session_created(session, thread_id=thread_id, created_thread=bool(created_thread))
    if name == "agent":
        resolved = resolve_discord_session(client, data, create=True)
        session = resolved.get("session", {}) if isinstance(resolved, dict) else {}
        if options.get("agent"):
            response = client.patch(f"/api/sessions/{quote(str(session.get('id')))}/agent", {"agent_id": options["agent"]})
            session = response.get("session", {}) if isinstance(response, dict) else session
        return f"Agent: `{session.get('agent_id', 'orchestrator')}`\nSession: `{session.get('id')}`"
    if name == "iterations":
        resolved = resolve_discord_session(client, data, create=True)
        session = resolved.get("session", {}) if isinstance(resolved, dict) else {}
        if options.get("iteration_cap"):
            response = client.patch(
                f"/api/sessions/{quote(str(session.get('id')))}/iterations",
                {"iteration_cap": int(options["iteration_cap"])},
            )
            session = response.get("session", {}) if isinstance(response, dict) else session
        return f"Iteration cap: `{session.get('iteration_cap', 5)}`\nSession: `{session.get('id')}`"
    if name == "cancel":
        resolved = resolve_discord_session(client, data, create=False)
        session = resolved.get("session", {}) if isinstance(resolved, dict) else {}
        if not session.get("id"):
            return "No active session here."
        response = client.post(f"/api/sessions/{quote(str(session.get('id')))}/cancel")
        return f"Cancel: {response.get('status')}"
    if name == "status":
        return status_text(client)
    if name == "capture":
        response = client.post(
            "/api/captures",
            {
                "source_platform": "discord",
                "source_channel_id": str(data.get("channel_id")),
                "external_message_id": str(data.get("id")),
                "capture_kind": "text",
                "raw_text": options["text"],
                "metadata": {"owner_authenticated": True},
            },
        )
        return str(response.get("message") or f"Captured: {response.get('capture', {}).get('id')}")
    if name == "today":
        return today_text(client)
    if name == "reviews":
        return reviews_text(client)
    if name == "ask":
        response = client.post(
            "/api/ask",
            {"source_platform": "discord", "source_external_message_id": str(data.get("id")), "message": options["message"]},
        )
        return str(response.get("answer") or response)
    if name == "agents":
        return agents_text(client)
    if name == "providers":
        return providers_text(client)
    if name == "model":
        response = client.patch(
            f"/api/agents/{quote(options['agent'])}/model",
            {"primary_provider_id": options["provider"], "primary_model": options["model"]},
        )
        return f"Model updated: {options['agent']} -> {options['provider']} / {options['model']} ({response.get('ok')})"
    if name == "autonomy":
        response = client.patch(f"/api/agents/{quote(options['agent'])}", {"autonomy_level": options["mode"]})
        return f"Autonomy updated: {options['agent']} -> {options['mode']} ({response.get('ok')})"
    if name == "sync":
        agents = client.post("/api/agents/sync")
        tools = client.post("/api/tools/sync")
        return f"Synced agents={agents.get('count')} tools={tools.get('count')}"
    return help_text()


def parse_lifeos_command(data: dict[str, Any]) -> dict[str, Any]:
    options = data.get("options") or []
    if not options:
        return {"name": "help", "options": {}}
    sub = options[0]
    values = {
        item["name"]: item.get("value")
        for item in sub.get("options", [])
        if isinstance(item, dict) and "name" in item
    }
    return {"name": str(sub.get("name", "help")), "options": values}


def handle_component(data: dict[str, Any]) -> dict[str, Any]:
    custom_id = str(data.get("data", {}).get("custom_id", ""))
    _, area, decision, target_id = custom_id.split(":", 3)
    if area == "proposal":
        if decision == "edit":
            return {"type": "modal", "payload": proposal_edit_modal_payload(target_id)}
        if decision not in {"create", "ignore"}:
            raise ValueError("Unknown proposal action")
        api_decision = "approve" if decision == "create" else "reject"
        return {
            "type": "proposal_decision",
            "proposal_id": target_id,
            "decision": decision,
            "payload": {
                "decision": api_decision,
                "decision_payload": {},
                "source_platform": "discord",
                "source_external_message_id": str(data.get("message", {}).get("id") or data.get("id")),
            },
        }
    if area != "review" or decision not in DECISIONS:
        raise ValueError("Unknown review action")
    if decision in {"correct", "clarify"}:
        return {"type": "modal", "payload": modal_payload(decision, target_id)}
    return {
        "type": "decision",
        "review_id": target_id,
        "decision": decision,
        "payload": {
            "decision": decision,
            "decision_payload": {"hours": 8} if decision == "snooze" else {},
            "source_platform": "discord",
            "source_external_message_id": str(data.get("message", {}).get("id") or data.get("id")),
        },
    }


def handle_modal(client: LifeOSApiClient, data: dict[str, Any]) -> str:
    custom_id = str(data.get("data", {}).get("custom_id", ""))
    text = modal_text(data)
    if custom_id.startswith("lifeos:proposal_modal:edit:"):
        proposal_id = custom_id.split(":", 3)[3]
        result = client.post(
            f"/api/action-proposals/{quote(proposal_id)}/decision",
            {
                "decision": "revise",
                "decision_text": text,
                "decision_payload": {},
                "source_platform": "discord",
                "source_external_message_id": str(data.get("message", {}).get("id") or data.get("id")),
            },
        )
        return f"Proposal edit: {result.get('status')}. Say `yes` or use Create when it looks right."
    _, area, decision, review_id = custom_id.split(":", 3)
    if area != "modal" or decision not in {"correct", "clarify"}:
        raise ValueError("Unknown modal")
    result = client.post(
        f"/api/reviews/{quote(review_id)}/decision",
        {
            "decision": decision,
            "decision_text": text,
            "decision_payload": {},
            "source_platform": "discord",
            "source_external_message_id": str(data.get("message", {}).get("id") or data.get("id")),
        },
    )
    return f"Review {decision}: {result.get('status')}"


def modal_payload(decision: str, review_id: str) -> dict[str, Any]:
    label = "Correction" if decision == "correct" else "Clarifying question/detail"
    return {
        "type": 9,
        "data": {
            "custom_id": f"lifeos:modal:{decision}:{review_id}",
            "title": f"LifeOS {decision}",
            "components": [
                {
                    "type": 1,
                    "components": [
                        {
                            "type": 4,
                            "custom_id": "text",
                            "style": 2,
                            "label": label,
                            "required": True,
                            "max_length": 1000,
                        }
                    ],
                }
            ],
        },
    }


def proposal_edit_modal_payload(proposal_id: str) -> dict[str, Any]:
    return {
        "type": 9,
        "data": {
            "custom_id": f"lifeos:proposal_modal:edit:{proposal_id}",
            "title": "Edit LifeOS proposal",
            "components": [
                {
                    "type": 1,
                    "components": [
                        {
                            "type": 4,
                            "custom_id": "text",
                            "style": 2,
                            "label": "Adjustment",
                            "required": True,
                            "max_length": 1000,
                        }
                    ],
                }
            ],
        },
    }


def modal_text(data: dict[str, Any]) -> str:
    for row in data.get("data", {}).get("components", []):
        for component in row.get("components", []):
            if component.get("custom_id") == "text":
                return str(component.get("value", ""))
    return ""


def handle_message(token: str, client: LifeOSApiClient, data: dict[str, Any], owner_id: str) -> None:
    author = data.get("author", {})
    if not isinstance(author, dict) or str(author.get("id")) != owner_id or author.get("bot"):
        return
    content = str(data.get("content") or "").strip()
    command = parse_legacy_command(content)
    channel_id = str(data.get("channel_id"))
    try:
        if command is None:
            try:
                add_reaction(token, channel_id, str(data.get("id")), "👀")
            except Exception:  # noqa: BLE001 - reaction is best effort
                pass
            payload = run_chat_message_payload(client, data)
        else:
            payload = {"content": run_legacy_command(client, command, data)[:1900]}
    except Exception as exc:  # noqa: BLE001
        payload = {"content": f"LifeOS failed: {exc}"[:1900]}
    post_discord_message(token, channel_id, payload)


def parse_legacy_command(content: str) -> dict[str, str] | None:
    if content == "!help":
        return {"name": "help", "text": ""}
    if content == "!lifeos help":
        return {"name": "help", "text": ""}
    if content == "!today":
        return {"name": "today", "text": ""}
    if content == "!reviews":
        return {"name": "reviews", "text": ""}
    if content == "!status":
        return {"name": "status", "text": ""}
    if content.startswith("!capture "):
        return {"name": "capture", "text": content.removeprefix("!capture ").strip()}
    if content.startswith("!ask "):
        return {"name": "ask", "text": content.removeprefix("!ask ").strip()}
    return None


def run_legacy_command(client: LifeOSApiClient, command: dict[str, str], message_data: dict[str, Any]) -> str:
    if command["name"] == "help":
        return help_text()
    if command["name"] == "today":
        return today_text(client)
    if command["name"] == "reviews":
        return reviews_text(client)
    if command["name"] == "status":
        return status_text(client)
    if command["name"] == "ask":
        return run_chat_message(client, {**message_data, "content": command["text"]})
    response = client.post(
        "/api/captures",
        {
            "source_platform": "discord",
            "source_channel_id": str(message_data.get("channel_id")),
            "external_message_id": str(message_data.get("id")),
            "capture_kind": "text",
            "raw_text": command["text"],
            "metadata": {"owner_authenticated": True},
        },
    )
    return str(response.get("message") or "Captured.")


def run_chat_message(client: LifeOSApiClient, message_data: dict[str, Any]) -> str:
    return str(run_chat_message_payload(client, message_data).get("content") or "")


def run_chat_message_payload(client: LifeOSApiClient, message_data: dict[str, Any]) -> dict[str, Any]:
    response = client.post(
        "/api/chat",
        {
            "source_platform": "discord",
            "external_channel_id": str(message_data.get("channel_id")),
            "external_thread_id": _message_thread_id(message_data),
            "external_message_id": str(message_data.get("id")),
            "user_id": str(message_data.get("author", {}).get("id")),
            "message": str(message_data.get("content") or ""),
            "metadata": {"owner_authenticated": True},
        },
    )
    return chat_response_payload(response)


def help_text() -> str:
    return "\n".join(
        [
            "LifeOS commands:",
            "`/lifeos new agent:<id> title:<title> iteration_cap:<n>`",
            "`/lifeos thread agent:<id> title:<title> iteration_cap:<n>`",
            "`/lifeos agent [agent:<id>]`, `/lifeos iterations [iteration_cap:<n>]`, `/lifeos cancel`",
            "`/lifeos capture text:<text>`",
            "`/lifeos ask message:<message>`",
            "`/lifeos today`, `/lifeos reviews`, `/lifeos status`",
            "`/lifeos agents`, `/lifeos providers`",
            "`/lifeos model agent:<id> provider:<id> model:<model>`",
            "`/lifeos autonomy agent:<id> mode:<safe|balanced|review_gated|manual>`",
            "Fallback: `!help`, `!capture ...`, `!today`, `!reviews`, `!status`",
        ]
    )


def resolve_discord_session(client: LifeOSApiClient, data: dict[str, Any], *, create: bool) -> dict[str, object]:
    return client.post(
        "/api/sessions/resolve",
        {
            "source_platform": "discord",
            "external_channel_id": str(data.get("channel_id")),
            "external_thread_id": _thread_id(data),
            "create_if_missing": create,
            "agent_id": "orchestrator",
            "title": "LifeOS session",
            "user_id": _user_id(data),
            "metadata": {"resolved_from": "discord_slash"},
        },
    )


def format_session_created(session: object, *, thread_id: str | None, created_thread: bool = False) -> str:
    if not isinstance(session, dict):
        return "Session create failed."
    lines = [
        "👀 New session created",
        f"Agent: `{session.get('agent_id', 'orchestrator')}`",
        f"Iteration cap: `{session.get('iteration_cap', 5)}`",
        f"Session: `{session.get('id')}`",
    ]
    if thread_id:
        lines.append(f"Thread: `{'created' if created_thread else 'bound'}:{thread_id}`")
    return "\n".join(lines)


def format_chat_response(response: dict[str, object]) -> str:
    answer = str(response.get("answer") or "")
    result = response.get("result", {})
    if not answer and isinstance(result, dict):
        answer = str(result.get("final_message_md") or result.get("status_summary") or "")
    if not answer:
        answer = "Done."
    status = str(response.get("status") or (result.get("status") if isinstance(result, dict) else "completed"))
    run_id = response.get("run_id")
    suffix = f"\n\n`run`: {run_id} · `{status}`" if run_id else f"\n\n`{status}`"
    return (answer + suffix)[:1900]


def chat_response_payload(response: dict[str, object]) -> dict[str, Any]:
    payload: dict[str, Any] = {"content": format_chat_response(response)}
    result = response.get("result", {})
    proposals = result.get("action_proposals", []) if isinstance(result, dict) else []
    pending = [
        proposal
        for proposal in proposals
        if isinstance(proposal, dict) and proposal.get("id") and proposal.get("status") in {"pending", "revised"}
    ]
    if pending:
        payload["embeds"] = [action_proposal_embed(pending)]
        payload["components"] = action_proposal_components(pending)
    return payload


def action_proposal_embed(proposals: list[dict[str, object]]) -> dict[str, Any]:
    lines = []
    for index, proposal in enumerate(proposals, start=1):
        lines.append(f"**{index}. {proposal.get('summary')}**")
        lines.append(f"`risk`: {proposal.get('risk')}  `status`: {proposal.get('status')}")
    return {
        "title": "Action proposal",
        "description": "\n".join(lines)[:3900],
        "color": 0x2F855A,
    }


def action_proposal_components(proposals: list[dict[str, object]]) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []

    def button(label: str, action: str, proposal_id: str, style: int) -> dict[str, Any]:
        return {
            "type": 2,
            "style": style,
            "label": label,
            "custom_id": f"lifeos:proposal:{action}:{proposal_id}",
        }

    for proposal in proposals[:5]:
        proposal_id = str(proposal.get("id"))
        rows.append(
            {
                "type": 1,
                "components": [
                    button("Create", "create", proposal_id, 3),
                    button("Edit", "edit", proposal_id, 2),
                    button("Ignore", "ignore", proposal_id, 4),
                ],
            }
        )
    return rows


def status_text(client: LifeOSApiClient) -> str:
    readiness = client.get("/api/readiness")
    providers = client.get("/api/providers")
    configured = [
        f"{provider.get('id')}:{sum(1 for key in provider.get('keys', []) if key.get('configured'))}"
        for provider in providers.get("items", [])
        if isinstance(provider, dict)
    ]
    return f"API: {readiness.get('status')} | providers: {', '.join(configured) or 'none'}"


def today_text(client: LifeOSApiClient) -> str:
    today = client.get("/api/today")
    tasks = today.get("tasks", [])
    lines = [str(today.get("focus", "Today"))]
    if isinstance(tasks, list):
        lines.extend(f"- {item.get('title')} ({item.get('domain')})" for item in tasks[:8] if isinstance(item, dict))
    return "\n".join(lines[:10])


def reviews_text(client: LifeOSApiClient) -> str:
    payload = client.get("/api/reviews?status=pending&limit=10")
    items = payload.get("items", [])
    if not items:
        return "No pending reviews."
    return "\n".join(
        f"- {item.get('title')} `{item.get('id')}`" for item in items if isinstance(item, dict)
    )


def agents_text(client: LifeOSApiClient) -> str:
    payload = client.get("/api/agents")
    items = payload.get("items", [])
    return "\n".join(
        f"- {item.get('id')} {item.get('autonomy_level')} {'on' if item.get('enabled') else 'off'}"
        for item in items
        if isinstance(item, dict)
    )[:1900]


def providers_text(client: LifeOSApiClient) -> str:
    payload = client.get("/api/providers")
    providers = payload.get("items", [])
    models = payload.get("agent_models", {})
    lines = [
        f"- {item.get('id')} keys={sum(1 for key in item.get('keys', []) if key.get('configured'))}/{len(item.get('keys', []))}"
        for item in providers
        if isinstance(item, dict)
    ]
    if isinstance(models, dict):
        lines.extend(
            f"- {agent}: {model.get('primary', {}).get('provider')}/{model.get('primary', {}).get('model')}"
            for agent, model in list(models.items())[:8]
            if isinstance(model, dict)
        )
    return "\n".join(lines)[:1900] or "No providers."


def _thread_id(data: dict[str, Any]) -> str | None:
    channel = data.get("channel")
    if isinstance(channel, dict) and int(channel.get("type", 0) or 0) in {10, 11, 12}:
        return str(data.get("channel_id"))
    return None


def _message_thread_id(data: dict[str, Any]) -> str | None:
    channel_type = data.get("channel_type")
    if channel_type is not None and int(channel_type) in {10, 11, 12}:
        return str(data.get("channel_id"))
    channel = data.get("channel")
    if isinstance(channel, dict) and int(channel.get("type", 0) or 0) in {10, 11, 12}:
        return str(data.get("channel_id"))
    return None


def _user_id(data: dict[str, Any]) -> str | None:
    user = data.get("user") or data.get("member", {}).get("user")
    return str(user.get("id")) if isinstance(user, dict) else None


def _is_owner(data: dict[str, Any], owner_id: str) -> bool:
    user = data.get("user") or data.get("member", {}).get("user")
    return isinstance(user, dict) and str(user.get("id")) == owner_id


def message(content: str) -> dict[str, Any]:
    return {"type": 4, "data": {"content": content[:1900]}}


def ephemeral(content: str) -> dict[str, Any]:
    return {"type": 4, "data": {"content": content[:1900], "flags": 64}}


def main() -> None:
    missing = validate_config()
    if missing:
        print(f"discord-gateway config missing: {', '.join(missing)}", flush=True)
        while True:
            time.sleep(60)

    token = os.environ["DISCORD_BOT_TOKEN"]
    channel_id = os.environ["DISCORD_APPROVAL_CHANNEL_ID"]
    client = LifeOSApiClient(os.getenv("LIFEOS_API_BASE_URL", "http://api:8000"))
    dry_run = env_flag("LIFEOS_GATEWAY_DRY_RUN")
    post_existing = env_flag("DISCORD_POST_EXISTING_ON_STARTUP")

    try:
        result = register_commands(token, dry_run=env_flag("DISCORD_COMMANDS_DRY_RUN", dry_run))
        print(f"discord-gateway commands {result}", flush=True)
    except Exception as exc:  # noqa: BLE001
        print(f"discord-gateway command registration failed: {exc}", flush=True)

    poller = threading.Thread(
        target=review_poller,
        args=(token, channel_id, client, dry_run, post_existing),
        daemon=True,
    )
    poller.start()
    asyncio.run(run_discord_gateway(token, client))


if __name__ == "__main__":
    main()
