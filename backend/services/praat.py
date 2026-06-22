"""Acoustic feature extraction using Praat (via parselmouth).

Given a clean WAV recording of a sustained vowel ("آآآ"), this module extracts
the acoustic biomarkers used by services/classifier.py:

  1. F0 (fundamental frequency, mean, Hz)
  2. F0 SD (pitch variability / stability, Hz)
  3. Jitter (local, %)
  4. Shimmer (local, %)
  5. HNR (harmonics-to-noise ratio, mean, dB)
  6. Intensity (mean, dB)
  7. Duration (seconds)

Every parameter below that influences the extracted values in a clinically
meaningful way is called out with a TUNABLE PARAMETER block — these are the
first things to revisit once real clinical validation data is available.
"""
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import parselmouth
from parselmouth.praat import call


class PraatAnalysisError(Exception):
    """Raised when Praat/parselmouth fails to analyze a recording."""


class AudioQualityError(Exception):
    """Raised when the recording is too noisy/unstable for Praat to extract reliable features.

    `reason` distinguishes the failure mode so the API can return a specific,
    actionable Arabic message instead of one generic "poor quality" error:
      - "no_voice": no detectable voiced pitch at all (too quiet / whisper /
        background noise only / wrong or muted microphone input).
      - "unstable": voice is present but too irregular for Praat to compute the
        cycle-to-cycle perturbation measures (jitter/shimmer).
    """

    def __init__(self, message: str, *, reason: str = "quality") -> None:
        self.reason = reason
        super().__init__(message)


class AudioTooShortError(Exception):
    """Raised when the recording is shorter than the minimum usable duration."""

    def __init__(self, duration_seconds: float, minimum_seconds: float) -> None:
        self.duration_seconds = duration_seconds
        self.minimum_seconds = minimum_seconds
        super().__init__(
            f"Recording is {duration_seconds:.2f}s, shorter than the "
            f"{minimum_seconds:.2f}s minimum required for analysis."
        )


# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: Praat's default pitch analysis floor, suitable
# for typical adult voices (covers low male pitch without picking up hum/noise
# as pitch).
# Current value: 75 Hz
# Suggested range: [60 - 100]
# Impact: Lowering the floor allows lower (e.g. very low male, pathological)
# pitches to be detected but increases the risk of octave errors / picking up
# low-frequency noise as voice. Raising it risks missing genuinely low voices.
# ============================================================
PITCH_FLOOR_HZ = 75.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: Praat's default pitch analysis ceiling,
# suitable for typical adult voices including higher female pitch.
# Current value: 500 Hz
# Suggested range: [300 - 600]
# Impact: Lowering the ceiling can clip legitimately high voices (especially
# female or pathological tremor); raising it increases the risk of picking up
# harmonics as fundamental frequency (octave-jump errors).
# ============================================================
PITCH_CEILING_HZ = 500.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: a conservative assumption that a usable
# sustained-vowel sample needs at least a couple of seconds of phonation to
# produce stable F0/jitter/shimmer estimates; not yet clinically validated.
# Current value: 2.0 seconds
# Suggested range: [1.5 - 3.0]
# Impact: Raising this rejects more borderline-short recordings (fewer false
# analyses on noisy/unstable short clips) but frustrates users who struggle to
# sustain the vowel. Lowering it accepts shorter clips at the cost of noisier,
# less reliable acoustic estimates.
# ============================================================
MINIMUM_DURATION_SECONDS = 2.0

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: Praat's documentation guidance to use roughly
# 1/4 of the pitch floor's period as the analysis time step for stable pitch
# tracking (here: 0.75 / PITCH_FLOOR_HZ ≈ 0.01s); not clinically tuned.
# Current value: 0.01 seconds (10 ms)
# Suggested range: [0.005 - 0.02]
# Impact: Smaller time steps yield finer-grained (but noisier and slower)
# pitch contours; larger steps smooth the contour but can blur short-term
# pitch instability that may itself be a biomarker.
# ============================================================
PITCH_TIME_STEP_SECONDS = 0.01

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: a simple assumption that frames quieter than
# 1/100th (-40 dB relative) of the loudest frame in the recording are likely
# leading/trailing silence or breath noise rather than the sustained vowel;
# not clinically validated.
# Current value: 0.01 (i.e. -40 dB relative to peak intensity)
# Suggested range: [0.005 - 0.05]
# Impact: A lower threshold trims more aggressively (risk of cutting into the
# actual phonation on quiet recordings); a higher threshold trims less
# (risk of leaving silence/breath noise that skews intensity and duration
# measurements).
# ============================================================
SILENCE_RELATIVE_INTENSITY_THRESHOLD = 0.01


@dataclass(frozen=True)
class AcousticFeatures:
    """Raw acoustic measurements extracted from a sustained-vowel recording."""

    duration_seconds: float
    f0_hz: float
    f0_sd_hz: float          # standard deviation of voiced F0 (pitch stability)
    jitter_percent: float
    shimmer_percent: float
    hnr_db: float            # harmonics-to-noise ratio (mean, dB)
    intensity_db: float


