import jwt
from fastapi import APIRouter, HTTPException, Request, status
from sqlalchemy import select

from app.core.deps import CurrentUser, DbDep
from app.core.rate_limit import limiter
from app.core.config import settings
from app.core.security import (
    REFRESH,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    needs_rehash,
    verify_password,
)
from app.models import User, UserRole
from app.schemas.auth import (
    AuthResponse,
    LoginRequest,
    RefreshRequest,
    RegisterRequest,
    TokenPair,
)
from app.schemas.user import UserMe
from app.services.notify import telegram_admin_bg

router = APIRouter(prefix="/auth", tags=["auth"])


def _tokens(user: User) -> TokenPair:
    return TokenPair(
        access_token=create_access_token(user.id, user.role),
        refresh_token=create_refresh_token(user.id),
    )


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit(settings.rate_limit_auth)
async def register(request: Request, payload: RegisterRequest, db: DbDep) -> AuthResponse:
    exists = await db.scalar(select(User).where(User.phone == payload.phone))
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, "رقم الهاتف مسجّل مسبقاً")

    user = User(
        name=payload.name,
        phone=payload.phone,
        password_hash=hash_password(payload.password),
        role=UserRole.USER.value,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    telegram_admin_bg(f"👤 مستخدم جديد: {user.name} — Souqna")
    return AuthResponse(user=UserMe.model_validate(user), tokens=_tokens(user))


@router.post("/login", response_model=AuthResponse)
@limiter.limit(settings.rate_limit_auth)
async def login(request: Request, payload: LoginRequest, db: DbDep) -> AuthResponse:
    user = await db.scalar(select(User).where(User.phone == payload.phone))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "رقم الهاتف أو كلمة المرور غير صحيحة")
    if user.is_banned or not user.is_active:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "الحساب موقوف")

    # Transparent upgrade of the password hash parameters over time.
    if needs_rehash(user.password_hash):
        user.password_hash = hash_password(payload.password)
        await db.commit()

    return AuthResponse(user=UserMe.model_validate(user), tokens=_tokens(user))


@router.post("/refresh", response_model=TokenPair)
@limiter.limit(settings.rate_limit_auth)
async def refresh(request: Request, payload: RefreshRequest, db: DbDep) -> TokenPair:
    try:
        data = decode_token(payload.refresh_token, REFRESH)
        user_id = int(data["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "رمز التحديث غير صالح")

    user = await db.get(User, user_id)
    if user is None or user.is_banned or not user.is_active:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "الحساب غير متاح")
    return _tokens(user)


@router.get("/me", response_model=UserMe)
async def me(user: CurrentUser) -> UserMe:
    return UserMe.model_validate(user)
