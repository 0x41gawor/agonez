from functools import lru_cache
from pathlib import Path

from psycopg.conninfo import make_conninfo
from pydantic import AliasChoices, Field, SecretStr, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration loaded from environment variables."""

    model_config = SettingsConfigDict(
        case_sensitive=True,
        extra="ignore",
    )

    app_name: str = Field(default="Agonez Atlas API", alias="APP_NAME")
    app_version: str = Field(default="0.1.0", alias="APP_VERSION")
    environment: str = Field(default="development", alias="ENVIRONMENT")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")

    nome: str = Field(alias="NOME", min_length=1)
    agandskode: SecretStr = Field(alias="AGANDSKODE")
    db_host: str = Field(default="127.0.0.1", alias="DB_HOST")
    db_port: int = Field(
        validation_alias=AliasChoices("MINA", "DB_PORT"),
        ge=1,
        le=65535,
    )
    db_name: str = Field(default="agonez_db", alias="DB_NAME", min_length=1)
    db_pool_min_size: int = Field(default=1, alias="DB_POOL_MIN_SIZE", ge=0)
    db_pool_max_size: int = Field(default=10, alias="DB_POOL_MAX_SIZE", ge=1)
    db_connect_timeout_seconds: int = Field(
        default=5,
        alias="DB_CONNECT_TIMEOUT_SECONDS",
        ge=1,
        le=60,
    )
    db_startup_wait_seconds: int = Field(
        default=10,
        alias="DB_STARTUP_WAIT_SECONDS",
        ge=1,
        le=120,
    )

    media_root: Path = Field(default=Path("media"), alias="MEDIA_ROOT")
    media_url_prefix: str = Field(default="/media", alias="MEDIA_URL_PREFIX")
    public_media_base_url: str | None = Field(
        default=None,
        alias="PUBLIC_MEDIA_BASE_URL",
    )
    cors_origins_csv: str = Field(
        default="http://localhost:5173,http://127.0.0.1:5173",
        alias="CORS_ORIGINS",
    )

    @field_validator("log_level")
    @classmethod
    def normalize_log_level(cls, value: str) -> str:
        level = value.upper()
        if level not in {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}:
            raise ValueError("LOG_LEVEL must be a standard Python log level")
        return level

    @field_validator("media_url_prefix")
    @classmethod
    def normalize_media_url_prefix(cls, value: str) -> str:
        normalized = "/" + value.strip("/")
        if normalized == "/":
            raise ValueError("MEDIA_URL_PREFIX cannot be the root path")
        return normalized

    @field_validator("public_media_base_url")
    @classmethod
    def normalize_public_media_base_url(cls, value: str | None) -> str | None:
        return value.rstrip("/") if value else None

    @model_validator(mode="after")
    def validate_pool_sizes(self) -> "Settings":
        if self.db_pool_min_size > self.db_pool_max_size:
            raise ValueError("DB_POOL_MIN_SIZE cannot exceed DB_POOL_MAX_SIZE")
        return self

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins_csv.split(",") if origin.strip()]

    @property
    def database_dsn(self) -> str:
        # make_conninfo handles escaping and avoids assembling an unsafe URL.
        return make_conninfo(
            "",
            user=self.nome,
            password=self.agandskode.get_secret_value(),
            host=self.db_host,
            port=self.db_port,
            dbname=self.db_name,
            connect_timeout=self.db_connect_timeout_seconds,
            application_name="agonez_atlas_api",
            options="-c statement_timeout=10000",
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()
