---
title: "AI Features — iOS/macOS Validation"
spec-ref: docs/features/ai-features/spec.md
plan-refs:
  - docs/features/ai-features/ios-macos/plan.md
  - docs/features/ai-features/ios-macos/tasks.md
version: "2.0.0"
status: locked
updated: 2026-02-09
last-validated: null
---

# AI Features — Validation: Acceptance Criteria & Test Plan

> The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

---

## 1. Traceability Matrix

| Req ID | Requirement Summary | Keyword | Test Case IDs | Platform | Status |
|--------|-------------------|---------|---------------|----------|--------|
| FR-AI-01 | Tiered engine requirements (FM → llama.cpp → CoreML) | MUST | AC-A-01, AC-A-01b, AC-A-02, AC-A-03 | Both | — |
| FR-AI-02 | Email categorization (DistilBERT primary, LLM fallback) | MUST | AC-A-04, AC-A-04b | Both | — |
| FR-AI-03 | Smart reply (up to 3 suggestions) | MUST | AC-A-05 | Both | — |
| FR-AI-04 | Thread summarization (2-4 sentences) | MUST | AC-A-06 | Both | — |
| FR-AI-05 | Semantic search embeddings (all-MiniLM-L6-v2) | MUST | AC-A-07 | Both | — |
| FR-AI-06 | Spam and phishing detection (DistilBERT + rules) | MUST | AC-A-09 | Both | — |
| FR-AI-07 | AI processing pipeline (background queue) | MUST | AC-A-04b, AC-A-07, AC-A-09 | Both | — |
| G-04 | AI categorization, smart reply, summarization | MUST | AC-A-04, AC-A-05, AC-A-06 | Both | — |
| NFR-AI-01 | Categorization speed (< 5ms CoreML, < 500ms LLM) | MUST | Perf-01 | Both | — |
| NFR-AI-02 | Batch categorization speed (< 1s CoreML, < 30s LLM) | MUST | Perf-02 | Both | — |
| NFR-AI-03 | Smart reply speed (< 2s FM, < 5s llama.cpp, 8s hard limit) | MUST | Perf-03 | Both | — |
| NFR-AI-04 | Embedding generation speed (< 60s for 100 emails) | MUST | Perf-04 | Both | — |
| NFR-AI-05 | Memory during inference (< 200MB CoreML, < 500MB LLM) | MUST | Perf-05 | Both | — |
| NFR-AI-06 | Spam detection speed (< 10ms CoreML + rules) | MUST | Perf-06 | Both | — |

---

## 2. Acceptance Criteria

---

**AC-A-01**: llama.cpp Integration

- **Given**: The llama.cpp SPM package is added (via SpeziLLM or llama.swift)
- **When**: The project is built for iOS and macOS
- **Then**: The build **MUST** succeed on both platforms without errors
  AND a small GGUF model **MUST** load successfully
  AND a simple text generation prompt **MUST** return a coherent response
- **Priority**: Critical

---

**AC-A-01b**: CoreML Model Integration

- **Given**: DistilBERT (.mlpackage) and all-MiniLM-L6-v2 (.mlpackage) are bundled in the app
- **When**: The app launches
- **Then**: `CoreMLClassifier` **MUST** load both models without error
  AND classification via `classify(text:labels:)` **MUST** return a valid category
  AND embedding via `embed(text:)` **MUST** return a 384-dimensional float array
  AND inference **MUST** use the ANE on A14+ devices
- **Priority**: Critical

---

**AC-A-02**: AI Engine Abstraction + Resolution

- **Given**: An `AIEngineProtocol` with implementations: `FoundationModelEngine`, `LlamaEngine`
- **When**: `AIEngineResolver.resolveGenerativeEngine()` is called
- **Then**: On iOS 26+ with Apple Intelligence → `FoundationModelEngine` **MUST** be returned
  AND on iOS 18-25 with downloaded GGUF → `LlamaEngine` **MUST** be returned
  AND on devices with ≥ 6 GB RAM → Qwen3-1.7B model **MUST** be selected
  AND on devices with < 6 GB RAM → Qwen3-0.6B model **MUST** be selected (if downloaded)
  AND when no generative engine is available → `StubAIEngine` **MUST** be returned (graceful degradation)
- **Protocol shape** (canonical, per spec Section 7.1):
  - `isAvailable() -> Bool`
  - `generate(prompt:maxTokens:) -> AsyncStream<String>`
  - `classify(text:categories:) -> String`
  - `embed(text:) -> [Float]`
  - `unload()`
- **Priority**: Critical

---

**AC-A-03**: Model Manager

