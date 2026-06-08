"""Current-user profile endpoints."""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.user import User
from schemas.user import UserResponse, UserUpdateRequest
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/users", tags=["Users"])


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get the current user's profile",
    description="Returns the profile of the authenticated user (identified via the bearer token).",
)
def get_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.put(
    "/me",
    response_model=UserResponse,
    summary="Update the current user's profile",
    description="Updates editable profile fields: name, therapeutic_goal, notifications_enabled. Only provided fields are changed.",
)
def update_me(
    payload: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> User:
    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(current_user, field, value)

    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user
