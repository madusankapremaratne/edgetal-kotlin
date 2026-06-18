# EdgeTal: On-Device Agentic RAG for Talent Discovery

   

**EdgeTal** (Repo: `edgetal-kotlin`) is a native Android research prototype that demonstrates **Agentic Retrieval-Augmented Generation (RAG)** entirely on the edge.

It acts as an autonomous "Pocket Recruiter," allowing users to index thousands of resumes, perform semantic searches ("Find a leader with Python skills"), and generate deep profile analyses using a quantized Large Language Model (LLM)—all without a single byte of data leaving the device.

## 🚀 Key Innovation: The "Talent Scout Agent"

Unlike passive keyword search tools, EdgeTal operates as an agentic system with a three-stage cognitive loop:

1.  **Plan (Query Translation)**: Maps abstract intents (e.g., "Creative roles") to high-dimensional vector space.
2.  **Decide (Vector Ranking)**: Autonomously scans a local **ObjectBox** vector store to rank candidates by semantic fit.
3.  **Act (Generative Analysis)**: Uses **Gemma-2B** (Int4 Quantized) to read the candidate's resume and write a "Strengths & Weaknesses" report.

-----

## 📊 Real-World Performance Benchmarks

Validated on **Google Pixel 7 Pro (Tensor G2)** and **Redmi Note 7 (Snapdragon 660)** at $N = 1,500$ embeddings.

### 1\. Retrieval Latency (The "Fast" Loop)

*Dataset: Kaggle Resume Dataset (N=1,500)*

| Query / Search Type | Google Pixel 7 Pro | Redmi Note 7 | Status / Target |
| :--- | :---: | :---: | :--- |
| **Raw Vector Search** | **11.9 ms** | **53.6 ms** | 🟢 Real-Time (< 200 ms) |
| **Static Semantic Search** | **59.3 ms** | **266.9 ms** | 🟢 Near Real-Time |
| **Keyword Baseline** | **535.8 ms** | **2,411.1 ms** | 🟡 CPU Batch Search |

> **Result:** The system achieves the research target of **\<200ms** semantic search latency on mainstream hardware.

### 2\. Generative Analysis & Reformulation (The "Deep" Loop)

*Model: Gemma-2B (Int4) via MediaPipe LLM API*

| Task / Phase | Google Pixel 7 Pro | Redmi Note 7 | Gap / Bottleneck |
| :--- | :---: | :---: | :---: |
| **Query Reformulation** | **6.7 s** | **48.2 s** | $7.2\times$ performance gap |
| **Generative Inference (Act)** | **42.4 s** | **305.3 s (5.1 min)** | $7.2\times$ performance gap (Bottleneck) |

> **Architecture Note:** Due to the heavy computational cost, Generation is handled as an asynchronous background task ("Report Queue"), ensuring the UI remains responsive.

-----