- **Given**: A `ModelManager` instance with no models downloaded
- **When**: Model management operations are performed
- **Then**: `availableModels()` **MUST** list models with name, size, license, and download status
  AND `downloadModel(id:)` **MUST** download the GGUF file via HTTPS with progress reporting (0-100%)
  AND downloads **MUST** be resumable (HTTP Range) and cancellable
  AND `verifyIntegrity(path:sha256:)` **MUST** validate SHA-256 checksum post-download
  AND verification failure **MUST** delete the corrupt file and prompt re-download
  AND `deleteModel(id:)` **MUST** remove the file and free storage
  AND `storageUsage()` **MUST** report total model storage accurately
  AND the app **MUST** display model source URL, file size, and license before download
- **Priority**: High

---

**AC-A-04**: Email Categorization

- **Given**: A synced email with subject "50% off shoes today only!"
- **When**: The categorization use case processes the email
- **Then**: The email **MUST** be categorized as `promotions`
  AND categorization **SHOULD** use `CoreMLClassifier` (DistilBERT) as primary path
  AND LLM-based classification **MUST** be available as fallback when CoreML is unavailable
  AND the category **MUST** be stored on `Email.aiCategory`
  AND the thread list **MUST** show the correct category badge
  AND the Promotions tab **MUST** include this thread
  AND manual re-categorization to `primary` **MUST** update the stored category
  AND `Thread.aiCategory` **MUST** be updated to reflect the latest email's category (derivation rule per spec Section 6)

**AC-A-04b**: Batch Categorization

- **Given**: 50 uncategorized emails after sync
- **When**: `AIProcessingQueue` runs background categorization
- **Then**: All 50 emails **MUST** be categorized within 60 seconds (hard limit)
  AND CoreML batch **SHOULD** complete within 1 second (target)
  AND the UI **MUST NOT** freeze during processing
  AND results **MUST** appear progressively in the thread list
- **Priority**: High

---

**AC-A-05**: Smart Reply

- **Given**: An email asking "Can you meet at 3pm tomorrow?"
- **When**: The smart reply use case is invoked
- **Then**: Up to 3 reply suggestions **MUST** be returned
  AND at least one suggestion **SHOULD** be affirmative
  AND at least one suggestion **SHOULD** be declining or alternative
  AND generation via Foundation Models **SHOULD** complete within 2 seconds (target)
  AND generation via llama.cpp **SHOULD** complete within 5 seconds (target)
  AND generation **MUST** complete within 8 seconds (hard limit)
  AND the UI **MUST NOT** block during generation (async streaming)
  AND tapping a suggestion **MUST** insert it into the composer body
  AND when no generative engine is available, smart reply UI **MUST** be hidden
- **Priority**: High

---

**AC-A-06**: Thread Summarization

- **Given**: A thread with 5 messages discussing a project deadline
- **When**: The summarize action is triggered
- **Then**: A summary of 2-4 sentences **MUST** be generated
  AND the summary **MUST** capture the key decision or action items
  AND the summary **MUST** be displayed at the top of the email detail
  AND the summary **MUST** be cached on `Thread.aiSummary` (not regenerated on revisit)
  AND threads with 3+ messages **SHOULD** auto-summarize on open
  AND on iOS 26+, Foundation Models `@Generable` structs **SHOULD** be used for structured output
  AND when no generative engine is available, summary card **MUST** be hidden
- **Priority**: High

---

**AC-A-07**: Semantic Search Embeddings

- **Given**: 100 synced emails with varied content
- **When**: The embedding pipeline runs during sync via `GenerateEmbeddingUseCase`
- **Then**: Each email **MUST** have a 384-dimensional embedding generated via all-MiniLM-L6-v2
  AND embeddings **MUST** be stored in the `SearchIndex` entity
  AND `VectorStore.search(query:limit:)` **MUST** return semantically similar emails
  AND the index **MUST** update incrementally as new emails are synced
  AND batch embedding of 100 emails **SHOULD** complete within 60 seconds
  AND when CoreML embedding model is unavailable, **MUST** fall back to FTS5 keyword search
- **Priority**: High

---

**AC-A-08**: AI Onboarding

- **Given**: The user is on the AI model download step in onboarding
- **When**: The user taps "Download"
- **Then**: The GGUF model download **MUST** start with a visible progress bar
  AND the model source URL, size, and license **MUST** be displayed before download
  AND the user **MUST** be able to skip without downloading
  AND if skipped, generative AI features (smart reply, summarization) **MUST** show a "Download model to enable" state
  AND classification features (categorization, spam) **MUST** still work (CoreML is bundled)
  AND after download completes, all AI features **MUST** begin working
- **Priority**: Medium

---

**AC-A-09**: Spam and Phishing Detection

