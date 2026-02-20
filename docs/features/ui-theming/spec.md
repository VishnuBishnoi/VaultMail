---
title: "UI Theming Engine — Specification"
version: "1.0.0"
status: draft
created: 2026-02-20
updated: 2026-02-20
authors:
  - Core Team
reviewers: []
tags: [ui, theming, design-tokens, typography, colors, spacing, accessibility]
depends-on:
  - docs/constitution.md
  - docs/features/foundation/spec.md
  - docs/features/settings-onboarding/spec.md
  - docs/features/thread-list/spec.md
---

# Specification: UI Theming Engine

> The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**, **SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**, and **OPTIONAL** in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

## 1. Summary

This specification defines a centralized theming engine for VaultMail. It replaces all inline `Color`, `Font`, and spacing literals scattered across ~60 SwiftUI views with semantic **design tokens** resolved through a single `ThemeProvider`. The engine ships with **6 built-in accent themes** users can switch instantly from Settings. Visual direction draws from WhatsApp (comfortable spacing, generous touch targets) and X/Twitter (minimalist typography, clean cards, subtle dividers).

**Brand color**: `#2596BE` (Cerulean Ocean Blue)

---

## 2. Goals and Non-Goals

### Goals

- **G-01**: Replace all hardcoded Color/Font/spacing values with semantic design tokens
- **G-02**: Ship a `ThemeProvider` that resolves tokens per-theme at runtime via `@Observable` + `@Environment`
- **G-03**: Provide 6 built-in themes with distinct accent colors, each supporting light and dark modes
- **G-04**: Adopt WhatsApp-like comfortable spacing (generous padding, 44pt minimum touch targets, spacious list rows)
- **G-05**: Adopt X/Twitter-like minimalist typography (clean hierarchy, subtle weight differences, no decorative fonts)
- **G-06**: Preserve all 181+ existing accessibility annotations
- **G-07**: Allow theme switching with zero app restart — immediate re-render on selection
- **G-08**: Provide reusable `ViewModifier` extensions (`vmCard`, `vmChip`, etc.) for consistent component styling

### Non-Goals (V1)

- **NG-01**: Custom font bundles — SF Pro (system) covers all needs
- **NG-02**: Per-view theme overrides — one global theme applies everywhere
- **NG-03**: User-created themes or theme editor (deferred to V2)
- **NG-04**: Redesigning navigation structure or information architecture
- **NG-05**: Animated theme transitions (theme change is instant, no cross-fade)

---

## 3. Theming Engine Architecture

### FR-TH-01: Theme Protocol

The application **MUST** define a `VaultMailTheme` protocol as the contract for all themes:

```swift
protocol VaultMailTheme: Sendable {
    var id: String { get }
    var displayName: String { get }
    var previewColor: Color { get }      // Accent color for picker circles

    var colors: ThemeColors { get }
    var typography: ThemeTypography { get }
    var spacing: ThemeSpacing { get }
    var shapes: ThemeShapes { get }
}
```

Each concrete theme **MUST** implement all token groups. The `previewColor` **MUST** return the theme's accent color for the Settings theme picker UI.

### FR-TH-02: ThemeProvider

The application **MUST** provide a `ThemeProvider` class that:

1. Is annotated `@Observable @MainActor`
2. Holds a `current: VaultMailTheme` property
3. Exposes convenience accessors: `colors`, `typography`, `spacing`, `shapes`
4. Provides an `apply(_ themeId: String)` method that swaps the current theme
5. Is injected at the app root via `.environment(themeProvider)`
6. Is accessed in views via `@Environment(ThemeProvider.self)`

Theme changes via `apply()` **MUST** trigger immediate re-render of all views that read theme tokens — no app restart required (G-07).

### FR-TH-03: ThemeRegistry

The application **MUST** provide a `ThemeRegistry` enum that:

1. Contains a static `allThemes: [VaultMailTheme]` array with all 6 built-in themes
2. Provides a `theme(for id: String) -> VaultMailTheme` lookup that falls back to the default theme if the ID is unknown
3. Returns themes in display order: VaultMail, Midnight, Forest, Sunset, Lavender, Rose

### FR-TH-04: Light/Dark Resolution

Each theme **MUST** define color values for both light and dark color schemes. The resolution strategy:

