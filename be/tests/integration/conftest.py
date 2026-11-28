"""Integration harness: the real application against a disposable PostgreSQL.

Every test in this directory carries the ``integration`` marker and is skipped unless
``AGONEZ_TEST_DATABASE_URL`` is set (``scripts/test_db.sh`` prints it). Once per session the
newest repository database dump is restored into a template database and the packaged
migrations are applied on top; every test then gets its own clone of that template.

The harness creates and drops databases, so before it opens any connection it checks that the
URL points at a container started by ``scripts/test_db.sh``.

A test marked ``@pytest.mark.before_migration("<version>.sql")`` gets a clone of the newest dump
that does not record that migration, with only the packaged migrations before it applied: the
database a deploy of that migration starts from (``apply_migrations`` then runs it).
"""

import asyncio
import importlib.util
import os
import re
import shutil
import subprocess
from collections.abc import AsyncIterator, Callable, Iterator
from dataclasses import dataclass, field
from datetime import date
from functools import cache
from importlib.resources import files
from pathlib import Path
from unittest import mock
from uuid import uuid4

import httpx
import psycopg
import pytest
from fastapi import FastAPI
from psycopg import sql
from psycopg.conninfo import conninfo_to_dict, make_conninfo

from agonez_api.app import create_app
from agonez_api.core.config import Settings
from agonez_api.core.database import DatabasePool, create_database_pool, open_database_pool
from agonez_api.migrations import runner
from agonez_api.migrations.runner import run_migrations
from agonez_api.modules.execution.repository import ExecutionRepository
from agonez_api.modules.execution.service import ExecutionService
from agonez_api.modules.mobile_execution.repository import MobileExecutionRepository
from agonez_api.modules.mobile_execution.service import MobileExecutionService
from agonez_api.modules.plans.repository import PlanRepository
from agonez_api.modules.plans.service import PlanService

URL_ENV = "AGONEZ_TEST_DATABASE_URL"
CONTAINER_ENV = "AGONEZ_TEST_DB_CONTAINER"
DUMP_ENV = "AGONEZ_TEST_DB_DUMP"

CONTAINER_LABEL = "agonez.integration-test"
PRODUCTION_CONTAINER = "agonez-db"
TEMPLATE_DATABASE = "agonez_it_template"
DUMP_PATTERN = "agonez_db_backup_*.sql"

INTEGRATION_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = INTEGRATION_DIR.parents[2]

# A Monday after the data in the dumps, so runs created by tests start in a known week.
FROZEN_TODAY = date(2027, 1, 4)

# Migration 0019 converts the runs of the dumps (T2.1); test_preflight.py and the migration
# tests need a dump taken before it.
RUN_PLAN_CONVERSION = "0019_run_plans_convert_legacy_runs.sql"


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers",
        "before_migration(version): the test database is the newest dump without that "
        "migration, with only the packaged migrations before it applied",
    )


@pytest.hookimpl(tryfirst=True)  # before `-m` deselects by marker
def pytest_collection_modifyitems(items: list[pytest.Item]) -> None:
    skip = pytest.mark.skip(reason=f"integration tests need {URL_ENV} (see scripts/test_db.sh)")
    for item in items:
        if INTEGRATION_DIR in item.path.parents:
            item.add_marker(pytest.mark.integration)
        if item.get_closest_marker("integration") and not os.environ.get(URL_ENV):
            item.add_marker(skip)


@dataclass(frozen=True)
class DatabaseServer:
    """A verified disposable PostgreSQL server."""

    container: str
    port: int
    user: str
    password: str = field(repr=False)

    def connect_admin(self) -> psycopg.Connection:
        """Autocommit connection to the maintenance database, for CREATE/DROP DATABASE."""
        return psycopg.connect(
            make_conninfo(
                "",
                host="127.0.0.1",
                port=self.port,
                user=self.user,
                password=self.password,
                dbname="postgres",
                connect_timeout=5,
            ),
            autocommit=True,
        )

    def settings(self, database: str, runtime_root: Path) -> Settings:
        # Init values win over the environment. The port must be passed as MINA: with
        # DB_PORT, an exported (production) MINA variable would take precedence.
        return Settings(
            NOME=self.user,
            AGANDSKODE=self.password,
            MINA=self.port,
            DB_HOST="127.0.0.1",
            DB_NAME=database,
            ENVIRONMENT="test",
            LOG_LEVEL="WARNING",
            DB_POOL_MIN_SIZE=1,
            DB_POOL_MAX_SIZE=5,
            MEDIA_ROOT=runtime_root / "media",
            PUBLIC_MEDIA_BASE_URL=None,
            WAITLIST_PATH=runtime_root / "waitlist.jsonl",
        )


