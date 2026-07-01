from fastapi import APIRouter
from sqlalchemy import select

from app.core.deps import DbDep
from app.models import Category
from app.schemas.category import CategoryOut

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
async def list_categories(db: DbDep) -> list[Category]:
    rows = await db.scalars(
        select(Category).where(Category.is_active.is_(True)).order_by(Category.sort_order)
    )
    return list(rows)
