"""Tool registry, permissions, and call endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import ReviewItem, Tool, ToolCall, ToolPermission
from lifeos_api.deps import db_session_dep
from lifeos_api.schemas.tool import ToolCallCreate, ToolPermissionUpdate
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.config_loader import ROOT, load_config
from lifeos_api.services.policy_engine import tool_effect
from lifeos_api.services.serialization import row_to_dict
from lifeos_api.services.status_events import create_status_event
from lifeos_core.ids import new_id
from lifeos_core.time import utc_now
from lifeos_tools.registry import load_tool_config

router = APIRouter()


@router.get("/tools")
async def list_tools(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    config_tools = load_tool_config(ROOT / "configs" / "tools.yaml")
    db_rows = (await session.scalars(select(Tool))).all()
    persisted = {row.id for row in db_rows}
    return {
        "items": [
            {
                "id": tool.id,
                "display_name": tool.display_name,
                "category": tool.category,
                "risk_level": tool.risk_level,
                "persisted": tool.id in persisted,
                "config": tool.raw,
            }
            for tool in config_tools
        ],
        "count": len(config_tools),
    }


@router.post("/tools/sync")
async def sync_tools(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    now = utc_now()
    synced = []
    for tool in load_tool_config(ROOT / "configs" / "tools.yaml"):
        row = await session.get(Tool, tool.id)
        if row is None:
            row = Tool(
                id=tool.id,
                display_name=tool.display_name,
                category=tool.category,
                description=tool.raw.get("description"),
                risk_level=tool.risk_level,
                enabled=True,
                schema_json=tool.raw.get("schemas", {}),
                created_at=now,
                updated_at=now,
            )
            session.add(row)
        else:
            row.display_name = tool.display_name
            row.category = tool.category
            row.risk_level = tool.risk_level
            row.schema_json = tool.raw.get("schemas", {})
            row.updated_at = now
        synced.append(tool.id)
    await create_audit_event(
        session,
        actor_type="system",
        actor_id="tool-registry",
        event_type="tools.synced",
        entity_type="tools",
        entity_id="registry",
        summary=f"Synced {len(synced)} tools from YAML registry.",
        after_json={"tools": synced},
    )
    await session.commit()
    return {"synced": synced, "count": len(synced)}


@router.get("/tools/permissions")
async def list_permissions(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(ToolPermission).order_by(ToolPermission.agent_id))).all()
    fields = [
        "id",
        "agent_id",
        "tool_id",
        "effect",
        "mode",
        "scopes",
        "requires_approval_when",
        "created_at",
        "updated_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}


@router.put("/tools/permissions")
async def update_permission(
    payload: ToolPermissionUpdate,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    now = utc_now()
    existing = (
        await session.scalars(
            select(ToolPermission)
            .where(ToolPermission.agent_id == payload.agent_id)
            .where(ToolPermission.tool_id == payload.tool_id)
        )
    ).first()
    if existing is None:
        existing = ToolPermission(
            id=new_id("perm"),
            agent_id=payload.agent_id,
            tool_id=payload.tool_id,
            effect=payload.effect,
            mode=payload.mode,
            scopes=payload.scopes,
            requires_approval_when=payload.requires_approval_when,
            created_at=now,
            updated_at=now,
        )
        session.add(existing)
    else:
        existing.effect = payload.effect
        existing.mode = payload.mode
        existing.scopes = payload.scopes
        existing.requires_approval_when = payload.requires_approval_when
        existing.updated_at = now
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="tool_permission.updated",
        entity_type="tool_permission",
        entity_id=existing.id,
        summary=f"{payload.agent_id} -> {payload.tool_id}: {payload.effect}",
        after_json=row_to_dict(
            existing,
            ["agent_id", "tool_id", "effect", "mode", "scopes", "requires_approval_when"],
        ),
    )
    await session.commit()
    return row_to_dict(
        existing,
        ["id", "agent_id", "tool_id", "effect", "mode", "scopes", "requires_approval_when"],
    )


@router.patch("/tools/permissions/{permission_id}")
async def patch_permission(
    permission_id: str,
    payload: ToolPermissionUpdate,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    existing = await session.get(ToolPermission, permission_id)
    if existing is None:
        return {"ok": False, "status": "not_found"}
    before = row_to_dict(
        existing,
        ["id", "agent_id", "tool_id", "effect", "mode", "scopes", "requires_approval_when"],
    )
    existing.agent_id = payload.agent_id
    existing.tool_id = payload.tool_id
    existing.effect = payload.effect
    existing.mode = payload.mode
    existing.scopes = payload.scopes
    existing.requires_approval_when = payload.requires_approval_when
    existing.updated_at = utc_now()
    after = row_to_dict(
        existing,
        ["id", "agent_id", "tool_id", "effect", "mode", "scopes", "requires_approval_when"],
    )
    await create_audit_event(
        session,
        actor_type="user",
        actor_id="owner",
        event_type="tool_permission.updated",
        entity_type="tool_permission",
        entity_id=existing.id,
        summary=f"{payload.agent_id} -> {payload.tool_id}: {payload.effect}",
        before_json=before,
        after_json=after,
    )
    await session.commit()
    return {"ok": True, "permission": after}


@router.post("/tools/calls")
async def create_tool_call(
    payload: ToolCallCreate,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    now = utc_now()
    tools_config = load_config("tools.yaml")
    effect = tool_effect(payload.agent_id, payload.tool_id, tools_config)
    status = "succeeded" if effect == "allow" else "requested"
    output = {"mode": "dry_run", "message": "Tool call recorded; executor integration pending."}
    review_id = None
    call_id = new_id("toolcall")

    if effect == "ask":
        review = ReviewItem(
            id=new_id("rev"),
            kind="tool",
            title=f"Tool approval: {payload.tool_id}",
            body_md=f"Agent `{payload.agent_id}` requested `{payload.tool_id}`.",
            source_capture_id=None,
            source_uri=None,
            proposed_by_agent_id=payload.agent_id,
            assigned_agent_id="approval-manager",
            priority="normal",
            confidence=1,
            risk_level="external_side_effect",
            sensitivity="normal",
            proposed_action_json={
                "command_type": "tool_call.approve",
                "risk_level": "external_side_effect",
                "payload": {**payload.model_dump(mode="json"), "tool_call_id": call_id},
            },
            validation_json={},
            status="pending",
            expires_at=None,
            snoozed_until=None,
            created_at=now,
            updated_at=now,
        )
        session.add(review)
        review_id = review.id

    call = ToolCall(
        id=call_id,
        run_id=payload.run_id,
        agent_id=payload.agent_id,
        tool_id=payload.tool_id,
        status=status if effect != "deny" else "denied",
        input_json=payload.input_json,
        output_json=output if effect == "allow" else None,
        redacted_input_json=payload.input_json,
        redacted_output_json=output if effect == "allow" else None,
        approval_review_item_id=review_id,
        error_json={"reason": "permission denied"} if effect == "deny" else None,
        created_at=now,
        started_at=now if effect == "allow" else None,
        finished_at=now if effect == "allow" else None,
    )
    session.add(call)
    await create_status_event(
        session,
        run_id=payload.run_id,
        event_type="tool.call_requested",
        title=f"Tool requested: {payload.tool_id}",
        visibility="discord_compact" if effect == "ask" else "web_only",
        detail_json={"tool_call_id": call.id, "effect": effect, "review_item_id": review_id},
    )
    if effect == "allow":
        await create_status_event(
            session,
            run_id=payload.run_id,
            event_type="tool.call_started",
            title=f"Tool started: {payload.tool_id}",
            visibility="web_only",
            detail_json={"tool_call_id": call.id},
        )
        await create_status_event(
            session,
            run_id=payload.run_id,
            event_type="tool.call_finished",
            title=f"Tool finished: {payload.tool_id}",
            visibility="discord_compact",
            detail_json={"tool_call_id": call.id, "status": call.status},
        )
    await create_audit_event(
        session,
        actor_type="agent",
        actor_id=payload.agent_id,
        event_type="tool.call_requested",
        entity_type="tool_call",
        entity_id=call.id,
        summary=f"{payload.agent_id} requested {payload.tool_id}; policy={effect}",
        after_json={"input": payload.input_json, "effect": effect},
    )
    await session.commit()
    return {
        "tool_call": row_to_dict(
            call,
            [
                "id",
                "run_id",
                "agent_id",
                "tool_id",
                "status",
                "input_json",
                "output_json",
                "approval_review_item_id",
                "error_json",
                "created_at",
            ],
        ),
        "review_item_id": review_id,
    }


@router.get("/tools/calls")
async def list_tool_calls(limit: int = 100, session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(ToolCall).order_by(desc(ToolCall.created_at)).limit(limit))).all()
    fields = [
        "id",
        "run_id",
        "agent_id",
        "tool_id",
        "status",
        "input_json",
        "output_json",
        "approval_review_item_id",
        "error_json",
        "created_at",
    ]
    return {"items": [row_to_dict(row, fields) for row in rows], "count": len(rows)}