1. Themes provide color values using SwiftUI `Color` initializers that support light/dark variants (e.g., `Color(.init(dynamicProvider:))` or asset catalog colors)
2. The system color scheme (controlled by `AppTheme` — system/light/dark) determines which variant renders
3. Theme selection (accent family) and color scheme selection (light/dark/system) are **independent** — users choose both

### FR-TH-05: SettingsStore Integration

`SettingsStore` **MUST** add a `selectedThemeId: String` property:

1. Persisted to UserDefaults with key `"selectedThemeId"`
2. Default value: `"default"` (the VaultMail cerulean theme)
3. Written via `didSet` following the existing SettingsStore pattern
4. The existing `theme: AppTheme` property (system/light/dark) **MUST** be preserved as-is — it controls color scheme, not accent theme

### FR-TH-06: AccentColor Asset

The `AccentColor.colorset` in the app's asset catalog **MUST** be populated with the default brand color `#2596BE` to provide baseline tinting for system controls (navigation bars, tint colors) even before views are fully migrated.

---

## 4. Design Tokens — Colors

### FR-CO-01: ThemeColors Struct

The application **MUST** define a `ThemeColors` struct containing all semantic color tokens:

**Backgrounds:**

| Token | Purpose | Light Default | Dark Default |
|-------|---------|---------------|--------------|
| `background` | Root screen background | `#FFFFFF` | `#000000` |
| `surface` | Cards, sheets, list rows | `#FFFFFF` | `#1C1C1E` |
| `surfaceElevated` | Modals, popovers, search bar | `#F2F2F7` | `#2C2C2E` |
| `surfaceSelected` | Selected/highlighted rows | `accent` at 8% | `accent` at 12% |

**Text:**

| Token | Purpose | Light Default | Dark Default | Min Contrast |
|-------|---------|---------------|--------------|-------------|
| `textPrimary` | Headings, sender names | `#000000` | `#FFFFFF` | 7:1 |
| `textSecondary` | Body text, subjects | `#3C3C43` at 60% | `#EBEBF5` at 60% | 4.5:1 |
| `textTertiary` | Timestamps, captions, snippets | `#3C3C43` at 30% | `#EBEBF5` at 30% | 3:1 |
| `textInverse` | Text on accent-colored backgrounds | `#FFFFFF` | `#000000` | — |

**Accent:**

| Token | Purpose | Light Default | Dark Default |
|-------|---------|---------------|--------------|
| `accent` | Primary brand — buttons, links, active states | `#2596BE` | `#3DAED4` |
| `accentMuted` | Subtle accent background — badges, selected rows | `accent` at 12% | `accent` at 15% |
| `accentHover` | Pressed/hover states | `#1E7FA3` | `#4BC2E8` |

**Semantic Status:**

| Token | Purpose | Light Default | Dark Default |
|-------|---------|---------------|--------------|
| `destructive` | Delete, spam, errors | `#FF3B30` | `#FF453A` |
| `destructiveMuted` | Destructive background | `destructive` at 12% | `destructive` at 15% |
| `success` | Sent, synced, online | `#34C759` | `#30D158` |
| `successMuted` | Success background | `success` at 12% | `success` at 15% |
| `warning` | Unsaved drafts, warnings | `#FF9500` | `#FF9F0A` |
| `warningMuted` | Warning background | `warning` at 12% | `warning` at 15% |

**UI Chrome:**

| Token | Purpose | Light Default | Dark Default |
|-------|---------|---------------|--------------|
| `separator` | List dividers | `#3C3C43` at 12% | `#545458` at 30% |
| `border` | Input field borders | `#3C3C43` at 18% | `#545458` at 40% |
| `disabled` | Disabled controls | `#3C3C43` at 18% | `#545458` at 30% |
| `shimmer` | Loading skeleton base | `#3C3C43` at 8% | `#545458` at 15% |

**Specialized:**

| Token | Purpose | Value |
|-------|---------|-------|
| `unreadDot` | Unread indicator circle | Same as `accent` |
| `starred` | Star/flag icon | `#FFD60A` (both modes) |

### FR-CO-02: AI Category Colors

The application **MUST** define category-specific color tokens that preserve existing semantic meaning:

