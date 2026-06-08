"""Audio preprocessing — converts arbitrary uploaded formats to clean WAV via ffmpeg.

Praat (and by extension parselmouth) works most reliably with mono, 16-bit PCM
WAV files at a consistent sample rate. Uploaded recordings can arrive as m4a,
aac, mp3, ogg, etc. (depending on the mobile device/codec), so every file is
normalized through ffmpeg before it ever reaches services/praat.py.
"""
import subprocess
import uuid
from pathlib import Path

from config import UPLOADS_DIR

# ============================================================
# TUNABLE PARAMETER — adjust based on future clinical research
# ============================================================
# This value was derived from: Praat's typical recommended sample rate for
# voice analysis (pitch ceiling must be well below Nyquist frequency).
# Current value: 44100 Hz
# Suggested range: [16000 - 48000]
# Impact: Higher sample rates preserve more spectral detail (helps shimmer/
# jitter precision) at the cost of larger files and slower processing. Lower
# rates risk aliasing artifacts that can distort pitch and perturbation
# measurements.
# ============================================================
TARGET_SAMPLE_RATE_HZ = 44100

# Praat/parselmouth read WAV most reliably as mono.
TARGET_CHANNELS = 1


class AudioConversionError(Exception):
    """Raised when ffmpeg fails to convert an uploaded recording to WAV."""


def save_upload(raw_bytes: bytes, original_filename: str) -> Path:
    """Persist the raw uploaded bytes under UPLOADS_DIR with a uuid4 filename.

    Returns the path to the saved original file (not yet converted).
    """
    suffix = Path(original_filename).suffix or ".bin"
    stored_name = f"{uuid.uuid4()}{suffix}"
    destination = UPLOADS_DIR / stored_name
    destination.write_bytes(raw_bytes)
    return destination


def convert_to_wav(source_path: Path) -> Path:
    """Convert any audio file to a normalized mono WAV using ffmpeg.

    Returns the path to the generated WAV file (same stem, .wav suffix,
    written alongside the source file in UPLOADS_DIR).
    """
    # Suffix with "-converted" so we never collide with (and ask ffmpeg to
    # overwrite in place) a source file that was already a .wav.
    wav_path = source_path.with_name(f"{source_path.stem}-converted.wav")

    command = [
        "ffmpeg",
        "-y",  # overwrite output without prompting
        "-i", str(source_path),
        "-ac", str(TARGET_CHANNELS),
        "-ar", str(TARGET_SAMPLE_RATE_HZ),
        "-sample_fmt", "s16",
        str(wav_path),
    ]

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=120,
        )
    except (subprocess.SubprocessError, OSError) as exc:
        raise AudioConversionError(f"ffmpeg failed to run: {exc}") from exc

    if result.returncode != 0 or not wav_path.exists():
        raise AudioConversionError(
            f"ffmpeg conversion failed (exit code {result.returncode}): {result.stderr[-2000:]}"
        )

    return wav_path
