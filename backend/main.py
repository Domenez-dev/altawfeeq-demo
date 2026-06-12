"""FastAPI application entrypoint for the التوفيق (Al-Tawfeeq) backend."""
from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

import models  # noqa: F401 — ensures all models are registered on Base before create_all
from config import API_DESCRIPTION, API_TITLE, API_VERSION
from database import Base, engine
from routers import analysis, auth, reports, schedules, sessions, users, home
from fastapi import Depends
from models.user import User
from schemas.user import UserResponse
from utils.helpers import get_current_user

Base.metadata.create_all(bind=engine)

app = FastAPI(title=API_TITLE, description=API_DESCRIPTION, version=API_VERSION)

# Permissive CORS for an MVP/prototype mobile app talking to this API.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    """Normalize every HTTPException into the { "detail": ..., "code": ... } shape.

    Endpoints that already raise with a structured dict `detail` pass through
    untouched; any other HTTPException (e.g. raised by FastAPI/Starlette
    internals) is wrapped with a generic HTTP_ERROR code.
    """
    if isinstance(exc.detail, dict) and "detail" in exc.detail and "code" in exc.detail:
        payload = exc.detail
    else:
        payload = {"detail": str(exc.detail), "code": "HTTP_ERROR"}

    return JSONResponse(status_code=exc.status_code, content=payload, headers=getattr(exc, "headers", None))


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Normalize FastAPI/Pydantic request validation errors into the same shape."""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={"detail": exc.errors(), "code": "VALIDATION_ERROR"},
    )


app.include_router(auth.router)
app.include_router(users.router)
app.include_router(analysis.router)
app.include_router(sessions.router)
app.include_router(reports.router)
app.include_router(schedules.router)
app.include_router(home.router)


@app.get("/api/profile", response_model=UserResponse, tags=["Profile"], summary="Get current user profile for frontend")
def get_profile(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@app.get("/", tags=["Health"], summary="Health check")
def root() -> dict[str, str]:
    return {"status": "ok", "service": API_TITLE}
