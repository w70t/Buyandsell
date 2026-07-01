from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.schemas.category import CategoryOut
from app.schemas.user import UserPublic


class ListingImageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    url: str
    position: int


class ListingCreate(BaseModel):
    title: str = Field(min_length=3, max_length=140)
    description: str = Field(min_length=5, max_length=5000)
    price: int = Field(ge=0)
    negotiable: bool = False
    condition: str = Field(default="used", pattern="^(new|used)$")
    category_id: int
    governorate: str = Field(min_length=2, max_length=64)
    city: str = ""


class ListingUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=3, max_length=140)
    description: str | None = Field(default=None, min_length=5, max_length=5000)
    price: int | None = Field(default=None, ge=0)
    negotiable: bool | None = None
    condition: str | None = Field(default=None, pattern="^(new|used)$")
    category_id: int | None = None
    governorate: str | None = None
    city: str | None = None
    status: str | None = Field(default=None, pattern="^(active|sold|hidden)$")


class ListingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str
    price: int
    currency: str
    negotiable: bool
    condition: str
    governorate: str
    city: str
    status: str
    views: int
    created_at: datetime
    category: CategoryOut
    seller: UserPublic
    images: list[ListingImageOut]