def _trim_silence(sound: parselmouth.Sound) -> parselmouth.Sound:
    """Trim leading/trailing low-intensity frames (silence/breath noise).

    Uses SILENCE_RELATIVE_INTENSITY_THRESHOLD relative to the recording's peak
    intensity to find the first and last "voiced enough" sample, and returns
    the sound extracted between those points. Falls back to the original sound
    if trimming would remove everything (e.g. a uniformly quiet recording).
    """
    amplitudes = np.abs(sound.values[0])
    peak = amplitudes.max() if amplitudes.size else 0.0

    if peak <= 0.0:
        return sound

    threshold = peak * SILENCE_RELATIVE_INTENSITY_THRESHOLD
    above_threshold = np.where(amplitudes >= threshold)[0]

    if above_threshold.size == 0:
        return sound

    start_index = int(above_threshold[0])
    end_index = int(above_threshold[-1])

    start_time = sound.xmin + start_index / sound.sampling_frequency
    end_time = sound.xmin + (end_index + 1) / sound.sampling_frequency

    if end_time - start_time < MINIMUM_DURATION_SECONDS / 2:
        # Trimming would leave an unreasonably short clip — keep the original
        # and let the duration check downstream decide whether to reject it.
        return sound

    return sound.extract_part(from_time=start_time, to_time=end_time, preserve_times=False)


def extract_features(wav_path: Path) -> AcousticFeatures:
    """Run the full Praat analysis pipeline on a WAV file.

    Raises:
        AudioTooShortError: if the (trimmed) recording is below
            MINIMUM_DURATION_SECONDS.
        PraatAnalysisError: if parselmouth/Praat fails to analyze the audio.
    """
    try:
        sound = parselmouth.Sound(str(wav_path))
        trimmed = _trim_silence(sound)

        duration_seconds = trimmed.get_total_duration()
        if duration_seconds < MINIMUM_DURATION_SECONDS:
            raise AudioTooShortError(duration_seconds, MINIMUM_DURATION_SECONDS)

        # --- F0 (fundamental frequency) ---------------------------------
        pitch = trimmed.to_pitch(
            time_step=PITCH_TIME_STEP_SECONDS,
            pitch_floor=PITCH_FLOOR_HZ,
            pitch_ceiling=PITCH_CEILING_HZ,
        )
        frequencies = pitch.selected_array["frequency"]
        voiced_frequencies = frequencies[frequencies > 0]  # drop unvoiced frames
        if voiced_frequencies.size == 0:
            raise AudioQualityError(
                "No voiced frames detected — recording may be too quiet or noisy.",
                reason="no_voice",
            )
        f0_hz = float(np.mean(voiced_frequencies))
        # Pitch variability (SD of the voiced F0 contour). On a sustained vowel
        # a small SD means a stable pitch; a large SD reflects instability/tremor.
        f0_sd_hz = float(np.std(voiced_frequencies)) if voiced_frequencies.size > 1 else 0.0

        # --- Jitter & shimmer (require a PointProcess derived from the
        # sound + its pitch contour — this is the standard Praat recipe for
        # voice-quality measurements) -------------------------------------
        point_process = call([trimmed, pitch], "To PointProcess (cc)")

        jitter_local = call(
            point_process, "Get jitter (local)", 0.0, 0.0, 0.0001, 0.02, 1.3
        )
        shimmer_local = call(
            [trimmed, point_process],
            "Get shimmer (local)",
            0.0, 0.0, 0.0001, 0.02, 1.3, 1.6,
        )

        if jitter_local is None or (isinstance(jitter_local, float) and np.isnan(jitter_local)):
            raise AudioQualityError(
                "Praat could not compute jitter — signal too irregular/noisy.",
                reason="unstable",
            )
        if shimmer_local is None or (isinstance(shimmer_local, float) and np.isnan(shimmer_local)):
            raise AudioQualityError(
                "Praat could not compute shimmer — signal too irregular/noisy.",
                reason="unstable",
            )

        jitter_percent = float(jitter_local) * 100.0
        shimmer_percent = float(shimmer_local) * 100.0

        # --- HNR (Harmonics-to-Noise Ratio) ------------------------------
        # Standard Praat recipe: cross-correlation harmonicity, then the mean
        # over the (mostly voiced) sustained vowel. A clean voice gives a high
        # HNR; breathy/noisy phonation lowers it.
        harmonicity = call(
            trimmed, "To Harmonicity (cc)", PITCH_TIME_STEP_SECONDS, PITCH_FLOOR_HZ, 0.1, 1.0
        )
        hnr_db = call(harmonicity, "Get mean", 0.0, 0.0)
        if hnr_db is None or (isinstance(hnr_db, float) and np.isnan(hnr_db)):
            # No reliable harmonicity (e.g. effectively unvoiced) — treat as a
            # very poor ratio rather than failing the whole analysis.
            hnr_db = 0.0
        hnr_db = float(hnr_db)

        # --- Intensity ---------------------------------------------------
        intensity = trimmed.to_intensity(minimum_pitch=PITCH_FLOOR_HZ)
        intensity_db = float(call(intensity, "Get mean", 0.0, 0.0, "energy"))

    except (AudioTooShortError, AudioQualityError, PraatAnalysisError):
        raise
    except Exception as exc:  # noqa: BLE001 — any parselmouth/Praat failure becomes our error
        raise PraatAnalysisError(f"Praat analysis failed: {exc}") from exc

    return AcousticFeatures(
        duration_seconds=duration_seconds,
        f0_hz=f0_hz,
        f0_sd_hz=f0_sd_hz,
        jitter_percent=jitter_percent,
        shimmer_percent=shimmer_percent,
        hnr_db=hnr_db,
        intensity_db=intensity_db,
    )
