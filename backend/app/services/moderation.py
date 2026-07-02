"""Reporting & moderation logic shared by the JSON API and the web UI."""
from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import logger
from app.models import (
    AuditLog,
    Listing,
    ListingStatus,
    NotificationType,
    Report,
    ReportStatus,
    User,
)
from app.services.notify import notify_user, telegram_admin_bg

REASON_LABELS = {
    "scam": "احتيال",
    "prohibited": "سلعة أو محتوى ممنوع",
    "offensive": "محتوى مسيء",
    "spam": "إعلان مكرر / مزعج",
    "other": "سبب آخر",
}


def audit(
    db: AsyncSession,
    admin_id: int | None,
    action: str,
    target_type: str,
    target_id: int | None,
    note: str = "",
) -> AuditLog:
    """Queue an audit entry. The caller owns the commit."""
    entry = AuditLog(
        admin_id=admin_id, action=action, target_type=target_type, target_id=target_id, note=note
    )
    db.add(entry)
    return entry


async def create_report(
    db: AsyncSession,
    reporter: User,
    listing_id: int | None,
    reported_user_id: int | None,
    reason: str,
    details: str,
) -> Report:
    """Create a report, auto-hiding the listing once it collects enough open reports."""
    listing: Listing | None = None
    if listing_id is not None:
        listing = await db.get(Listing, listing_id)
        if listing is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "الإعلان غير موجود")
        if listing.seller_id == reporter.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "لا يمكنك الإبلاغ عن إعلانك")
        if reported_user_id is None:
            reported_user_id = listing.seller_id

    if reported_user_id is not None:
        if reported_user_id == reporter.id:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "لا يمكنك الإبلاغ عن نفسك")
        if await db.get(User, reported_user_id) is None:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "المستخدم غير موجود")

    # One open report per user per target keeps the queue clean.
    dup = await db.scalar(
        select(Report).where(
            Report.reporter_id == reporter.id,
            Report.listing_id == listing_id,
            Report.reported_user_id == reported_user_id,
            Report.status == ReportStatus.OPEN.value,
        )
    )
    if dup is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "لديك بلاغ مفتوح على هذا الهدف مسبقاً")

    report = Report(
        reporter_id=reporter.id,
        listing_id=listing_id,
        reported_user_id=reported_user_id,
        reason=reason,
        details=details.strip(),
    )
    db.add(report)
    await db.flush()

    # Auto-hide: too many distinct open reports on an active listing.
    if listing is not None and listing.status == ListingStatus.ACTIVE.value:
        open_count = await db.scalar(
            select(func.count())
            .select_from(Report)
            .where(Report.listing_id == listing_id, Report.status == ReportStatus.OPEN.value)
        ) or 0
        if open_count >= settings.reports_auto_hide_threshold:
            listing.status = ListingStatus.HIDDEN.value
            audit(
                db,
                None,
                "auto_hide_listing",
                "listing",
                listing.id,
                f"بلغ عدد البلاغات المفتوحة {open_count}",
            )
            notify_user(
                db,
                listing.seller_id,
                NotificationType.MODERATION.value,
                "تم إخفاء إعلانك مؤقتاً",
                "أُخفي الإعلان تلقائياً بانتظار مراجعة الإدارة بسبب تعدد البلاغات.",
                f"/listings/{listing.id}",
            )
            logger.info("listing %s auto-hidden after %s open reports", listing.id, open_count)

    await db.commit()
    await db.refresh(report)

    reason_label = REASON_LABELS.get(reason, reason)
    target = f"إعلان #{listing_id}" if listing_id else f"مستخدم #{reported_user_id}"
    telegram_admin_bg(f"🚩 بلاغ جديد ({reason_label}) على {target} — Souqna")
    return report


async def resolve_report(
    db: AsyncSession,
    admin: User,
    report_id: int,
    action: str,
    note: str = "",
    dismiss: bool = False,
) -> Report:
    """Close a report, optionally applying a moderation action to its target."""
    report = await db.get(Report, report_id)
    if report is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "البلاغ غير موجود")
    if report.status != ReportStatus.OPEN.value:
        raise HTTPException(status.HTTP_409_CONFLICT, "البلاغ مُعالج مسبقاً")

    if dismiss:
        report.status = ReportStatus.DISMISSED.value
        report.action = "none"
    else:
        report.status = ReportStatus.RESOLVED.value
        report.action = action

        if action == "hide_listing" and report.listing_id is not None:
            listing = await db.get(Listing, report.listing_id)
            if listing is not None and listing.status != ListingStatus.HIDDEN.value:
                listing.status = ListingStatus.HIDDEN.value
                notify_user(
                    db,
                    listing.seller_id,
                    NotificationType.MODERATION.value,
                    "تم إخفاء إعلانك",
                    "أخفت الإدارة إعلانك بعد مراجعة البلاغات." + (f" ملاحظة: {note}" if note else ""),
                    f"/listings/{listing.id}",
                )
        elif action == "delete_listing" and report.listing_id is not None:
            listing = await db.get(Listing, report.listing_id)
            if listing is not None:
                notify_user(
                    db,
                    listing.seller_id,
                    NotificationType.MODERATION.value,
                    "تم حذف إعلانك",
                    "حذفت الإدارة إعلانك لمخالفته الشروط." + (f" ملاحظة: {note}" if note else ""),
                )
                await db.delete(listing)
        elif action == "ban_user" and report.reported_user_id is not None:
            target_user = await db.get(User, report.reported_user_id)
            if target_user is not None:
                target_user.is_banned = True

    report.resolved_by = admin.id
    report.resolved_at = datetime.now(timezone.utc).replace(tzinfo=None)
    audit(
        db,
        admin.id,
        "dismiss_report" if dismiss else f"resolve_report:{action}",
        "report",
        report.id,
        note,
    )
    await db.commit()
    await db.refresh(report)
    return report
