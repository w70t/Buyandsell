from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """All configuration comes from environment variables (12-factor).

    The same code runs on a Raspberry Pi and on a VPS — only the env changes.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore", case_sensitive=False)

    # App
    app_name: str = "Souqna"
    app_env: str = "production"
    secret_key: str = "change-me"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30
    cors_origins: str = "*"
    public_base_url: str = "http://localhost:8080"

    # Database
    database_url: str = "postgresql+asyncpg://souqna:souqna@db:5432/souqna"

    # Storage
    storage_backend: str = "local"  # local | minio
    upload_dir: str = "/data/uploads"
    max_upload_mb: int = 8

    # MinIO / S3
    minio_endpoint: str = "minio:9000"
    minio_access_key: str = "souqna"
    minio_secret_key: str = "souqna"
    minio_bucket: str = "souqna-media"
    minio_secure: bool = False

    # Rate limiting
    rate_limit_default: str = "100/minute"
    rate_limit_auth: str = "10/minute"

    # Optional Redis (rate-limit storage shared across workers; unset = in-memory).
    redis_url: str = ""

    # Moderation: hide a listing automatically once it collects this many open reports.
    reports_auto_hide_threshold: int = 5

    # Telegram notifications for the admin (leave empty to disable).
    telegram_bot_token: str = ""
    telegram_admin_chat_id: str = ""

    # Web (SSR) session cookies. Set true once you serve over HTTPS.
    cookie_secure: bool = False

    # Seed admin
    admin_phone: str = "07700000000"
    admin_name: str = "Admin"
    admin_password: str = "change-me"

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def is_dev(self) -> bool:
        return self.app_env.lower() == "development"

    # Alembic / async engines both need a sync-vs-async aware URL.
    @property
    def sync_database_url(self) -> str:
        return self.database_url.replace("+asyncpg", "+psycopg2")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
