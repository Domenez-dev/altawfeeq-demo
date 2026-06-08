"""Vocal-biomarker scoring and illness classification.

Turns raw acoustic measurements (services/praat.py) into 0-100 subscores per
metric, a single composite overall_score, and a 3-way classification used
throughout the app (healthy / at_risk / sick).

IMPORTANT — BASELINE CAVEAT
---------------------------
The F0/jitter/shimmer reference baselines below are derived from research on
FEMALE subjects only. Until male-specific baselines are added, classification
results for male users will be LESS ACCURATE — male voices naturally have
lower F0 and may show different jitter/shimmer ranges even when healthy. Treat
male results as a rough approximation, not a validated assessment.
"""
from dataclasses import dataclass

from models.session import Classification

# ---------------------------------------------------------------------------
# Reference baselines (NORMAL vs ALZHEIMER), derived from female-subject
# research. See module docstring re: male accuracy caveat.
# ---------------------------------------------------------------------------

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: published female-subject voice research on
# mean fundamental frequency in healthy vs Alzheimer's-affected speakers.
# Current value: normal = 206 Hz, alzheimer = 229 Hz
# Suggested range: normal [190 - 220], alzheimer [215 - 245]
# Impact: These two values define the linear interpolation endpoints for
# f0_score. Narrowing the gap between them makes the score more sensitive to
# small F0 deviations (more false positives); widening it makes the score more
# forgiving (more false negatives). NOT YET VALIDATED FOR MALE VOICES.
# ============================================================
F0_BASELINE_NORMAL_HZ = 206.0
F0_BASELINE_ALZHEIMER_HZ = 229.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: published female-subject voice research on
# jitter (local, %) in healthy vs Alzheimer's-affected speakers.
# Current value: normal = 0.86%, alzheimer = 1.95%
# Suggested range: normal [0.5 - 1.0], alzheimer [1.5 - 2.5]
# Impact: Defines the linear interpolation endpoints for jitter_score. A
# narrower gap increases sensitivity (more false positives); a wider gap
# increases tolerance (more false negatives). NOT YET VALIDATED FOR MALE VOICES.
# ============================================================
JITTER_BASELINE_NORMAL_PERCENT = 0.86
JITTER_BASELINE_ALZHEIMER_PERCENT = 1.95

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: published female-subject voice research on
# shimmer (local, %) in healthy vs Alzheimer's-affected speakers.
# Current value: normal = 3.69%, alzheimer = 5.26%
# Suggested range: normal [3.0 - 4.0], alzheimer [4.5 - 6.0]
# Impact: Defines the linear interpolation endpoints for shimmer_score. A
# narrower gap increases sensitivity (more false positives); a wider gap
# increases tolerance (more false negatives). NOT YET VALIDATED FOR MALE VOICES.
# ============================================================
SHIMMER_BASELINE_NORMAL_PERCENT = 3.69
SHIMMER_BASELINE_ALZHEIMER_PERCENT = 5.26

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: NO strong research baseline currently exists
# for intensity in this context — this is an ASSUMPTION of a comfortable,
# normal speaking/sustained-vowel loudness range for a phone-mic recording.
# Current value: normal range = 60-80 dB
# Suggested range: [55-65] lower bound, [75-85] upper bound
# Impact: Recordings outside this range score lower. Too narrow a range
# penalizes naturally quiet/loud speakers or varying recording setups; too
# wide a range makes the intensity subscore nearly meaningless.
# ============================================================
INTENSITY_NORMAL_RANGE_DB = (60.0, 80.0)

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: NO strong research baseline currently exists —
# this is an ASSUMPTION that a sustained "آآآ" of 3-8 seconds reflects
# adequate breath support and vocal stamina for reliable analysis.
# Current value: ideal range = 3-8 seconds
# Suggested range: [2-4] lower bound, [6-10] upper bound
# Impact: Recordings outside this range score lower on duration_score. Too
# narrow a range penalizes naturally shorter/longer sustainable phonations;
# too wide makes the duration subscore nearly meaningless.
# ============================================================
DURATION_IDEAL_RANGE_SECONDS = (3.0, 8.0)

