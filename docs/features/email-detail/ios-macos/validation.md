---
title: "Email Detail — iOS/macOS Validation"
spec-ref: docs/features/email-detail/spec.md
plan-refs:
  - docs/features/email-detail/ios-macos/plan.md
  - docs/features/email-detail/ios-macos/tasks.md
version: "1.2.0"
status: locked
last-validated: null
---

# Email Detail — Validation: Acceptance Criteria & Test Plan

> The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

---

## 1. Traceability Matrix

| Req ID | Requirement Summary | Keyword | Test Case IDs | Platform | Status |
|--------|-------------------|---------|---------------|----------|--------|
| FR-ED-01 | Thread display + actions + mark read | MUST | AC-U-08 | Both | — |
| FR-ED-02 | AI integration (summary + smart reply) | MUST | AC-U-11 | Both | — |
| FR-ED-03 | Attachment handling + security | MUST | AC-U-10 | Both | — |
| FR-ED-04 | HTML rendering safety | MUST | AC-U-09 | Both | — |
| FR-ED-05 | Large thread handling (pagination) | MUST | AC-U-08 | Both | — |
| NFR-ED-01 | Email open time (< 300ms) | MUST | PERF-01 | Both | — |
| NFR-ED-02 | Large thread performance | MUST | PERF-02 | Both | — |
| NFR-ED-03 | Accessibility (WCAG 2.1 AA) | MUST | AC-U-08, AC-U-09, AC-U-10 | Both | — |
| NFR-ED-04 | HTML sanitization performance (< 50ms) | MUST | PERF-03 | Both | — |
| G-01 | Threaded conversation display | MUST | AC-U-08 | Both | — |
| G-02 | HTML safety (sanitization + tracking) | MUST | AC-U-09 | Both | — |
| G-03 | Attachment security | MUST | AC-U-10 | Both | — |
| G-05 | Accessibility | MUST | AC-U-08, AC-U-09, AC-U-10 | Both | — |

---

## 2. Acceptance Criteria

---

**AC-U-08**: Email Detail View

- **Given**: The user taps a thread with 5 messages (3 read, 2 unread)
- **When**: The email detail view opens
- **Then**: All 5 messages **MUST** be displayed in chronological order
  AND the 3 read messages **SHOULD** be collapsed
  AND the latest unread message **MUST** be expanded
  AND the thread **MUST** be marked as read (all messages marked via MarkReadUseCase)
  AND reply, reply-all, forward buttons **MUST** be visible in the toolbar
  AND tapping a collapsed message **MUST** expand it
  AND star toggle **MUST** update immediately (optimistic update)
  AND tapping archive **MUST** show 5-second undo toast and navigate back to thread list
  AND tapping delete **MUST** show 5-second undo toast and navigate back to thread list
  AND "Mark Unread" in overflow **MUST** mark the thread unread and navigate back
  AND VoiceOver **MUST** navigate each message as a unit, announcing sender, timestamp, status
  AND all non-HTML text **MUST** scale correctly with Dynamic Type at all sizes
- **Priority**: Critical

---

**AC-U-09**: Message Rendering + HTML Safety

- **Given**: An email with HTML body containing `<script>` tags, 2 tracking pixels (1x1 images), 3 remote images, and quoted text from a previous reply
- **When**: The message is displayed
- **Then**: HTML content **MUST** render correctly with formatting preserved
  AND `<script>`, `<iframe>`, `<form>` elements **MUST** be removed
  AND event handler attributes (onclick, onerror, etc.) **MUST** be stripped
  AND remote images **MUST** be blocked by default with placeholder displayed
  AND a "Load Remote Images" action **MUST** be available per message
  AND tracking pixels **MUST** be stripped with count displayed (e.g., "2 trackers blocked")
  AND tracking pixels **MUST** remain stripped even after "Load Remote Images" is tapped
  AND links **MUST** open in the system default browser
  AND long-press on a link **SHOULD** show the destination URL preview
  AND quoted text **SHOULD** be collapsed with a "Show quoted text" expander
  AND tapping "Show quoted text" **MUST** expand the quoted content without network request
  AND plain text emails **MUST** render with preserved line breaks
  AND if sanitization fails, the plain text body **MUST** be shown as fallback
  AND WKWebView **MUST** have JavaScript disabled
- **Priority**: Critical

---

**AC-U-10**: Attachment Handling + Security

