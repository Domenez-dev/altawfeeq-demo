"""Vocal-biomarker scoring and illness classification.

Turns raw acoustic measurements (services/praat.py) into 0-100 subscores per
metric, a single composite overall_score, and a 3-way classification used
throughout the app (healthy / at_risk / sick).

IMPORTANT — CALIBRATION CAVEAT
------------------------------
The thresholds below are HEURISTIC, tuned so that real phone-microphone
sustained-vowel recordings produce graded, varied scores (rather than every
metric pinning at 100 or crushing to 0). They are NOT clinically validated and
should be replaced with proper, sex-specific reference data once it exists.

Design notes after recalibration:
  * F0 is scored sex-agnostically as a healthy *band* (covers typical male and
    female pitch) instead of a single female baseline, so a normal low-pitched
    (e.g. male) voice no longer always scores 100.
  * Jitter/shimmer "normal→risk" ranges are widened to match the higher
    perturbation typical of phone recordings, so a healthy voice is no longer
    forced to 0.
  * Intensity and duration are scored as a peak around an ideal value, so they
    vary smoothly with the recording instead of being a flat pass/fail.
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
# F0 is scored as a healthy *band* rather than against a single (female-only)
# baseline. Full credit inside [PLATEAU_LOW, PLATEAU_HIGH], tapering linearly to
# 0 at the hard bounds. The plateau covers typical adult male (~100-150 Hz) and
# female (~180-220 Hz) sustained-vowel pitch, so a normal voice of either sex
# scores high and only abnormally low/high pitch is penalised.
# Suggested ranges: plateau [90-100]..[215-230], hard [50-60]..[300-340].
# ============================================================
F0_PLATEAU_LOW_HZ = 95.0
F0_PLATEAU_HIGH_HZ = 225.0
F0_HARD_LOW_HZ = 55.0
F0_HARD_HIGH_HZ = 320.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# Jitter (local, %). Lower is better: <= NORMAL scores 100, >= ALZHEIMER scores
# 0, linear in between. NORMAL is the "excellent / pristine" anchor: it's set
# low (0.5%) so a clean steady male/female voice lands in the high-80s..90s with
# headroom, rather than everyone pegging at 100. ALZHEIMER stays wide enough
# (4.5%) that real phone recordings aren't crushed to 0.
# Suggested range: normal [0.3 - 0.6], alzheimer [3.5 - 5.5].
# ============================================================
JITTER_BASELINE_NORMAL_PERCENT = 0.5
JITTER_BASELINE_ALZHEIMER_PERCENT = 4.5

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# Shimmer (local, %). Lower is better: <= NORMAL scores 100, >= ALZHEIMER
# scores 0, linear in between. NORMAL is the "excellent" anchor (2.5%), set low
# so a clean voice scores high-80s..90s with headroom instead of pegging at 100.
# ALZHEIMER (13%) stays wide so real phone recordings aren't crushed to 0.
# Suggested range: normal [2.0 - 3.0], alzheimer [11 - 15].
# ============================================================
SHIMMER_BASELINE_NORMAL_PERCENT = 2.5
SHIMMER_BASELINE_ALZHEIMER_PERCENT = 13.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# HNR — Harmonics-to-Noise Ratio (dB). HIGHER is better (more harmonic energy
# relative to noise = a cleaner, healthier voice). >= NORMAL scores 100,
# <= FLOOR scores 0, linear in between. Clinical reference: a healthy voice is
# usually > 20 dB; below 20 dB is treated as suspect. NORMAL is set at 20 dB so
# a clean voice scores high, and FLOOR is kept low (5 dB) so noisy but real
# phone recordings are not crushed straight to 0.
# Suggested range: normal [18 - 22], floor [4 - 8].
# ============================================================
HNR_BASELINE_NORMAL_DB = 20.0
HNR_BASELINE_FLOOR_DB = 5.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# F0 SD — pitch variability (Hz) on the SUSTAINED vowel "آآآ". On a sustained
# vowel a steady pitch is healthy, so here LOWER SD (more stable) is better and
# a large SD reflects pitch instability/tremor. <= STABLE scores 100, >= UNSTABLE
# scores 0, linear in between.
# NOTE: this is the opposite framing from spontaneous/connected speech, where
# *low* pitch variability (monotone, < ~20 Hz) is the suspect sign. That
# connected-speech rule is presented as reference-only in the app because the
# recording task here is a sustained vowel.
# Suggested range: stable [2 - 5], unstable [25 - 40].
# ============================================================
F0_SD_BASELINE_STABLE_HZ = 3.0
F0_SD_BASELINE_UNSTABLE_HZ = 30.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# Intensity (dB). Scored as a smooth peak: full credit at the ideal centre,
# tapering linearly to 0 once the value is TOLERANCE dB away on either side.
# This makes the subscore vary with the recording (a comfortable mid-level
# loudness scores best) instead of being a flat in-range/out-of-range gate.
# Centre 70 dB, tolerance 22 dB → meaningful credit roughly across 48-92 dB.
# ============================================================
INTENSITY_IDEAL_CENTER_DB = 70.0
INTENSITY_TOLERANCE_DB = 22.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# Duration (s). Scored as a smooth peak: full credit at the ideal centre,
# tapering linearly to 0 once the value is TOLERANCE seconds away on either
# side. A sustained "آآآ" around the centre reflects good breath support;
# very short or very long phonations score lower instead of flat pass/fail.
# Centre 6 s, tolerance 5 s → meaningful credit roughly across 1-11 s.
# ============================================================
DURATION_IDEAL_CENTER_SECONDS = 6.0
DURATION_TOLERANCE_SECONDS = 5.0

# ============================================================
# TUNABLE PARAMETER — metric weights for overall score
# ============================================================
# Seven acoustic biomarkers measured on the sustained vowel "آآآ". The
# phonation/voice-quality measures (jitter, shimmer, HNR) carry the most weight
# because they are the ones the sustained-vowel task captures most reliably.
# The three TEMPORAL biomarkers from the literature (speech rate, pause
# duration, pause ratio) need connected speech, so they are NOT scored here —
# they are presented as reference-only in the app.
# Weights sum to 1.0. When HNR / F0 SD are unavailable (e.g. an old recording),
# their weight is redistributed proportionally over the remaining metrics.
# ============================================================
WEIGHT_F0 = 0.18
WEIGHT_F0_SD = 0.10
WEIGHT_JITTER = 0.20
WEIGHT_SHIMMER = 0.15
WEIGHT_HNR = 0.17
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
    """0-100 subscores for each acoustic metric, plus the composite score.

    `hnr_score` and `f0_sd_score` are optional (None when the corresponding raw
    feature was not available, e.g. recordings analysed before HNR/F0-SD
    extraction was added) so the pipeline stays backward compatible.
    """

    f0_score: float
    jitter_score: float
    shimmer_score: float
    intensity_score: float
    duration_score: float
    overall_score: float
    hnr_score: float | None = None
    f0_sd_score: float | None = None


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


def _score_band(
    value: float, plateau_low: float, plateau_high: float, hard_low: float, hard_high: float
) -> float:
    """Score a value with a healthy plateau and graded taper.

    Inside [plateau_low, plateau_high] -> 100. Between a hard bound and the
    plateau the score tapers linearly to 0 at the hard bound. Beyond the hard
    bounds -> 0. Used for F0, where a whole band of pitches is "normal".
    """
    if plateau_low <= value <= plateau_high:
        return 100.0

    if value < plateau_low:
        span = max(plateau_low - hard_low, 1e-9)
        score = 100.0 * (value - hard_low) / span
    else:
        span = max(hard_high - plateau_high, 1e-9)
        score = 100.0 * (hard_high - value) / span
    return _clamp(score)


def _score_peak(value: float, center: float, tolerance: float) -> float:
    """Score a value by closeness to an ideal `center`.

    100 at the center, decreasing linearly to 0 at `center +/- tolerance`
    (clamped to [0, 100]). Used for intensity and duration, where there is a
    single ideal value rather than a wide acceptable band.
    """
    tolerance = max(tolerance, 1e-9)
    score = 100.0 * (1.0 - abs(value - center) / tolerance)
    return _clamp(score)


def score_features(
    *,
    f0_hz: float,
    jitter_percent: float,
    shimmer_percent: float,
    intensity_db: float,
    duration_seconds: float,
    hnr_db: float | None = None,
    f0_sd_hz: float | None = None,
) -> MetricScores:
    """Compute per-metric 0-100 subscores and the weighted composite score.

    `hnr_db` and `f0_sd_hz` are optional. When either is omitted, its weight is
    redistributed proportionally over the metrics that ARE present, so the
    composite score stays on the same 0-100 scale regardless of how many
    biomarkers were available.
    """
    f0_score = _score_band(
        f0_hz, F0_PLATEAU_LOW_HZ, F0_PLATEAU_HIGH_HZ, F0_HARD_LOW_HZ, F0_HARD_HIGH_HZ
    )
    jitter_score = _score_against_baseline(
        jitter_percent, JITTER_BASELINE_NORMAL_PERCENT, JITTER_BASELINE_ALZHEIMER_PERCENT
    )
    shimmer_score = _score_against_baseline(
        shimmer_percent, SHIMMER_BASELINE_NORMAL_PERCENT, SHIMMER_BASELINE_ALZHEIMER_PERCENT
    )
    intensity_score = _score_peak(intensity_db, INTENSITY_IDEAL_CENTER_DB, INTENSITY_TOLERANCE_DB)
    duration_score = _score_peak(duration_seconds, DURATION_IDEAL_CENTER_SECONDS, DURATION_TOLERANCE_SECONDS)

    # HNR: higher dB is better (a clean voice); F0 SD: on a sustained vowel a
    # lower (more stable) pitch is better. Both are optional.
    hnr_score = (
        _score_against_baseline(hnr_db, HNR_BASELINE_NORMAL_DB, HNR_BASELINE_FLOOR_DB)
        if hnr_db is not None
        else None
    )
    f0_sd_score = (
        _score_against_baseline(f0_sd_hz, F0_SD_BASELINE_STABLE_HZ, F0_SD_BASELINE_UNSTABLE_HZ)
        if f0_sd_hz is not None
        else None
    )

    # Build (score, weight) pairs only for metrics we actually have, then
    # renormalise the weights so they always sum to 1.0.
    weighted: list[tuple[float, float]] = [
        (f0_score, WEIGHT_F0),
        (jitter_score, WEIGHT_JITTER),
        (shimmer_score, WEIGHT_SHIMMER),
        (intensity_score, WEIGHT_INTENSITY),
        (duration_score, WEIGHT_DURATION),
    ]
    if hnr_score is not None:
        weighted.append((hnr_score, WEIGHT_HNR))
    if f0_sd_score is not None:
        weighted.append((f0_sd_score, WEIGHT_F0_SD))

    total_weight = sum(w for _, w in weighted)
    overall_score = _clamp(sum(s * w for s, w in weighted) / total_weight)

    return MetricScores(
        f0_score=f0_score,
        jitter_score=jitter_score,
        shimmer_score=shimmer_score,
        intensity_score=intensity_score,
        duration_score=duration_score,
        hnr_score=hnr_score,
        f0_sd_score=f0_sd_score,
        overall_score=overall_score,
    )


def classify(overall_score: float) -> Classification:
    """Map a composite overall_score to a 3-way classification."""
    if overall_score >= HEALTHY_THRESHOLD:
        return Classification.healthy
    if overall_score >= SICK_THRESHOLD:
        return Classification.at_risk
    return Classification.sick
