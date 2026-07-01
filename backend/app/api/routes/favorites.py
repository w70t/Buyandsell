from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.api.serializers import listing_to_out
from app.core.deps import CurrentUser, DbDep
from app.models import Favorite, Listing
from app.schemas.listing import ListingOut

router = APIRouter(prefix="/favorites", tags=["favorites"])


@router.get("", response_model=list[ListingOut])
async def list_favorites(user: CurrentUser, db: DbDep) -> list[ListingOut]:
    rows = await db.scalars(
        select(Listing)
        .join(Favorite, Favorite.listing_id == Listing.id)
        .where(Favorite.user_id == user.id)
        .options(
            selectinload(Listing.category),
            selectinload(Listing.seller),
            selectinload(Listing.images),
        )
        .order_by(Favorite.created_at.desc())
    )
    return [listing_to_out(r) for r in rows]


@router.get("/ids", response_model=list[int])
async def favorite_ids(user: CurrentUser, db: DbDep) -> list[int]:
    rows = await db.scalars(select(Favorite.listing_id).where(Favorite.user_id == user.id))
    return list(rows)


@router.post("/{listing_id}", status_code=status.HTTP_201_CREATED)
async def add_favorite(listing_id: int, user: CurrentUser, db: DbDep) -> dict:
    if await db.get(Listing, listing_id) is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    exists = await db.get(Favorite, {"user_id": user.id, "listing_id": listing_id})
    if exists is None:
        db.add(Favorite(user_id=user.id, listing_id=listing_id))
        await db.commit()
    return {"detail": "added"}


@router.delete("/{listing_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(listing_id: int, user: CurrentUser, db: DbDep) -> None:
    fav = await db.get(Favorite, {"user_id": user.id, "listing_id": listing_id})
    if fav is not None:
        await db.delete(fav)
        await db.commit()
