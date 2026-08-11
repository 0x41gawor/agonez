from pathlib import Path

import pytest
from pydantic import ValidationError

from agonez_api.core.config import Settings


def test_settings_use_required_named_credentials(tmp_path: Path) -> None:
    settings = Settings(
        NOME="atlas_user",
        AGANDSKODE="a password with spaces",
        MINA=33327,
        MEDIA_ROOT=tmp_path,
        CORS_ORIGINS="http://localhost:5173, https://atlas.example",
    )

    assert settings.nome == "atlas_user"
    assert settings.agandskode.get_secret_value() == "a password with spaces"
    assert settings.db_port == 33327
    assert settings.db_name == "agonez_db"
    assert settings.cors_origins == ["http://localhost:5173", "https://atlas.example"]
    assert "password='a password with spaces'" in settings.database_dsn
    assert "statement_timeout=10000" in settings.database_dsn
    assert "default_transaction_read_only" not in settings.database_dsn


def test_settings_reject_invalid_pool_range(tmp_path: Path) -> None:
    with pytest.raises(ValidationError, match="DB_POOL_MIN_SIZE"):
        Settings(
            NOME="atlas_user",
            AGANDSKODE="secret",
            MINA=33327,
            MEDIA_ROOT=tmp_path,
            DB_POOL_MIN_SIZE=5,
            DB_POOL_MAX_SIZE=2,
        )


def test_settings_accept_legacy_db_port_fallback(tmp_path: Path) -> None:
    settings = Settings(
        NOME="atlas_user",
        AGANDSKODE="secret",
        DB_PORT=35432,
        MEDIA_ROOT=tmp_path,
    )

    assert settings.db_port == 35432
