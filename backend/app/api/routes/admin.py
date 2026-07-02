from datetime import datetime

from fastapi import APIRouter, HTTPException, Query, status
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.api.serializers import listing_to_out
from app.core.deps import AdminUser, DbDep
from app.models import (
    AuditLog,
    Category,
    Listing,
    ListingStatus,
    NotificationType,
    Report,
    ReportStatus,
    User,
    UserRole,
)
from app.models import Message as MessageModel
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate
from app.schemas.common import Page
from app.schemas.listing import ListingOut
from app.schemas.report import ReportOut, ReportResolve
from app.schemas.user import UserMe
from app.services.moderation import audit, resolve_report
from app.services.notify import notify_user
from app.services.storage import storage

router = APIRouter(prefix="/admin", tags=["admin"], dependencies=[])


class AdminStats(BaseModel):
    users: int
    listings: int
    active_listings: int
    messages: int
    open_reports: int
    banned_users: int


class UserAdminUpdate(BaseModel):
    is_banned: bool | None = None
    is_active: bool | None = None
    role: str | None = None


class ListingStatusUpdate(BaseModel):
    status: str = Field(pattern="^(active|sold|hidden)$")


class AuditLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    admin_id: int | None
    action: str
    target_type: str
    target_id: int | None
    note: str
    created_at: datetime


@router.get("/stats", response_model=AdminStats)
async def stats(admin: AdminUser, db: DbDep) -> AdminStats:
    users = await db.scalar(select(func.count()).select_from(User)) or 0
    listings = await db.scalar(select(func.count()).select_from(Listing)) or 0
    active = await db.scalar(
        select(func.count()).select_from(Listing).where(Listing.status == "active")
    ) or 0
    messages = await db.scalar(select(func.count()).select_from(MessageModel)) or 0
    open_reports = await db.scalar(
        select(func.count()).select_from(Report).where(Report.status == ReportStatus.OPEN.value)
    ) or 0
    banned = await db.scalar(
        select(func.count()).select_from(User).where(User.is_banned.is_(True))
    ) or 0
    return AdminStats(
        users=users,
        listings=listings,
        active_listings=active,
        messages=messages,
        open_reports=open_reports,
        banned_users=banned,
    )


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
    audit(db, admin.id, "update_user", "user", user.id, str(data))
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
    notify_user(
        db,
        listing.seller_id,
        NotificationType.MODERATION.value,
        "تم حذف إعلانك",
        f"حذفت الإدارة إعلانك «{listing.title}» لمخالفته الشروط.",
    )
    audit(db, admin.id, "delete_listing", "listing", listing.id, listing.title)
    await db.delete(listing)
    await db.commit()


@router.patch("/listings/{listing_id}/status", response_model=ListingOut)
async def set_listing_status(
    listing_id: int, payload: ListingStatusUpdate, admin: AdminUser, db: DbDep
) -> ListingOut:
    listing = await db.scalar(
        select(Listing)
        .where(Listing.id == listing_id)
        .options(
            selectinload(Listing.category),
            selectinload(Listing.seller),
            selectinload(Listing.images),
        )
    )
    if listing is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
    old = listing.status
    listing.status = payload.status
    if payload.status == ListingStatus.HIDDEN.value and old != ListingStatus.HIDDEN.value:
        notify_user(
            db,
            listing.seller_id,
            NotificationType.MODERATION.value,
            "تم إخفاء إعلانك",
            "أخفت الإدارة إعلانك بانتظار المراجعة.",
            f"/listings/{listing.id}",
        )
    audit(db, admin.id, "set_listing_status", "listing", listing.id, f"{old} -> {payload.status}")
    await db.commit()
    return listing_to_out(listing)


# ---- Reports (moderation queue) ----
@router.get("/reports", response_model=Page[ReportOut])
async def list_reports(
    admin: AdminUser,
    db: DbDep,
    status_filter: str | None = Query(default=None, alias="status", pattern="^(open|resolved|dismissed)$"),
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
) -> Page[ReportOut]:
    conditions = []
    if status_filter:
        conditions.append(Report.status == status_filter)
    total = await db.scalar(select(func.count()).select_from(Report).where(*conditions)) or 0
    rows = await db.scalars(
        select(Report)
        .where(*conditions)
        .order_by(Report.created_at.desc(), Report.id.desc())
        .offset((page - 1) * size)
        .limit(size)
    )
    return Page(items=[ReportOut.model_validate(r) for r in rows], total=total, page=page, size=size)


@router.post("/reports/{report_id}/resolve", response_model=ReportOut)
async def resolve_report_endpoint(
    report_id: int, payload: ReportResolve, admin: AdminUser, db: DbDep
) -> ReportOut:
    report = await resolve_report(db, admin, report_id, payload.action, payload.note)
    return ReportOut.model_validate(report)


@router.post("/reports/{report_id}/dismiss", response_model=ReportOut)
async def dismiss_report_endpoint(report_id: int, admin: AdminUser, db: DbDep) -> ReportOut:
    report = await resolve_report(db, admin, report_id, "none", dismiss=True)
    return ReportOut.model_validate(report)


# ---- Audit log ----
@router.get("/audit", response_model=Page[AuditLogOut])
async def list_audit_log(
    admin: AdminUser,
    db: DbDep,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=50, ge=1, le=200),
) -> Page[AuditLogOut]:
    total = await db.scalar(select(func.count()).select_from(AuditLog)) or 0
    rows = await db.scalars(
        select(AuditLog)
        .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
        .offset((page - 1) * size)
        .limit(size)
    )
    return Page(items=[AuditLogOut.model_validate(a) for a in rows], total=total, page=page, size=size)


# ---- Category management ----
@router.post("/categories", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
async def create_category(payload: CategoryCreate, admin: AdminUser, db: DbDep) -> Category:
    if await db.scalar(select(Category).where(Category.slug == payload.slug)):
        raise HTTPException(status.HTTP_409_CONFLICT, "المعرّف مستخدم مسبقاً")
    category = Category(**payload.model_dump())
    db.add(category)
    await db.flush()
    audit(db, admin.id, "create_category", "category", category.id, category.slug)
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
    audit(db, admin.id, "update_category", "category", category.id, category.slug)
    await db.commit()
    await db.refresh(category)
    return category
