"""Schedule CRUD endpoints — reminder entries only, no delivery mechanism.

# TODO: wire up APScheduler + FCM push notifications here
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.schedule import Schedule
from models.user import User
from schemas.schedule import ScheduleCreateRequest, ScheduleResponse, ScheduleUpdateRequest
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/schedules", tags=["Schedules"])


def _get_owned_schedule(db: DBSession, schedule_id: int, user_id: int) -> Schedule:
    schedule = (
        db.query(Schedule)
        .filter(Schedule.id == schedule_id, Schedule.user_id == user_id)
        .first()
    )
    if schedule is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"detail": "الموعد غير موجود", "code": "SCHEDULE_NOT_FOUND"},
        )
    return schedule


@router.get(
    "",
    response_model=list[ScheduleResponse],
    summary="List the current user's scheduled sessions",
    description="Returns all schedule entries belonging to the current user, soonest first.",
)
def list_schedules(
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> list[Schedule]:
    return (
        db.query(Schedule)
        .filter(Schedule.user_id == current_user.id)
        .order_by(Schedule.scheduled_for.asc())
        .all()
    )


@router.post(
    "",
    response_model=ScheduleResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a scheduled session reminder",
    description="Creates a new schedule entry for the current user. This only stores the entry — no notification is sent.",
)
def create_schedule(
    payload: ScheduleCreateRequest,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> Schedule:
    schedule = Schedule(
        user_id=current_user.id,
        scheduled_for=payload.scheduled_for,
        label=payload.label,
    )
    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


@router.put(
    "/{schedule_id}",
    response_model=ScheduleResponse,
    summary="Update a scheduled session reminder",
    description="Updates one of the current user's schedule entries — e.g. mark it complete or change its date/time.",
    responses={404: {"description": "Schedule not found or does not belong to the current user"}},
)
def update_schedule(
    schedule_id: int,
    payload: ScheduleUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> Schedule:
    schedule = _get_owned_schedule(db, schedule_id, current_user.id)

    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(schedule, field, value)

    db.add(schedule)
    db.commit()
    db.refresh(schedule)
    return schedule


@router.delete(
    "/{schedule_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a scheduled session reminder",
    description="Deletes one of the current user's schedule entries.",
    responses={404: {"description": "Schedule not found or does not belong to the current user"}},
)
def delete_schedule(
    schedule_id: int,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> None:
    schedule = _get_owned_schedule(db, schedule_id, current_user.id)
    db.delete(schedule)
    db.commit()
