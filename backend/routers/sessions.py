"""Session history endpoints — list, latest, and detail."""
import math

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.session import CLASSIFICATION_LABELS_AR, Session
from models.user import User
from schemas.session import SessionListResponse, SessionResponse
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/sessions", tags=["Sessions"])

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: the product spec's request for a simple,
# fixed page size for session history; not performance-tuned.
# Current value: 20 sessions per page
# Suggested range: [10 - 50]
# Impact: Larger pages mean fewer round trips but heavier responses; smaller
# pages are lighter but require more pagination requests for long histories.
# ============================================================
PAGE_SIZE = 20


def _to_response(session: Session) -> SessionResponse:
    return SessionResponse(
        **{c.name: getattr(session, c.name) for c in Session.__table__.columns},
        classification_label=CLASSIFICATION_LABELS_AR[session.classification],
    )


@router.get(
    "",
    response_model=SessionListResponse,
    summary="List the current user's sessions (paginated)",
    description=f"Returns sessions ordered from most recent to oldest, {PAGE_SIZE} per page.",
)
def list_sessions(
    page: int = Query(default=1, ge=1, description="1-indexed page number"),
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> SessionListResponse:
    base_query = db.query(Session).filter(Session.user_id == current_user.id)
    total = base_query.count()

    items = (
        base_query.order_by(desc(Session.recorded_at))
        .offset((page - 1) * PAGE_SIZE)
        .limit(PAGE_SIZE)
        .all()
    )

    pages = max(1, math.ceil(total / PAGE_SIZE))

    return SessionListResponse(
        items=[_to_response(s) for s in items],
        total=total,
        page=page,
        page_size=PAGE_SIZE,
        pages=pages,
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
