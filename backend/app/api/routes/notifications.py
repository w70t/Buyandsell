from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import func, select, update

from app.core.deps import CurrentUser, DbDep
from app.models import Notification
from app.schemas.common import Page
from app.schemas.notification import NotificationOut, UnreadCount

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=Page[NotificationOut])
async def list_notifications(
    user: CurrentUser,
    db: DbDep,
    page: int = Query(default=1, ge=1),
    size: int = Query(default=20, ge=1, le=100),
) -> Page[NotificationOut]:
    total = await db.scalar(
        select(func.count()).select_from(Notification).where(Notification.user_id == user.id)
    ) or 0
    rows = await db.scalars(
        select(Notification)
        .where(Notification.user_id == user.id)
        .order_by(Notification.created_at.desc(), Notification.id.desc())
        .offset((page - 1) * size)
        .limit(size)
    )
    return Page(
        items=[NotificationOut.model_validate(n) for n in rows], total=total, page=page, size=size
    )


@router.get("/unread-count", response_model=UnreadCount)
async def unread_count(user: CurrentUser, db: DbDep) -> UnreadCount:
    count = await db.scalar(
        select(func.count())
        .select_from(Notification)
        .where(Notification.user_id == user.id, Notification.is_read.is_(False))
    ) or 0
    return UnreadCount(unread=count)


@router.post("/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_read(user: CurrentUser, db: DbDep) -> None:
    await db.execute(
        update(Notification)
        .where(Notification.user_id == user.id, Notification.is_read.is_(False))
        .values(is_read=True)
    )
    await db.commit()


@router.post("/{notification_id}/read", status_code=status.HTTP_204_NO_CONTENT)
async def mark_read(notification_id: int, user: CurrentUser, db: DbDep) -> None:
    notification = await db.get(Notification, notification_id)
    if notification is None or notification.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "الإشعار غير موجود")
    notification.is_read = True
    await db.commit()
