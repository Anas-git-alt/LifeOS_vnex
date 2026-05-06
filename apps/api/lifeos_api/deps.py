"""Shared FastAPI dependencies."""

from collections.abc import AsyncGenerator, Generator

from fastapi import HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from lifeos_api.config import Settings, get_settings


def settings_dep() -> Generator[Settings, None, None]:
    yield get_settings()


async def db_session_dep(request: Request) -> AsyncGenerator[AsyncSession, None]:
    sessionmaker = getattr(request.app.state, "sessionmaker", None)
    if sessionmaker is None:
        raise HTTPException(status_code=503, detail="DATABASE_URL is not configured")
    async with sessionmaker() as session:
        yield session
