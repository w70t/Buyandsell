from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.api.serializers import listing_to_out
from app.core.deps import AdminUser, DbDep
from app.models import Category, Listing, Message, User, UserRole
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from app.schemas.common import Page
from app.schemas.listing import ListingOut
from app.schemas.user import UserMe
from app.services.storage import storage

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[])


class AdminStats(BaseModel):
    users: int
    listings: int
    active_listings: int
    messages: int


class UserAdminUpdate(BaseModel):
    is_banned: bool | None = None
    is_active: bool | None = None
    role: str | None = None


@router.get("/stats", response_model=AdminStats)
async def stats(admin: AdminUser, db: DbDep) -> AdminStats:
    users = await db.scalar(select(func.count()).select_from(User)) or 0
    listings = await db.scalar(select(func.count()).select_from(Listing)) or 0
    active = await db.scalar(
        select(func.count()).select_from(Listing).where(Listing.status == "active")
    ) or 0
    messages = await db.scalar(select(func.count()).select_from(Message)) or 0
    return AdminStats(users=users, listings=listings, active_listings=active, messages=messages)


@router.get("/users", response_model=Page[UserMe])
async def list_users(
    admin: AdminUser,
    db: DbDep,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
) -> Page[UserMe]:
    total = await db.scalar(select(func.count()).select_from(User)) or 0
    rows = await db.scalars(
        select(User).order_by(User.created_at.desc()).offset((page - 1) * size).limit(size)
    )
    return Page(items=[UserMe.model_validate(u) for u in rows], total=total, page=page, size=size)


@router.patch("/users/{user_id}", response_model=UserMe)
async def update_user(user_id: int, payload: UserAdminUpdate, admin: AdminUser, db: DbDep) -> UserMe:
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "المستخدم غير موجود")
    data = payload.model_dump(exclude_unset=True)
    if "role" in data and data["role"] not in (UserRole.USER.value, UserRole.ADMIN.value):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "دور غير صالح")
    for field, value in data.items():
        setattr(user, field, value)
    await db.commit()
    await db.refresh(user)
    return UserMe.model_validate(user)


@router.get("/listings", response_model=Page[ListingOut])
async def list_all_listings(
    admin: AdminUser,
    db: DbDep,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
) -> Page[ListingOut]:
    total = await db.scalar(select(func.count()).select_from(Listing)) or 0
    rows = await db.scalars(
        select(Listing)
        .options(
            selectinload(Listing.category),
            selectinload(Listing.seller),
            selectinload(Listing.images),
        )
        .order_by(Listing.created_at.desc())
        .offset((page - 1) * size)
        .limit(size)
    )
    return Page(items=[listing_to_out(r) for r in rows], total=total, page=page, size=size)


@router.delete("/listings/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_any_listing(listing_id: int, admin: AdminUser, db: DbDep) -> None:
    listing = await db.scalar(
        select(Listing).where(Listing.id == listing_id).options(selectinload(Listing.images))
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    for img in listing.images:
        storage.delete(img.key)
    await db.delete(listing)
    await db.commit()


# ---- Category management ----
@router.post("/categories", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
async def create_category(payload: CategoryCreate, admin: AdminUser, db: DbDep) -> Category:
    if await db.scalar(select(Category).where(Category.slug == payload.slug)):
        raise HTTPException(status.HTTP_409_CONFLICT, "المعرّف مستخدم مسبقاً")
    category = Category(**payload.model_dump())
    db.add(category)
    await db.commit()
    await db.refresh(category)
    return category


@router.patch("/categories/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int, payload: CategoryUpdate, admin: AdminUser, db: DbDep
) -> Category:
    category = await db.get(Category, category_id)
    if category is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "القسم غير موجود")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(category, field, value)
    await db.commit()
    await db.refresh(category)
    return category
