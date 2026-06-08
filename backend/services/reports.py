"""Aggregation logic for weekly / monthly / all-time session reports."""
from collections.abc import Sequence
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from models.session import Classification, Session
from services.classifier import HEALTHY_THRESHOLD, SICK_THRESHOLD

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: reusing the existing overall_score
# classification thresholds (services/classifier.py) to bucket sessions for
# the report's pie-chart "metric_distribution" (good / average / weak), so the
# two views of "how am I doing" stay consistent for the user.
# Current value: good >= HEALTHY_THRESHOLD (70), weak < SICK_THRESHOLD (40),
# average in between.
# Suggested range: keep in sync with services.classifier thresholds, or
# define independent UX-driven buckets if product research suggests otherwise.
# Impact: Changing these shifts how sessions are bucketed in the report pie
# chart without affecting the underlying classification stored per session.
# ============================================================
DISTRIBUTION_GOOD_THRESHOLD = HEALTHY_THRESHOLD
DISTRIBUTION_WEAK_THRESHOLD = SICK_THRESHOLD

_LABEL_GOOD = "جيد"
_LABEL_AVERAGE = "متوسط"
_LABEL_WEAK = "ضعيف"


@dataclass(frozen=True)
class PeriodWindow:
    start: datetime
    end: datetime


def _now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def weekly_window(now: datetime | None = None) -> tuple[PeriodWindow, PeriodWindow]:
    """Return (current 7-day window, previous 7-day window)."""
    now = now or _now()
    current = PeriodWindow(start=now - timedelta(days=7), end=now)
    previous = PeriodWindow(start=now - timedelta(days=14), end=now - timedelta(days=7))
    return current, previous


def monthly_window(now: datetime | None = None) -> tuple[PeriodWindow, PeriodWindow]:
    """Return (current 30-day window, previous 30-day window)."""
    now = now or _now()
    current = PeriodWindow(start=now - timedelta(days=30), end=now)
    previous = PeriodWindow(start=now - timedelta(days=60), end=now - timedelta(days=30))
    return current, previous


def _classification_breakdown(sessions: Sequence[Session]) -> dict[str, int]:
    breakdown = {"healthy": 0, "at_risk": 0, "sick": 0}
    for session in sessions:
        breakdown[session.classification.value] += 1
    return breakdown


def _metric_distribution(sessions: Sequence[Session]) -> list[dict[str, int | str]]:
    counts = {_LABEL_GOOD: 0, _LABEL_AVERAGE: 0, _LABEL_WEAK: 0}
    for session in sessions:
        if session.overall_score >= DISTRIBUTION_GOOD_THRESHOLD:
            counts[_LABEL_GOOD] += 1
        elif session.overall_score < DISTRIBUTION_WEAK_THRESHOLD:
            counts[_LABEL_WEAK] += 1
        else:
            counts[_LABEL_AVERAGE] += 1
    return [{"label": label, "count": count} for label, count in counts.items()]


def _average_overall_score(sessions: Sequence[Session]) -> float | None:
    if not sessions:
        return None
    return sum(s.overall_score for s in sessions) / len(sessions)


def _average_metric_scores(sessions: Sequence[Session]) -> dict[str, float] | None:
    if not sessions:
        return None
    count = len(sessions)
    return {
        "f0_score": sum(s.f0_score for s in sessions) / count,
        "jitter_score": sum(s.jitter_score for s in sessions) / count,
        "shimmer_score": sum(s.shimmer_score for s in sessions) / count,
        "intensity_score": sum(s.intensity_score for s in sessions) / count,
        "duration_score": sum(s.duration_score for s in sessions) / count,
    }


def build_report(
    *,
    period: str,
    current_sessions: Sequence[Session],
    previous_sessions: Sequence[Session] | None = None,
    window: PeriodWindow | None = None,
) -> dict:
    """Aggregate a list of sessions (and optionally a comparison period) into
    the dict shape expected by schemas.session.ReportResponse.
    """
    average_overall = _average_overall_score(current_sessions)

    trend: float | None = None
    if previous_sessions is not None:
        previous_average = _average_overall_score(previous_sessions)
        if average_overall is not None and previous_average is not None:
            trend = average_overall - previous_average

    return {
        "period": period,
        "start_date": window.start if window else None,
        "end_date": window.end if window else None,
        "total_sessions": len(current_sessions),
        "average_overall_score": average_overall,
        "average_metric_scores": _average_metric_scores(current_sessions),
        "classification_breakdown": _classification_breakdown(current_sessions),
        "trend": trend,
        "metric_distribution": _metric_distribution(current_sessions),
    }
