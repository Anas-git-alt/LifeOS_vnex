"""Today dashboard aggregate endpoint."""

from fastapi import APIRouter, Depends
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.db.models import FinanceEntry, LifeItem, PrayerLog, RawCapture, ReviewItem
from lifeos_api.deps import db_session_dep
from lifeos_api.services.serialization import row_to_dict

router = APIRouter()


@router.get("/today")
async def get_today(session: AsyncSession = Depends(db_session_dep)) -> dict[str, object]:
    pending_review_count = await session.scalar(
        select(func.count()).select_from(ReviewItem).where(ReviewItem.status == "pending")
    )
    open_task_count = await session.scalar(
        select(func.count()).select_from(LifeItem).where(LifeItem.status == "open")
    )
    recent_captures = (
        await session.scalars(select(RawCapture).order_by(desc(RawCapture.created_at)).limit(6))
    ).all()
    tasks = (
        await session.scalars(
            select(LifeItem).where(LifeItem.status == "open").order_by(LifeItem.created_at.desc()).limit(8)
        )
    ).all()
    finance = (
        await session.scalars(select(FinanceEntry).order_by(desc(FinanceEntry.created_at)).limit(5))
    ).all()
    prayers = (
        await session.scalars(select(PrayerLog).order_by(desc(PrayerLog.created_at)).limit(5))
    ).all()
    return {
        "focus": "Review pending items and keep capture flowing through approvals.",
        "counts": {
            "pending_reviews": pending_review_count or 0,
            "open_tasks": open_task_count or 0,
        },
        "recent_captures": [
            row_to_dict(row, ["id", "source_platform", "capture_kind", "raw_text", "status", "created_at"])
            for row in recent_captures
        ],
        "tasks": [
            row_to_dict(row, ["id", "domain", "item_type", "title", "status", "priority", "due_at", "created_at"])
            for row in tasks
        ],
        "finance_entries": [
            row_to_dict(row, ["id", "local_date", "entry_type", "amount", "currency", "category", "status"])
            for row in finance
        ],
        "prayer_logs": [
            row_to_dict(row, ["id", "local_date", "prayer", "status", "created_at"])
            for row in prayers
        ],
    }
