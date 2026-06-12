"""Session history endpoints — list, latest, and detail."""
from datetime import datetime, timezone
import math
import random

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.session import CLASSIFICATION_LABELS_AR, Session
from models.user import User
from schemas.home import HomeIndicator
from schemas.session import (
    CreateSessionRequest,
    FrontendSessionResponse,
    SessionListResponse,
    SessionResponse,
    SessionResultResponse,
)
from services import classifier, feedback
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/sessions", tags=["Sessions"])

PAGE_SIZE = 20

MONTHS_AR = {
    1: "جانفي", 2: "فيفري", 3: "مارس", 4: "أفريل", 5: "ماي", 6: "جوان",
    7: "جويلية", 8: "أوت", 9: "سبتمبر", 10: "أكتوبر", 11: "نوفمبر", 12: "ديسمبر"
}


def _to_frontend_session(s: Session) -> FrontendSessionResponse:
    month_name = MONTHS_AR.get(s.recorded_at.month, "")
    date_str = f"{s.recorded_at.year} - {s.recorded_at.day:02d} {month_name}"
    time_str = f"{s.recorded_at.hour:02d}:{s.recorded_at.minute:02d}"

    indicators = [
        HomeIndicator(
            name="شدة الصوت",
            percent=s.intensity_score / 100.0,
            status="جيد" if s.intensity_score >= 70.0 else "متوسط" if s.intensity_score >= 40.0 else "ضعيف",
        ),
        HomeIndicator(
            name="المدة",
            percent=s.duration_score / 100.0,
            status="جيد" if s.duration_score >= 70.0 else "متوسط" if s.duration_score >= 40.0 else "ضعيف",
        ),
        HomeIndicator(
            name="الطبقة الصوتية",
            percent=s.f0_score / 100.0,
            status="جيد" if s.f0_score >= 70.0 else "متوسط" if s.f0_score >= 40.0 else "ضعيف",
        ),
        HomeIndicator(
            name="الاضطراب (Jitter)",
            percent=s.jitter_score / 100.0,
            status="جيد" if s.jitter_score >= 70.0 else "متوسط" if s.jitter_score >= 40.0 else "ضعيف",
        ),
    ]

    return FrontendSessionResponse(
        id=s.id,
        title=f"جلسة {s.id:02d}",
        date=date_str,
        time=time_str,
        overall_percent=s.overall_score / 100.0,
        indicators=indicators,
    )


def _to_response(session: Session) -> SessionResponse:
    return SessionResponse(
        **{c.name: getattr(session, c.name) for c in Session.__table__.columns},
        classification_label=CLASSIFICATION_LABELS_AR[session.classification],
    )


