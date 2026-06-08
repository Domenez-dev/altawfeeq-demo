"""Pydantic schemas for users and authentication."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from models.user import Gender


class LoginRequest(BaseModel):
    email: EmailStr = Field(..., examples=["fatima@altawfeeq.dz"])
    password: str = Field(..., examples=["password123"])


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: EmailStr
    gender: Gender
    birth_year: int
    therapeutic_goal: str | None = None
    notifications_enabled: bool
    created_at: datetime


class UserUpdateRequest(BaseModel):
    """Fields a user is allowed to update on their own profile."""

    name: str | None = Field(default=None, examples=["فاطمة بلقاسم"])
    therapeutic_goal: str | None = Field(default=None, examples=["متابعة دورية"])
    notifications_enabled: bool | None = None
