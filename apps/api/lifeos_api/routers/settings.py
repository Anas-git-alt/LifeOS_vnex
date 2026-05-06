"""Runtime system settings."""

from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import SystemSetting
from lifeos_api.deps import db_session_dep
from lifeos_api.services.audit import create_audit_event
from lifeos_api.services.serialization import row_to_dict
from lifeos_core.time import utc_now

router = APIRouter()


class SettingsPatch(BaseModel):
    values: dict[str, Any] = Field(default_factory=dict)


FIELDS = ["key", "value_json", "description", "created_at", "updated_at"]


@router.get("/settings")
async def list_settings(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    rows = (await session.scalars(select(SystemSetting).order_by(SystemSetting.key))).all()
    return {"items": [row_to_dict(row, FIELDS) for row in rows], "count": len(rows)}


@router.patch("/settings")
async def patch_settings(
    payload: SettingsPatch,
    session: AsyncSession = Depends(db_session_dep),
) -> dict[str, object]:
    now = utc_now()
    changed = []
    for key, value in payload.values.items():
        row = await session.get(SystemSetting, key)
        before = row_to_dict(row, FIELDS) if row else None
        if row is None:
            row = SystemSetting(
                key=key,
                value_json={"value": value},
                description=None,
                created_at=now,
                updated_at=now,
            )
            session.add(row)
        else:
            row.value_json = value if isinstance(value, dict) else {"value": value}
            row.updated_at = now
        changed.append(row_to_dict(row, FIELDS))
        await create_audit_event(
            session,
            actor_type="user",
            actor_id="owner",
            event_type="setting.updated",
            entity_type="system_setting",
            entity_id=key,
            summary=f"Updated setting {key}",
            before_json=before,
            after_json=row_to_dict(row, FIELDS),
        )
    await session.commit()
    return {"ok": True, "items": changed, "count": len(changed)}