- **Given**: An email with subject "Verify your account immediately" from "security@paypa1.com" containing a phishing URL
- **When**: The `DetectSpamUseCase` processes the email
- **Then**: The email **MUST** be flagged as spam/phishing
  AND detection **MUST** combine DistilBERT text classification with `RuleEngine` URL/header analysis
  AND the spam flag **MUST** be stored on `Email.isSpam`
  AND a visual warning **MUST** be shown in the thread list and email detail
  AND the email **MUST NOT** be auto-deleted
  AND the user **MUST** be able to mark it as "Not Spam" to override
  AND detection **SHOULD** complete within 10ms per email (CoreML/ANE + rules)
  AND when CoreML is unavailable, spam detection **MUST** be skipped (not crash)
- **Priority**: High

---

## 3. Edge Cases

| # | Scenario | Expected Behavior |
|---|---------|-------------------|
| E-01 | AI model file corrupted on disk | `verifyIntegrity()` fails; model deleted; user prompted to re-download |
| E-02 | App killed during AI inference | Model state cleaned up on next launch; no corrupt cache entries |
| E-03 | Insufficient RAM to load LLM | `LlamaEngine` returns `isAvailable() == false`; resolver falls back to stub; generative features hidden |
| E-04 | Network lost during model download | Download paused; resumed when connectivity returns (HTTP Range) |
| E-05 | Foundation Models unavailable (region/device) | `AIEngineResolver` falls back to llama.cpp; if no GGUF, falls to stub |
| E-06 | Email body contains prompt injection | `PromptTemplates` sanitizes HTML/scripts; LLM output validated for expected format |
| E-07 | Very long email thread (50+ messages) | Summarization truncates to most recent N messages within context window |
| E-08 | User deletes model while AI is running | Inference completes or cancels gracefully; model file deleted after unload |
| E-09 | CoreML ANE unavailable (A13 or older) | `CoreMLClassifier` falls back to CPU inference (~15ms vs 3.47ms) |
| E-10 | Batch of 1000+ emails after initial sync | `AIProcessingQueue` processes in batches of 50 with yields between batches |

---

## 4. Performance Validation

> **Source of truth**: Spec Section 4 (NFR-AI-01 through NFR-AI-06). Target and hard-limit values below match the spec. Warning and fail thresholds for memory (rows 9-10) are validation-specific additions not present in the spec NFRs — they provide operational guardrails between the spec targets and device limits.

| Metric | Target | Hard Limit | Measurement Method | Failure Threshold |
|--------|--------|------------|--------------------|-------------------|
| Categorization (CoreML/ANE, single) | < 5 ms | 2 s | Wall clock on A14+ device | Fails if > 2 s |
| Categorization (LLM fallback, single) | < 500 ms | 2 s | Wall clock on min-spec device | Fails if > 2 s |
| Batch categorization, 100 (CoreML) | < 1 s | 60 s | Wall clock for full batch | Fails if > 60 s |
| Batch categorization, 100 (LLM) | < 30 s | 60 s | Wall clock for full batch | Fails if > 60 s |
| Smart reply, 3 suggestions (FM) | < 2 s | 8 s | Wall clock | Fails if > 8 s |
| Smart reply, 3 suggestions (llama.cpp) | < 5 s | 8 s | Wall clock | Fails if > 8 s |
| Spam detection (CoreML + rules) | < 10 ms | 500 ms | Wall clock on A14+ | Fails if > 500 ms |
| Embedding generation, 100 emails | < 60 s | — | Background processing time | — |
| Memory during CoreML inference | < 200 MB above baseline | — | Instruments Allocations | **Warning** if > 200 MB; **Fails** if > 500 MB |
| Memory during LLM inference | < 500 MB above baseline | — | Instruments Allocations | **Warning** if > 500 MB; **Fails** if > 800 MB |

> **Threshold definitions**: "Warning" means investigation required but not a release blocker. "Fail" is a hard limit that blocks release. The gap between target and fail allows for measurement variance while catching genuine regressions.

---

## 5. Device Test Matrix

| Device | OS | Generative Engine | Classification | Expected Behavior |
|--------|----|------------------|----------------|-------------------|
| iPhone 15 Pro | iOS 26+ | Foundation Models | DistilBERT (ANE) | All features, zero download |
| iPhone 15 Pro | iOS 18 | Qwen3-1.7B (llama.cpp) | DistilBERT (ANE) | All features after GGUF download |
| iPhone SE 3rd | iOS 18 | Qwen3-0.6B (llama.cpp) | DistilBERT (ANE) | Acceptable generative quality |
| iPhone 12 | iOS 18 | Qwen3-0.6B or none | DistilBERT (ANE, A14) | Classification always works |
| MacBook Air M1 | macOS 26+ | Foundation Models | DistilBERT (ANE) | All features, zero download |
| MacBook Air M1 | macOS 14 | Qwen3-1.7B (llama.cpp) | DistilBERT (ANE) | All features after download |

---

## 6. Sign-Off

| Reviewer | Role | Date | Status |
|----------|------|------|--------|
| — | Spec Author | — | — |
| — | QA Lead | — | — |
| — | Engineering Lead | — | — |