- **Given**: An email with 3 attachments: 1 image (500 KB), 1 PDF (10 MB), 1 `.exe` file (2 MB)
- **When**: The email detail is displayed
- **Then**: All 3 attachments **MUST** show filename, type, and size
  AND no attachment **MUST** auto-download
  AND tapping download on the image **MUST** show a progress indicator and download to sandbox
  AND tapping download on the `.exe` file **MUST** display a security warning before proceeding
  AND after download, tapping the image **MUST** show a QuickLook preview
  AND after download, tapping the PDF **MUST** show a QuickLook preview
  AND the share button **MUST** open the system share sheet
  AND downloaded files **MUST** be stored in the app's sandbox directory
  AND cancelling a download **MUST** clean up partial data
  AND if download fails after retries, a "Retry" button **MUST** be shown
  AND VoiceOver **MUST** announce each attachment with name, size, and download state
- **Priority**: High

---

**AC-U-10b**: Cellular Attachment Download

- **Given**: An email with a 30 MB attachment and the device is on a cellular network
- **When**: The user taps download
- **Then**: A warning **MUST** appear: "This attachment is 30 MB. Download on cellular?"
  AND the warning **MUST** have "Download" and "Cancel" options
  AND tapping "Download" **MUST** proceed with the download
  AND tapping "Cancel" **MUST** abort the download
- **Priority**: High

---

**AC-U-11**: AI Integration

- **Given**: A thread is opened with AI features available (model downloaded, device supported)
- **When**: The email detail view loads
- **Then**: The thread **MUST** render immediately without waiting for AI results
  AND an AI summary **SHOULD** appear at the top of the thread when ready
  AND smart reply suggestions **SHOULD** appear at the bottom when ready
  AND if AI generation fails, the summary and suggestion areas **MUST** be hidden (no error shown to user)
  AND tapping a smart reply **MUST** navigate to the Composer with pre-filled text
- **Priority**: Medium

---

## 3. Edge Cases

| # | Scenario | Expected Behavior |
|---|---------|-------------------|
| E-01 | Large thread (100+ messages) | Paginate: load 25 most recent initially; "Show earlier messages" button at top; no OOM; scroll position preserved when loading more |
| E-02 | Email with malformed HTML (unclosed tags, encoding tricks) | Render safely; no crash; fallback to plain text if sanitization produces empty output |
| E-03 | Email with only HTML body (no plain text alternative) | Render HTML normally; HTML-stripped text used for snippet if needed |
| E-04 | Very large attachment (50MB+) on cellular network | Show cellular download warning before proceeding; security warning also shown if dangerous type |
| E-05 | Offline with uncached email body | Show "Message body not available offline" placeholder for uncached messages; cached messages still visible with full content |
| E-06 | Tracking pixels with "Load Remote Images" enabled | Tracking pixels still stripped even when remote images are allowed; tracker count still displayed |
| E-07 | Email with `cid:` inline images | Show placeholder with indication inline images not available in V1; not counted as tracking pixels |
| E-08 | Thread with 0 messages (data corruption) | Display "This conversation appears empty" message + back navigation to thread list |
| E-09 | Email with deeply nested quoted text (10+ reply levels) | Collapsed by default; expanding shows all levels without layout break or clipping |
| E-10 | Mark-as-read fails on server sync | Revert to unread state locally; show error toast: "Couldn't mark as read. Tap to retry." |
| E-11 | Archive action fails after navigating back | Cancel back-navigation; revert optimistic update; show error toast with retry |
| E-12 | Email from trusted sender (per-sender "Always Load") | Remote images load automatically; tracking pixels still stripped |

---

## 4. Performance Validation

| Metric | Target | Hard Limit | Measurement Method | Failure Threshold |
|--------|--------|------------|--------------------|-------------------|
| Email open (cached, 5 messages) | < 300ms | 500ms | Time from thread row tap to first message content visible on iPhone SE 3rd gen | Fails if > 500ms on 3 consecutive runs |
| Large thread (100+ messages) | Smooth scroll | No OOM | Load 100-message thread on iPhone SE 3rd gen; scroll through all messages | Fails if crash or memory > 200MB above baseline |
| HTML sanitization (single email) | < 50ms | 200ms | Time to sanitize average HTML email (50KB body) on iPhone SE 3rd gen | Fails if > 200ms on 10 consecutive emails |

---

## 5. Device Test Matrix

Refer to Foundation validation Section 5 for shared device test matrix.

---

## 6. Sign-Off

| Reviewer | Role | Date | Status |
|----------|------|------|--------|
| — | Spec Author | — | — |
| — | QA Lead | — | — |
| — | Engineering Lead | — | — |
