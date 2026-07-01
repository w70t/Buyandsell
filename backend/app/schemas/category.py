from pydantic import BaseModel, ConfigDict, Field


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    slug: str
    name_ar: str
    subtitle_ar: str
    icon: str
    sort_order: int


class CategoryCreate(BaseModel):
    slug: str = Field(min_length=2, max_length=64)
    name_ar: str = Field(min_length=1, max_length=120)
    subtitle_ar: str = ""
    icon: str = "widgets"
    sort_order: int = 0


class CategoryUpdate(BaseModel):
    name_ar: str | None = None
    subtitle_ar: str | None = None
    icon: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None
