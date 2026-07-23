"""Jinja2 environment + shared template helpers for the web UI."""
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path

from fastapi import Request, Response
from fastapi.templating import Jinja2Templates
from sqlalchemy import func, select

from app.core.config import settings
from app.db.session import SessionLocal
from app.models import Category, Notification, User
from app.web.deps import ensure_csrf
from app.web.icons import CATEGORY_ICONS, category_icon, icon

TEMPLATES_DIR = Path(__file__).parent / "templates"
STATIC_DIR = Path(__file__).parent / "static"

GOVERNORATES = [
    "بغداد", "البصرة", "نينوى", "أربيل", "النجف", "كربلاء", "كركوك",
    "الأنبار", "ديالى", "ذي قار", "السليمانية", "صلاح الدين", "بابل",
    "واسط", "ميسان", "المثنى", "الديوانية", "دهوك",
]

REPORT_REASONS = [
    ("scam", "احتيال"),
    ("prohibited", "سلعة أو محتوى ممنوع"),
    ("offensive", "محتوى مسيء"),
    ("spam", "إعلان مكرر / مزعج"),
    ("other", "سبب آخر"),
]

def fmt_price(value: int | None) -> str:
    if not value:
        return "مجاني"
    return f"{value:,}".replace(",", "٬") + " د.ع"


def timeago(dt: datetime | None) -> str:
    if dt is None:
        return ""
    now = datetime.now(timezone.utc).replace(tzinfo=None)
    delta = now - dt
    seconds = int(delta.total_seconds())
    if seconds < 60:
        return "الآن"
    minutes = seconds // 60
    if minutes < 60:
        return f"قبل {minutes} دقيقة"
    hours = minutes // 60
    if hours < 24:
        return f"قبل {hours} ساعة"
    days = hours // 24
    if days < 30:
        return f"قبل {days} يوم"
    months = days // 30
    if months < 12:
        return f"قبل {months} شهر"
    return f"قبل {months // 12} سنة"


templates = Jinja2Templates(directory=str(TEMPLATES_DIR))
templates.env.filters["price"] = fmt_price
templates.env.filters["timeago"] = timeago
templates.env.globals["governorates"] = GOVERNORATES
templates.env.globals["report_reasons"] = REPORT_REASONS
templates.env.globals["category_icons"] = CATEGORY_ICONS
templates.env.globals["icon"] = icon
templates.env.globals["category_icon"] = category_icon
templates.env.globals["app_name"] = settings.app_name


async def base_context(request: Request, response: Response, user: User | None) -> dict:
    """Context every page needs: user, csrf token, nav categories, unread badge."""
    csrf_token = ensure_csrf(request, response)
    unread = 0
    async with SessionLocal() as db:
        categories = list(
            await db.scalars(
                select(Category).where(Category.is_active.is_(True)).order_by(Category.sort_order)
            )
        )
        if user is not None:
            unread = await db.scalar(
                select(func.count())
                .select_from(Notification)
                .where(Notification.user_id == user.id, Notification.is_read.is_(False))
            ) or 0
    return {
        "request": request,
        "user": user,
        "csrf_token": csrf_token,
        "nav_categories": categories,
        "unread_count": unread,
    }


def render(name: str, context: dict, response: Response, status_code: int = 200):
    """Render a template, carrying over cookies set on the dependency response."""
    result = templates.TemplateResponse(context["request"], name, context, status_code=status_code)
    # Cookies set by deps (token rotation / csrf) live on `response`; copy them.
    for header, value in response.raw_headers:
        if header == b"set-cookie":
            result.raw_headers.append((header, value))
    return result
