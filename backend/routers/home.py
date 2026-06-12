"""Home dashboard endpoint — provides daily progress and indicator scores."""
from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy import desc
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.session import Session
from models.user import User
from schemas.home import HomeResponse, HomeIndicator
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/home", tags=["Home"])


@router.get(
    "",
    response_model=HomeResponse,
    summary="Get user's daily progress and vocal indicators",
    description="Calculates progress based on today's session and returns vocal indicator scores.",
)
def get_home_data(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> HomeResponse:
    # Get user's most recent session overall to pull baseline indicators
    latest_session = (
        db.query(Session)
        .filter(Session.user_id == current_user.id)
        .order_by(desc(Session.recorded_at))
        .first()
    )

    # Check if a session was recorded today (in current UTC calendar day)
    has_session_today = False
    if latest_session:
        now_utc = datetime.now(timezone.utc).replace(tzinfo=None)
        has_session_today = latest_session.recorded_at.date() == now_utc.date()

    if latest_session:
        # Map 100-scale subscores to 0.0-1.0 percentages
        indicators = [
            HomeIndicator(
                name="شدة الصوت",
                percent=latest_session.intensity_score / 100.0,
                status="جيد" if latest_session.intensity_score >= 70.0 else "متوسط" if latest_session.intensity_score >= 40.0 else "ضعيف",
            ),
            HomeIndicator(
                name="المدة",
                percent=latest_session.duration_score / 100.0,
                status="جيد" if latest_session.duration_score >= 70.0 else "متوسط" if latest_session.duration_score >= 40.0 else "ضعيف",
            ),
            HomeIndicator(
                name="الطبقة الصوتية",
                percent=latest_session.f0_score / 100.0,
                status="جيد" if latest_session.f0_score >= 70.0 else "متوسط" if latest_session.f0_score >= 40.0 else "ضعيف",
            ),
            HomeIndicator(
                name="الاضطراب (Jitter)",
                percent=latest_session.jitter_score / 100.0,
                status="جيد" if latest_session.jitter_score >= 70.0 else "متوسط" if latest_session.jitter_score >= 40.0 else "ضعيف",
            ),
        ]
        # Count indicators that are not failing ("ضعيف") as completed
        completed_count = sum(1 for ind in indicators if ind.status in ("جيد", "متوسط"))
        today_progress = latest_session.overall_score / 100.0 if has_session_today else 0.0
    else:
        # Default empty state if user has no sessions recorded at all
        indicators = [
            HomeIndicator(name="شدة الصوت", percent=0.0, status="ضعيف"),
            HomeIndicator(name="المدة", percent=0.0, status="ضعيف"),
            HomeIndicator(name="الطبقة الصوتية", percent=0.0, status="ضعيف"),
            HomeIndicator(name="الاضطراب (Jitter)", percent=0.0, status="ضعيف"),
        ]
        completed_count = 0
        today_progress = 0.0

    return HomeResponse(
        user_name=current_user.name,
        today_progress=today_progress,
        completed_indicators=completed_count,
        total_indicators=4,
        indicators=indicators,
    )
