from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator

REASONS = ("scam", "prohibited", "offensive", "spam", "other")


class ReportCreate(BaseModel):
    listing_id: int | None = None
    reported_user_id: int | None = None
    reason: str = Field(pattern="^(scam|prohibited|offensive|spam|other)$")
    details: str = Field(default="", max_length=2000)

    @model_validator(mode="after")
    def _has_target(self) -> "ReportCreate":
        if self.listing_id is None and self.reported_user_id is None:
            raise ValueError("يجب تحديد إعلان أو مستخدم للإبلاغ عنه")
        return self


class ReportOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    reporter_id: int
    listing_id: int | None
    reported_user_id: int | None
    reason: str
    details: str
    status: str
    action: str
    created_at: datetime


class ReportResolve(BaseModel):
    action: str = Field(default="none", pattern="^(none|hide_listing|delete_listing|ban_user)$")
    note: str = Field(default="", max_length=400)
