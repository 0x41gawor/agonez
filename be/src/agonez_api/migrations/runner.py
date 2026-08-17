import hashlib
import logging
from importlib.resources import files

import psycopg

from agonez_api.core.config import Settings

logger = logging.getLogger(__name__)
MIGRATION_LOCK_ID = 6_742_021_147


async def run_migrations(settings: Settings) -> None:
    """Apply pending packaged SQL migrations once, in filename order."""

    connection = await psycopg.AsyncConnection.connect(
        settings.database_dsn,
        autocommit=True,
    )
    lock_acquired = False
    try:
        await connection.execute("SELECT pg_advisory_lock(%s)", (MIGRATION_LOCK_ID,))
        lock_acquired = True
        await connection.execute(
            """
            CREATE TABLE IF NOT EXISTS public.agonez_schema_migrations (
                version text PRIMARY KEY,
                checksum text NOT NULL,
                applied_at timestamptz NOT NULL DEFAULT now()
            )
            """
        )
        migration_root = files("agonez_api.migrations").joinpath("versions")
        migrations = sorted(
            (resource for resource in migration_root.iterdir() if resource.name.endswith(".sql")),
            key=lambda resource: resource.name,
        )
        for resource in migrations:
            sql = resource.read_text(encoding="utf-8")
            checksum = hashlib.sha256(sql.encode()).hexdigest()
            existing = await (
                await connection.execute(
                    "SELECT checksum FROM public.agonez_schema_migrations WHERE version = %s",
                    (resource.name,),
                )
            ).fetchone()
            if existing is not None:
                if existing[0] != checksum:
                    raise RuntimeError(f"Applied migration {resource.name} has changed")
                continue

            logger.info("Applying database migration %s", resource.name)
            async with connection.transaction():
                await connection.execute(sql)
                await connection.execute(
                    """
                    INSERT INTO public.agonez_schema_migrations (version, checksum)
                    VALUES (%s, %s)
                    """,
                    (resource.name, checksum),
                )
    finally:
        try:
            if lock_acquired:
                await connection.execute(
                    "SELECT pg_advisory_unlock(%s)",
                    (MIGRATION_LOCK_ID,),
                )
        finally:
            await connection.close()
