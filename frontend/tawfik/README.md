# Taoufik

**Taoufik** is a voice-based screening tool for the early detection of **Mild
Cognitive Impairment (MCI / الضعف الإدراكي البسيط)** and **Alzheimer's disease**.
The user records a few seconds of a sustained vowel — the long "آآآ" sound — and
the app analyses the recording, extracts acoustic biomarkers, and returns a
simple, Arabic screening result:

- **سليم معرفياً (CU – Cognitively Unimpaired)** — voice indicators are within
  the normal range.
- **ضعف إدراكي بسيط (MCI)** — some indicators are borderline; follow-up advised.
- **مريض** — indicators are concerning; a specialist should be consulted.

> ⚠️ Taoufik is a **screening aid, not a medical diagnosis**. Any result should
> be confirmed by a qualified specialist.

---

## 1. The idea behind it

Speech is one of the earliest functions affected by cognitive decline. Long
before a clinical diagnosis, subtle changes appear in **how** a person speaks:
the voice becomes less stable, pauses grow longer and more frequent, speech
slows down, and the voice loses some of its "clean" harmonic quality. These
measurable changes are called **speech / vocal biomarkers**.

Taoufik turns a phone microphone into a lightweight biomarker scanner. Because
sustaining a vowel ("آآآ") is an easy, language-independent task that anyone can
repeat, it is well suited to a short, repeatable home test.

---

## 2. What the app measures (the 7 biomarkers)

From a single sustained-vowel recording, the backend extracts **seven acoustic
biomarkers**, grouped into the standard categories used in the speech-biomarker
literature. Each one has a *normal* reference range and a *suspect* rule.

### Bloc 2 — Phonation (إنتاج الصوت)

| Biomarker | Normal (سليم) | Suspect | What it means |
|---|---|---|---|
| **Jitter** (الاضطراب) | < 1 % (0.2 – 1 %) | > 1 % (Alzheimer often 1–3 %+) | Cycle-to-cycle irregularity of pitch — neural control of the voice |
| **Shimmer** (اضطراب الشدة) | < 4 % (0.5 – 3 %) | > 4 % (Alzheimer often 3–8 %) | Cycle-to-cycle irregularity of loudness — voice stability |
| **HNR** (نسبة التوافقيات إلى الضجيج) | > 20 dB | < 20 dB | Harmonics-to-noise ratio — how "clean" vs noisy the voice is |

### Bloc 3 — Prosody (الإيقاع والتنغيم)

| Biomarker | Normal (سليم) | Suspect | What it means |
|---|---|---|---|
| **F0 mean** (الطبقة الصوتية) | Men 120–180 Hz / Women 220–300 Hz | Instability / abnormal pitch | Average fundamental frequency |
| **F0 SD** (تباين الطبقة) | Low & stable on "آآآ" | Large swings (tremor/instability) on a sustained vowel | Pitch variability / stability |

### Helper indicators (مؤشرات مساعدة)

| Biomarker | Normal (سليم) | Suspect | What it means |
|---|---|---|---|
| **Intensity** (شدة الصوت) | 70 – 80 dB | Lower & unstable | Loudness / breath support |
| **Duration** (المدة) | 3 – 8 s comfortable | Very short | Ability to sustain the vowel |

### Bloc 1 — Temporal (التوقيت الزمني) — *reference only*

The three temporal biomarkers below are the **strongest evidence** in the
literature, but they require **connected speech** (reading a sentence), not a
sustained vowel. They are therefore shown in the app as **reference information
only** and are *not* measured by the current sustained-vowel test:

| Biomarker | Normal (سليم) | MCI suspect | Alzheimer suspect |
|---|---|---|---|
| **Speech rate** (معدل الكلام) | 3.5 – 5.5 syll/s (≈120–160 wpm) | < 3.5 syll/s | < 2.8 syll/s |
| **Mean pause duration** (متوسط مدة التوقفات) | 0.20 – 0.60 s | 0.60 – 1.00 s | > 1.00 s |
| **Pause ratio** (نسبة التوقفات) | < 20 % | > 25 % | > 25 % |

> **Important caveat (phonation):** Jitter, Shimmer and HNR are sensitive to the
> microphone, hoarseness/inflammation, fatigue, vocal-cord problems, and the
> recording conditions. They are used as *supporting* indicators only and are
> never relied on alone.

---

## 3. How the algorithm works

The pipeline turns raw audio into a single screening decision in four stages.

```
recording (آآآ)  ─►  1. Feature extraction (Praat)
                 ─►  2. Per-biomarker scoring (0–100)
                 ─►  3. Weighted composite score (0–100)
                 ─►  4. Three-way classification (CU / MCI / مريض)
```

### Stage 1 — Feature extraction (Praat)

The uploaded audio is converted to WAV, leading/trailing silence is trimmed, and
**Praat** (via the `parselmouth` Python library) extracts the raw values: F0 and
its standard deviation, jitter, shimmer, HNR, mean intensity, and duration.
A recording that is too short, too quiet, or too unstable to analyse is rejected
with a clear Arabic message instead of producing an unreliable result.

### Stage 2 — Per-biomarker scoring (0–100)

Each raw value is mapped to a **0–100 subscore** against reference anchors:

- **Jitter, Shimmer** — lower is better; the score falls linearly from a clean
  "normal" anchor toward an "Alzheimer" anchor.