| Category | Foreground | Muted Background |
|----------|------------|------------------|
| Primary | `accent` | `accentMuted` |
| Social | `#34C759` (light) / `#30D158` (dark) | foreground at 12%/15% |
| Promotions | `#FF9500` (light) / `#FF9F0A` (dark) | foreground at 12%/15% |
| Updates | `#AF52DE` (light) / `#BF5AF2` (dark) | foreground at 12%/15% |
| Forums | `#5AC8FA` (light) / `#64D2FF` (dark) | foreground at 12%/15% |
| Uncategorized | `textTertiary` | `shimmer` |

Category colors **MUST** be part of `ThemeColors` so themes can optionally override them.

### FR-CO-03: Avatar Palette

The application **MUST** define an `avatarPalette: [Color]` property on `ThemeColors` containing 10 deterministic colors for contact avatars. The default palette **SHOULD** preserve the existing 10-color set: blue, green, orange, purple, pink, red, teal, indigo, mint, cyan.

---

## 5. Design Tokens — Typography

### FR-TY-01: ThemeTypography Struct

The application **MUST** define a `ThemeTypography` struct with the following type scale. All values use SF Pro (system font) via `Font.system(size:weight:design:)`. No custom font files.

| Token | Default Size | Weight | Design | Primary Usage |
|-------|-------------|--------|--------|---------------|
| `displayLarge` | 34 | `.bold` | `.default` | Onboarding hero text |
| `displaySmall` | 28 | `.bold` | `.default` | Screen titles |
| `titleLarge` | 22 | `.semibold` | `.default` | Section headers |
| `titleMedium` | 17 | `.semibold` | `.default` | Sender names (unread), card titles |
| `titleSmall` | 15 | `.semibold` | `.default` | Sub-section headers |
| `bodyLarge` | 17 | `.regular` | `.default` | Email body, primary content |
| `bodyMedium` | 15 | `.regular` | `.default` | Subject lines, sender names (read) |
| `bodySmall` | 13 | `.regular` | `.default` | Snippets, secondary content |
| `labelLarge` | 15 | `.medium` | `.default` | Button labels |
| `labelMedium` | 13 | `.medium` | `.default` | Tab labels, chip text |
| `labelSmall` | 11 | `.medium` | `.default` | Badge text, overline text |
| `caption` | 12 | `.regular` | `.default` | Timestamps, metadata |
| `captionMono` | 12 | `.regular` | `.monospaced` | Technical details, IDs |

### FR-TY-02: Unread vs Read Distinction

Thread row text **MUST** distinguish unread from read state:

| Element | Unread | Read |
|---------|--------|------|
| Sender name | `titleMedium` (17pt semibold) | `bodyMedium` (15pt regular) |
| Subject | `bodyMedium` weight `.medium` | `bodyMedium` weight `.regular` |
| Snippet | `bodySmall` + `textTertiary` | `bodySmall` + `textTertiary` |
| Timestamp | `caption` + `textTertiary` | `caption` + `textTertiary` |

### FR-TY-03: Dynamic Type Support

All typography tokens **MUST** use `Font.system()` to inherit Dynamic Type scaling. Views **MUST NOT** use fixed-height frames that clip text at larger accessibility sizes.

---

## 6. Design Tokens — Spacing

### FR-SP-01: Spacing Scale

The application **MUST** define a `ThemeSpacing` struct with a base spacing scale following WhatsApp-like comfortable density:

| Token | Value (pt) | Usage |
|-------|-----------|-------|
| `xxs` | 2 | Inline icon gaps |
| `xs` | 4 | Tight internal padding |
| `sm` | 8 | Between related elements |
| `md` | 12 | Default component padding |
| `lg` | 16 | List row horizontal padding |
| `xl` | 20 | Section spacing |
| `xxl` | 24 | Card padding, generous gaps |
| `xxxl` | 32 | Screen-level margins |

### FR-SP-02: Component Spacing Tokens

The application **MUST** define named component spacing tokens:

