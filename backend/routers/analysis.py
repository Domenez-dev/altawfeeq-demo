"""Audio analysis endpoint — runs the full Praat pipeline on an uploaded recording."""
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, UploadFile, status
from sqlalchemy.orm import Session as DBSession

from database import get_db
from models.session import CLASSIFICATION_LABELS_AR, Session
from models.user import User
from schemas.session import AnalysisResultResponse
from services import audio, classifier, feedback
from services.praat import (
    AudioQualityError,
    AudioTooShortError,
    PraatAnalysisError,
    extract_features,
)
from utils.helpers import get_current_user

router = APIRouter(prefix="/api/analysis", tags=["Analysis"])

# Logs to the uvicorn output so we can compare the raw acoustic values produced
# on different machines (e.g. local vs VPS). Identical values across different
# recordings usually point to a broken audio decode (ffmpeg) rather than Praat.
logger = logging.getLogger("uvicorn.error")

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: a practical assumption about the maximum size
# of a short sustained-vowel recording from a phone, generous enough to avoid
# rejecting legitimate clips while preventing excessively large uploads.
# Current value: 25 MB
# Suggested range: [10 - 50] MB
# Impact: Lower limits reject larger (e.g. uncompressed) recordings; higher
# limits allow bigger uploads at the cost of more disk/processing usage.
# ============================================================
MAX_UPLOAD_BYTES = 25 * 1024 * 1024

_ALLOWED_CONTENT_TYPE_PREFIXES = ("audio/", "video/")  # some devices tag m4a as video/mp4


