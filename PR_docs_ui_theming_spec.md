# PR Title
Comprehensive UI theming engine + multi-account sync reliability + macOS background helper

## PR Body
## Summary
This branch delivers three major tracks:
1. A new app-wide theming engine with selectable themes and global font-size controls across iOS/macOS UI surfaces.
2. Reliability and correctness improvements for sync (multi-account allocation, catch-up/pagination, background scheduling, notification coordination, and thread/detail loading behavior).
3. macOS background execution improvements via a new helper target, login/background state coordination, and helper polling refinements.

It also includes onboarding/composer/search/settings/thread-list UI refinements, MIME/sanitization fixes, and extensive test/documentation updates.

## Scope
- 25 commits ahead of `main`
- 146 files changed
- 8,714 insertions / 2,052 deletions

## What Changed
### 1) App-wide theming foundation
- Added a complete theme system under `Shared/Theme/*`:
  - `ThemeProvider`, `ThemeRegistry`, `VaultMailTheme`
  - color/spacing/typography/shape abstractions
  - concrete themes: Default, Forest, Lavender, Midnight, Rose, Sunset
  - shared view modifiers for theme application
- Added global font-size domain model and settings persistence support (`AppFontSize`, `SettingsStore` updates).
- Introduced reusable settings UI components for theme selection (`ThemePickerCell`).
- Applied theme/font improvements across major SwiftUI surfaces:
  - thread list + row components
  - email detail and message rendering
  - composer screens
  - onboarding flow
  - search UI
  - settings pages
  - macOS sidebar/settings/main views

### 2) Sync architecture and behavior hardening
- Improved `SyncEmailsUseCase` with staged catch-up flow and pagination robustness.
- Added sync/catch-up state modeling (`SyncCatchUpStatus`) and folder coordination (`FolderSyncCoordinator`).
- Refined fetch/use-case behavior for thread and detail loading (`FetchThreadsUseCase`, `FetchEmailDetailUseCase`).
- Improved multi-account IDLE + notification coordination and refresh handling.
- Hardened iOS background scheduling and diagnostics (`BackgroundSyncScheduler`).
- Added background execution coordination primitives (`BackgroundExecutionArbiter`, shared background state store).
- Reduced helper poll interval on macOS and aligned reliability alerts/notification delivery reporting.

### 3) macOS helper + app lifecycle integration
- Added a dedicated `MailBackgroundHelper` target with assets, entitlements, plist, and app entrypoint.
- Added helper poller (`MacBackgroundHelperPoller`) and login-item management (`MacLoginItemManager`).
- Updated app/project configuration and entitlements to support background helper lifecycle.

### 4) Message handling and content correctness
- MIME decoding and HTML sanitization improvements (`MIMEDecoder`, `HTMLSanitizer`) including quoted-printable cleanup fixes.
- Reply action alignment improvements across platforms.
- Improved thread detail loading performance and related repository paths.

### 5) UX and platform consistency improvements
- Composer refresh work (including macOS search-indexing integration merge).
- macOS sidebar/settings typography and visual refinements.
- Notification settings and account/settings polish.
- Onboarding path improvements and simulator-specific onboarding build-path fixes.

### 6) Tests and docs
- Added/expanded tests for:
  - theming engine (`ThemeEngineTests`)
  - background execution arbiter and scheduler
  - sync use case behavior
  - macOS thread list/main view pagination
  - MIME/HTML sanitizer and notification paths
  - async/deadlock and undo-send stability fixes
- Updated documentation for sync feature plans/tasks/validation/spec.
- Added dedicated UI theming specification doc (`docs/features/ui-theming/spec.md`).

## Key Files/Areas
- App/theme architecture:
  - `VaultMailPackage/Sources/VaultMailFeature/Shared/Theme/*`
  - `VaultMailPackage/Sources/VaultMailFeature/Shared/Services/SettingsStore.swift`
- Sync + background:
  - `VaultMailPackage/Sources/VaultMailFeature/Domain/UseCases/SyncEmailsUseCase.swift`
  - `VaultMailPackage/Sources/VaultMailFeature/Data/Sync/BackgroundSyncScheduler.swift`
  - `VaultMailPackage/Sources/VaultMailFeature/Shared/Background/*`
  - `VaultMailPackage/Sources/VaultMailFeature/Data/Sync/MacBackgroundHelperPoller.swift`
- macOS helper target:
  - `MailBackgroundHelper/*`
  - `VaultMail.xcodeproj/project.pbxproj`
- UI adoption across features:
  - `Presentation/ThreadList/*`, `Presentation/EmailDetail/*`, `Presentation/Composer/*`, `Presentation/Settings/*`, `Presentation/macOS/*`
- Documentation:
  - `docs/features/ui-theming/spec.md`
  - `docs/features/email-sync/*`

## Notes
- Branch includes one merge commit from `codex/composer-refresh-macos-search` to incorporate composer + macOS search flow updates.
- `.claude/settings.local.json` is part of the current diff; consider excluding if it is environment-local and not intended for shared history.

## Suggested Validation Checklist
- Build and smoke test iOS + macOS targets.
- Verify theme switching and font-size propagation across thread list, detail, composer, search, onboarding, and settings.
- Validate multi-account sync catch-up behavior and pagination under load.
- Validate macOS helper lifecycle (launch/login item/polling/background notifications).
- Confirm quoted-printable/HTML rendering correctness in message detail.
- Run full `VaultMailFeatureTests` suite.