| Token | Value (pt) | Description |
|-------|-----------|-------------|
| `listRowVertical` | 12 | Vertical padding per thread row |
| `listRowHorizontal` | 16 | Horizontal padding per thread row |
| `listRowSpacing` | 10 | Gap between avatar and content in rows |
| `sectionSpacing` | 24 | Vertical space between list sections |
| `cardPadding` | 16 | Internal padding of cards/message bubbles |
| `avatarSize` | 44 | Thread list avatar diameter |
| `avatarSizeLarge` | 56 | Detail view, onboarding avatars |
| `avatarSizeSmall` | 32 | Stacked/secondary avatars |
| `iconSize` | 20 | Standard icon size |
| `iconSizeSmall` | 16 | Inline/caption icons |
| `touchMinimum` | 44 | Minimum tap target per Apple HIG |
| `chipVertical` | 6 | Category chip vertical padding |
| `chipHorizontal` | 12 | Category chip horizontal padding |
| `searchBarHeight` | 36 | Search input field height |
| `bottomTabHeight` | 56 | Bottom tab bar total height |

---

## 7. Design Tokens — Shapes

### FR-SH-01: Corner Radii

The application **MUST** define a `ThemeShapes` struct with corner radius tokens:

| Token | Value (pt) | Usage |
|-------|-----------|-------|
| `small` | 8 | Input fields, small cards, search bar |
| `medium` | 12 | Message bubbles, standard cards |
| `large` | 16 | Sheets, large cards, image previews |
| `extraLarge` | 20 | Modals, onboarding cards |
| `full` | Capsule | Chips, pills, badges, category tabs |

### FR-SH-02: Shadow Definitions

The application **MUST** define shadow tokens as a `ShadowStyle` struct (color, radius, x, y):

| Token | Color | Radius | X | Y | Usage |
|-------|-------|--------|---|---|-------|
| `shadowSubtle` | black at 4% | 2 | 0 | 1 | List rows on hover |
| `shadowMedium` | black at 8% | 4 | 0 | 2 | Message bubbles, cards |
| `shadowElevated` | black at 12% | 8 | 0 | 4 | Sheets, modals, popovers |

Shadows **SHOULD** be suppressed in dark mode (set radius to 0) since elevated surfaces are already visually distinct via background color.

### FR-SH-03: Prebuilt Shape Helpers

`ThemeShapes` **SHOULD** expose computed properties for frequently used shapes:

- `smallRect` → `RoundedRectangle(cornerRadius: small)`
- `mediumRect` → `RoundedRectangle(cornerRadius: medium)`
- `largeRect` → `RoundedRectangle(cornerRadius: large)`
- `capsule` → `Capsule()`

---

## 8. Component Styles (ViewModifiers)

### FR-CS-01: Reusable ViewModifier Extensions

The application **MUST** define `View` extension methods that apply consistent styling by reading from the current theme. Each modifier reads `@Environment(ThemeProvider.self)`:

| Modifier | Applies |
|----------|---------|
| `vmCard()` | `surface` background + `medium` corner radius + `shadowMedium` |
| `vmChip(isSelected:)` | `capsule` shape + `accentMuted`/`accent` background + `labelMedium` font |
| `vmPrimaryButton()` | `accent` background + `textInverse` foreground + `large` corner radius + `touchMinimum` height |
| `vmSecondaryButton()` | `border` stroke + `accent` foreground + `large` corner radius + `touchMinimum` height |
| `vmSearchBar()` | `surfaceElevated` background + `small` corner radius + `border` stroke + `searchBarHeight` |
| `vmSectionHeader()` | `titleSmall` font + `textSecondary` color |
| `vmListRow()` | `listRowVertical`/`listRowHorizontal` padding + `separator` bottom border |

### FR-CS-02: Thread Row Component Style

Thread rows **MUST** follow this layout structure:

```
[listRowVertical padding]
HStack(spacing: listRowSpacing) {
  [6x6 unreadDot, accent color]
  [avatarSize x avatarSize, circular clip]
  VStack(alignment: .leading, spacing: xs) {
    HStack { senderText | Spacer | timestamp(caption, textTertiary) }
    HStack { subject(bodyMedium) | Spacer | starIcon(starred color) }
    HStack { snippet(bodySmall, textTertiary) | Spacer | [attachmentIcon] [categoryChip] }
  }
}
[listRowHorizontal padding]
```

Unread rows **SHOULD** have a `surfaceSelected` background tint.

### FR-CS-03: Message Bubble Component Style

Message bubbles in email detail **MUST** use:

```
VStack(spacing: 0) {
  MessageHeader    [cardPadding]
  Divider          [separator color]
  EmailBody        [cardPadding]
  Attachments      [cardPadding, if present]
}
.background(surface)
.clipShape(mediumRect)
.shadow(shadowMedium)   // light mode only
```

### FR-CS-04: Category Tab Component Style

Category filter tabs **MUST** use:

```
HStack(spacing: xs) {
  Text(label).font(labelMedium)
  if unreadCount > 0 {
    Text("\(unreadCount)")
      .font(labelSmall)
      .padding(.horizontal, xs)
      .padding(.vertical, xxs)
  }
}
.padding(.horizontal, chipHorizontal)
.padding(.vertical, chipVertical)
.background(isSelected ? accent : surfaceElevated, in: Capsule())
.foregroundStyle(isSelected ? textInverse : textPrimary)
```

### FR-CS-05: Settings List Style

Settings screens **MUST** preserve `.listStyle(.insetGrouped)` on iOS. Within settings:

- Section headers: `vmSectionHeader()` modifier
- Row labels: `bodyLarge` font
- Row descriptions: `bodySmall` font + `textSecondary` color
- Row icons: `accent` tint + `iconSize` frame

---

## 9. Built-in Themes

### FR-BT-01: Theme Catalog

The application **MUST** ship with 6 built-in themes:

| ID | Display Name | Accent (Light) | Accent (Dark) | Vibe |
|----|-------------|-----------------|----------------|------|
| `default` | VaultMail | `#2596BE` | `#3DAED4` | Clean, professional — the brand |
| `midnight` | Midnight | `#6366F1` | `#818CF8` | Elegant, deep indigo |
| `forest` | Forest | `#059669` | `#34D399` | Privacy, trust, emerald |
| `sunset` | Sunset | `#EA580C` | `#FB923C` | Warm, energetic amber |
| `lavender` | Lavender | `#9333EA` | `#C084FC` | Creative, modern purple |
| `rose` | Rose | `#E11D48` | `#FB7185` | Bold, vibrant pink-red |

### FR-BT-02: Shared Background Strategy

All 6 themes **MUST** share the same background and surface system:

- **Light mode**: `#FFFFFF` background, `#FFFFFF` surface, `#F2F2F7` surfaceElevated
- **Dark mode**: `#000000` background (AMOLED-friendly), `#1C1C1E` surface, `#2C2C2E` surfaceElevated

Only the **accent family** (accent, accentMuted, accentHover) changes between themes. This keeps the app minimal — accent color is the sole differentiator.

### FR-BT-03: Per-Theme Derived Colors

Each theme **MUST** derive the following from its accent:

- `accentMuted`: accent at 12% opacity (light) / 15% opacity (dark)
- `accentHover`: accent darkened ~15% (light) / lightened ~15% (dark)
- `unreadDot`: same as accent
- `surfaceSelected`: accent at 8% (light) / 12% (dark)
- `categoryPrimary`: same as accent (Primary category uses brand color)

All other semantic colors (destructive, success, warning, text hierarchy, chrome) remain constant across themes.

---

## 10. Settings UI — Theme Picker

### FR-SET-01: Theme Picker Location

The theme picker **MUST** appear in Settings > Appearance section, above the existing color scheme (system/light/dark) picker.

### FR-SET-02: Theme Picker Layout

The theme picker **MUST** display as a `LazyVGrid` with 3 columns:

```
Section("Theme") {
    LazyVGrid(columns: [GridItem(.flexible()), ...], spacing: lg) {
        ForEach(ThemeRegistry.allThemes) { theme in
            ThemePickerCell(theme: theme, isSelected: ...)
        }
    }
}
```

### FR-SET-03: ThemePickerCell Design

Each cell **MUST** contain:

1. A `Circle` of `avatarSize` (44pt) filled with `theme.previewColor`
2. A checkmark overlay (`Image(systemName: "checkmark")`, `textInverse` color) if selected
3. A border ring (`accent` color, 2pt) if selected
4. The theme's `displayName` below the circle in `caption` font + `textSecondary` color

### FR-SET-04: Immediate Apply

Tapping a theme cell **MUST**:

1. Update `settings.selectedThemeId` (persists to UserDefaults)
2. Call `themeProvider.apply(themeId)` which swaps the current theme
3. All views re-render immediately — no confirm dialog, no restart

### FR-SET-05: Color Scheme Independence

