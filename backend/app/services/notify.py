"""Notifications: in-app records + optional Telegram messages to the admin.

In-app notifications are rows the user sees in the app/web bell. Telegram is a
fire-and-forget side channel for the operator (new users, new listings, new
reports); it is disabled unless TELEGRAM_BOT_TOKEN and TELEGRAM_ADMIN_CHAT_ID
are set, so the platform never depends on it.
"""
from __future__ import annotations

import asyncio

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.logging import logger
from app.models import Notification


def notify_user(
    db: AsyncSession,
    user_id: int,
    type: str,
    title: str,
    body: str = "",
    link: str = "",
) -> Notification:
    """Queue an in-app notification. The caller owns the commit."""
    notification = Notification(user_id=user_id, type=type, title=title, body=body, link=link)
    db.add(notification)
    return notification


def telegram_enabled() -> bool:
    return bool(settings.telegram_bot_token and settings.telegram_admin_chat_id)


async def send_telegram_admin(text: str) -> bool:
    """Send a message to the admin chat. Returns False (and logs) on any failure."""
    if not telegram_enabled():
        return False
    url = f"https://api.telegram.org/bot{settings.telegram_bot_token}/sendMessage"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                url,
                json={"chat_id": settings.telegram_admin_chat_id, "text": text},
            )
        if resp.status_code != 200:
            logger.warning("telegram sendMessage failed: %s %s", resp.status_code, resp.text[:200])
            return False
        return True
    except httpx.HTTPError as exc:
        logger.warning("telegram sendMessage error: %s", exc)
        return False


def telegram_admin_bg(text: str) -> None:
    """Fire-and-forget Telegram notification — never blocks or fails a request."""
    if not telegram_enabled():
        return
    try:
        asyncio.create_task(send_telegram_admin(text))
    except RuntimeError:  # no running loop (e.g. sync scripts) — skip silently
        logger.debug("telegram notification skipped: no running event loop")
