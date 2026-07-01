from sqlalchemy import Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)
    name_ar: Mapped[str] = mapped_column(String(120), nullable=False)
    subtitle_ar: Mapped[str] = mapped_column(String(200), default="", nullable=False)
    # Icon key resolved to a concrete icon on the Flutter side.
    icon: Mapped[str] = mapped_column(String(48), default="widgets", nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
