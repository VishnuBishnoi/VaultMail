---
title: "Thread List — iOS/macOS Validation"
spec-ref: docs/features/thread-list/spec.md
plan-refs:
  - docs/features/thread-list/ios-macos/plan.md
  - docs/features/thread-list/ios-macos/tasks.md
version: "1.1.0"
status: draft
last-validated: null
---

# Thread List — Validation: Acceptance Criteria & Test Plan

> The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

---

## 1. Traceability Matrix

| Req ID | Requirement Summary | Keyword | Test Case IDs | Platform | Status |
|--------|-------------------|---------|---------------|----------|--------|
| FR-TL-01 | Thread display + pagination | MUST | AC-U-02, AC-U-03 | Both | — |
| FR-TL-02 | Category filtering | MUST | AC-U-02 | Both | — |
| FR-TL-03 | Gestures and interactions | MUST | AC-U-04 | Both | — |
| FR-TL-04 | Folder + account navigation | MUST | AC-U-05, AC-U-12 | Both | — |
| FR-TL-05 | Navigation flows | MUST | AC-U-01 | Both | — |
| NFR-TL-01 | Scroll performance (60 fps) | MUST | PERF-01 | Both | — |
| NFR-TL-02 | List load time (< 200ms) | MUST | PERF-02 | Both | — |
| NFR-TL-03 | Accessibility (WCAG 2.1 AA) | MUST | AC-U-06 | Both | — |
| NFR-TL-04 | Memory (≤ 50MB above baseline) | MUST | PERF-03 | Both | — |
| G-02 | Multiple Gmail accounts | MUST | AC-U-12 | Both | — |
| G-03 | Threaded conversation view | MUST | AC-U-02 | Both | — |

---

## 2. Acceptance Criteria

---

**AC-U-01**: iOS Navigation

- **Given**: The app is launched on iOS with at least one account
- **When**: The user navigates between screens
- **Then**: Thread list **MUST** be the root view
  AND tapping a thread **MUST** push the email detail view
  AND tapping compose **MUST** present the composer as a sheet
  AND tapping search **MUST** present the search view
  AND tapping settings **MUST** push or present the settings view
  AND tapping a folder **MUST** update the thread list for that folder
  AND back navigation **MUST** work consistently
- **Priority**: Critical

---

**AC-U-02**: Thread List

- **Given**: An account with synced emails
- **When**: The thread list is displayed
- **Then**: Threads **MUST** be sorted by most recent message date (newest first)
  AND each row **MUST** display: sender name, subject, snippet, timestamp, unread indicator, star indicator, attachment indicator
  AND category tabs **MUST** filter threads by AI category (hidden when AI unavailable)
  AND each category tab **MUST** show an unread badge count when > 0
  AND the list **MUST** paginate in pages of 25, auto-loading on scroll
  AND the list **MUST** scroll at 60fps with no visible jank
  AND the view **MUST** show appropriate states: loading, empty, error, offline
  AND empty state **MUST** display an appropriate message
- **Priority**: Critical

---

**AC-U-03**: Thread Row

- **Given**: A thread with known properties (unread, starred, has attachment, categorized)
- **When**: The thread row is rendered
- **Then**: Unread threads **MUST** display bold sender name, bold subject, and a blue dot indicator
  AND starred threads **MUST** display a filled star icon
  AND threads with attachments **MUST** display a paperclip icon
  AND the category badge **MUST** show the correct category (hidden for uncategorized)
  AND the timestamp **MUST** display relative time (e.g., "2:30 PM", "Yesterday", "Feb 5")
  AND multi-participant threads **MUST** show count suffix (e.g., "John, Sarah (3)")
  AND VoiceOver **MUST** announce all visible information as a single coherent label
  AND all text **MUST** scale correctly with Dynamic Type at all sizes
- **Priority**: High

---

**AC-U-04**: Thread List Interactions