def _docker(*arguments: str) -> str:
    result = subprocess.run(["docker", *arguments], capture_output=True, text=True, check=False)
    if result.returncode != 0:
        pytest.fail(
            f"docker {' '.join(arguments[:2])} failed: {result.stderr.strip()}", pytrace=False
        )
    return result.stdout.strip()


def _verified_server() -> DatabaseServer:
    """Parse the URL and prove it is our disposable container, without connecting to it."""

    def refuse(reason: str) -> None:
        pytest.fail(f"Refusing to run integration tests: {reason}", pytrace=False)

    parts = conninfo_to_dict(os.environ[URL_ENV])
    host = str(parts.get("host", ""))
    port = str(parts.get("port", ""))
    container = os.environ.get(CONTAINER_ENV, "")
    if host not in {"127.0.0.1", "localhost"}:
        refuse(f"{URL_ENV} must point at 127.0.0.1")
    if not port.isdigit() or not parts.get("user") or not parts.get("password"):
        refuse(f"{URL_ENV} must name a port, a user and a password")
    if not container or container == PRODUCTION_CONTAINER:
        refuse(f"{CONTAINER_ENV} must name the disposable container")
    label = _docker(
        "container",
        "inspect",
        "-f",
        f'{{{{ index .Config.Labels "{CONTAINER_LABEL}" }}}}',
        container,
    )
    if label != "true":
        refuse(f"container '{container}' was not started by scripts/test_db.sh")
    if f"127.0.0.1:{port}" not in _docker("port", container, "5432/tcp").splitlines():
        refuse(f"port {port} is not published by container '{container}'")
    return DatabaseServer(
        container=container,
        port=int(port),
        user=str(parts["user"]),
        password=str(parts["password"]),
    )


def _dump_path() -> Path:
    override = os.environ.get(DUMP_ENV)
    if override:
        path = Path(override).resolve()
        if not path.is_file():
            pytest.fail(f"{DUMP_ENV} does not name a file: {path}", pytrace=False)
        return path
    # The names carry ISO dates; file times only say when the checkout was made.
    dumps = sorted(REPOSITORY_ROOT.glob(DUMP_PATTERN), key=lambda item: item.name)
    if not dumps:
        pytest.fail(f"No {DUMP_PATTERN} in {REPOSITORY_ROOT}; set {DUMP_ENV}", pytrace=False)
    return dumps[-1]


@cache
def _recorded_migrations(dump: Path) -> frozenset[str]:
    """The versions in the dump's ``public.agonez_schema_migrations`` table."""
    versions: set[str] = set()
    with dump.open(encoding="utf-8") as lines:
        for line in lines:
            if line.startswith("COPY public.agonez_schema_migrations "):
                break
        for line in lines:
            if line.startswith("\\."):
                break
            versions.add(line.split("\t", 1)[0])
    return frozenset(versions)


def _dump_without(version: str) -> Path:
    """The newest dump that does not record ``version`` yet (or the ``DUMP_ENV`` override).

    Tests of a migration need data from before it; this keeps them on such a dump after a
    backup taken once the migration is deployed has been committed.
    """
    override = os.environ.get(DUMP_ENV)
    candidates = (
        [_dump_path()]
        if override
        else sorted(REPOSITORY_ROOT.glob(DUMP_PATTERN), key=lambda item: item.name, reverse=True)
    )
    for dump in candidates:
        if version not in _recorded_migrations(dump):
            return dump
    where = f"{DUMP_ENV} ({override})" if override else f"{DUMP_PATTERN} in {REPOSITORY_ROOT}"
    pytest.fail(f"No dump without {version}: {where}", pytrace=False)


def _packaged_migrations() -> dict[str, Path]:
    root = Path(str(files("agonez_api.migrations").joinpath("versions")))
    return {path.name: path for path in sorted(root.iterdir()) if path.name.endswith(".sql")}


async def apply_migrations(settings: Settings, work_dir: Path, *, through: str | None) -> None:
    """The real runner, given only the packaged migrations up to and including ``through``.

    ``through=None`` applies none (it only creates the bookkeeping table). The files are copied
    byte for byte, so their checksums match when the full runner sees the database later.
    """
    packaged = _packaged_migrations()
    if through is not None and through not in packaged:
        pytest.fail(f"{through} is not a packaged migration", pytrace=False)
    versions = work_dir / "versions"
    versions.mkdir(parents=True)
    for name, path in packaged.items():
        if through is not None and name <= through:
            shutil.copyfile(path, versions / name)
    with mock.patch.object(runner, "files", lambda _package: work_dir):
        await runner.run_migrations(settings)


def _migration_before(version: str) -> str | None:
    earlier = [name for name in _packaged_migrations() if name < version]
    return earlier[-1] if earlier else None


def _dump_owner_roles(dump: Path) -> set[str]:
    statement = re.compile(r"^ALTER .* OWNER TO (\w+);$")
    with dump.open(encoding="utf-8") as lines:
        return {match.group(1) for line in lines if (match := statement.match(line.rstrip("\n")))}


