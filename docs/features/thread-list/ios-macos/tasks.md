---
title: "Thread List — iOS/macOS Task Breakdown"
platform: iOS, macOS
plan-ref: docs/features/thread-list/ios-macos/plan.md
version: "1.1.0"
status: draft
updated: 2026-02-07
---

# Thread List — iOS/macOS Task Breakdown

> Each task references its plan ID, spec section, and acceptance criteria. Status values: `todo`, `in-progress`, `done`, `blocked`.

---

### IOS-U-01: iOS Navigation Structure

- **Status**: `todo`
- **Spec ref**: Thread List spec, FR-TL-05
- **Validation ref**: AC-U-01
- **Description**: Set up iOS navigation using NavigationStack with programmatic path-based routing. MV pattern — no ViewModels.
- **Deliverables**:
  - [ ] `NavigationRouter.swift` — @Observable route state, path-based navigation
  - [ ] Root NavigationStack with thread list as landing screen
  - [ ] Route definitions for: Email Detail, Composer (sheet), Search, Settings, Account Switcher (sheet), Folder Navigation
  - [ ] Deep link support structure (for future use)
  - [ ] Unit tests for router state transitions

### IOS-U-02: Thread List View

- **Status**: `todo`
- **Spec ref**: Thread List spec, FR-TL-01, FR-TL-02
- **Validation ref**: AC-U-02
- **Description**: Implement the main thread list screen with MV pattern (@State, @Environment, .task).
- **Deliverables**:
  - [ ] `ThreadListView.swift` — LazyVStack of thread rows with cursor-based pagination (25/page, FR-TL-01)
  - [ ] `CategoryTabBar.swift` — horizontal tab bar (All, Primary, Social, Promotions, Updates) with unread badges (FR-TL-02)
  - [ ] View states: loading, loaded, empty (no threads), empty (filtered), error, offline (FR-TL-01)
  - [ ] AI unavailability fallback: hide category tabs entirely (FR-TL-02)
  - [ ] Automatic next-page loading on scroll near bottom (FR-TL-01)
  - [ ] Inline error banner with retry for sync/pagination failures
  - [ ] SwiftUI previews for all states

### IOS-U-03: Thread Row Component

- **Status**: `todo`
- **Spec ref**: Thread List spec, FR-TL-01, NFR-TL-03
- **Validation ref**: AC-U-03
- **Description**: Implement the thread row UI component with full accessibility.
- **Deliverables**:
  - [ ] `ThreadRowView.swift` — sender name(s), subject, snippet, timestamp (FR-TL-01)
  - [ ] `AvatarView.swift` — initials + generated color, stack up to 2 for multi-participant (FR-TL-01)
  - [ ] Unread indicator: bold sender + bold subject + blue dot (FR-TL-01)
  - [ ] Star indicator: filled star icon when starred (FR-TL-01)
  - [ ] Attachment indicator: paperclip icon (FR-TL-01)
  - [ ] `CategoryBadgeView.swift` — colored pill badge, hidden for uncategorized (FR-TL-01)
  - [ ] Relative timestamp formatting: "2:30 PM", "Yesterday", "Mon", "Feb 5", "Feb 5, 2025" (FR-TL-01)
  - [ ] Dynamic Type support: all text scales, layout adapts at all sizes (NFR-TL-03)
  - [ ] VoiceOver: single coherent accessibilityLabel per row (NFR-TL-03)
  - [ ] Color independence: unread/star/category use shape+color, not color alone (NFR-TL-03)
  - [ ] SwiftUI previews for all variant combinations

### IOS-U-04: Thread List Interactions

- **Status**: `todo`
- **Spec ref**: Thread List spec, FR-TL-03
- **Validation ref**: AC-U-04
- **Description**: Implement pull-to-refresh, swipe gestures, and multi-select with batch actions.
- **Deliverables**:
  - [ ] Pull-to-refresh triggering incremental sync (Email Sync FR-SYNC-02)
  - [ ] Swipe right: archive with optimistic update + 5s undo toast (FR-TL-03 / FR-SYNC-10)
  - [ ] Swipe left: delete with optimistic update + 5s undo toast (FR-TL-03 / FR-SYNC-10)
  - [ ] Swipe left partial: reveal delete + "more" button (Mark Read/Unread, Star, Move)
  - [ ] Server sync failure → revert UI + error toast with retry (FR-TL-03)
  - [ ] Long-press for multi-select mode with checkboxes (FR-TL-03)
  - [ ] Batch action toolbar: Archive, Delete, Mark Read, Mark Unread, Star, Move (FR-TL-03)
  - [ ] Select All / Deselect All toggle (FR-TL-03)
  - [ ] Batch partial failure handling: report count, keep failed selected (FR-TL-03)
  - [ ] Reduce Motion: cross-dissolve for swipe animations (NFR-TL-03)

### IOS-U-05: Folder Navigation + Outbox

- **Status**: `todo`
- **Spec ref**: Thread List spec, FR-TL-04
- **Validation ref**: AC-U-05
- **Description**: Implement folder sidebar, system folders, custom labels, and virtual Outbox view.
- **Deliverables**:
  - [ ] `FolderSidebarView.swift` — system folders (Inbox, Starred, Sent, Drafts, Spam, Trash) with badges (FR-TL-04)
  - [ ] Custom Gmail labels below system folders, sorted alphabetically (FR-TL-04)
  - [ ] `OutboxRowView.swift` — queued/sending/failed emails with send state display (FR-TL-04 / FR-SYNC-07)
  - [ ] Outbox: retry action for failed, cancel for queued (FR-TL-04)
  - [ ] Folder selection updates thread list filter (FR-TL-04)
  - [ ] Badge shows "—" when count unavailable (FR-TL-04 error handling)

### IOS-U-12: Account Switcher

- **Status**: `todo`
- **Spec ref**: Thread List spec, FR-TL-04
- **Validation ref**: AC-U-12
- **Description**: Multi-account navigation and unified inbox.
- **Deliverables**:
  - [ ] `AccountSwitcherView.swift` — sheet with account list (email, avatar, unread count)
  - [ ] Per-account thread list: selecting account switches to that account's Inbox
  - [ ] Unified inbox: all accounts merged, sorted by `latestDate`
  - [ ] Account indicator per thread in unified view (colored dot or small avatar)
  - [ ] Compose defaults to selected account (or configured default)
