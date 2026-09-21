import json
from pathlib import Path
from typing import cast

from httpx import ASGITransport, AsyncClient

from agonez_api.app import create_app
from agonez_api.core.config import Settings
from agonez_api.core.database import DatabasePool
from agonez_api.modules.waitlist.schemas import WaitlistSubmission
from agonez_api.modules.waitlist.store import WaitlistStore


def read_records(path: Path) -> list[dict[str, str]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def test_store_appends_unique_normalized_addresses(tmp_path: Path) -> None:
    path = tmp_path / "private" / "waitlist.jsonl"
    store = WaitlistStore(path)

    assert store.add(email="athlete@example.com", locale="en") is True
    assert store.add(email="ATHLETE@example.com", locale="pl") is False

    records = read_records(path)
    assert len(records) == 1
    assert records[0]["email"] == "athlete@example.com"
    assert records[0]["locale"] == "en"
    assert records[0]["created_at"].endswith("Z")
    assert path.stat().st_mode & 0o777 == 0o600


def test_submission_schema_normalizes_email() -> None:
    submission = WaitlistSubmission(email="  Athlete@Example.COM ")

    assert submission.email == "athlete@example.com"


async def test_waitlist_endpoint_persists_locale_and_hides_duplicates(tmp_path: Path) -> None:
    waitlist_path = tmp_path / "waitlist.jsonl"
    settings = Settings(
        NOME="atlas_user",
        AGANDSKODE="secret",
        MINA=33327,
        MEDIA_ROOT=tmp_path,
        WAITLIST_PATH=waitlist_path,
    )
    app = create_app(settings=settings, pool=cast(DatabasePool, object()))

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        first = await client.post(
            "/api/waitlist",
            headers={"Accept-Language": "pl-PL"},
            json={"email": "Athlete@Example.com", "website": ""},
        )
        duplicate = await client.post(
            "/api/waitlist",
            headers={"Accept-Language": "en-US"},
            json={"email": "athlete@example.com", "website": ""},
        )
        honeypot = await client.post(
            "/api/waitlist",
            json={"email": "bot@example.com", "website": "https://spam.example"},
        )
        invalid = await client.post("/api/waitlist", json={"email": "not-an-email"})

    assert first.status_code == 202
    assert duplicate.status_code == 202
    assert honeypot.status_code == 202
    assert first.json() == duplicate.json() == honeypot.json() == {"accepted": True}
    assert invalid.status_code == 422
    assert read_records(waitlist_path)[0]["locale"] == "pl"
    assert len(read_records(waitlist_path)) == 1
