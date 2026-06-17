from __future__ import annotations

import asyncio

from app.db.migration_runner import run_pending_sql_migrations
from app.db.session import engine


async def _main() -> None:
    try:
        await run_pending_sql_migrations(engine)
    finally:
        await engine.dispose()


def main() -> None:
    asyncio.run(_main())


if __name__ == "__main__":
    main()
