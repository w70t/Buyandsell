"""Server-rendered admin dashboard at /admin."""
from __future__ import annotations

from fastapi import APIRouter, Form, HTTPException, Query, Request, Response, status
from fastapi.responses import RedirectResponse
from sqlalchemy import func, select
from sqlalchemy.orm import selectinload

from app.db.session import SessionLocal
from app.models import (
    AuditLog,
    Category,
    Listing,
    ListingStatus,
    Message,
    NotificationType,
    Report,
    ReportStatus,
    User,
    UserRole,
)
from app.services.moderation import REASON_LABELS, audit, resolve_report
from app.services.notify import notify_user
from app.services.storage import storage
from app.web.deps import AdminWebUser, CsrfCheck
from app.web.helpers import base_context, render

router = APIRouter(prefix="/admin", include_in_schema=False)

PAGE_SIZE = 20


def _redirect(url: str) -> RedirectResponse:
    return RedirectResponse(url, status_code=status.HTTP_303_SEE_OTHER)


@router.get("")
async def dashboard(request: Request, response: Response, user: AdminWebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        stats = {
            "users": await db.scalar(select(func.count()).select_from(User)) or 0,
            "listings": await db.scalar(select(func.count()).select_from(Listing)) or 0,
            "active_listings": await db.scalar(
                select(func.count()).select_from(Listing).where(Listing.status == "active")
            ) or 0,
            "messages": await db.scalar(select(func.count()).select_from(Message)) or 0,
            "open_reports": await db.scalar(
                select(func.count()).select_from(Report).where(Report.status == "open")
            ) or 0,
            "banned_users": await db.scalar(
                select(func.count()).select_from(User).where(User.is_banned.is_(True))
            ) or 0,
        }
    ctx["stats"] = stats
    return render("admin/dashboard.html", ctx, response)


# ---- Users ----
@router.get("/users")
async def admin_users(
    request: Request,
    response: Response,
    user: AdminWebUser,
    q: str = Query(default=""),
    page: int = Query(default=1, ge=1),
):
    ctx = await base_context(request, response, user)
    conditions = []
    if q.strip():
        like = f"%{q.strip()}%"
        conditions.append((User.name.ilike(like)) | (User.phone.ilike(like)))
    async with SessionLocal() as db:
        total = await db.scalar(select(func.count()).select_from(User).where(*conditions)) or 0
        users = list(
            await db.scalars(
                select(User)
                .where(*conditions)
                .order_by(User.created_at.desc())
                .offset((page - 1) * PAGE_SIZE)
                .limit(PAGE_SIZE)
            )
        )
    ctx.update(users=users, total=total, page=page, pages=(total + PAGE_SIZE - 1) // PAGE_SIZE, q=q)
    return render("admin/users.html", ctx, response)


@router.post("/users/{user_id}/ban")
async def ban_user(user: AdminWebUser, user_id: int, banned: bool = Form(...), _=CsrfCheck):
    async with SessionLocal() as db:
        target = await db.get(User, user_id)
        if target is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "المستخدم غير موجود")
        if target.id == user.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "لا يمكنك حظر نفسك")
        target.is_banned = banned
        audit(db, user.id, "ban_user" if banned else "unban_user", "user", target.id, target.name)
        await db.commit()
    return _redirect("/admin/users")


@router.post("/users/{user_id}/role")
async def set_role(user: AdminWebUser, user_id: int, role: str = Form(...), _=CsrfCheck):
    if role not in (UserRole.USER.value, UserRole.ADMIN.value):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "دور غير صالح")
    async with SessionLocal() as db:
        target = await db.get(User, user_id)
        if target is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "المستخدم غير موجود")
        target.role = role
        audit(db, user.id, f"set_role:{role}", "user", target.id, target.name)
        await db.commit()
    return _redirect("/admin/users")


# ---- Listings ----
@router.get("/listings")
async def admin_listings(
    request: Request,
    response: Response,
    user: AdminWebUser,
    status_filter: str = Query(default="", alias="status"),
    page: int = Query(default=1, ge=1),
):
    ctx = await base_context(request, response, user)
    conditions = []
    if status_filter in ("active", "sold", "hidden"):
        conditions.append(Listing.status == status_filter)
    async with SessionLocal() as db:
        total = await db.scalar(select(func.count()).select_from(Listing).where(*conditions)) or 0
        listings = list(
            await db.scalars(
                select(Listing)
                .where(*conditions)
                .options(
                    selectinload(Listing.category),
                    selectinload(Listing.seller),
                    selectinload(Listing.images),
                )
                .order_by(Listing.created_at.desc())
                .offset((page - 1) * PAGE_SIZE)
                .limit(PAGE_SIZE)
            )
        )
    ctx.update(
        listings=listings,
        total=total,
        page=page,
        pages=(total + PAGE_SIZE - 1) // PAGE_SIZE,
        status_filter=status_filter,
    )
    return render("admin/listings.html", ctx, response)