@router.post(
    "/analyze",
    response_model=AnalysisResultResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Analyze a sustained-vowel recording",
    description=(
        "Uploads a recording of a sustained vowel (e.g. \"آآآ\"), converts it to WAV, "
        "runs the Praat acoustic analysis pipeline (F0, jitter, shimmer, intensity, duration), "
        "computes a composite score and classification, generates Arabic feedback, "
        "stores the resulting session, and returns the full result."
    ),
    responses={
        422: {
            "description": "The recording could not be analyzed",
            "content": {
                "application/json": {
                    "examples": {
                        "invalid_format": {"value": {"detail": "تعذر قراءة الملف الصوتي", "code": "INVALID_FORMAT"}},
                        "audio_too_short": {"value": {"detail": "التسجيل قصير جداً، يرجى المحاولة مجدداً", "code": "AUDIO_TOO_SHORT"}},
                        "audio_no_voice": {"value": {"detail": "لم نسمع صوتاً واضحاً. اقترب من الميكروفون وكرّر النطق بصوت أعلى في مكان هادئ.", "code": "AUDIO_NO_VOICE"}},
                        "audio_unstable": {"value": {"detail": "الصوت غير مستقر بما يكفي للتحليل. أطِل نطق الحرف بثبات مثل \"آآآ\" دون تغيير النبرة.", "code": "AUDIO_UNSTABLE"}},
                        "audio_quality_poor": {"value": {"detail": "جودة التسجيل غير كافية للتحليل", "code": "AUDIO_QUALITY_POOR"}},
                        "praat_failed": {"value": {"detail": "فشل تحليل الصوت", "code": "PRAAT_ANALYSIS_FAILED"}},
                    }
                }
            },
        }
    },
)
async def analyze_recording(
    file: UploadFile,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> AnalysisResultResponse:
    raw_bytes = await file.read()

    # Log every upload up front so even a rejection before feature extraction
    # leaves a trace of what arrived (name / size / declared content type).
    logger.info(
        "ANALYZE request | upload=%s size=%d type=%s",
        file.filename,
        len(raw_bytes),
        file.content_type,
    )

    if not raw_bytes:
        logger.warning("ANALYZE rejected | code=INVALID_FORMAT reason=empty upload")
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": "الملف فارغ", "code": "INVALID_FORMAT"},
        )

    if len(raw_bytes) > MAX_UPLOAD_BYTES:
        logger.warning(
            "ANALYZE rejected | code=INVALID_FORMAT reason=too large (%d > %d bytes)",
            len(raw_bytes),
            MAX_UPLOAD_BYTES,
        )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": "حجم الملف أكبر من المسموح", "code": "INVALID_FORMAT"},
        )

    if file.content_type and not file.content_type.startswith(_ALLOWED_CONTENT_TYPE_PREFIXES):
        logger.warning(
            "ANALYZE rejected | code=INVALID_FORMAT reason=unsupported content type %s",
            file.content_type,
        )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": "صيغة الملف غير مدعومة", "code": "INVALID_FORMAT"},
        )

    original_path = audio.save_upload(raw_bytes, file.filename or "recording")

    try:
        wav_path = audio.convert_to_wav(original_path)
    except audio.AudioConversionError as exc:
        # Include the ffmpeg failure detail — this is the usual culprit on a
        # server that's missing a codec for the device's recording format.
        logger.warning("ANALYZE rejected | code=INVALID_FORMAT reason=ffmpeg conversion failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": "تعذر قراءة الملف الصوتي", "code": "INVALID_FORMAT"},
        ) from exc

    try:
        features = extract_features(wav_path)
    except AudioTooShortError as exc:
        logger.warning("ANALYZE rejected | code=AUDIO_TOO_SHORT reason=%s", exc)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": "التسجيل قصير جداً، يرجى المحاولة مجدداً", "code": "AUDIO_TOO_SHORT"},
        ) from exc
    except AudioQualityError as exc:
        # Map the specific failure mode to an actionable Arabic message so the
        # user knows *what* to fix, instead of a single generic "poor quality".
        quality_messages = {
            "no_voice": (
                "لم نسمع صوتاً واضحاً. اقترب من الميكروفون وكرّر النطق بصوت أعلى في مكان هادئ.",
                "AUDIO_NO_VOICE",
            ),
            "unstable": (
                "الصوت غير مستقر بما يكفي للتحليل. أطِل نطق الحرف بثبات مثل \"آآآ\" دون تغيير النبرة.",
                "AUDIO_UNSTABLE",
            ),
        }
        detail_text, error_code = quality_messages.get(
            exc.reason, ("جودة التسجيل غير كافية للتحليل", "AUDIO_QUALITY_POOR")
        )
        logger.warning("ANALYZE rejected | code=%s reason=%s", error_code, exc)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": detail_text, "code": error_code},
        ) from exc
    except PraatAnalysisError as exc:
        logger.warning("ANALYZE rejected | code=PRAAT_ANALYSIS_FAILED reason=%s", exc)
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={"detail": "فشل تحليل الصوت", "code": "PRAAT_ANALYSIS_FAILED"},
        ) from exc

    logger.info(
        "ANALYZE raw features | upload=%s (%d bytes, type=%s) wav=%s | "
        "duration=%.3fs f0=%.2fHz jitter=%.4f%% shimmer=%.4f%% intensity=%.2fdB",
        file.filename,
        len(raw_bytes),
        file.content_type,
        wav_path.name,
        features.duration_seconds,
        features.f0_hz,
        features.jitter_percent,
        features.shimmer_percent,
        features.intensity_db,
    )

    scores = classifier.score_features(
        f0_hz=features.f0_hz,
        jitter_percent=features.jitter_percent,
        shimmer_percent=features.shimmer_percent,
        intensity_db=features.intensity_db,
        duration_seconds=features.duration_seconds,
    )
    classification = classifier.classify(scores.overall_score)
    feedback_text = feedback.build_feedback_text(scores, classification)

    session = Session(
        user_id=current_user.id,
        recorded_at=datetime.now(timezone.utc),
        duration_seconds=features.duration_seconds,
        f0_hz=features.f0_hz,
        jitter_percent=features.jitter_percent,
        shimmer_percent=features.shimmer_percent,
        intensity_db=features.intensity_db,
        overall_score=scores.overall_score,
        f0_score=scores.f0_score,
        jitter_score=scores.jitter_score,
        shimmer_score=scores.shimmer_score,
        intensity_score=scores.intensity_score,
        duration_score=scores.duration_score,
        classification=classification,
        feedback_text=feedback_text,
        audio_filename=original_path.name,
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return AnalysisResultResponse(
        **{c.name: getattr(session, c.name) for c in Session.__table__.columns},
        classification_label=CLASSIFICATION_LABELS_AR[session.classification],
    )


# ---------------------------------------------------------------------------
# Indicator Detail endpoint for frontend
# ---------------------------------------------------------------------------
from pydantic import BaseModel


class IndicatorDataPointResponse(BaseModel):
    date: str
    value: float


class IndicatorDetailResponse(BaseModel):
    name: str
    history: list[IndicatorDataPointResponse]
    analysis: str
    natural_range: str
    results: str


@router.get(
    "/indicators/{indicator_name}",
    response_model=IndicatorDetailResponse,
    summary="Get detail and history for a specific vocal indicator",
)
def get_indicator_detail(
    indicator_name: str,
    current_user: User = Depends(get_current_user),
    db: DBSession = Depends(get_db),
) -> IndicatorDetailResponse:
    # Take the 10 MOST RECENT sessions (so newly recorded ones always appear),
    # then reverse to chronological order (oldest → newest) for the history
    # graph. Ordering ascending + limit would pin the graph to the oldest
    # sessions and hide every new recording once 10 older ones exist.
    from sqlalchemy import desc
    sessions = (
        db.query(Session)
        .filter(Session.user_id == current_user.id)
        .order_by(desc(Session.recorded_at))
        .limit(10)
        .all()
    )
    sessions.reverse()

    history = []
    for s in sessions:
        date_str = f"{s.recorded_at.day:02d}/{s.recorded_at.month:02d}"

        # Select score based on the requested indicator
        if "شدة" in indicator_name or "intensity" in indicator_name.lower():
            val = s.intensity_score
        elif "المدة" in indicator_name or "duration" in indicator_name.lower():
            val = s.duration_score
        elif "الطبقة" in indicator_name or "pitch" in indicator_name.lower() or "f0" in indicator_name.lower():
            val = s.f0_score
        elif "الاضطراب" in indicator_name or "jitter" in indicator_name.lower():
            val = s.jitter_score
        else:
            val = s.overall_score

        history.append(IndicatorDataPointResponse(date=date_str, value=val))

    # Provide helpful descriptions and suggestions in Arabic
    if "شدة" in indicator_name or "intensity" in indicator_name.lower():
        natural_range = "60% - 90%"
        analysis_txt = "شدة الصوت تعبر عن مدى وضوح وقوة نبرة الصوت. مستواك مستقر بشكل عام."
        results_txt = "حاول التحدث في بيئة هادئة وبصوت ثابت ومستمر لتدريب عضلات النطق."
    elif "المدة" in indicator_name or "duration" in indicator_name.lower():
        natural_range = "3 - 8 ثواني"
        analysis_txt = "المدة تعبر عن القدرة على التحكم في هواء الزفير والمحافظة على النبرة الصوتية."
        results_txt = "تدرب على أخذ نفس عميق قبل بدء النطق، للمحافظة على طول واستقرار النبرة."
    elif "الطبقة" in indicator_name or "pitch" in indicator_name.lower() or "f0" in indicator_name.lower():
        natural_range = "70% - 100%"
        analysis_txt = "الطبقة الصوتية تعكس استقرار التردد الأساسي للصوت وخلوه من التذبذب غير الطبيعي."
        results_txt = "قم بتمارين تمديد الصوت بلطف وتجنب إجهاد حنجرتك وأوتارك الصوتية."
    else:
        natural_range = "60% - 90%"
        analysis_txt = "مؤشر الاضطراب (Jitter) يقيس مدى انتظام الموجات الصوتية الفردية."
        results_txt = "الاسترخاء والترطيب الجيد للحلق يساعدان كثيراً في خفض اضطراب نبرة الصوت."

    return IndicatorDetailResponse(
        name=indicator_name,
        history=history,
        analysis=analysis_txt,
        natural_range=natural_range,
        results=results_txt,
    )
