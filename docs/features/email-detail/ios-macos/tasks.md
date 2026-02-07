---
title: "Email Detail — iOS/macOS Task Breakdown"
platform: iOS, macOS
plan-ref: docs/features/email-detail/ios-macos/plan.md
version: "1.2.0"
status: locked
updated: 2026-02-07
---

# Email Detail — iOS/macOS Task Breakdown

> Each task references its plan ID, spec section, and acceptance criteria. Status values: `todo`, `in-progress`, `done`, `blocked`.

---

### IOS-U-08: Email Detail View

- **Status**: `todo`
- **Spec ref**: Email Detail spec, FR-ED-01, FR-ED-05
- **Validation ref**: AC-U-08
- **Description**: Implement the threaded email detail view with expand/collapse, mark-as-read, thread actions, view states, and large thread pagination. MV pattern — no ViewModels.
- **Deliverables**:
  - [ ] `EmailDetailView.swift` — scrollable message thread (uses @State, @Environment, .task)
  - [ ] Expand/collapse individual messages; auto-expand latest unread, collapse read (FR-ED-01)
  - [ ] If all messages read, expand latest message (FR-ED-01)
  - [ ] Mark-as-read on open via `MarkReadUseCase` — optimistic + server sync (FR-ED-01 / FR-SYNC-10)
  - [ ] Thread actions toolbar: reply, reply-all, forward, star, archive, delete (FR-ED-01)
  - [ ] Optimistic update + revert on failure for star/archive/delete (FR-SYNC-10 / FR-SYNC-05)
  - [ ] Undo toast for archive and delete (5-second window) (FR-ED-01)
  - [ ] Navigate back to thread list on archive/delete (FR-ED-01)
  - [ ] Mark Unread via overflow menu → navigate back to thread list (FR-ED-01)
  - [ ] View states: loading, loaded, error, offline, empty-defensive (FR-ED-01)
  - [ ] Large thread pagination: load 25 most recent, "Show earlier messages" button (FR-ED-05)
  - [ ] Scroll position preserved when loading earlier messages (FR-ED-05)
  - [ ] VoiceOver: each message navigable as unit, announce sender/timestamp/status (NFR-ED-03)
  - [ ] VoiceOver custom actions: expand/collapse, reply, star (NFR-ED-03)
  - [ ] Dynamic Type for all non-HTML text (NFR-ED-03)
  - [ ] Reduce Motion: cross-dissolve for expand/collapse animations (NFR-ED-03)
  - [ ] SwiftUI previews for all view states

### IOS-U-09: Message Bubble + HTML Rendering

- **Status**: `todo`
- **Spec ref**: Email Detail spec, FR-ED-01, FR-ED-04
- **Validation ref**: AC-U-09
- **Description**: Implement individual email message display with HTML sanitization, tracking pixel detection, remote content blocking, quoted text collapsing, and link safety.
- **Deliverables**:
  - [ ] `MessageBubbleView.swift` — sender, recipients, timestamp, body, attachments (FR-ED-01)
  - [ ] `MessageHeaderView.swift` — sender avatar (initials + color), name, To/CC display (collapsed by default, expandable) (FR-ED-01)
  - [ ] Collapsed message row: sender name, timestamp, one-line snippet (FR-ED-01)
  - [ ] `HTMLEmailView.swift` — WKWebView with JS disabled, no cookies/storage access (FR-ED-04)
  - [ ] `HTMLSanitizer.swift` — strip scripts, iframes, forms, event handlers, dangerous URIs (FR-ED-04)
  - [ ] `TrackingPixelDetector.swift` — detect 1x1/0x0 images, known domains, hidden elements (FR-ED-04)
  - [ ] Tracking domain blocklist bundled as static JSON file (FR-ED-04)
  - [ ] Remote content blocking with "Load Remote Images" per-message button (FR-ED-04)
  - [ ] Per-sender "Always Load" preference — TrustedSender entity in SwiftData (FR-ED-04)
  - [ ] Tracking pixels still stripped even when remote images loaded (FR-ED-04)
  - [ ] Tracker count display per message: "N trackers blocked" (FR-ED-04)
  - [ ] `QuotedTextDetector.swift` — detect `>` prefix, `<blockquote>`, `gmail_quote` (FR-ED-01)
  - [ ] Quoted text collapsed by default with "Show quoted text" expander (FR-ED-01)
  - [ ] Link handling: open in system browser, not within WKWebView (FR-ED-04)
  - [ ] Link safety: long-press shows destination URL (iOS); hover tooltip (macOS) (FR-ED-04)
  - [ ] CID inline images: placeholder with "not available" indication (FR-ED-03)
  - [ ] Plain text fallback when sanitization fails or produces empty output (FR-ED-04)
  - [ ] Dynamic Type CSS injection for WKWebView font-size override (NFR-ED-03)
  - [ ] Color independence: star uses icon shape, not just color (NFR-ED-03)
  - [ ] Unit tests for HTMLSanitizer with real-world HTML samples
  - [ ] Unit tests for TrackingPixelDetector
  - [ ] Unit tests for QuotedTextDetector
  - [ ] SwiftUI previews for collapsed/expanded, HTML/plain text, with/without tracking

### IOS-U-10: Attachment Handling

- **Status**: `todo`
- **Spec ref**: Email Detail spec, FR-ED-03
- **Validation ref**: AC-U-10
- **Description**: Implement attachment display, download with progress, security warnings, cellular warning, QuickLook preview, and share sheet.
- **Deliverables**:
  - [ ] `AttachmentRowView.swift` — metadata display (name, type, size, download state) (FR-ED-03)
  - [ ] Download on explicit user tap only — no auto-download (FR-ED-03)
  - [ ] Download progress indicator (determinate if size known, indeterminate otherwise) (FR-ED-03)
  - [ ] Security warning for dangerous file types before download (FR-ED-03)
  - [ ] Cellular download warning for attachments ≥ 25 MB (FR-ED-03 / FR-SYNC-08)
  - [ ] Cellular + security warnings stack (both shown when applicable) (FR-ED-03)
  - [ ] Download cancel: clean up partial file, reset isDownloaded (FR-ED-03)
  - [ ] Download error with "Retry" button after 3 retry failures (FR-ED-03 / FR-SYNC-08)
  - [ ] `AttachmentPreviewView.swift` — QuickLook preview for images, PDFs (sandboxed) (FR-ED-03)
  - [ ] Share sheet integration via system share button (FR-ED-03)
  - [ ] Sandboxed storage within app directory (FR-ED-03)
  - [ ] macOS drag-and-drop for downloaded attachments (Foundation Section 7.2)
  - [ ] VoiceOver: attachment name, size, download state accessible (NFR-ED-03)

### IOS-U-11: AI Integration

- **Status**: `todo`
- **Spec ref**: Email Detail spec, FR-ED-02
- **Validation ref**: AC-U-11
- **Description**: Implement AI summary display and smart reply suggestions with async loading and graceful fallback.
- **Deliverables**:
  - [ ] AI summary section at top of thread via `SummarizeThreadUseCase` (FR-ED-02)
  - [ ] Subtle loading indicator while AI is processing (FR-ED-02)
  - [ ] Smart reply suggestions at bottom of thread via `SmartReplyUseCase` (FR-ED-02)
  - [ ] Smart reply fade-in animation when ready (FR-ED-02)
  - [ ] Async loading: thread renders immediately, AI content appears when ready (FR-ED-02)
  - [ ] Graceful hiding when AI unavailable or fails — no error shown (FR-ED-02)
  - [ ] Tapping a smart reply navigates to Composer with pre-filled text (FR-ED-02)
