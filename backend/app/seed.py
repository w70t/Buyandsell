"""Idempotent seed: base categories + the initial admin account.

Runs on every boot; only inserts what is missing.
"""
import asyncio

from sqlalchemy import select

from app.core.config import settings
from app.core.logging import configure_logging, logger
from app.core.security import hash_password
from app.db.session import SessionLocal, engine
from app.models import Category, User, UserRole

CATEGORIES = [
    ("all", "كل الأقسام", "تصفّح كل المعروضات", "grid", 0),
    ("realestate", "عقارات", "شقق، بيوت وأراضٍ", "home", 1),
    ("cars", "سيارات ومركبات", "مركبات، قطع غيار وإكسسوارات", "car", 2),
    ("phones", "هواتف وأجهزة", "موبايلات وأجهزة لوحية", "phone", 3),
    ("electronics", "إلكترونيات", "حواسيب وأجهزة منزلية", "bolt", 4),
    ("furniture", "أثاث ومنزل", "أثاث، ديكور وأدوات", "chair", 5),
    ("fashion", "أزياء وإكسسوارات", "ملابس، أحذية ومجوهرات", "shirt", 6),
    ("jobs", "وظائف", "فرص عمل وتدريب", "work", 7),
    ("kids", "مستلزمات الأطفال", "ألعاب ومستلزمات الأطفال", "stroller", 8),
    ("pets", "حيوانات أليفة", "حيوانات ومستلزماتها", "pets", 9),
    ("services", "خدمات", "صيانة، نقل ورعاية", "tools", 10),
    ("hobby", "رياضة وهوايات", "رياضة، سفر وفنون", "sports", 11),
    ("books", "كتب وأدوات", "كتب، قرطاسية وترفيه", "book", 12),
    ("free", "مجاني ومقايضة", "هدايا وتبادل", "gift", 13),
    ("other", "أخرى", "كل ما لا يندرج تحت قسم", "widgets", 14),
]


async def seed_categories() -> None:
    async with SessionLocal() as db:
        for slug, name_ar, subtitle, icon, order in CATEGORIES:
            exists = await db.scalar(select(Category).where(Category.slug == slug))
            if exists is None:
                db.add(
                    Category(
                        slug=slug,
                        name_ar=name_ar,
                        subtitle_ar=subtitle,
                        icon=icon,
                        sort_order=order,
                    )
                )
        await db.commit()
    logger.info("categories seeded")


async def seed_admin() -> None:
    async with SessionLocal() as db:
        exists = await db.scalar(select(User).where(User.phone == settings.admin_phone))
        if exists is None:
            db.add(
                User(
                    name=settings.admin_name,
                    phone=settings.admin_phone,
                    password_hash=hash_password(settings.admin_password),
                    role=UserRole.ADMIN.value,
                )
            )
            await db.commit()
            logger.info("admin user created (%s)", settings.admin_phone)
        else:
            logger.info("admin user already exists")


async def main() -> None:
    configure_logging()
    await seed_categories()
    await seed_admin()
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
