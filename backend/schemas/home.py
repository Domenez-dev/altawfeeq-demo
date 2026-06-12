"""Pydantic schemas for the home dashboard api."""
from pydantic import BaseModel


class HomeIndicator(BaseModel):
    name: str
    percent: float
    status: str


class HomeResponse(BaseModel):
    user_name: str
    today_progress: float
    completed_indicators: int
    total_indicators: int
    indicators: list[HomeIndicator]