# ============================================================
# TUNABLE PARAMETER — metric weights for overall score
# ============================================================
# Current weights: F0=0.30, Jitter=0.30, Shimmer=0.20, Intensity=0.10, Duration=0.10
# These are assumptions. Adjust when more clinical data is available.
# ============================================================
WEIGHT_F0 = 0.30
WEIGHT_JITTER = 0.30
WEIGHT_SHIMMER = 0.20
WEIGHT_INTENSITY = 0.10
WEIGHT_DURATION = 0.10

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: an assumption of three roughly even-sized
# bands (healthy / borderline / concerning) over the 0-100 overall score
# range; not yet clinically validated against diagnosed outcomes.
# Current value: healthy >= 70, at_risk in [40, 70), sick < 40
# Suggested range: healthy threshold [65-75], sick threshold [35-45]
# Impact: Raising the healthy threshold (or the sick threshold) flags more
# users as at_risk/sick (higher sensitivity, more false alarms); lowering
# them does the opposite (higher specificity, more missed cases).
# ============================================================
HEALTHY_THRESHOLD = 70.0
SICK_THRESHOLD = 40.0


@dataclass(frozen=True)
class MetricScores:
    """0-100 subscores for each acoustic metric, plus the composite score."""

    f0_score: float
    jitter_score: float
    shimmer_score: float
    intensity_score: float
    duration_score: float
    overall_score: float


def _clamp(value: float, low: float = 0.0, high: float = 100.0) -> float:
    return max(low, min(high, value))


def _score_against_baseline(value: float, normal: float, alzheimer: float) -> float:
    """Linearly interpolate a 0-100 score between a 'normal' and 'alzheimer' reference.

    `value == normal` -> 100, `value == alzheimer` -> 0, clamped to [0, 100].
    Values past the alzheimer reference (further from normal) clamp at 0;
    values better than normal (closer to "more normal than normal") clamp at 100.
    """
    span = alzheimer - normal
    if span == 0:
        return 100.0

    fraction_toward_alzheimer = (value - normal) / span
    score = 100.0 * (1.0 - fraction_toward_alzheimer)
    return _clamp(score)


def _score_within_range(value: float, low: float, high: float) -> float:
    """Score a value that has an ideal [low, high] range.

    Inside the range -> 100. Outside, the score decreases linearly with
    distance from the nearest edge, reaching 0 once the value is as far
    outside the range as the range itself is wide (clamped to [0, 100]).
    """
    if low <= value <= high:
        return 100.0

    span = max(high - low, 1e-9)
    distance = (low - value) if value < low else (value - high)
    score = 100.0 * (1.0 - distance / span)
    return _clamp(score)


def score_features(
    *,
    f0_hz: float,
    jitter_percent: float,
    shimmer_percent: float,
    intensity_db: float,
    duration_seconds: float,
) -> MetricScores:
    """Compute per-metric 0-100 subscores and the weighted composite score."""
    f0_score = _score_against_baseline(f0_hz, F0_BASELINE_NORMAL_HZ, F0_BASELINE_ALZHEIMER_HZ)
    jitter_score = _score_against_baseline(
        jitter_percent, JITTER_BASELINE_NORMAL_PERCENT, JITTER_BASELINE_ALZHEIMER_PERCENT
    )
    shimmer_score = _score_against_baseline(
        shimmer_percent, SHIMMER_BASELINE_NORMAL_PERCENT, SHIMMER_BASELINE_ALZHEIMER_PERCENT
    )
    intensity_score = _score_within_range(intensity_db, *INTENSITY_NORMAL_RANGE_DB)
    duration_score = _score_within_range(duration_seconds, *DURATION_IDEAL_RANGE_SECONDS)

    overall_score = _clamp(
        WEIGHT_F0 * f0_score
        + WEIGHT_JITTER * jitter_score
        + WEIGHT_SHIMMER * shimmer_score
        + WEIGHT_INTENSITY * intensity_score
        + WEIGHT_DURATION * duration_score
    )

    return MetricScores(
        f0_score=f0_score,
        jitter_score=jitter_score,
        shimmer_score=shimmer_score,
        intensity_score=intensity_score,
        duration_score=duration_score,
        overall_score=overall_score,
    )


def classify(overall_score: float) -> Classification:
    """Map a composite overall_score to a 3-way classification."""
    if overall_score >= HEALTHY_THRESHOLD:
        return Classification.healthy
    if overall_score >= SICK_THRESHOLD:
        return Classification.at_risk
    return Classification.sick
