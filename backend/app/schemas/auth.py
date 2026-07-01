from pydantic import BaseModel, Field, field_validator

from app.schemas.user import UserMe, normalize_phone


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    phone: str
    password: str = Field(min_length=6, max_length=128)

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str) -> str:
        return normalize_phone(v)

    @field_validator("name")
    @classmethod
    def _name(cls, v: str) -> str:
        return v.strip()


class LoginRequest(BaseModel):
    phone: str
    password: str

    @field_validator("phone")
    @classmethod
    def _phone(cls, v: str) -> str:
        return normalize_phone(v)


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AuthResponse(BaseModel):
    user: UserMe
    tokens: TokenPair
