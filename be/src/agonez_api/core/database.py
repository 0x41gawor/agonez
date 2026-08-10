from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from psycopg.rows import dict_row
from psycopg_pool import AsyncConnectionPool

from agonez_api.core.config import Settings

DatabasePool = AsyncConnectionPool[Any]


def create_database_pool(settings: Settings) -> DatabasePool:
    return AsyncConnectionPool(
        conninfo=settings.database_dsn,
        min_size=settings.db_pool_min_size,
        max_size=settings.db_pool_max_size,
        kwargs={"autocommit": True, "row_factory": dict_row},
        open=False,
        name="agonez-atlas",
    )


@asynccontextmanager
async def open_database_pool(
    pool: DatabasePool,
    *,
    wait_seconds: int,
) -> AsyncIterator[None]:
    await pool.open(wait=True, timeout=wait_seconds)
    try:
        yield
    finally:
        await pool.close()