- **Given**: The thread list is displayed
- **When**: The user performs gestures
- **Then**: Pull-to-refresh **MUST** trigger an incremental sync and update the list
  AND swipe right on a thread **MUST** archive it with a 5-second undo toast
  AND swipe left on a thread **MUST** delete it (move to Trash) with a 5-second undo toast
  AND partial swipe left **MUST** reveal delete + "more" actions
  AND long-press **MUST** enter multi-select mode with checkboxes
  AND in multi-select mode, batch archive/delete/mark-read/star **MUST** work on all selected threads
  AND if a swipe action fails on server, the UI **MUST** revert and show an error toast
- **Priority**: High

---

**AC-U-05**: Folder Navigation + Outbox

- **Given**: An account with synced folders and queued outbox emails
- **When**: The user navigates folders
- **Then**: System folders **MUST** be displayed: Inbox, Starred, Sent, Drafts, Spam, Trash, Outbox
  AND each folder **MUST** show appropriate badge count (unread for Inbox/Spam, draft count for Drafts, queued+failed for Outbox)
  AND custom Gmail labels **MUST** appear below system folders, sorted alphabetically
  AND selecting a folder **MUST** update the thread list to show that folder's threads
  AND Outbox **MUST** display queued/sending/failed emails with send state
  AND failed Outbox items **MUST** allow retry; queued items **MUST** allow cancel
- **Priority**: High

---

**AC-U-06**: Accessibility

- **Given**: The thread list is displayed with VoiceOver enabled and/or large Dynamic Type
- **When**: The user interacts via VoiceOver or uses large text sizes
- **Then**: Every thread row **MUST** have a single, coherent accessibility label announcing: sender, subject, snippet, time, and status indicators
  AND all text **MUST** scale from extra small to accessibility 5 (xxxLarge) without clipping or layout breaks
  AND contrast ratios **MUST** meet 4.5:1 for normal text, 3:1 for large text/icons
  AND unread, starred, and category indicators **MUST** use shape/icon in addition to color
  AND swipe actions **MUST** be accessible via VoiceOver custom actions
  AND if "Reduce Motion" is enabled, swipe animations **SHOULD** use cross-dissolve
- **Priority**: High

---

**AC-U-12**: Multi-Account

- **Given**: Two Gmail accounts are configured
- **When**: The user navigates the app
- **Then**: The account switcher **MUST** list both accounts with email, avatar, and unread count
  AND selecting an account **MUST** show that account's Inbox
  AND a unified inbox option **MUST** show threads from both accounts merged by date
  AND threads in unified view **MUST** indicate which account they belong to
  AND composing a new email **MUST** default to the selected account (or the configured default)
- **Priority**: High

---

## 3. Edge Cases

| # | Scenario | Expected Behavior |
|---|---------|-------------------|
| E-01 | Empty inbox (new account, no emails) | Empty state with illustration + "No emails" message + pull-to-refresh hint |
| E-02 | AI categorization unavailable | Category tab bar hidden; all threads in single list |
| E-03 | Thread list with 500+ threads | LazyVStack pagination; scroll at 60fps; memory ≤ 50MB above baseline |
| E-04 | Swipe archive fails (server error) | UI reverts; error toast "Couldn't archive. Tap to retry." |
| E-05 | Network offline while viewing thread list | "You're offline" banner; cached data shown; pull-to-refresh disabled |
| E-06 | Unified inbox with 3+ accounts | All threads merged by date; each shows account indicator; no duplicates |
| E-07 | Dynamic Type at accessibility xxxLarge | Layout adapts; no text clipping; sender name and snippet truncate gracefully |
| E-08 | Outbox with mix of queued/sending/failed | Each shows correct state; failed shows retry; queued shows cancel |

---

## 4. Performance Validation

| Metric | Target | Hard Limit | Measurement Method | Failure Threshold |
|--------|--------|------------|--------------------|-------------------|
| Thread list scroll FPS | 60 fps | 30 fps | Instruments Core Animation on iPhone SE 3rd gen with 500+ threads | Fails if drops below 30fps for >1s |
| List load time (cached) | < 200ms | 500ms | Time from `onAppear` to first rendered frame | Fails if > 500ms on 3 runs |
| Memory (500+ threads) | ≤ 50MB | 100MB | Xcode Memory Debugger after scrolling 500 threads | Fails if > 100MB above baseline |

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
