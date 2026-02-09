---
title: "Search — iOS/macOS Task Breakdown"
platform: iOS, macOS
plan-ref: docs/features/search/ios-macos/plan.md
version: "1.0.0"
status: draft
updated: 2025-02-07
---

# Search — iOS/macOS Task Breakdown

> Each task references its plan ID, spec section, and acceptance criteria. Status values: `todo`, `in-progress`, `done`, `blocked`.

> Note: Backend tasks IOS-A-14 through IOS-A-17 (embedding engine, vector store, search index manager, search use case) are tracked in the AI Features task file. This file tracks the search-specific UI task.

---

### IOS-A-14 to IOS-A-17: Semantic Search Backend (tracked in AI Features tasks)

> These backend tasks are defined and tracked in `docs/features/ai-features/ios-macos/tasks.md`. See that file for full deliverables, status, and spec refs.

| Task ID | Description | Tracked In |
|---------|-------------|------------|
| IOS-A-14 | `VectorStore` — embedding storage + cosine similarity | AI Features tasks |
| IOS-A-15 | `SearchIndexManager` — incremental index build during sync | AI Features tasks |
| IOS-A-16 | `GenerateEmbeddingUseCase` — batch embeddings via CoreML | AI Features tasks |
| IOS-A-17 | `SearchEmailsUseCase` — semantic + exact combined search | AI Features tasks |

### IOS-A-18: Search UI

- **Status**: `todo`
- **Spec ref**: Search spec, FR-SEARCH-01, FR-SEARCH-02, FR-SEARCH-03
- **Validation ref**: AC-A-07
- **Description**: Search bar, results display, and filters. Depends on backend tasks IOS-A-14..17.
- **Deliverables**:
  - [ ] `SearchView.swift` — search bar, results, filters
  - [ ] `SearchViewModel.swift`
  - [ ] Recent searches persistence
  - [ ] Unit and integration tests
