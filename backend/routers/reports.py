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
