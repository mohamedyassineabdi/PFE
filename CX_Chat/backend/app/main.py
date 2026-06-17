import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.db.migration_runner import run_pending_sql_migrations
from app.db.session import engine


def _env_flag(name: str, default: str = "0") -> bool:
    return os.getenv(name, default).strip().lower() in {"1", "true", "yes", "on"}


def _cors_allowed_origins() -> list[str]:
    raw = os.getenv("CORS_ALLOWED_ORIGINS", "")
    if raw.strip():
        return [origin.strip().rstrip("/") for origin in raw.split(",") if origin.strip()]
    return [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
    ]


def create_app() -> FastAPI:
    app = FastAPI(title="CX Assessment API", version="0.1.0")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=_cors_allowed_origins(),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    app.include_router(api_router, prefix="/api/v1")

    @app.on_event("startup")
    async def _run_startup_migrations() -> None:
        if _env_flag("RUN_DB_MIGRATIONS_ON_STARTUP"):
            await run_pending_sql_migrations(engine)

    return app


app = create_app()
