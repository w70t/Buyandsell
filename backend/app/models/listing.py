from enum import StrEnum

from sqlalchemy import BigInteger, Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, TimestampMixin


class ListingStatus(StrEnum):
    ACTIVE = "active"
    SOLD = "sold"
    HIDDEN = "hidden"


class Listing(Base, TimestampMixin):
    __tablename__ = "listings"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(140), nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    price: Mapped[int] = mapped_column(BigInteger, nullable=False, default=0)
    currency: Mapped[str] = mapped_column(String(8), default="IQD", nullable=False)
    negotiable: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    condition: Mapped[str] = mapped_column(String(16), default="used", nullable=False)  # new | used

    category_id: Mapped[int] = mapped_column(
        ForeignKey("categories.id", ondelete="RESTRICT"), index=True, nullable=False
    )
    governorate: Mapped[str] = mapped_column(String(64), index=True, nullable=False)
    city: Mapped[str] = mapped_column(String(80), default="", nullable=False)

    seller_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False
    )
    status: Mapped[str] = mapped_column(String(16), default=ListingStatus.ACTIVE.value, index=True, nullable=False)
    views: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    seller = relationship("User", back_populates="listings")
    category = relationship("Category")
    images = relationship(
        "ListingImage",
        back_populates="listing",
        cascade="all, delete-orphan",
        order_by="ListingImage.position",
    )
