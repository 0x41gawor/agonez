"""Integration harness: the real application against a disposable PostgreSQL.

Every test in this directory carries the ``integration`` marker and is skipped unless
``AGONEZ_TEST_DATABASE_URL`` is set (``scripts/test_db.sh`` prints it). Once per session the
newest repository database dump is restored into a template database and the packaged
migrations are applied on top; every test then gets its own clone of that template.

The harness creates and drops databases, so before it opens any connection it checks that the
URL points at a container started by ``scripts/test_db.sh``.
"""

import asyncio
import os
import re
import subprocess
from collections.abc import AsyncIterator, Iterator
from dataclasses import dataclass, field
from datetime import date
from pathlib import Path
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


@pytest.fixture(scope="session")
def template_database(
    database_server: DatabaseServer,
    tmp_path_factory: pytest.TempPathFactory,
) -> Iterator[str]:
    """Restored dump plus pending migrations. One pytest session per container at a time."""
    dump = _dump_path()
    with database_server.connect_admin() as admin:
        for role in sorted(_dump_owner_roles(dump)):
            if admin.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (role,)).fetchone():
                continue
            admin.execute(sql.SQL("CREATE ROLE {}").format(sql.Identifier(role)))
        _drop_database(admin, TEMPLATE_DATABASE)
        admin.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(TEMPLATE_DATABASE)))
    try:
        _restore(database_server, dump, TEMPLATE_DATABASE)
        runtime_root = tmp_path_factory.mktemp("template")
        asyncio.run(run_migrations(database_server.settings(TEMPLATE_DATABASE, runtime_root)))
        yield TEMPLATE_DATABASE
    finally:
        with database_server.connect_admin() as admin:
            _drop_database(admin, TEMPLATE_DATABASE)


@pytest.fixture
def database_name(database_server: DatabaseServer, template_database: str) -> Iterator[str]:
    """A fresh clone of the template, dropped after the test."""
    name = f"agonez_it_{uuid4().hex[:12]}"
    with database_server.connect_admin() as admin:
        admin.execute(
            sql.SQL("CREATE DATABASE {} TEMPLATE {}").format(
                sql.Identifier(name), sql.Identifier(template_database)
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
