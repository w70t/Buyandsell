from fastapi import APIRouter, HTTPException, Query, UploadFile, status
from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload

from app.api.serializers import listing_to_out
from app.core.deps import CurrentUser, DbDep, OptionalUser
from app.models import Category, Listing, ListingImage, ListingStatus
from app.schemas.common import Page
from app.schemas.listing import ListingCreate, ListingOut, ListingUpdate
from app.services.notify import telegram_admin_bg
from app.services.storage import UploadError, storage

router = APIRouter(prefix="/listings", tags=["listings"])

MAX_IMAGES = 10
_EAGER = (
    selectinload(Listing.category),
    selectinload(Listing.seller),
    selectinload(Listing.images),
)


async def _get_owned(db: DbDep, listing_id: int, user_id: int) -> Listing:
    listing = await db.scalar(
        select(Listing).where(Listing.id == listing_id).options(*_EAGER)
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    if listing.seller_id != user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "لا تملك صلاحية تعديل هذا الإعلان")
    return listing


@router.get("", response_model=Page[ListingOut])
async def list_listings(
    db: DbDep,
    q: str | None = Query(default=None, max_length=140),
    category_id: int | None = None,
    governorate: str | None = None,
    min_price: int | None = Query(default=None, ge=0),
    max_price: int | None = Query(default=None, ge=0),
    sort: str = Query(default="recent", pattern="^(recent|price_asc|price_desc)$"),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=50),
) -> Page[ListingOut]:
    conditions = [Listing.status == ListingStatus.ACTIVE.value]
    if q:
        like = f"%{q.strip()}%"
        conditions.append(or_(Listing.title.ilike(like), Listing.description.ilike(like)))
    if category_id:
        conditions.append(Listing.category_id == category_id)
    if governorate:
        conditions.append(Listing.governorate == governorate)
    if min_price is not None:
        conditions.append(Listing.price >= min_price)
    if max_price is not None:
        conditions.append(Listing.price <= max_price)

    total = await db.scalar(select(func.count()).select_from(Listing).where(*conditions)) or 0

    order = {
        "recent": Listing.created_at.desc(),
        "price_asc": Listing.price.asc(),
        "price_desc": Listing.price.desc(),
    }[sort]

    rows = await db.scalars(
        select(Listing)
        .where(*conditions)
        .options(*_EAGER)
        .order_by(order)
        .offset((page - 1) * size)
        .limit(size)
    )
    return Page(items=[listing_to_out(r) for r in rows], total=total, page=page, size=size)


@router.get("/mine", response_model=list[ListingOut])
async def my_listings(user: CurrentUser, db: DbDep) -> list[ListingOut]:
    rows = await db.scalars(
        select(Listing)
        .where(Listing.seller_id == user.id)
        .options(*_EAGER)
        .order_by(Listing.created_at.desc())
    )
    return [listing_to_out(r) for r in rows]


@router.get("/{listing_id}", response_model=ListingOut)
async def get_listing(listing_id: int, db: DbDep, user: OptionalUser) -> ListingOut:
    listing = await db.scalar(
        select(Listing).where(Listing.id == listing_id).options(*_EAGER)
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    # Hidden listings are only visible to their owner.
    if listing.status == ListingStatus.HIDDEN.value and (user is None or user.id != listing.seller_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")

    if user is None or user.id != listing.seller_id:
        listing.views += 1
        await db.commit()
    return listing_to_out(listing)


@router.post("", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
async def create_listing(payload: ListingCreate, user: CurrentUser, db: DbDep) -> ListingOut:
    category = await db.get(Category, payload.category_id)
    if category is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "القسم غير موجود")

    listing = Listing(
        title=payload.title,
        description=payload.description,
        price=payload.price,
        negotiable=payload.negotiable,
        condition=payload.condition,
        category_id=payload.category_id,
        governorate=payload.governorate,
        city=payload.city,
        seller_id=user.id,
    )
    db.add(listing)
    await db.commit()
    listing = await db.scalar(
        select(Listing).where(Listing.id == listing.id).options(*_EAGER)
    )
    telegram_admin_bg(f"📋 إعلان جديد #{listing.id}: {listing.title} ({listing.price} IQD) — Souqna")
    return listing_to_out(listing)


@router.patch("/{listing_id}", response_model=ListingOut)
async def update_listing(
    listing_id: int, payload: ListingUpdate, user: CurrentUser, db: DbDep
) -> ListingOut:
    listing = await _get_owned(db, listing_id, user.id)
    data = payload.model_dump(exclude_unset=True)
    if "category_id" in data:
        if await db.get(Category, data["category_id"]) is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "القسم غير موجود")
    for field, value in data.items():
        setattr(listing, field, value)
    await db.commit()
    listing = await db.scalar(
        select(Listing).where(Listing.id == listing.id).options(*_EAGER)
    )
    return listing_to_out(listing)


@router.delete("/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_listing(listing_id: int, user: CurrentUser, db: DbDep) -> None:
    listing = await db.scalar(
        select(Listing).where(Listing.id == listing_id).options(selectinload(Listing.images))
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    if listing.seller_id != user.id and not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "لا تملك صلاحية الحذف")
    for img in listing.images:
        storage.delete(img.key)
    await db.delete(listing)
    await db.commit()


@router.post("/{listing_id}/images", response_model=ListingOut, status_code=status.HTTP_201_CREATED)
async def add_image(listing_id: int, file: UploadFile, user: CurrentUser, db: DbDep) -> ListingOut:
    listing = await _get_owned(db, listing_id, user.id)
    if len(listing.images) >= MAX_IMAGES:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, f"الحد الأقصى {MAX_IMAGES} صور")

    raw = await file.read()
    try:
        key = storage.save_image(raw, folder="listings")
    except UploadError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(exc))

    position = (max((img.position for img in listing.images), default=-1)) + 1
    # Append to the loaded relationship so the returned object reflects the change.
    listing.images.append(
        ListingImage(key=key, url=storage.public_url(key), position=position)
    )
    await db.commit()
    return listing_to_out(listing)


@router.delete("/{listing_id}/images/{image_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_image(listing_id: int, image_id: int, user: CurrentUser, db: DbDep) -> None:
    await _get_owned(db, listing_id, user.id)
    image = await db.get(ListingImage, image_id)
    if image is None or image.listing_id != listing_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الصورة غير موجودة")
    storage.delete(image.key)
    await db.delete(image)
    await db.commit()