def _drop_database(admin: psycopg.Connection, name: str) -> None:
    admin.execute(sql.SQL("DROP DATABASE IF EXISTS {} WITH (FORCE)").format(sql.Identifier(name)))


def _restore(server: DatabaseServer, dump: Path, database: str) -> None:
    # psql runs inside the container: the dump contains COPY ... FROM stdin blocks.
    command = [
        "docker",
        "exec",
        "-i",
        server.container,
        "psql",
        "-X",
        "-q",
        "-v",
        "ON_ERROR_STOP=1",
        "-U",
        server.user,
        "-d",
        database,
    ]
    with dump.open("rb") as source:
        result = subprocess.run(command, stdin=source, capture_output=True, check=False)
    if result.returncode != 0:
        errors = result.stderr.decode(errors="replace").strip()
        pytest.fail(f"Restoring {dump.name} failed: {errors}", pytrace=False)


@pytest.fixture(scope="session")
def database_server() -> DatabaseServer:
    return _verified_server()


def _create_from_dump(server: DatabaseServer, dump: Path, database: str) -> None:
    """(Re)create ``database`` as a plain restore of ``dump``, owner roles included."""
    with server.connect_admin() as admin:
        for role in sorted(_dump_owner_roles(dump)):
            if admin.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (role,)).fetchone():
                continue
            admin.execute(sql.SQL("CREATE ROLE {}").format(sql.Identifier(role)))
        _drop_database(admin, database)
        admin.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(database)))
    _restore(server, dump, database)


# Pre-T2.2 stand-in. Migration 0019 makes exec.plan_runs.run_plan_id and the tracks'
# plan_lineage_key NOT NULL, and the run creation of master before T2.2 sets neither. Until this
# branch is rebased onto T2.2, these triggers give such a run an empty run plan and its tracks
# random lineage keys, so that the tests creating runs keep running on converted data; the runs
# stay bound to library rows exactly as before. Inert for rows that carry the values. Installed
# only while T2.2's module is absent; delete it together with ``_install_pre_t22_stand_in``
# when rebasing onto T2.2 (handoff/T2.1.md).
PRE_T22_STAND_IN = """
CREATE FUNCTION public.agonez_it_pre_t22_run_plan() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.run_plan_id IS NULL THEN
        INSERT INTO plans.workout_plans (name, description, accent, scope, source_plan_id)
        SELECT plan.name, plan.description, plan.accent, 'run', plan.id
        FROM plans.plan_revisions AS revision
        JOIN plans.workout_plans AS plan ON plan.id = revision.plan_id
        WHERE revision.id = NEW.initial_plan_revision_id
        RETURNING id INTO NEW.run_plan_id;
    END IF;
    RETURN NEW;
END;
$$;
CREATE FUNCTION public.agonez_it_pre_t22_track_key() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    NEW.plan_lineage_key := coalesce(NEW.plan_lineage_key, gen_random_uuid());
    RETURN NEW;
END;
$$;
CREATE TRIGGER agonez_it_pre_t22_run_plan BEFORE INSERT ON exec.plan_runs
    FOR EACH ROW EXECUTE FUNCTION public.agonez_it_pre_t22_run_plan();
CREATE TRIGGER agonez_it_pre_t22_track_key BEFORE INSERT ON exec.workout_unit_tracks
    FOR EACH ROW EXECUTE FUNCTION public.agonez_it_pre_t22_track_key();
CREATE TRIGGER agonez_it_pre_t22_track_key BEFORE INSERT ON exec.exercise_unit_tracks
    FOR EACH ROW EXECUTE FUNCTION public.agonez_it_pre_t22_track_key();
"""
T22_MODULE = "agonez_api.modules.execution.run_plan_repository"  # 02 §3.2, created by T2.2


def _install_pre_t22_stand_in(settings: Settings) -> None:
    if importlib.util.find_spec(T22_MODULE) is not None:
        return
    with psycopg.connect(settings.database_dsn, autocommit=True) as connection:
        required = connection.execute(
            """
            SELECT attnotnull FROM pg_attribute
            WHERE attrelid = 'exec.plan_runs'::regclass AND attname = 'run_plan_id'
            """
        ).fetchone()
        if required is not None and required[0]:
            connection.execute(PRE_T22_STAND_IN)


@pytest.fixture(scope="session")
def template_database(
    database_server: DatabaseServer,
    tmp_path_factory: pytest.TempPathFactory,
) -> Iterator[str]:
    """Restored dump plus pending migrations. One pytest session per container at a time."""
    try:
        _create_from_dump(database_server, _dump_path(), TEMPLATE_DATABASE)
        settings = database_server.settings(TEMPLATE_DATABASE, tmp_path_factory.mktemp("template"))
        asyncio.run(run_migrations(settings))
        _install_pre_t22_stand_in(settings)
        yield TEMPLATE_DATABASE
    finally:
        with database_server.connect_admin() as admin:
            _drop_database(admin, TEMPLATE_DATABASE)