@router.post("/listings/{listing_id}/status")
async def admin_set_listing_status(
    user: AdminWebUser, listing_id: int, new_status: str = Form(alias="status"), _=CsrfCheck
):
    if new_status not in ("active", "sold", "hidden"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "حالة غير صالحة")
    async with SessionLocal() as db:
        listing = await db.get(Listing, listing_id)
        if listing is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        old = listing.status
        listing.status = new_status
        if new_status == ListingStatus.HIDDEN.value and old != new_status:
            notify_user(
                db,
                listing.seller_id,
                NotificationType.MODERATION.value,
                "تم إخفاء إعلانك",
                "أخفت الإدارة إعلانك بانتظار المراجعة.",
                f"/listings/{listing.id}",
            )
        audit(db, user.id, "set_listing_status", "listing", listing.id, f"{old} -> {new_status}")
        await db.commit()
    return _redirect("/admin/listings")


@router.post("/listings/{listing_id}/delete")
async def admin_delete_listing(user: AdminWebUser, listing_id: int, _=CsrfCheck):
    async with SessionLocal() as db:
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
        audit(db, user.id, "delete_listing", "listing", listing.id, listing.title)
        await db.delete(listing)
        await db.commit()
    return _redirect("/admin/listings")


# ---- Reports ----
@router.get("/reports")
async def admin_reports(
    request: Request,
    response: Response,
    user: AdminWebUser,
    status_filter: str = Query(default="open", alias="status"),
    page: int = Query(default=1, ge=1),
):
    ctx = await base_context(request, response, user)
    conditions = []
    if status_filter in ("open", "resolved", "dismissed"):
        conditions.append(Report.status == status_filter)
    async with SessionLocal() as db:
        total = await db.scalar(select(func.count()).select_from(Report).where(*conditions)) or 0
        reports = list(
            await db.scalars(
                select(Report)
                .where(*conditions)
                .options(
                    selectinload(Report.reporter),
                    selectinload(Report.listing),
                    selectinload(Report.reported_user),
                )
                .order_by(Report.created_at.desc(), Report.id.desc())
                .offset((page - 1) * PAGE_SIZE)
                .limit(PAGE_SIZE)
            )
        )
    ctx.update(
        reports=reports,
        total=total,
        page=page,
        pages=(total + PAGE_SIZE - 1) // PAGE_SIZE,
        status_filter=status_filter,
        reason_labels=REASON_LABELS,
    )
    return render("admin/reports.html", ctx, response)


@router.post("/reports/{report_id}/resolve")
async def admin_resolve_report(
    user: AdminWebUser,
    report_id: int,
    action: str = Form(default="none"),
    note: str = Form(default=""),
    _=CsrfCheck,
):
    if action not in ("none", "hide_listing", "delete_listing", "ban_user"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "إجراء غير صالح")
    async with SessionLocal() as db:
        await resolve_report(db, user, report_id, action, note[:400])
    return _redirect("/admin/reports")


@router.post("/reports/{report_id}/dismiss")
async def admin_dismiss_report(user: AdminWebUser, report_id: int, _=CsrfCheck):
    async with SessionLocal() as db:
        await resolve_report(db, user, report_id, "none", dismiss=True)
    return _redirect("/admin/reports")


# ---- Categories ----
@router.get("/categories")
async def admin_categories(request: Request, response: Response, user: AdminWebUser):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        categories = list(await db.scalars(select(Category).order_by(Category.sort_order)))
    ctx["categories"] = categories
    return render("admin/categories.html", ctx, response)


@router.post("/categories")
async def admin_create_category(
    user: AdminWebUser,
    slug: str = Form(min_length=2, max_length=64),
    name_ar: str = Form(min_length=1, max_length=120),
    subtitle_ar: str = Form(default=""),
    icon: str = Form(default="widgets"),
    sort_order: int = Form(default=0),
    _=CsrfCheck,
):
    async with SessionLocal() as db:
        if await db.scalar(select(Category).where(Category.slug == slug)):
            raise HTTPException(status.HTTP_409_CONFLICT, "المعرّف مستخدم مسبقاً")
        category = Category(
            slug=slug, name_ar=name_ar, subtitle_ar=subtitle_ar, icon=icon, sort_order=sort_order
        )
        db.add(category)
        await db.flush()
        audit(db, user.id, "create_category", "category", category.id, slug)
        await db.commit()
    return _redirect("/admin/categories")


@router.post("/categories/{category_id}/toggle")
async def admin_toggle_category(user: AdminWebUser, category_id: int, _=CsrfCheck):
    async with SessionLocal() as db:
        category = await db.get(Category, category_id)
        if category is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "القسم غير موجود")
        category.is_active = not category.is_active
        audit(db, user.id, "toggle_category", "category", category.id, category.slug)
        await db.commit()
    return _redirect("/admin/categories")


# ---- Audit log ----
@router.get("/audit")
async def admin_audit(
    request: Request, response: Response, user: AdminWebUser, page: int = Query(default=1, ge=1)
):
    ctx = await base_context(request, response, user)
    async with SessionLocal() as db:
        total = await db.scalar(select(func.count()).select_from(AuditLog)) or 0
        entries = list(
            await db.scalars(
                select(AuditLog)
                .options(selectinload(AuditLog.admin))
                .order_by(AuditLog.created_at.desc(), AuditLog.id.desc())
                .offset((page - 1) * 50)
                .limit(50)
            )
        )
    ctx.update(entries=entries, total=total, page=page, pages=(total + 49) // 50)
    return render("admin/audit.html", ctx, response)
