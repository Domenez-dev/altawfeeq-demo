"""Pydantic schemas for analysis sessions."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from models.session import Classification


class SessionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    recorded_at: datetime
    duration_seconds: float
    f0_hz: float
    jitter_percent: float
    shimmer_percent: float
    intensity_db: float
    overall_score: float
    f0_score: float
    jitter_score: float
    shimmer_score: float
    intensity_score: float
    duration_score: float
    classification: Classification
    classification_label: str = Field(
        ..., description="Arabic display label for the classification (معاف / في طريق المرض / مريض)"
    )
    feedback_text: str
    audio_filename: str
    created_at: datetime


class SessionListResponse(BaseModel):
    items: list[SessionResponse]
    total: int
    page: int
    page_size: int
    pages: int


class AnalysisResultResponse(SessionResponse):
    """Response returned right after an audio analysis completes.

    Identical to a stored session, kept as a distinct schema so the
    /analyze endpoint can document its own response shape independently
    from the sessions list/detail endpoints.
    """


# ---------------------------------------------------------------------------
# Report schemas (weekly / monthly / all-time aggregations over sessions)
# ---------------------------------------------------------------------------


class MetricScoresAverage(BaseModel):
    f0_score: float
    jitter_score: float
    shimmer_score: float
    intensity_score: float
    duration_score: float


class ClassificationBreakdown(BaseModel):
    healthy: int
    at_risk: int
    sick: int


class MetricDistributionEntry(BaseModel):
    label: str = Field(..., description="Bucket label, e.g. 'جيد' / 'متوسط' / 'ضعيف'")
    count: int


class ReportResponse(BaseModel):
    period: str = Field(..., description="One of 'weekly', 'monthly', 'alltime'")
    start_date: datetime | None = None
    end_date: datetime | None = None
    total_sessions: int
    average_overall_score: float | None = None
    average_metric_scores: MetricScoresAverage | None = None
    classification_breakdown: ClassificationBreakdown
    trend: float | None = Field(
        default=None,
        description=(
            "Difference in average overall_score versus the previous equivalent "
            "period (current - previous). Null when there is no previous period "
            "to compare against (e.g. all-time reports)."
        ),
    )
    metric_distribution: list[MetricDistributionEntry]
