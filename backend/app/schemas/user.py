import re

from pydantic import BaseModel, ConfigDict, field_validator

# Iraqi mobile numbers: 07XXXXXXXXX (11 digits) — also accept +9647XXXXXXXXX.
_PHONE_RE = re.compile(r"^(?:\+964|0)7\d{9}$")


def normalize_phone(value: str) -> str:
    value = value.strip().replace(" ", "").replace("-", "")
    if not _PHONE_RE.match(value):
        raise ValueError("رقم هاتف عراقي غير صالح (مثال: 07701234567)")
    # Store in local 0-prefixed form.
    if value.startswith("+964"):
        value = "0" + value[4:]
    return value


class UserBase(BaseModel):
    name: str
    phone: str


class UserPublic(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    phone: str


class UserMe(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    phone: str
    role: str
    is_active: bool


class UserUpdate(BaseModel):
    name: str | None = None

    @field_validator("name")
    @classmethod
    def _name(cls, v: str | None) -> str | None:
        if v is not None and len(v.strip()) < 2:
            raise ValueError("الاسم قصير جداً")
        return v.strip() if v else v