- **HNR** — higher (cleaner) is better; high dB → high score.
- **F0 mean** — scored as a healthy *band* (covers normal male and female
  pitch); only abnormally high/low pitch is penalised.
- **F0 SD** — on a sustained vowel a *stable* pitch is healthy, so a low SD
  scores high and a large SD (instability) scores low.
- **Intensity, Duration** — scored as a smooth peak around an ideal value.

### Stage 3 — Composite score

The subscores are combined into one **overall score (0–100)** using weights that
favour the voice-quality measures the sustained vowel captures most reliably:

| Biomarker | Weight |
|---|---|
| Jitter | 0.20 |
| F0 mean | 0.18 |
| HNR | 0.17 |
| Shimmer | 0.15 |
| F0 SD | 0.10 |
| Intensity | 0.10 |
| Duration | 0.10 |

If a biomarker is unavailable (e.g. an older recording without HNR/F0-SD), its
weight is redistributed over the remaining ones, so the score always stays on
the same 0–100 scale.

### Stage 4 — When does it decide "ill" vs "not"?

The overall score is bucketed into the three-way result using two thresholds:

| Overall score | Result |
|---|---|
| **≥ 70** | **سليم معرفياً (CU)** — normal |
| **40 – 70** | **ضعف إدراكي بسيط (MCI)** — borderline / follow-up |
| **< 40** | **مريض** — concerning, see a specialist |

In parallel, the app surfaces *per-indicator* flags (e.g. "Jitter > 1 %",
"HNR < 20 dB") so the user and clinician can see **which** biomarkers drove the
result, not just the final label. Short, encouraging Arabic feedback is
generated from the same subscores.

> The thresholds and reference anchors are **heuristic and tunable**. They are
> documented in the backend (every value sits under a `TUNABLE PARAMETER` block)
> and are meant to be replaced with sex-specific, clinically validated reference
> data as it becomes available.

### Expected performance (from the literature)

For distinguishing **MCI** from **healthy controls (CU)** using speech/voice
biomarkers, the literature reports roughly:

- Accuracy ≈ 80 %
- Sensitivity ≈ 80 %
- Specificity ≈ 77–80 %
- AUC ≈ 78 %

These figures describe the biomarker approach in general and are a realistic
target ceiling for a sustained-vowel-only screening test, which captures the
phonation/prosody biomarkers but not the (stronger) temporal ones.

---

## 4. App architecture

Taoufik is a three-tier application; the backend and database are deployed
online so the mobile app works from anywhere.

```
┌─────────────────────┐        HTTPS/JSON        ┌──────────────────────────────┐
│   Flutter app       │  ───────────────────►    │   FastAPI backend (Python)   │
│   (Android)         │   record + upload WAV    │                              │
│                     │  ◄───────────────────    │   • Praat / parselmouth      │
│  • record "آآآ"     │   scores + classification│     (acoustic analysis)      │
│  • show 7 indicators│                          │   • scoring + classification │
│  • CU / MCI / مريض  │                          │   • Arabic feedback          │
│  • history & reports│                          │                              │
└─────────────────────┘                          └───────────────┬──────────────┘
                                                                  │ SQLAlchemy
                                                                  ▼
                                                       ┌──────────────────────┐
                                                       │   Database (Postgres) │
                                                       │   users + sessions    │
                                                       └──────────────────────┘
```

### Frontend — Flutter (this folder)

- Records the sustained vowel as PCM, writes a WAV, and uploads it.
- Displays the screening result in Arabic (CU / MCI / مريض), the seven
  biomarkers with their status, per-indicator history charts, daily/weekly
  reports, and educational reference content (including the temporal biomarkers).
- State management with **Riverpod**; networking with **Dio**.
- The API base URL is configurable at build time:
  `flutter run --dart-define=API_BASE_URL=http://<host>:8000/api`

### Backend — FastAPI + Praat (`../../backend`)

- `POST /api/analysis/analyze` runs the full pipeline (convert → extract →
  score → classify → store) and returns the session with its biomarkers,
  composite score, classification, and Arabic feedback.
- Acoustic analysis uses **Praat** through `parselmouth`.
- Other endpoints serve the home dashboard, session history, indicator detail +
  history, and weekly/monthly reports.

### Database — Postgres (via SQLAlchemy)

- Stores users and every analysis **session** (raw biomarkers + subscores +
  classification + feedback), which powers the history and trend reports.
- New biomarker columns are added by an idempotent startup migration, so
  deploying a newer backend over an existing database needs no manual step.

### Deployment

The backend (FastAPI + Praat) and the database run on an online server; the
Flutter app talks to it over the network. Updating the screening logic therefore
means **deploying the backend and running the (automatic) migration** — the app
itself stays compatible with both the old and new server responses.

---

## 5. Repository layout

```
frontend/tawfik/   ← this Flutter app
  lib/
    screens/       UI (voice test, result, history, reports, info, about…)
    services/      API client (Dio)
    models/        API + local data models
    providers/     Riverpod state
    utils/         indicator_helpers.dart — biomarker reference + classification
backend/           ← FastAPI + Praat (deployed online)
  routers/         analysis, sessions, home, reports…
  services/        praat.py, classifier.py, feedback.py, indicators.py
  models/          SQLAlchemy models (users, sessions)
```

---

## 6. Running locally

**Backend**

```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt        # FastAPI, parselmouth, SQLAlchemy…
python seed.py                         # optional: demo users + history
uvicorn main:app --reload --port 8000
```

**Frontend**

```bash
cd frontend/tawfik
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```
