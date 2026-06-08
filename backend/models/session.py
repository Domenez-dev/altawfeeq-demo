"""Recording/analysis session model."""
import enum
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Classification(str, enum.Enum):
    healthy = "healthy"
    at_risk = "at_risk"
    sick = "sick"


# Arabic display labels for each classification value.
CLASSIFICATION_LABELS_AR: dict[Classification, str] = {
    Classification.healthy: "معاف",
    Classification.at_risk: "في طريق المرض",
    Classification.sick: "مريض",
}


class Session(Base):
    __tablename__ = "sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False, index=True)
    recorded_at: Mapped[datetime] = mapped_column(DateTime, nullable=False)

    duration_seconds: Mapped[float] = mapped_column(Float, nullable=False)
    f0_hz: Mapped[float] = mapped_column(Float, nullable=False)
    jitter_percent: Mapped[float] = mapped_column(Float, nullable=False)
    shimmer_percent: Mapped[float] = mapped_column(Float, nullable=False)
    intensity_db: Mapped[float] = mapped_column(Float, nullable=False)

    overall_score: Mapped[float] = mapped_column(Float, nullable=False)
    f0_score: Mapped[float] = mapped_column(Float, nullable=False)
    jitter_score: Mapped[float] = mapped_column(Float, nullable=False)
    shimmer_score: Mapped[float] = mapped_column(Float, nullable=False)
    intensity_score: Mapped[float] = mapped_column(Float, nullable=False)
    duration_score: Mapped[float] = mapped_column(Float, nullable=False)

    classification: Mapped[Classification] = mapped_column(Enum(Classification), nullable=False)
    feedback_text: Mapped[str] = mapped_column(String, nullable=False)
    audio_filename: Mapped[str] = mapped_column(String, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )

    user: Mapped["User"] = relationship("User", back_populates="sessions")
