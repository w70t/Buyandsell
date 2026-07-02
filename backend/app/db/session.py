from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings

# SQLite (tests/dev) uses NullPool and rejects pool sizing arguments.
_pool_kwargs = (
    {} if settings.database_url.startswith("sqlite") else {"pool_size": 5, "max_overflow": 10}
)

engine = create_async_engine(
    settings.database_url,
    echo=False,
    pool_pre_ping=True,
    **_pool_kwargs,
)

SessionLocal = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session
