"""Read-only catalogue checks for the mobile Execution migrations.

Run against a migrated disposable database by exporting the normal backend database settings:

    NOME=... AGANDSKODE=... MINA=... DB_HOST=... \
    .venv/bin/python tests/live_mobile_migration_checks.py
"""

from __future__ import annotations

import hashlib
from importlib.resources import files

import psycopg

from agonez_api.core.config import Settings


def main() -> None:
    settings = Settings()
    migration_root = files("agonez_api.migrations").joinpath("versions")
    expected_versions = {
        name: hashlib.sha256(migration_root.joinpath(name).read_bytes()).hexdigest()
        for name in (
            "0008_mobile_execution_enum_values.sql",
            "0009_mobile_workout_execution.sql",
        )
    }

    with psycopg.connect(settings.database_dsn) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT migration.version, migration.checksum
                FROM public.agonez_schema_migrations AS migration
                WHERE migration.version = ANY(%s)
                """,
                (list(expected_versions),),
            )
            applied = dict(cursor.fetchall())
            assert applied == expected_versions

            cursor.execute(
                """
                SELECT type.typname, enum.enumlabel
                FROM pg_type AS type
                JOIN pg_namespace AS namespace ON namespace.oid = type.typnamespace
                JOIN pg_enum AS enum ON enum.enumtypid = type.oid
                WHERE namespace.nspname = 'exec'
                  AND type.typname IN ('exercise_execution_mode', 'performed_set_status')
                """
            )
            enums: dict[str, set[str]] = {}
            for type_name, label in cursor.fetchall():
                enums.setdefault(type_name, set()).add(label)
            assert "not_performed" in enums["exercise_execution_mode"]
            assert "not_performed" in enums["performed_set_status"]

            cursor.execute(
                """
                SELECT table_name, column_name, is_nullable
                FROM information_schema.columns
                WHERE table_schema = 'exec'
                  AND (table_name, column_name) IN (
                    ('workout_unit_performances', 'client_uuid'),
                    ('workout_unit_performances', 'lease_device_id'),
                    ('workout_unit_performances', 'lease_epoch'),
                    ('workout_unit_performances', 'applied_seq'),
                    ('workout_unit_performances', 'revision'),
                    ('exercise_unit_performances', 'client_uuid'),
                    ('exercise_unit_performances', 'performed_ordinal'),
                    ('exercise_unit_performances', 'rev'),
                    ('set_performances', 'client_uuid'),
                    ('set_performances', 'performed_at'),
                    ('set_performances', 'received_at'),
                    ('set_performances', 'heart_rate_bpm'),
                    ('set_performances', 'rev')
                  )
                """
            )
            columns = {(table, column): nullable for table, column, nullable in cursor.fetchall()}
            assert len(columns) == 13
            for key in (
                ("workout_unit_performances", "client_uuid"),
                ("workout_unit_performances", "lease_device_id"),
                ("exercise_unit_performances", "client_uuid"),
                ("exercise_unit_performances", "performed_ordinal"),
                ("set_performances", "client_uuid"),
                ("set_performances", "received_at"),
            ):
                assert columns[key] == "NO"

            cursor.execute(
                """
                SELECT relation.relname, con.conname,
                       pg_get_constraintdef(con.oid)
                FROM pg_constraint AS con
                JOIN pg_class AS relation ON relation.oid = con.conrelid
                JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
                WHERE namespace.nspname = 'exec'
                  AND relation.relname IN (
                    'workout_unit_performances',
                    'exercise_unit_performances',
                    'set_performances',
                    'mobile_sync_ops'
                  )
                """
            )
            constraints = {
                (table, name): definition for table, name, definition in cursor.fetchall()
            }
            assert (
                "UNIQUE (client_uuid)"
                in constraints[
                    ("workout_unit_performances", "workout_performances_client_uuid_unique")
                ]
            )
            assert (
                "UNIQUE (client_uuid)"
                in constraints[
                    ("exercise_unit_performances", "exercise_performances_client_uuid_unique")
                ]
            )
            assert (
                "UNIQUE (client_uuid)"
                in constraints[("set_performances", "set_performances_client_uuid_unique")]
            )
            assert "heart_rate_bpm >= 25" in constraints[
                ("set_performances", "set_performances_heart_rate_valid")
            ]
            assert "PRIMARY KEY (workout_unit_performance_id, lease_epoch, seq)" in constraints[
                ("mobile_sync_ops", "mobile_sync_ops_pkey")
            ]
            assert "UNIQUE (op_id)" in constraints[
                ("mobile_sync_ops", "mobile_sync_ops_op_id_unique")
            ]
            assert (
                "REFERENCES exec.workout_unit_performances(id) ON DELETE CASCADE"
                in constraints[
                    (
                        "mobile_sync_ops",
                        "mobile_sync_ops_workout_unit_performance_id_fkey",
                    )
                ]
            )

            cursor.execute(
                """
                SELECT indexname, indexdef
                FROM pg_indexes
                WHERE schemaname = 'exec'
                  AND indexname IN (
                    'exercise_performances_actual_order_unique',
                    'workout_sessions_one_in_progress_per_run'
                  )
                """
            )
            indexes = dict(cursor.fetchall())
            assert "UNIQUE INDEX" in indexes["exercise_performances_actual_order_unique"]
            active_index = indexes["workout_sessions_one_in_progress_per_run"]
            assert "UNIQUE INDEX" in active_index
            assert "WHERE (status = 'in_progress'" in active_index

    print("Mobile Execution migration catalogue checks passed")


if __name__ == "__main__":
    main()
