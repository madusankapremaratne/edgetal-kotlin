# EdgeTal — Private Talent Intelligence

**On-device candidate search. GDPR by design.**

This is the **Flutter** edition of EdgeTal — an agentic, on-device
Retrieval-Augmented-Generation app for talent discovery. It is a ground-up
rewrite of the original Kotlin/Android prototype (preserved on the
`kotlin-legacy` branch). Import resumes, run natural-language semantic search,
and generate candidate fit analyses with a local LLM — **without any data
leaving the device**.

The UI was redesigned for a modern, minimal, employer/HR audience in the
European market: calm Indigo + Slate palette, Inter typography, generous
whitespace, hairline borders, and an explicit privacy / GDPR posture throughout.

---

## Features

| Screen | What it does |
| --- | --- |
| **Candidates** | Local talent pool with stats (candidates / indexed / vectors), filter, delete |
| **Search** | On-device semantic vector search + **AI-assisted** query reformulation + feedback loop |
| **Candidate profile** | Sectioned resume with match highlighting and "Analyse fit with AI" |
| **AI fit analysis** | Local LLM evaluates a candidate against a pasted role (reasoning + verdict) |
| **Models** | Download / resume / delete the on-device Gemma model; embedder status |
| **Insights** | Retrieval-latency & precision benchmarks, evaluation suite, CSV export |
| **Import** | CSV import (URL or local file) — Kaggle / Extended / auto-detected formats |

The app **boots with sample European candidates already indexed**, so every
screen is explorable immediately.

---

## Architecture

```
lib/
├── app/            Composition root (Riverpod providers), router, theme entry, bootstrap/seed
├── core/           Design system (theme, palette, spacing), shared widgets, formatters
├── data/
│   ├── models/     Resume, ResumeEmbedding, SearchQuery, PerformanceMetric
│   ├── local/      LocalDatabase (JSON-file store; swappable for ObjectBox)
│   ├── repository/ ResumeRepository — the single persistence seam
│   └── importer/   CsvImporter (format detection + mapping)
└── domain/
    ├── embedding/  EmbeddingProvider + native (platform channel) + offline hashing fallback
    ├── llm/        LlmProvider + native bridge + mock; SearchAgent, CandidateAgent, downloads
    ├── search/     VectorSearchEngine (cosine; brute-force, HNSW-ready)
    ├── ingestion/  EmbeddingIngestionService
    └── monitor/    PerformanceMonitor
features/           One folder per screen: a Riverpod controller + its UI
```

- **State management:** Riverpod `StateNotifier`s mirror the original MVVM /
  `StateFlow` ViewModels one-to-one.
- **Navigation:** `go_router` `StatefulShellRoute` preserves per-tab stacks;
  adaptive shell (bottom `NavigationBar` on phones, `NavigationRail` on
  tablet/desktop).
- **Persistence:** a JSON-file-backed `LocalDatabase` keeps the app runnable
  with zero codegen or native build steps. It's isolated behind
  `ResumeRepository`, so moving to **ObjectBox** (with its native HNSW vector
  index, like the original) only touches those two files.

## On-device ML

The original used **MediaPipe Text Embedder** and **MediaPipe LLM Inference**
(Gemma-2B Int4). There is no drop-in Flutter package for these, so EdgeTal
bridges to them over **platform channels**, with graceful fallbacks:

| Capability | Native (production) | Fallback (runs everywhere) |
| --- | --- | --- |
| Embeddings | `edgetal/embedder` → MediaPipe Text Embedder | Deterministic hashing embedder (lexical) |
| Generation | `edgetal/llm` → MediaPipe LLM (Gemma-2B) | Heuristic structured responses |

Every AI result is **badged** in the UI as *on-device model* vs *offline
heuristic*, so nothing is ever misrepresented.

### Android — implemented ✅

The native pipeline is live and validated on a physical device:
`EmbedderChannel.kt` / `LlmChannel.kt` call MediaPipe (`tasks-text` /
`tasks-genai` 0.10.18), `text_embedder.tflite` ships in
`android/app/src/main/assets/`, and the app auto-detects the model's true
embedding dimension. When the active embedder changes (offline fallback →
on-device), stored embeddings are **automatically re-indexed** so query and
document vectors share the same space. Download the Gemma model in-app from the
**Models** screen (resumable, ~1.3 GB) to enable on-device generation.

### iOS / macOS — stubbed

`AppDelegate.swift` (iOS) and `MainFlutterWindow.swift` (macOS) register the same
channels; they currently return `notImplemented`, so the app falls back to the
offline providers. Implement with the MediaPipe iOS/macOS frameworks to match
Android.

### Persistence — JSON store (ObjectBox swap pending)

Persistence is a JSON-file `LocalDatabase` behind `ResumeRepository`. Swapping in
**ObjectBox** with its native HNSW vector index (like the original) is the one
remaining seam and touches only those two files plus the search engine.

---

## Running

```bash
cd edgetal
flutter pub get
flutter run            # phone, tablet, or desktop
flutter test           # unit tests + app-boot smoke test
flutter analyze        # clean
```

> Web is not a target: the local store and downloads use `dart:io`. Build for
> Android / iOS / macOS.

## License

MIT — see the parent repository.
