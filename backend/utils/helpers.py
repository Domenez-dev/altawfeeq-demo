"""Auth helpers: password hashing, JWT issuing/verification, current-user dependency."""
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session as DBSession

from config import ACCESS_TOKEN_EXPIRE_MINUTES, ALGORITHM, SECRET_KEY
from database import get_db
from models.user import User

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
# auto_error=False → a missing/invalid Authorization header does NOT raise; this
# is an open single-user prototype, so we fall back to the only user instead.
_bearer_scheme = HTTPBearer(
    auto_error=False,
    description="Optional in this prototype — falls back to the single seed user.",
)


def hash_password(plain_password: str) -> str:
    return _pwd_context.hash(plain_password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return _pwd_context.verify(plain_password, hashed_password)


def create_access_token(*, subject: str) -> str:
    """Create a signed JWT whose 'sub' claim is the user's email."""
    expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    payload = {"sub": subject, "exp": expire}
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


_NO_USER_ERROR = HTTPException(
    status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
    detail={"detail": "لا يوجد مستخدم مُهيّأ، شغّل seed.py", "code": "NO_USER"},
)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    db: DBSession = Depends(get_db),
) -> User:
    """Resolve the current user.

    Open single-user prototype: if a valid bearer token is supplied we honour it,
    but a missing or invalid token is fine too — we simply fall back to the only
    (first) user in the database. This means the API never returns 401, so the
    app "just opens". The single failure mode is an unseeded database (503).
    """
    if credentials is not None:
        try:
            payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
            email = payload.get("sub")
            if email:
                user = db.query(User).filter(User.email == email).first()
                if user is not None:
                    return user
        except JWTError:
            pass  # ignore a bad token and fall back to the prototype user

    user = db.query(User).order_by(User.id).first()
    if user is None:
        raise _NO_USER_ERROR
    return user
