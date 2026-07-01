from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import ACCESS, decode_token
from app.db.session import get_db
from app.models import User, UserRole

_bearer = HTTPBearer(auto_error=False)

DbDep = Annotated[AsyncSession, Depends(get_db)]
_CredsDep = Annotated[HTTPAuthorizationCredentials | None, Depends(_bearer)]


async def _load_user(db: AsyncSession, token: str) -> User:
    try:
        payload = decode_token(token, ACCESS)
        user_id = int(payload["sub"])
    except (jwt.PyJWTError, KeyError, ValueError):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "رمز الدخول غير صالح")

    user = await db.get(User, user_id)
    if user is None or not user.is_active or user.is_banned:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "الحساب غير متاح")
    return user


async def get_current_user(db: DbDep, creds: _CredsDep) -> User:
    if creds is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "مطلوب تسجيل الدخول")
    return await _load_user(db, creds.credentials)


async def get_current_user_optional(db: DbDep, creds: _CredsDep) -> User | None:
    if creds is None:
        return None
    try:
        return await _load_user(db, creds.credentials)
    except HTTPException:
        return None


async def require_admin(user: Annotated[User, Depends(get_current_user)]) -> User:
    if user.role != UserRole.ADMIN.value:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "صلاحيات المدير مطلوبة")
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
OptionalUser = Annotated[User | None, Depends(get_current_user_optional)]
AdminUser = Annotated[User, Depends(require_admin)]
