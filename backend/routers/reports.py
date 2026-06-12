"""Aggregated report endpoints — weekly, monthly, all-time."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.session import Session
from models.user import User
from schemas.session import ReportResponse
from services import reports as reports_service
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/reports", tags=["Reports"])


def _sessions_in(db: DBSession, user_id: int, window: reports_service.PeriodWindow) -> list[Session]:
    return (
        db.query(Session)
        .filter(
            Session.user_id == user_id,
            Session.recorded_at >= window.start,
            Session.recorded_at < window.end,
        )
        .all()
    )


@router.get(
    "/weekly",
    response_model=ReportResponse,
    summary="Weekly report (last 7 days)",
    description="Aggregated stats for the last 7 days, including a trend comparison against the previous 7 days.",
)
def weekly_report(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> ReportResponse:
    current_window, previous_window = reports_service.weekly_window()
    current_sessions = _sessions_in(db, current_user.id, current_window)
    previous_sessions = _sessions_in(db, current_user.id, previous_window)

    return ReportResponse(
        **reports_service.build_report(
            period="weekly",
            current_sessions=current_sessions,
            previous_sessions=previous_sessions,
            window=current_window,
        )
    )


@router.get(
    "/monthly",
    response_model=ReportResponse,
    summary="Monthly report (last 30 days)",
    description="Aggregated stats for the last 30 days, including a trend comparison against the previous 30 days.",
)
def monthly_report(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> ReportResponse:
    current_window, previous_window = reports_service.monthly_window()
    current_sessions = _sessions_in(db, current_user.id, current_window)
    previous_sessions = _sessions_in(db, current_user.id, previous_window)

    return ReportResponse(
        **reports_service.build_report(
            period="monthly",
            current_sessions=current_sessions,
            previous_sessions=previous_sessions,
            window=current_window,
        )
    )


@router.get(
    "/alltime",
    response_model=ReportResponse,
    summary="All-time report",
    description="Aggregated stats across every session the user has ever recorded. No trend comparison (no 'previous' period).",
)
def alltime_report(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> ReportResponse:
    all_sessions = db.query(Session).filter(Session.user_id == current_user.id).all()

    return ReportResponse(
        **reports_service.build_report(
            period="alltime",
            current_sessions=all_sessions,
            previous_sessions=None,
            window=None,
        )
    )


# ---------------------------------------------------------------------------
# Frontend-specific reports endpoint
# ---------------------------------------------------------------------------
from pydantic import BaseModel


class WeeklyReportResponse(BaseModel):
    average_percent: float
    compared_to_last_week: float
    chart_data: list[float]
    good_count: int
    average_count: int
    weak_count: int
    sessions_count: int


@router.get(
    "",
    response_model=WeeklyReportResponse,
    summary="Get aggregated user report (weekly / monthly / all-time) for the frontend",
)
def get_reports_summary(
    period: str = "weekly",
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> WeeklyReportResponse:
    # Determine windows
    if period == "weekly":
        current_window, previous_window = reports_service.weekly_window()
        current_sessions = _sessions_in(db, current_user.id, current_window)
        previous_sessions = _sessions_in(db, current_user.id, previous_window)
    elif period == "monthly":
        current_window, previous_window = reports_service.monthly_window()
        current_sessions = _sessions_in(db, current_user.id, current_window)
        previous_sessions = _sessions_in(db, current_user.id, previous_window)
    else:  # all-time / "all"
        current_sessions = db.query(Session).filter(Session.user_id == current_user.id).all()
        previous_sessions = None

    # Sort current sessions chronologically for chart
    current_sessions = sorted(current_sessions, key=lambda s: s.recorded_at)

    total_sessions = len(current_sessions)
    if total_sessions > 0:
        average_overall = sum(s.overall_score for s in current_sessions) / total_sessions
        average_percent = average_overall / 100.0
    else:
        average_overall = 0.0
        average_percent = 0.0

    compared_to_last_week = 0.0
    if previous_sessions:
        prev_total = len(previous_sessions)
        if prev_total > 0:
            prev_avg = sum(s.overall_score for s in previous_sessions) / prev_total
            compared_to_last_week = (average_overall - prev_avg) / 100.0

    chart_data = [s.overall_score for s in current_sessions]

    # Bucketing
    good_count = 0
    average_count = 0
    weak_count = 0
    for s in current_sessions:
        if s.overall_score >= 70.0:
            good_count += 1
        elif s.overall_score >= 40.0:
            average_count += 1
        else:
            weak_count += 1

    return WeeklyReportResponse(
        average_percent=average_percent,
        compared_to_last_week=compared_to_last_week,
        chart_data=chart_data,
        good_count=good_count,
        average_count=average_count,
        weak_count=weak_count,
        sessions_count=total_sessions,
    )
