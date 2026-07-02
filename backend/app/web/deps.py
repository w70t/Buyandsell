"""Cookie-based auth + CSRF for the server-rendered web app.

The web layer reuses the exact same JWTs as the mobile API, carried in
HTTP-only cookies instead of an Authorization header. When the access token
expires the dependency silently rotates the pair from the refresh cookie, so
web sessions behave like the app's persistent login.
"""
from __future__ import annotations

import secrets
from typing import Annotated

import jwt
from fastapi import Depends, Form, HTTPException, Request, Response, status

from app.core.config import settings
from app.core.security import (
    ACCESS,
    REFRESH,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from app.db.session import SessionLocal
from app.models import User, UserRole

COOKIE_ACCESS = "sq_access"
COOKIE_REFRESH = "sq_refresh"
COOKIE_CSRF = "sq_csrf"


class LoginRequired(Exception):
    """Raised by web dependencies; handled app-wide with a redirect to /login."""

    def __init__(self, next_path: str = "/") -> None:
        self.next_path = next_path


def set_auth_cookies(response: Response, user: User) -> None:
    common = {
        "httponly": True,
        "samesite": "lax",
        "secure": settings.cookie_secure,
        "path": "/",
    }
    response.set_cookie(
        COOKIE_ACCESS,
        create_access_token(user.id, user.role),
        max_age=settings.access_token_expire_minutes * 60,
        **common,
    )
    response.set_cookie(
        COOKIE_REFRESH,
        create_refresh_token(user.id),
        max_age=settings.refresh_token_expire_days * 24 * 3600,
        **common,
    )


def clear_auth_cookies(response: Response) -> None:
    response.delete_cookie(COOKIE_ACCESS, path="/")
    response.delete_cookie(COOKIE_REFRESH, path="/")


async def _load(db, token: str, expected: str) -> User | None:
    try:
        payload = decode_token(token, expected)
        user_id = int(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        return None
    user = await db.get(User, user_id)
    if user is None or not user.is_active or user.is_banned:
        return None
    return user


async def get_web_user(request: Request, response: Response) -> User | None:
    """Resolve the logged-in user from cookies, rotating expired access tokens."""
    access = request.cookies.get(COOKIE_ACCESS)
    refresh = request.cookies.get(COOKIE_REFRESH)
    async with SessionLocal() as db:
        if access:
            user = await _load(db, access, ACCESS)
            if user is not None:
                return user
        if refresh:
            user = await _load(db, refresh, REFRESH)
            if user is not None:
                set_auth_cookies(response, user)
                return user
    return None


async def require_web_user(request: Request, response: Response) -> User:
    user = await get_web_user(request, response)
    if user is None:
        raise LoginRequired(next_path=request.url.path)
    return user


async def require_web_admin(request: Request, response: Response) -> User:
    user = await require_web_user(request, response)
    if user.role != UserRole.ADMIN.value:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "صلاحيات المدير مطلوبة")
    return user


WebUser = Annotated[User | None, Depends(get_web_user)]
AuthedWebUser = Annotated[User, Depends(require_web_user)]
AdminWebUser = Annotated[User, Depends(require_web_admin)]


# ---- CSRF (double-submit cookie) ----
def ensure_csrf(request: Request, response: Response) -> str:
    token = request.cookies.get(COOKIE_CSRF)
    if not token:
        token = secrets.token_urlsafe(32)
        response.set_cookie(
            COOKIE_CSRF,
            token,
            samesite="lax",
            secure=settings.cookie_secure,
            path="/",
        )
    return token


async def verify_csrf(request: Request, csrf_token: Annotated[str, Form()] = "") -> None:
    cookie = request.cookies.get(COOKIE_CSRF, "")
    if not cookie or not secrets.compare_digest(cookie, csrf_token):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "انتهت صلاحية النموذج، أعد المحاولة")


CsrfCheck = Depends(verify_csrf)
