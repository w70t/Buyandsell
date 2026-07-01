"""Block until PostgreSQL accepts connections (used by the container entrypoint)."""
import asyncio
import sys

from sqlalchemy import text

from app.core.logging import configure_logging, logger
from app.db.session import engine


async def main(retries: int = 30, delay: float = 2.0) -> None:
    configure_logging()
    for attempt in range(1, retries + 1):
        try:
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            logger.info("database is ready")
            await engine.dispose()
            return
        except Exception as exc:  # noqa: BLE001
            logger.info("waiting for database (%s/%s): %s", attempt, retries, exc)
            await asyncio.sleep(delay)
    logger.error("database not reachable, giving up")
    sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
