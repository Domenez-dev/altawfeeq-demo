"""Seeds altawfeeq.db with premade test users and realistic fake session history.

Run with: python seed.py

Resets the database (drops and recreates all tables) before seeding, so it is
safe to run repeatedly during development.
"""
import random
from datetime import datetime, timedelta, timezone

import models  # noqa: F401 — registers all models on Base before create_all
from database import Base, SessionLocal, engine
from models.session import Session
from models.user import Gender, User
from services import classifier, feedback
from utils.helpers import hash_password

SEED_PASSWORD = "password123"

_rng = random.Random(42)


def _now() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _make_features(quality: float) -> dict[str, float]:
    """Generate plausible raw acoustic features for a given quality level.

    quality: 0.0 (far into pathological range) .. 1.0 (perfectly normal).
    Interpolates between the classifier's normal/alzheimer baselines (with a
    little noise) so the generated sessions exercise the real scoring and
    classification pipeline realistically.
    """
    quality = max(0.0, min(1.0, quality))

    f0 = classifier.F0_BASELINE_ALZHEIMER_HZ + (
        classifier.F0_BASELINE_NORMAL_HZ - classifier.F0_BASELINE_ALZHEIMER_HZ
    ) * quality
    jitter = classifier.JITTER_BASELINE_ALZHEIMER_PERCENT + (
        classifier.JITTER_BASELINE_NORMAL_PERCENT - classifier.JITTER_BASELINE_ALZHEIMER_PERCENT
    ) * quality
    shimmer = classifier.SHIMMER_BASELINE_ALZHEIMER_PERCENT + (
        classifier.SHIMMER_BASELINE_NORMAL_PERCENT - classifier.SHIMMER_BASELINE_ALZHEIMER_PERCENT
    ) * quality

    f0 += _rng.uniform(-6.0, 6.0)
    jitter = max(0.1, jitter + _rng.uniform(-0.12, 0.12))
    shimmer = max(0.1, shimmer + _rng.uniform(-0.25, 0.25))

    if quality > 0.5:
        intensity = _rng.uniform(64.0, 76.0)
        duration = _rng.uniform(4.0, 7.5)
    else:
        intensity = _rng.uniform(54.0, 68.0)
        duration = _rng.uniform(1.8, 4.2)

    return {
        "f0_hz": f0,
        "jitter_percent": jitter,
        "shimmer_percent": shimmer,
        "intensity_db": intensity,
        "duration_seconds": duration,
    }


def _build_session(user: User, recorded_at: datetime, quality: float, index: int) -> Session:
    raw = _make_features(quality)
    scores = classifier.score_features(**raw)
    classification = classifier.classify(scores.overall_score)
    feedback_text = feedback.build_feedback_text(scores, classification)

    return Session(
        user_id=user.id,
        recorded_at=recorded_at,
        duration_seconds=raw["duration_seconds"],
        f0_hz=raw["f0_hz"],
        jitter_percent=raw["jitter_percent"],
        shimmer_percent=raw["shimmer_percent"],
        intensity_db=raw["intensity_db"],
        overall_score=scores.overall_score,
        f0_score=scores.f0_score,
        jitter_score=scores.jitter_score,
        shimmer_score=scores.shimmer_score,
        intensity_score=scores.intensity_score,
        duration_score=scores.duration_score,
        classification=classification,
        feedback_text=feedback_text,
        audio_filename=f"seed-user{user.id}-session{index}.wav",
        created_at=recorded_at,
    )


def _seed_user_sessions(user: User, qualities: list[float], days_ago: list[int]) -> list[Session]:
    sessions = []
    now = _now()
    for index, (quality, offset) in enumerate(zip(qualities, days_ago), start=1):
        recorded_at = now - timedelta(days=offset, hours=_rng.randint(0, 12))
        sessions.append(_build_session(user, recorded_at, quality, index))
    return sessions


def main() -> None:
    print("Resetting database...")
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        hashed = hash_password(SEED_PASSWORD)

        mohamed = User(
            name="محمد",
            email="mohamed@altawfeeq.dz",
            hashed_password=hashed,
            gender=Gender.male,
            birth_year=1958,
            therapeutic_goal="متابعة دورية",
            notifications_enabled=True,
        )
        fatima = User(
            name="فاطمة",
            email="fatima@altawfeeq.dz",
            hashed_password=hashed,
            gender=Gender.female,
            birth_year=1962,
            therapeutic_goal="الحفاظ على الصحة الصوتية",
            notifications_enabled=True,
        )
        layla = User(
            name="ليلى",
            email="layla@altawfeeq.dz",
            hashed_password=hashed,
            gender=Gender.female,
            birth_year=1950,
            therapeutic_goal="متابعة مع مختص",
            notifications_enabled=False,
        )

        db.add_all([mohamed, fatima, layla])
        db.commit()
        for user in (mohamed, fatima, layla):
            db.refresh(user)

        # --- محمد: 7 sessions over the past ~5 weeks, mixed results ---------
        mohamed_qualities = [0.82, 0.35, 0.68, 0.30, 0.74, 0.42, 0.60]
        mohamed_days_ago = [33, 28, 24, 18, 12, 6, 1]
        mohamed_sessions = _seed_user_sessions(mohamed, mohamed_qualities, mohamed_days_ago)

        # --- فاطمة: 5 sessions, generally healthy / improving trend ---------
        fatima_qualities = [0.66, 0.72, 0.78, 0.81, 0.88]
        fatima_days_ago = [24, 18, 12, 6, 1]
        fatima_sessions = _seed_user_sessions(fatima, fatima_qualities, fatima_days_ago)

        # --- ليلى: 6 sessions, deteriorating trend (scores dropping) --------
        layla_qualities = [0.86, 0.74, 0.62, 0.50, 0.40, 0.28]
        layla_days_ago = [30, 24, 18, 12, 6, 1]
        layla_sessions = _seed_user_sessions(layla, layla_qualities, layla_days_ago)

        db.add_all(mohamed_sessions + fatima_sessions + layla_sessions)
        db.commit()

        print("\nSeeded users and sessions successfully.\n")
        print("Test user credentials (all use the same password):")
        print(f"  password: {SEED_PASSWORD}\n")
        for user in (mohamed, fatima, layla):
            print(f"  {user.name:<6}  email: {user.email}")
        print()

    finally:
        db.close()


if __name__ == "__main__":
    main()