The existing color scheme picker (System / Light / Dark) **MUST** remain below the theme picker. The two controls are independent — users can combine any accent theme with any color scheme preference.

---

## 11. Accessibility

### NFR-ACC-01: WCAG 2.1 AA Contrast

All text color tokens **MUST** meet WCAG 2.1 AA minimum contrast ratios against their expected background:

- Normal text (< 18pt or < 14pt bold): **4.5:1** minimum
- Large text (>= 18pt or >= 14pt bold): **3:1** minimum
- Interactive UI components: **3:1** against adjacent colors

### NFR-ACC-02: Dynamic Type

All `ThemeTypography` tokens **MUST** use `Font.system()` to automatically scale with Dynamic Type. Views **MUST NOT** constrain text containers with fixed heights that clip at large text sizes.

### NFR-ACC-03: Reduce Transparency

When `UIAccessibility.isReduceTransparencyEnabled` is true, the application **SHOULD** replace opacity-based muted colors (`accentMuted`, `destructiveMuted`, etc.) with solid color equivalents at similar perceived brightness.

### NFR-ACC-04: Increased Contrast

When `UIAccessibility.isDarkerSystemColorsEnabled` is true, the application **SHOULD** increase text color opacity to full and widen border strokes from 1pt to 2pt.

### NFR-ACC-05: Preserve Existing Annotations

All 181+ existing `accessibilityLabel`, `accessibilityHint`, `accessibilityHidden`, `accessibilityAction`, and `accessibilityAddTraits` annotations **MUST** be preserved during migration. No accessibility annotation **MAY** be removed without explicit justification.

### NFR-ACC-06: Theme Picker Accessibility

Each `ThemePickerCell` **MUST** have:

- `accessibilityLabel`: theme display name
- `accessibilityAddTraits(.isButton)`
- `accessibilityAddTraits(.isSelected)` when active
- `accessibilityHint`: "Double tap to apply \(theme.displayName) theme"

---

## 12. Non-Functional Requirements

### NFR-TH-01: Theme Switch Performance

Theme switching **MUST** complete (all visible views re-rendered) in under **100ms** on iPhone 15 or equivalent.

### NFR-TH-02: Memory Overhead

The theming engine **MUST NOT** increase baseline memory usage by more than **2MB** (all 6 themes loaded in registry).

### NFR-TH-03: Binary Size

Design token files **MUST NOT** add more than **50KB** to the compiled binary.

### NFR-TH-04: Backward Compatibility

During incremental migration, views that still use inline system colors **MUST** continue working correctly. The `AccentColor` asset (FR-TH-06) ensures `.accentColor` references pick up the brand color.

### NFR-TH-05: Platform Parity

All design tokens and themes **MUST** work on both iOS 17+ and macOS 14+. Platform-specific adjustments (e.g., macOS sidebar density) **MAY** be implemented as platform-conditional values within the same token struct.

### NFR-TH-06: iOS 26 Compatibility

The theming engine **MUST** coexist with existing iOS 26 Liquid Glass effects (BottomTabBar). Liquid Glass views **MAY** bypass theme surface colors since the system handles their appearance.

---

## 13. Migration Strategy

### FR-MIG-01: Phased Rollout

Migration **MUST** proceed in three phases:

**Phase 1 — Foundation**: Create all theming engine files, inject `ThemeProvider` at app root, populate `AccentColor` asset. Zero view changes — engine exists alongside existing inline styles.

**Phase 2 — Shared Components**: Migrate reusable components that appear across multiple features:
1. `AvatarView` — spacing tokens (avatarSize)
2. `CategoryBadgeView` — category color tokens + chip style
3. `CategoryTabBar` — chip style + spacing tokens
4. `BottomTabBar` — spacing + color tokens
5. `ErrorToastView`, `UndoToastView`, `UndoSendToastView` — card style
6. Define all `ViewModifier` extensions

