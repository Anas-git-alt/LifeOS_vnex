"""FastAPI entrypoint for the LifeOS command core."""

from contextlib import asynccontextmanager
from collections.abc import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from lifeos_api.config import get_settings
from lifeos_api.db.session import create_engine, create_sessionmaker
from lifeos_api.routers import (
    ask,
    agents,
    audit,
    captures,
    events,
    handoffs,
    health,
    jobs,
    memory,
    providers,
    reviews,
    runs,
    sessions,
    settings as system_settings,
    today,
    tools,
)
from lifeos_api.services.runtime_config import seed_runtime_config


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    settings = get_settings()
    app.state.engine = None
    app.state.sessionmaker = None
    if settings.database_url:
        engine = create_engine(settings)
        app.state.engine = engine
        app.state.sessionmaker = create_sessionmaker(engine)
        async with app.state.sessionmaker() as session:
            await seed_runtime_config(session)
    try:
        yield
    finally:
        if app.state.engine is not None:
            await app.state.engine.dispose()


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="LifeOS vNext API",
        description="Command core for the Discord-first, escalation-gated LifeOS swarm.",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router, prefix="/api", tags=["health"])
    app.include_router(ask.router, prefix="/api", tags=["ask"])
    app.include_router(captures.router, prefix="/api", tags=["captures"])
    app.include_router(reviews.router, prefix="/api", tags=["reviews"])
    app.include_router(sessions.router, prefix="/api", tags=["sessions"])
    app.include_router(runs.router, prefix="/api", tags=["runs"])
    app.include_router(agents.router, prefix="/api", tags=["agents"])
    app.include_router(handoffs.router, prefix="/api", tags=["handoffs"])
    app.include_router(tools.router, prefix="/api", tags=["tools"])
    app.include_router(providers.router, prefix="/api", tags=["providers"])
    app.include_router(system_settings.router, prefix="/api", tags=["settings"])
    app.include_router(memory.router, prefix="/api", tags=["memory"])
    app.include_router(jobs.router, prefix="/api", tags=["jobs"])
    app.include_router(today.router, prefix="/api", tags=["today"])
    app.include_router(audit.router, prefix="/api", tags=["audit"])
    app.include_router(events.router, prefix="/api", tags=["events"])

    @app.get("/", include_in_schema=False)
    async def root() -> dict[str, str]:
        return {
            "service": "lifeos-api",
            "status": "ok",
            "health": "/api/health",
            "readiness": "/api/readiness",
        }

    return app


app = create_app()
