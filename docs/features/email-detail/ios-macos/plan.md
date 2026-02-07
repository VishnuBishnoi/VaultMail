---
title: "Email Detail — iOS/macOS Implementation Plan"
platform: iOS, macOS
spec-ref: docs/features/email-detail/spec.md
version: "1.2.0"
status: locked
assignees:
  - Core Team
target-milestone: V1.0
---

# Email Detail — iOS/macOS Implementation Plan

---

## 1. Scope

This plan covers the email detail screen implementation: threaded message display with expand/collapse, HTML rendering with sanitization, tracking pixel detection, attachment handling with security, thread-level actions (reply, star, archive, delete), large thread pagination, quoted text collapsing, and AI integration points (summary + smart reply).

---

## 2. Platform Context

Refer to Foundation plan Section 2 for OS versions, device targets, and platform guidelines.

---

## 3. Architecture Mapping

### Email Detail Layout

```
┌──────────────────────────────────────────────────────────┐
│ ← Back    Thread Subject                        ★  ⋯    │
├──────────────────────────────────────────────────────────┤
│ [AI Summary — async, collapsible]                        │
├──────────────────────────────────────────────────────────┤
│ [Show earlier messages]  (if 50+ messages)               │
├──────────────────────────────────────────────────────────┤
│ ▸ Alice (collapsed) — snippet...             Feb 3       │
├──────────────────────────────────────────────────────────┤
│ ▸ Bob (collapsed) — snippet...               Feb 4       │
├──────────────────────────────────────────────────────────┤
│ ▾ Charlie (expanded)                         Feb 5       │
│   To: Alice, Bob  CC: Dave                               │
│   ┌────────────────────────────────────────┐             │
│   │ HTML email body (WKWebView, JS off)    │             │
│   │ [🖼 Remote images blocked] [Load]       │             │
│   │ [▸ Show quoted text]                   │             │
│   └────────────────────────────────────────┘             │
│   📎 report.pdf (2.1 MB) [Download] [Share]              │
│   📎 photo.jpg (500 KB) [Download] [Share]               │
│   🛡 3 trackers blocked                                   │
├──────────────────────────────────────────────────────────┤
│ [Smart Reply: "Thanks!" | "Got it" | "Will do"]         │
├──────────────────────────────────────────────────────────┤
│ [↩ Reply]  [↩↩ Reply All]  [↪ Forward]   [⋯ More]      │
└──────────────────────────────────────────────────────────┘
```

### Files

| File | Layer | Purpose |
|------|-------|---------|
| `EmailDetailView.swift` | Presentation/Views | Scrollable threaded message view (uses @State, @Environment, .task) |
| `MessageBubbleView.swift` | Presentation/Views | Individual message display (sender, body, timestamp, attachments) |
| `MessageHeaderView.swift` | Presentation/Components | Sender avatar, name, recipients, timestamp per message |
| `AttachmentRowView.swift` | Presentation/Components | Attachment metadata display + download action + progress |
| `AttachmentPreviewView.swift` | Presentation/Components | QuickLook preview wrapper (sandboxed) |
| `HTMLEmailView.swift` | Presentation/Components | WKWebView wrapper with sanitized HTML rendering (JS disabled) |
| `HTMLSanitizer.swift` | Domain/Utilities | HTML sanitization engine (strip scripts, forms, tracking pixels) |
| `TrackingPixelDetector.swift` | Domain/Utilities | Detect and strip 1x1 images, known tracking domains, hidden elements |
| `QuotedTextDetector.swift` | Domain/Utilities | Detect reply chains in plain text and HTML |

**Note**: Per CLAUDE.md, this feature uses the MV (Model-View) pattern. No ViewModels — view logic uses `@State`, `@Environment`, `@Observable` services, and `.task` modifiers. Per Foundation FR-FOUND-01, views **MUST** call domain use cases only — never repositories directly.

---

## 4. Implementation Phases

| Task ID | Description | Spec FRs | Dependencies |
|---------|-------------|----------|-------------|
| IOS-U-08 | Email detail view + thread actions + pagination | FR-ED-01, FR-ED-05 | IOS-U-01 (Navigation Router) |
| IOS-U-09 | Message bubble + HTML rendering + sanitization + quoted text | FR-ED-01, FR-ED-04 | IOS-U-08 |
| IOS-U-10 | Attachment handling + download + preview + security | FR-ED-03 | IOS-U-08 |
| IOS-U-11 | AI integration (summary + smart reply) | FR-ED-02 | IOS-U-08, AI Features spec |

---

## 5. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| HTML sanitization edge cases (malformed HTML, encoding tricks) | Medium | High | Build comprehensive test suite with real-world email HTML samples; use established sanitization patterns |
| WKWebView memory with many messages in thread | Medium | Medium | Lazy-load WKWebViews; reuse single instance with content swapping; paginate at 50+ messages (FR-ED-05) |
| Dynamic Type in WKWebView not scaling correctly | Medium | Medium | Inject CSS font-size override based on Dynamic Type setting; test at all accessibility sizes |
| Tracking pixel false positives (legitimate 1x1 images) | Low | Low | Keep blocklist conservative; per-message "Load Images" action as override |
| Quoted text detection accuracy (non-standard formats) | Medium | Low | Support common markers (>, blockquote, gmail_quote); accept imperfect detection for edge cases |
