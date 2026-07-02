from datetime import datetime
from enum import StrEnum

from sqlalchemy import ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class ReportReason(StrEnum):
    SCAM = "scam"
    PROHIBITED = "prohibited"
    OFFENSIVE = "offensive"
    SPAM = "spam"
    OTHER = "other"


class ReportStatus(StrEnum):
    OPEN = "open"
    RESOLVED = "resolved"
    DISMISSED = "dismissed"


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[int] = mapped_column(primary_key=True)
    reporter_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    # A report targets a listing, a user, or both. Targets survive deletion so
    # the moderation trail stays intact.
    listing_id: Mapped[int | None] = mapped_column(
        ForeignKey("listings.id", ondelete="SET NULL"), index=True, nullable=True
    )
    reported_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), index=True, nullable=True
    )
    reason: Mapped[str] = mapped_column(String(32), nullable=False)
    details: Mapped[str] = mapped_column(Text, default="", nullable=False)
    status: Mapped[str] = mapped_column(
        String(16), default=ReportStatus.OPEN.value, index=True, nullable=False
    )
    # What the moderator did when closing the report (none | hide_listing | delete_listing | ban_user).
    action: Mapped[str] = mapped_column(String(32), default="", nullable=False)
    resolved_by: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    resolved_at: Mapped[datetime | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        server_default=func.now(), index=True, nullable=False
    )

    reporter = relationship("User", foreign_keys=[reporter_id])
    listing = relationship("Listing", foreign_keys=[listing_id])
    reported_user = relationship("User", foreign_keys=[reported_user_id])
