"""Authentication endpoints — login only (no self-registration in this MVP)."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.user import User
from schemas.user import LoginRequest, TokenResponse
from utils.helpers import create_access_token, verify_password

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post(
    "/login",
    response_model=TokenResponse,
    summary="Log in with email and password",
    description="Validates the user's credentials and returns a JWT bearer token to use for all other endpoints.",
    responses={
        401: {
            "description": "Invalid email or password",
            "content": {"application/json": {"example": {"detail": "بيانات الدخول غير صحيحة", "code": "INVALID_CREDENTIALS"}}},
        }
    },
)
def login(payload: LoginRequest, db: DBSession = Depends(get_db)) -> TokenResponse:
    user = db.query(User).filter(User.email == payload.email).first()

    if user is None or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail={"detail": "بيانات الدخول غير صحيحة", "code": "INVALID_CREDENTIALS"},
        )

    token = create_access_token(subject=user.email)
    return TokenResponse(access_token=token)
