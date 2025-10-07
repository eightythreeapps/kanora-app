# iOS Development Rules

This document defines a shared standard for AI-assisted development, code reviews, and architecture decisions across all iOS/macOS projects within the 83apps ecosystem.

---

## 1. Generic iOS/macOS Development Practices

### 1.1 Architectural Overview

All 83apps projects follow **MVVM** or **MVVM + Repository** architecture, depending on data complexity.

**Key Principles:**
- **Models** define data structures (Core Data or SwiftData).
- **ViewModels** manage presentation logic and state.
- **Views** are pure SwiftUI; no business logic.
- **Repositories/Services** encapsulate data and side effects (networking, disk, playback).
- **Dependency Injection** is mandatory (no singletons in production code).
- **Design Systems** enforce consistent theming and typography across apps.

**Typical Directory Layout**
```
App/
├── Model/            # SwiftData/Core Data models
├── ViewModels/       # Business logic & state
├── Views/            # SwiftUI views
├── Services/         # Data and utility services
├── Design/           # Theme system & design tokens
├── Preview/          # Test data, factories, mock repos
└── Utilities/        # Helpers, extensions, etc.
```

---

### 1.2 Core Architectural Patterns

#### MVVM Essentials
- Views observe `@Published` state in `@StateObject` ViewModels.
- ViewModels marked `@MainActor` for thread safety.
- No Core Data/SwiftData access in Views.
- Services return Combine publishers or async/await tasks.
- ViewModels store identifiers, not managed objects, to avoid context issues.

#### Repository Pattern (Optional)
- Repositories abstract persistence (Core Data / SwiftData / Files / API).
- ViewModels depend on repository protocols, injected at init.
- Mock repositories power unit tests and SwiftUI previews.

---

### 1.3 Design System and Theming

**Rules:**
- Never hardcode fonts, colors, or spacing.
- Always use semantic tokens (`theme.colors.textPrimary`, `theme.spacing.md`, etc.).
- Apply `.designSystem()` at the root view.
- Typography, spacing, and radius scales must be shared across platforms.

**Design Tokens:**
| Category | Tokens |
|-----------|---------|
| Colors | primary, secondary, surface, background, textPrimary, textSecondary |
| Typography | display, headline, title, body, label, caption |
| Spacing | xxxs → xxxxl |
| Effects | radiusXS → radiusXL, shadow levels |

---

### 1.4 Localization

All user-facing strings **must** be localized.

**Guidelines:**
- Use generated `L10n` enums from `Localizable.xcstrings`.
- Use `Text(L10n.key)` rather than hardcoded text.
- For plurals: use functions in `L10n` that accept counts.
- Never store localized text in `@Published` properties; compute in `View`.

**Example:**
```swift
Text(L10n.Gifts.addGift)
Button(L10n.Actions.save) { viewModel.save() }
```

---

### 1.5 SwiftData & Core Data Rules

#### SwiftData (Giftboxd-style)
- Use `@Model` macros for entities.
- Always include **all related models** in `.modelContainer(for:)` previews.
- Use in-memory containers for previews/tests.
- Avoid accessing relationships after context deallocation.

#### Core Data (Kanora-style)
- Separate view, background, and child contexts.
- Use lightweight migrations.
- Background imports run via `performBackgroundTask`.
- Save hierarchically (`saveWithParent(context:)`).

**Context Rules**
| Type | Usage |
|------|--------|
| View Context | UI-bound fetches |
| Background Context | Imports, scans, migrations |
| Child Context | Temporary edits (forms) |

---

### 1.6 Previews

All previews follow a standardized **Preview Factory Pattern**.

**Structure:**
1. `PreviewState` enum defines states (`empty`, `populated`, `loading`, `error`).
2. `TestDataBuilder` creates realistic, connected data graphs.
3. `PreviewFactory` instantiates views with in-memory containers and design systems.

**Usage:**
```swift
#Preview("Populated") {
    PreviewFactory.makeDashboardView(state: .populated)
}

#Preview("Empty State") {
    PreviewFactory.makeDashboardView(state: .empty)
}
```

**Rules:**
- Never inline test data inside preview blocks.
- Always use `.designSystem()`.
- Always include all models in `.modelContainer(for:)`.

---

### 1.7 Code Conventions

**File Structure**
- One type per file.
- Extensions grouped logically.
- Protocols in `/Protocols`, implementations in `/Implementations`.

**Naming**
| Type | Pattern |
|------|----------|
| ViewModels | `{Feature}ViewModel` |
| Views | `{Feature}View` |
| Services | `{Domain}Service` |
| Enums | PascalCase (`ViewState`, `GiftStatus`) |
| Localisation Keys | `L10n.Category.key` |

**Do not:**
- ❌ Use `print()`.
- ❌ Force unwrap.
- ❌ Access persistence from Views.
- ❌ Access singletons (`.shared`) from ViewModels.
- ❌ Hardcode localized strings.

---

## 2. App-Specific Guidelines

---

### 2.1 Giftboxd

**Purpose:**  
A SwiftUI gift tracking app for iOS, watchOS, and extensions (Share + Widget) using SwiftData and App Groups.

**Core Tech**
- SwiftUI + SwiftData
- Shared SQLite in App Group `group.com.eightythreeapps.Giftboxd`
- Multi-target (iOS, watchOS, Share, Widget)
- Design System: semantic tokens, spacing, typography
- PreviewFactory with state-based data generation

**Architecture**
- Shared models (`@Model` types) across targets.
- Photo handling with GPS metadata via `PhotoManager`.
- Share Extension uses lightweight models (`SharedGiftIdea`, etc.).
- Importer processes shared data upon activation.

**Critical Patterns**
- Always add new models to all targets.
- Wrap iOS-only APIs with `#if os(watchOS)`.
- Use PreviewFactory for all previews.
- Use App Groups for data sharing.
- Use `@ThemeAccess` for color and typography.

**Preview Example**
```swift
#Preview("Gift Detail") {
    PreviewFactory.makeGiftDetailView(state: .populated)
}
```

**Key Anti-Patterns**
- Don’t use production containers in previews.
- Don’t access SwiftData relationships after context destruction.
- Don’t duplicate test data across files.

---