@router.get(
    "",
    response_model=list[FrontendSessionResponse],
    summary="List the current user's sessions formatted for frontend",
    description="Returns a simple list of sessions belonging to the current user, ordered from most recent to oldest.",
)
def list_sessions(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> list[FrontendSessionResponse]:
    items = (
        db.query(Session)
        .filter(Session.user_id == current_user.id)
        .order_by(desc(Session.recorded_at))
        .all()
    )
    return [_to_frontend_session(s) for s in items]


def _make_features(quality: float) -> dict[str, float]:
    quality = max(0.0, min(1.0, quality))

    f0 = classifier.F0_BASELINE_ALZHEIMER_HZ + (
        classifier.F0_BASELINE_NORMAL_HZ - classifier.F0_BASELINE_ALZHEIMER_HZ
    ) * quality
    jitter = classifier.JITTER_BASELINE_ALZHEIMER_PERCENT + (
        classifier.JITTER_BASELINE_NORMAL_PERCENT - classifier.JITTER_BASELINE_ALZHEIMER_PERCENT
    ) * quality
    shimmer = classifier.SHIMMER_BASELINE_ALZHEIMER_PERCENT + (
        classifier.SHIMMER_BASELINE_NORMAL_PERCENT - classifier.SHIMMER_BASELINE_ALZHEIMER_PERCENT
    ) * quality

    f0 += random.uniform(-6.0, 6.0)
    jitter = max(0.1, jitter + random.uniform(-0.12, 0.12))
    shimmer = max(0.1, shimmer + random.uniform(-0.25, 0.25))

    if quality > 0.5:
        intensity = random.uniform(64.0, 76.0)
        duration = random.uniform(4.0, 7.5)
    else:
        intensity = random.uniform(54.0, 68.0)
        duration = random.uniform(1.8, 4.2)

    return {
        "f0_hz": f0,
        "jitter_percent": jitter,
        "shimmer_percent": shimmer,
        "intensity_db": intensity,
        "duration_seconds": duration,
    }


@router.post(
    "",
    response_model=SessionResultResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new vocal session from the frontend",
)
def create_session(
    payload: CreateSessionRequest,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> SessionResultResponse:
    quality = random.uniform(0.5, 0.95)
    features = _make_features(quality)

    duration = float(payload.duration_seconds) if payload.duration_seconds > 0 else features["duration_seconds"]

    scores = classifier.score_features(
        f0_hz=features["f0_hz"],
        jitter_percent=features["jitter_percent"],
        shimmer_percent=features["shimmer_percent"],
        intensity_db=features["intensity_db"],
        duration_seconds=duration,
    )

    classification = classifier.classify(scores.overall_score)
    feedback_text = feedback.build_feedback_text(scores, classification)
    recorded_at = datetime.now(timezone.utc).replace(tzinfo=None)

    session = Session(
        user_id=current_user.id,
        recorded_at=recorded_at,
        duration_seconds=duration,
        f0_hz=features["f0_hz"],
        jitter_percent=features["jitter_percent"],
        shimmer_percent=features["shimmer_percent"],
        intensity_db=features["intensity_db"],
        overall_score=scores.overall_score,
        f0_score=scores.f0_score,
        jitter_score=scores.jitter_score,
        shimmer_score=scores.shimmer_score,
        intensity_score=scores.intensity_score,
        duration_score=scores.duration_score,
        classification=classification,
        feedback_text=feedback_text,
        audio_filename=f"user{current_user.id}-session-{int(recorded_at.timestamp())}.wav",
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    month_name = MONTHS_AR.get(recorded_at.month, "")
    date_str = f"{recorded_at.year} - {month_name} {recorded_at.day:02d}"

    indicators = [
        HomeIndicator(
            name="شدة الصوت",
            percent=scores.intensity_score / 100.0,
            status="جيد" if scores.intensity_score >= 70.0 else "متوسط" if scores.intensity_score >= 40.0 else "ضعيف",
        ),
        HomeIndicator(
            name="المدة",
            percent=scores.duration_score / 100.0,
            status="جيد" if scores.duration_score >= 70.0 else "متوسط" if scores.duration_score >= 40.0 else "ضعيف",
        ),
        HomeIndicator(
            name="الطبقة الصوتية",
            percent=scores.f0_score / 100.0,
            status="جيد" if scores.f0_score >= 70.0 else "متوسط" if scores.f0_score >= 40.0 else "ضعيف",
        ),
        HomeIndicator(
            name="الاضطراب (Jitter)",
            percent=scores.jitter_score / 100.0,
            status="جيد" if scores.jitter_score >= 70.0 else "متوسط" if scores.jitter_score >= 40.0 else "ضعيف",
        ),
    ]

    return SessionResultResponse(
        session_id=session.id,
        date=date_str,
        overall_percent=session.overall_score / 100.0,
        indicators=indicators,
    )


@router.get(
    "/latest",
    response_model=SessionResponse,
    summary="Get the current user's most recent session",
    description="Returns the single most recently recorded session, or 404 if the user has none yet.",
    responses={404: {"description": "No sessions found for this user"}},
)
def get_latest_session(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> SessionResponse:
    session = (
        db.query(Session)
        .filter(Session.user_id == current_user.id)
        .order_by(desc(Session.recorded_at))
        .first()
    )

    if session is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"detail": "لا توجد جلسات بعد", "code": "SESSION_NOT_FOUND"},
        )

    return _to_response(session)


@router.get(
    "/{session_id}",
    response_model=SessionResponse,
    summary="Get a single session's detail",
    description="Returns full detail for one session belonging to the current user.",
    responses={404: {"description": "Session not found or does not belong to the current user"}},
)
def get_session(
    session_id: int,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> SessionResponse:
    session = (
        db.query(Session)
        .filter(Session.id == session_id, Session.user_id == current_user.id)
        .first()
    )

    if session is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"detail": "الجلسة غير موجودة", "code": "SESSION_NOT_FOUND"},
        )

    return _to_response(session)