@pytest.fixture(scope="session")
def migration_templates(
    database_server: DatabaseServer,
    tmp_path_factory: pytest.TempPathFactory,
) -> Iterator[Callable[[str], str]]:
    """``template_before(version)``: the template a ``before_migration`` test is cloned from.

    Built on first use: the newest dump without ``version``, plus every packaged migration
    before it (through the real runner). Dropped at the end of the session.
    """
    built: dict[str, str] = {}

    def template_before(version: str) -> str:
        if version not in built:
            name = f"agonez_it_before_{version.split('_', 1)[0]}"
            try:
                _create_from_dump(database_server, _dump_without(version), name)
                settings = database_server.settings(name, tmp_path_factory.mktemp(name))
                asyncio.run(
                    apply_migrations(
                        settings,
                        tmp_path_factory.mktemp(f"{name}_versions"),
                        through=_migration_before(version),
                    )
                )
            except BaseException:
                with database_server.connect_admin() as admin:
                    _drop_database(admin, name)
                raise
            built[version] = name
        return built[version]

    try:
        yield template_before
    finally:
        with database_server.connect_admin() as admin:
            for name in built.values():
                _drop_database(admin, name)


@pytest.fixture
def database_name(
    request: pytest.FixtureRequest,
    database_server: DatabaseServer,
) -> Iterator[str]:
    """A fresh clone of the template (or of a ``before_migration`` one), dropped afterwards."""
    marker = request.node.get_closest_marker("before_migration")
    if marker is None:
        template = request.getfixturevalue("template_database")
    else:
        (version,) = marker.args
        template = request.getfixturevalue("migration_templates")(version)
    name = f"agonez_it_{uuid4().hex[:12]}"
    with database_server.connect_admin() as admin:
        admin.execute(
            sql.SQL("CREATE DATABASE {} TEMPLATE {}").format(
                sql.Identifier(name), sql.Identifier(template)
            )
        )
    try:
        yield name
    finally:
        with database_server.connect_admin() as admin:
            _drop_database(admin, name)


@pytest.fixture
def settings(database_server: DatabaseServer, database_name: str, tmp_path: Path) -> Settings:
    return database_server.settings(database_name, tmp_path)


@pytest.fixture
async def pool(settings: Settings) -> AsyncIterator[DatabasePool]:
    """The application's pool. create_app() does not open a pool it was given."""
    database_pool = create_database_pool(settings)
    async with open_database_pool(database_pool, wait_seconds=settings.db_startup_wait_seconds):
        yield database_pool


@pytest.fixture
async def db(pool: DatabasePool) -> AsyncIterator[psycopg.AsyncConnection]:
    """Autocommit, dict-row connection for assertions and direct set-up."""
    async with pool.connection() as connection:
        yield connection


class FrozenClock:
    """The Execution service's ``today``; assign ``clock.today`` to move time."""

    def __init__(self, today: date) -> None:
        self.today = today

    def __call__(self) -> date:
        return self.today


@pytest.fixture
def clock() -> FrozenClock:
    # Mobile context and run listing read the real date unless a request passes `?date=`.
    return FrozenClock(FROZEN_TODAY)


@pytest.fixture
def app(settings: Settings, pool: DatabasePool, clock: FrozenClock) -> FastAPI:
    application = create_app(settings=settings, pool=pool)
    # create_app() builds the service with the real date; routes resolve it from app.state.
    application.state.execution_service = ExecutionService(
        application.state.execution_repository,
        today=clock,
    )
    return application


@pytest.fixture
async def client(app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    """HTTP client over ASGI. Unhandled server errors raise in the test with their traceback."""
    async with httpx.AsyncClient(
        transport=httpx.ASGITransport(app=app),
        base_url="http://testserver",
    ) as http:
        yield http


@pytest.fixture
def plan_repository(app: FastAPI) -> PlanRepository:
    return app.state.plan_repository


@pytest.fixture
def plan_service(app: FastAPI) -> PlanService:
    return app.state.plan_service


@pytest.fixture
def execution_repository(app: FastAPI) -> ExecutionRepository:
    return app.state.execution_repository


@pytest.fixture
def execution_service(app: FastAPI) -> ExecutionService:
    return app.state.execution_service


@pytest.fixture
def mobile_execution_repository(app: FastAPI) -> MobileExecutionRepository:
    return app.state.mobile_execution_repository


@pytest.fixture
def mobile_execution_service(app: FastAPI) -> MobileExecutionService:
    return app.state.mobile_execution_service
