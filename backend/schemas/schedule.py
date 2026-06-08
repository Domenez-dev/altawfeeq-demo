"""Pydantic schemas for session schedules/reminders."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ScheduleCreateRequest(BaseModel):
    scheduled_for: datetime = Field(..., examples=["2026-06-15T09:00:00"])
    label: str | None = Field(default=None, examples=["جلسة أسبوعية"])


class ScheduleUpdateRequest(BaseModel):
    scheduled_for: datetime | None = None
    label: str | None = None
    is_completed: bool | None = None


class ScheduleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    scheduled_for: datetime
    label: str | None = None
    is_completed: bool
    created_at: datetime
