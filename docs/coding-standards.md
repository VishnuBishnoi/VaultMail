# Coding Standards

> All agents and engineers **MUST** follow these standards when writing Swift code in this project.

---

## Required Agent Skills

This project includes two agent skills that provide comprehensive reference material for writing Swift code. Agents **MUST** consult these skills when writing, reviewing, or improving Swift code.

### 1. SwiftUI Expert Skill

- **Location**: `.agents/skills/swiftui-expert-skill/`
- **Source**: [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill)
- **Use when**: Building new SwiftUI features, refactoring existing views, reviewing code quality, or adopting modern SwiftUI patterns.

Key areas covered:
- State management (`@Observable` over `ObservableObject`, correct property wrapper selection)
- Modern API usage (deprecated → modern replacements)
- View composition and extraction patterns
- Performance optimization (lazy stacks, stable identity, minimal state updates)
- Animation patterns (implicit/explicit, transitions, phase/keyframe)
- iOS 26+ Liquid Glass adoption (only when explicitly requested)

### 2. Swift Concurrency Skill

- **Location**: `.agents/skills/swift-concurrency/`
- **Source**: [AvdLee/Swift-Concurrency-Agent-Skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill)
- **Use when**: Writing async code, using actors, handling Sendable conformance, migrating to Swift 6, or debugging data races.

Key areas covered:
- async/await patterns and structured concurrency
- Actor isolation and `@MainActor` usage
- Sendable conformance and thread safety
- Task lifecycle, cancellation, and task groups
- Swift 6 migration strategies
- Core Data concurrency integration
- Performance profiling and testing

---

## Mandatory Patterns

### SwiftUI

- Use `@Observable` (not `ObservableObject`) for all new observable state
- Use `@State` with `@Observable` classes (not `@StateObject`)
- Use `.task` modifier for async work (not `Task { }` in `onAppear`)
- Use `NavigationStack` (not `NavigationView`)
- Use `foregroundStyle()` (not `foregroundColor()`)
- Use `clipShape(.rect(cornerRadius:))` (not `cornerRadius()`)
- No ViewModels — follow MV pattern with native SwiftUI state management

### Swift Concurrency

- All concurrency uses Swift Concurrency (async/await, actors, `@MainActor`)
- No GCD (`DispatchQueue`), no completion handlers in new code
- Prefer structured concurrency (child tasks, task groups) over unstructured `Task`
- Use `Task.detached` only with documented justification
- All types crossing concurrency boundaries must be `Sendable`
- `@MainActor` only for code that genuinely needs main-thread isolation

### General Swift

- Swift 6.1+, strict concurrency checking enabled
- `struct` over `class` unless reference semantics required
- `let` over `var` — immutability by default
- Early return pattern over nested conditionals
- No force-unwraps without absolute certainty
- No empty `catch` blocks

---

## Skill Reference Files

When you need detailed guidance on a specific topic, consult these reference files:

### SwiftUI References (`.agents/skills/swiftui-expert-skill/references/`)

| File | Topic |
|------|-------|
| `state-management.md` | Property wrappers and data flow |
| `view-structure.md` | View composition and extraction |
| `performance-patterns.md` | Performance optimization |
| `list-patterns.md` | ForEach identity and list best practices |
| `layout-best-practices.md` | Layout patterns and testability |
| `modern-apis.md` | Modern API replacements |
| `animation-basics.md` | Core animation concepts |
| `animation-transitions.md` | Transitions and Animatable protocol |
| `animation-advanced.md` | Phase/keyframe animations (iOS 17+) |
| `sheet-navigation-patterns.md` | Sheet and navigation patterns |
| `scroll-patterns.md` | ScrollView patterns |
| `text-formatting.md` | Modern text formatting |
| `image-optimization.md` | Image loading and optimization |
| `liquid-glass.md` | iOS 26+ Liquid Glass API |

### Swift Concurrency References (`.agents/skills/swift-concurrency/references/`)

| File | Topic |
|------|-------|
| `async-await-basics.md` | async/await syntax and patterns |
| `tasks.md` | Task lifecycle, cancellation, groups |
| `actors.md` | Actor isolation, @MainActor, reentrancy |
| `sendable.md` | Sendable conformance and safety |
| `threading.md` | Thread/task relationship and isolation |
| `memory-management.md` | Retain cycles in tasks |
| `async-sequences.md` | AsyncSequence and AsyncStream |
| `core-data.md` | Core Data concurrency |
| `performance.md` | Profiling and optimization |
| `testing.md` | Testing async code |
| `migration.md` | Swift 6 migration |
| `linting.md` | Concurrency lint rules |
| `glossary.md` | Concurrency terminology |