**Phase 3 — Feature Views**: Migrate feature-by-feature:
1. Thread List (ThreadListView, ThreadRowView, OutboxRowView, FolderListView, MultiSelectToolbar, MoveToFolderSheet, AccountSwitcherSheet, AccountIndicatorView)
2. Email Detail (EmailDetailView, MessageBubbleView, MessageHeaderView, AttachmentRowView, AttachmentPreviewView)
3. Composer (ComposerView, RecipientFieldView, BodyEditorView, SmartReplyChipView, AttachmentPickerView)
4. Search (SearchContentView, SearchFilterChipsView, RecentSearchesView, HighlightedThreadRowView)
5. Settings (SettingsView + all sub-views — add theme picker here)
6. Onboarding (OnboardingView + all step views, ProviderSelectionView, AppPasswordEntryView, ManualAccountSetupView)
7. AI (AIChatView, AISummaryView, SmartReplyView)
8. macOS (MacOSMainView, SidebarView, MacSettingsView, MacThreadListContentView, MacAddAccountView, AppCommands)
9. Shared (DatabaseErrorView)

### FR-MIG-02: Incremental Compatibility

At any point during migration, the app **MUST** build and run correctly with a mix of migrated and un-migrated views. Un-migrated views continue using `Color.accentColor` (which picks up the asset catalog brand color) and system text colors.

### FR-MIG-03: Test Preservation

All existing 934+ tests **MUST** continue passing at each migration phase. New tests **MUST** be added for:

- `ThemeRegistry`: all 6 themes resolve, no nil tokens
- `ThemeProvider`: theme switching updates `current`, persists to UserDefaults
- `SettingsStore`: `selectedThemeId` round-trips through UserDefaults

---

## 14. File Manifest

### New Files

All new files live in `VaultMailPackage/Sources/VaultMailFeature/`:

| Path | Description |
|------|-------------|
| `Shared/Theme/ThemeColors.swift` | Color token struct (FR-CO-01, FR-CO-02, FR-CO-03) |
| `Shared/Theme/ThemeTypography.swift` | Typography token struct (FR-TY-01) |
| `Shared/Theme/ThemeSpacing.swift` | Spacing token struct (FR-SP-01, FR-SP-02) |
| `Shared/Theme/ThemeShapes.swift` | Shapes + shadow structs (FR-SH-01, FR-SH-02, FR-SH-03) |
| `Shared/Theme/VaultMailTheme.swift` | Theme protocol (FR-TH-01) |
| `Shared/Theme/ThemeProvider.swift` | @Observable provider (FR-TH-02) |
| `Shared/Theme/ThemeRegistry.swift` | Theme catalog (FR-TH-03) |
| `Shared/Theme/Themes/DefaultTheme.swift` | VaultMail `#2596BE` (FR-BT-01) |
| `Shared/Theme/Themes/MidnightTheme.swift` | Midnight `#6366F1` (FR-BT-01) |
| `Shared/Theme/Themes/ForestTheme.swift` | Forest `#059669` (FR-BT-01) |
| `Shared/Theme/Themes/SunsetTheme.swift` | Sunset `#EA580C` (FR-BT-01) |
| `Shared/Theme/Themes/LavenderTheme.swift` | Lavender `#9333EA` (FR-BT-01) |
| `Shared/Theme/Themes/RoseTheme.swift` | Rose `#E11D48` (FR-BT-01) |
| `Shared/Theme/ViewModifiers/ThemeModifiers.swift` | vmCard, vmChip, etc. (FR-CS-01) |
| `Presentation/Settings/ThemePickerCell.swift` | Theme selector cell (FR-SET-03) |

### Modified Files

| Path | Change |
|------|--------|
| `Shared/Services/SettingsStore.swift` | Add `selectedThemeId` property (FR-TH-05) |
| `VaultMail/Assets.xcassets/AccentColor.colorset/Contents.json` | Set `#2596BE` (FR-TH-06) |
| `Presentation/Settings/SettingsView.swift` | Add theme picker section (FR-SET-01) |
| All ~60 Presentation views | Replace inline colors/fonts/spacing with theme tokens (Phase 2–3) |

---

## 15. Open Questions

| # | Question | Status |
|---|----------|--------|
| OQ-1 | Should themes also vary the SF Pro design (`.rounded` variant for some themes)? | Open |
| OQ-2 | Should dark mode suppress all shadows or just reduce them? | Proposed: suppress (radius 0) |
| OQ-3 | Should the avatar palette change per-theme or remain constant? | Proposed: constant |
| OQ-4 | Should macOS use slightly tighter spacing values than iOS? | Proposed: same tokens, macOS sidebar excepted |
