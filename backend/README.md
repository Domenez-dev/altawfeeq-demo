# التوفيق (Al-Tawfeeq) — Backend

A Python/FastAPI backend for **التوفيق**, a voice-based screening tool that
analyzes sustained-vowel recordings ("آآآ") to extract acoustic biomarkers
(F0, jitter, shimmer, intensity, duration) using **Praat** (via
[parselmouth](https://parselmouth.readthedocs.io/)), and produces a composite
vocal-health score, a 3-way classification (معاف / في طريق المرض / مريض), and
Arabic feedback. This is an MVP/prototype — not a medical diagnostic device.

## Tech stack

FastAPI · parselmouth (Praat) · SQLAlchemy + SQLite · Pydantic v2 · ffmpeg ·
python-jose + passlib (JWT auth) · uvicorn

## Setup

1. **Install ffmpeg** (required for audio preprocessing):
   - Arch: `sudo pacman -S ffmpeg`
   - Debian/Ubuntu: `sudo apt install ffmpeg`
   - macOS: `brew install ffmpeg`

2. **Create and activate a virtualenv:**
   ```bash
   cd backend
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

## Running

```bash
uvicorn main:app --reload
```

The API will be available at `http://127.0.0.1:8000`, and interactive Swagger
docs at **http://127.0.0.1:8000/docs**.

The SQLite database (`altawfeeq.db`) and an `uploads/` directory for stored
recordings are created automatically on first run.

## Seeding test data

```bash
python seed.py
```

This **resets** the database and inserts three premade test users with fake
session histories (so reports/trends have something to show). Credentials are
printed to the console after seeding:

| Name  | Email                     | Password      | Notes                                         |
|-------|---------------------------|---------------|-----------------------------------------------|
| محمد  | mohamed@altawfeeq.dz      | password123   | 7 sessions over ~5 weeks, mixed results       |
| فاطمة | fatima@altawfeeq.dz       | password123   | 5 sessions, generally healthy/improving trend |
| ليلى  | layla@altawfeeq.dz        | password123   | 6 sessions, deteriorating trend over time     |

Use `POST /api/auth/login` with one of these email/password pairs to get a JWT,
then click **Authorize** in `/docs` (or send `Authorization: Bearer <token>`)
to call the protected endpoints.

## Tunable parameters — read before adjusting scoring behavior

This is a prototype whose acoustic-analysis and classification parameters are
**assumptions or early-research-derived values**, not clinically validated
thresholds. Every such value is marked in the source with a clearly visible
`TUNABLE PARAMETER` comment block explaining its current value, suggested
range, and the impact of changing it. Look for these blocks in:

- **`services/praat.py`** — pitch floor/ceiling, minimum recording duration,
  pitch analysis time step, silence-trimming threshold.
- **`services/classifier.py`** — F0/jitter/shimmer normal-vs-Alzheimer
  baselines, intensity/duration "ideal range" assumptions, per-metric scoring
  weights, and the healthy/at-risk/sick classification thresholds.
- **`services/feedback.py`** — the subscore threshold used to decide whether a
  metric-specific remark is surfaced to the user.
- **`services/reports.py`** — the score thresholds used to bucket sessions
  into the "good / average / weak" pie-chart distribution.

**⚠️ Male baseline caveat:** The F0/jitter/shimmer reference baselines in
`services/classifier.py` are derived from research on **female subjects only**.
Classification results for male users are therefore a rough approximation —
male voices naturally have lower F0 and may show different healthy jitter/
shimmer ranges. Do not treat male results as equally validated until
male-specific baselines are added.

## Notes

- Schedules (`/api/schedules`) are CRUD-only — there is no scheduler loop or
  push-notification delivery. APScheduler is installed and imported but not
  wired up; see the `# TODO: wire up APScheduler + FCM push notifications here`
  comment in `models/schedule.py` and `routers/schedules.py`.
- Errors are returned as structured JSON: `{ "detail": "...", "code": "..." }`,
  with custom codes such as `AUDIO_TOO_SHORT`, `AUDIO_QUALITY_POOR`,
  `INVALID_FORMAT`, `PRAAT_ANALYSIS_FAILED`, `SESSION_NOT_FOUND`, etc.
- Uploaded recordings are stored under `uploads/` with `uuid4`-based filenames.
