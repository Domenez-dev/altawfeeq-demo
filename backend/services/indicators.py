"""Canonical vocal-biomarker indicator names + frontend list builder.

Single source of truth for the Arabic indicator names shown across the app
(home dashboard, session list/detail, indicator-detail screen) so they always
match. The sustained-vowel task measures seven biomarkers; the temporal ones
(speech rate / pauses) are reference-only and therefore not produced here.
"""
from schemas.home import HomeIndicator

# Canonical Arabic indicator names (also used by the frontend kIndicatorNames).
INTENSITY = "شدة الصوت"
DURATION = "المدة"
F0 = "الطبقة الصوتية"
F0_SD = "تباين الطبقة (F0 SD)"
JITTER = "الاضطراب (Jitter)"
SHIMMER = "اضطراب الشدة (Shimmer)"
HNR = "نسبة HNR"


def status_for(score: float) -> str:
    """3-way Arabic status bucket for a 0-100 subscore."""
    return "جيد" if score >= 70.0 else "متوسط" if score >= 40.0 else "ضعيف"


def _ind(name: str, score: float) -> HomeIndicator:
    return HomeIndicator(name=name, percent=score / 100.0, status=status_for(score))


def build_indicators(
    *,
    intensity_score: float,
    duration_score: float,
    f0_score: float,
    jitter_score: float,
    shimmer_score: float,
    hnr_score: float | None = None,
    f0_sd_score: float | None = None,
) -> list[HomeIndicator]:
    """Build the ordered indicator list for the frontend.

    HNR and F0-SD are appended only when available (older sessions, recorded
    before those biomarkers were added, carry None for them).
    """
    items = [
        _ind(INTENSITY, intensity_score),
        _ind(DURATION, duration_score),
        _ind(F0, f0_score),
        _ind(JITTER, jitter_score),
        _ind(SHIMMER, shimmer_score),
    ]
    if hnr_score is not None:
        items.append(_ind(HNR, hnr_score))
    if f0_sd_score is not None:
        items.append(_ind(F0_SD, f0_sd_score))
    return items