## 🛠 Technology Stack

  * **Language**: Kotlin 1.9.20 (Coroutines + Flow)
  * **Vector Store**: [ObjectBox 3.7.0](https://objectbox.io/) (NoSQL Edge Database)
  * **Embeddings**: Google MediaPipe Text Embedder (MobileNet v3, 384-dim)
  * **LLM Inference**: **Google MediaPipe LLM API** (running `gemma-2b-it-cpu-int4.bin`)
  * **Architecture**: MVVM with Clean Architecture (Domain/Data/UI layers)
  * **DI**: Hilt 2.48

-----

## 📂 Project Structure

```bash
EdgeTal/
├── app/
│   ├── src/main/assets/
│   │   ├── text_embedder.tflite       # For Vector Search
│   │   └── gemma-2b-it-cpu-int4.bin   # For Generative Analysis (Large File)
│   ├── src/main/java/com/knovik/skillvault/
│   │   ├── domain/
│   │   │   ├── agent/                 # Agentic Logic
│   │   │   │   └── TalentScoutAgent.kt
│   │   │   ├── embedding/             # MediaPipe Embedder
│   │   │   └── llm/                   # Gemma-2B Interface
│   │   ├── data/
│   │   │   └── local/                 # ObjectBox Entities
│   │   └── ui/
│   │       ├── search/                # Semantic Search UI
│   │       └── analysis/              # Generative Report UI
```

-----

## ⚡ Setup & Installation

**Prerequisites:**

  * Android Studio Iguana or later
  * Device with **4GB+ RAM** (required for LLM inference)
  * Android API 26+

### 1\. Clone & Sync

```bash
git clone https://github.com/madusankapremaratne/edgetal-kotlin.git
cd edgetal-kotlin
```

### 2\. Build & Run

```bash
./gradlew installDebug
```

The text embedder (`text_embedder.tflite`) is bundled in `app/src/main/assets/`, so semantic search works out of the box.

### 3\. Download the LLM (In-App — Recommended)

Open the **Models** tab in the app and tap **Download Model (~1.3 GB)**. The app downloads `gemma-2b-it-cpu-int4.bin` directly from Hugging Face into its private storage — no adb or cables needed.

  * **Resumable:** Interrupted downloads continue where they left off.
  * **Custom source:** Under *Advanced*, paste any direct download URL (e.g. a Hugging Face `resolve` link). For gated repos such as the official [google/gemma](https://huggingface.co/google/gemma-2b-it), accept the license on Hugging Face and paste a read access token.
  * **Storage:** The Models tab also shows the installed size and lets you delete the model to free space.

### 4\. Deploying the LLM via adb (Alternative)

If you already have the model file on your computer (e.g. from [Kaggle Models](https://www.kaggle.com/models/google/gemma)), you can push it manually instead:

**Step 1: Push the model to temporary storage**
Push the model to `/data/local/tmp/` first (the most reliable location for large files):

```bash
adb push gemma-2b-it-cpu-int4.bin /data/local/tmp/
```

**Step 2: Move to App Internal Storage**
The app expects the model in its private internal storage for performance and permissions. Use `run-as` to move it:

```bash
# Create the directory
adb shell "run-as com.knovik.skillvault mkdir -p /data/data/com.knovik.skillvault/files"

# Copy the file
adb shell "run-as com.knovik.skillvault cp /data/local/tmp/gemma-2b-it-cpu-int4.bin /data/data/com.knovik.skillvault/files/"

# Verify (optional)
adb shell "run-as com.knovik.skillvault ls -lh /data/data/com.knovik.skillvault/files/"
```

**Step 3: Cleanup**
Remove the temporary file from `/data/local/tmp/`:

```bash
adb shell rm /data/local/tmp/gemma-2b-it-cpu-int4.bin
```

> [!TIP]
> If you have multiple devices connected, add `-s <device-id>` (e.g., `adb -s 2B131FDH3000XK push ...`) to specify the target.

Either way, the app loads the model from its internal `filesDir` (see `LlmInferenceProvider.kt` / `ModelDownloadManager.kt`).

-----

## 📖 Usage Workflow

### 1\. Ingestion (The Knowledge Base)

Import the Kaggle Resume CSV. The app automatically chunks text and generates 384-dimensional vectors stored in ObjectBox.

### 2\. Semantic Search (The Scout)

Type a natural language query: *"Find me a project manager who knows Agile and Python."*

  * **Under the hood:** The agent converts your query to a vector and performs a Cosine Similarity search.
  * **Output:** Ranked list of candidates with "Fit Scores."

### 3\. Deep Analysis (The Analyst)

Click the **"AI Analyze"** button on a candidate profile.

  * **Under the hood:** The app loads Gemma-2B into RAM. It feeds the resume text into a prompt: *"Analyze this resume for a [Role]. List strengths and missing skills."*
  * **Output:** A generated text report appears after processing.

-----

## 🔬 Research Context

This project was developed as part of the research paper:
**"Benchmarking On-Device Agentic RAG for Privacy-Preserving Talent Discovery"**

  * **Problem:** Cloud LLMs violate GDPR when processing resumes.
  * **Solution:** Move the entire "Recruiter Brain" (Indexing + Retrieval + Reasoning) to the Edge.
  * **Dataset:** [Kaggle Resume Dataset](https://www.kaggle.com/datasets/saugataroyarghya/resume-dataset)

## License

MIT License.

**Project Lead**: Madusanka Premaratne Rathnayake Mudiyanselage
**Contact**: [rmmpremaratne@gmail.com]
**GitHub Issues**: [https://github.com/madusankapremaratne/edgetal-kotlin/issues](https://github.com/madusankapremaratne/edgetal-kotlin/issues)
