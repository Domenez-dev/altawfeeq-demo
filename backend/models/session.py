"""Recording/analysis session model."""
import enum
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base


class Classification(str, enum.Enum):
    # Stable internal keys (kept healthy/at_risk/sick for DB/back-compat), mapped
    # to the clinical 3-way screening scheme used throughout the app:
    #   healthy → CU  (Cognitively Unimpaired / سليم معرفياً)
    #   at_risk → MCI (Mild Cognitive Impairment / ضعف إدراكي بسيط)
    #   sick    → اشتباه مرضي (suspected impairment, refer to a specialist)
    healthy = "healthy"
    at_risk = "at_risk"
    sick = "sick"


# Arabic display labels for each classification value (CU / MCI / مريض).
CLASSIFICATION_LABELS_AR: dict[Classification, str] = {
    Classification.healthy: "سليم معرفياً (CU)",
    Classification.at_risk: "ضعف إدراكي بسيط (MCI)",
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
    # Added later; nullable so recordings analysed before HNR/F0-SD extraction
    # existed still load cleanly.
    hnr_db: Mapped[float | None] = mapped_column(Float, nullable=True)
    f0_sd_hz: Mapped[float | None] = mapped_column(Float, nullable=True)

    overall_score: Mapped[float] = mapped_column(Float, nullable=False)
    f0_score: Mapped[float] = mapped_column(Float, nullable=False)
    jitter_score: Mapped[float] = mapped_column(Float, nullable=False)
    shimmer_score: Mapped[float] = mapped_column(Float, nullable=False)
    intensity_score: Mapped[float] = mapped_column(Float, nullable=False)
    duration_score: Mapped[float] = mapped_column(Float, nullable=False)
    hnr_score: Mapped[float | None] = mapped_column(Float, nullable=True)
    f0_sd_score: Mapped[float | None] = mapped_column(Float, nullable=True)

    classification: Mapped[Classification] = mapped_column(Enum(Classification), nullable=False)
    feedback_text: Mapped[str] = mapped_column(String, nullable=False)
    audio_filename: Mapped[str] = mapped_column(String, nullable=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=lambda: datetime.now(timezone.utc), nullable=False
    )

    user: Mapped["User"] = relationship("User", back_populates="sessions")
