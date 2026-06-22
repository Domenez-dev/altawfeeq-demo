"""Application configuration and settings."""
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

# Database
DATABASE_URL = f"sqlite:///{BASE_DIR / 'altawfeeq.db'}"

# Uploaded audio storage
UPLOADS_DIR = BASE_DIR / "uploads"
UPLOADS_DIR.mkdir(parents=True, exist_ok=True)

# JWT auth settings
SECRET_KEY = os.environ.get("ALTAWFEEQ_SECRET_KEY", "dev-secret-key-change-in-production-please")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # one week, convenient for an MVP/prototype

# API metadata
API_TITLE = "Taoufik API"
API_DESCRIPTION = (
    "Backend API for Taoufik — a voice-based MCI / Alzheimer's screening tool. "
    "Analyzes sustained vowel ('آآآ') recordings using Praat to extract seven "
    "acoustic biomarkers (F0, F0 SD, jitter, shimmer, HNR, intensity, duration) "
    "and produces a composite vocal-health score plus a 3-way screening "
    "classification (CU / MCI / مريض) with Arabic feedback."
)
# Backend / API version — single source of truth. It is passed to the FastAPI
# app (see main.py) so it shows up in the OpenAPI schema and /docs, and is also
# returned by the GET /version endpoint.
# BUMP RULE: increase this version by 0.0.1 on every new change to the backend
# or API (e.g. 0.1.0 -> 0.1.1).
API_VERSION = "0.2.0"
