# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Swift and iOS Development principals
Please refer to @IOS_DEVELOPMENT_STANDARDS.md

## Project Overview

Kanora is a Mac Catalyst music player and library manager built with Swift and SwiftUI. It supports CD ripping, local playback, and remote streaming via REST API. The project targets macOS 12+ and uses modern iOS/macOS development practices.

Platform Strategy:

  - Native macOS: Uses AppKit (NSImage, NSImage(contentsOfFile:))
  - Mac Catalyst & iOS: Uses UIKit (UIImage, UIImage(contentsOfFile:))

The pattern #if os(macOS) && !targetEnvironment(macCatalyst) ensures AppKit APIs are only used on native macOS where they're fully available, while iOS and Catalyst apps use UIKit APIs exclusively.

## Build and Development Commands

### Building and Running
```bash
# Open project in Xcode
open Kanora/Kanora.xcodeproj

# Build from command line
cd Kanora
xcodebuild -scheme Kanora -destination 'platform=macOS' build

# Run tests
xcodebuild -scheme Kanora -destination 'platform=macOS' test

# Run specific test
xcodebuild -scheme Kanora -destination 'platform=macOS' test -only-testing:KanoraTests/LibraryViewModelTests/testLoadLibraries
```

### Code Quality
```bash
# Run SwiftLint (if installed)
swiftlint

# Install SwiftLint
brew install swiftlint
```

**Note:** SwiftLint runs automatically during builds. Configuration is in `.swiftlint.yml` with strict rules including:
- Line length: 120 chars warning, 150 error
- No print statements (use proper logging)
- Force unwrapping is flagged
- Comprehensive opt-in rules enabled

## Architecture Overview

### MVVM Pattern

Kanora follows strict MVVM architecture with clear separation of concerns:

**Model Layer** (`Kanora/Models/`)
- Core Data entities: User, Library, Artist, Album, Track, Playlist, PlaylistItem
- Extensions in `CoreDataExtensions/` provide convenience initializers and computed properties
- Never accessed directly from Views

**View Layer** (`Kanora/Views/`)
- SwiftUI views organized by feature: Library/, Player/, Sidebar/
- Views are "dumb" - no business logic, only UI and bindings
- Use `@StateObject` for owned ViewModels, `@ObservedObject` for passed ones
- All views must call `viewModel.onAppear()` and `onDisappear()` for lifecycle management

**ViewModel Layer** (`Kanora/ViewModels/`)
- All ViewModels inherit from `BaseViewModel`
- Must be marked `@MainActor` for thread safety
- Use `@Published` properties for observable state
- Manage Combine subscriptions via `cancellables` property
- **Critical:** Store object IDs, not Core Data objects, as `@Published` properties (cross-context safety)

**Service Layer** (`Kanora/Services/`)
- Protocol-first design: `Protocols/` define interfaces, `Implementations/` provide concrete types
- Services are stateless - no `@Published` properties
- Return Combine publishers for async operations
- Three main services: `LibraryService`, `AudioPlayerService`, `APIServerService`

### Dependency Injection

**ServiceContainer** (`Kanora/Utilities/ServiceContainer.swift`)
- Singleton pattern: `ServiceContainer.shared` for production
- Preview instance: `ServiceContainer.preview` for SwiftUI previews
- Mock support: `ServiceContainer.mock(libraryService: mock)` for testing
- Provides access to all services and PersistenceController
- **Always inject** - never access `.shared` directly in ViewModels

### Core Data Stack

**PersistenceController** (`Kanora/Models/Persistence.swift`)
- Singleton: `PersistenceController.shared` (production) or `.preview` (previews)
- Store location: `~/Library/Application Support/Kanora/Kanora.sqlite`
- Automatic lightweight migrations enabled
- Three context types:
  - **View Context**: Main queue, for UI operations
  - **Background Context**: For imports, batch operations (use `performBackgroundTask`)
  - **Child Context**: For temporary edits (forms with cancel option)

**Context Management Rules:**
- Use `viewContext` for fetches displayed in UI
- Use background contexts for heavy operations (CD ripping, file scanning)
- Use child contexts for form editing with rollback capability
- Always save hierarchically: `saveWithParent(context:)` for child contexts

### Localization System

**L10n.swift** (`Kanora/Localisation/L10n.swift`)
- Centralized localization via nested enums
- 14 categories: Actions, Navigation, Player, Library, Forms, Errors, Preferences, Import, Dialogs, Time, About, Placeholders, Common, TableColumns, MenuCommands
- Usage: `Text(L10n.Library.artistsTitle)` or `Text(L10n.Library.trackCount(count))`
- String Catalog: `Localizable.xcstrings` (iOS 15+ String Catalog format)
- **Never use hardcoded strings** - all user-facing text must use L10n enum
- Plural support available: `L10n.Library.trackCount(5)` handles singular/plural

### Navigation Architecture

**NavigationState** (`Kanora/Models/Navigation/NavigationItem.swift`)
- Centralized navigation state as `@ObservableObject`
- Three sidebar sections: Library, Media, Settings
- NavigationDestination enum for type-safe routing
- ContentRouter handles destination → View mapping
- Keyboard shortcuts defined in `KanoraApp.swift` via CommandMenu

## Critical Patterns and Conventions

### ViewModel Creation Pattern
```swift
@MainActor
class MyViewModel: BaseViewModel {
    @Published var items: [Item] = []
    @Published var viewState: ViewState = .idle

    override func onAppear() {
        super.onAppear()
        loadItems()
    }

    private func loadItems() {
        viewState = .loading
        do {
            items = try services.itemService.fetchItems(in: context)
            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
            handleError(error, context: "Loading items")
        }
    }
}
```

### View Initialization Pattern
```swift
struct MyView: View {
    @StateObject private var viewModel: MyViewModel

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: MyViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        // View implementation
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}
```

### Platform-Specific UI
Mac Catalyst requires platform-specific handling:
```swift
#if os(macOS)
import AppKit
Color(nsColor: .textBackgroundColor)
#else
import UIKit
Color(uiColor: .secondarySystemBackground)
#endif

// iOS 16+ availability checks
if #available(iOS 16.0, macOS 13.0, *) {
    NavigationSplitView { } detail: { }
} else {
    NavigationView { }
}
```

### Testing Pattern
```swift
@MainActor
final class MyViewModelTests: XCTestCase {
    var viewModel: MyViewModel!
    var services: ServiceContainer!
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        let persistence = PersistenceController(inMemory: true)
        context = persistence.viewContext
        services = ServiceContainer(persistence: persistence)
        viewModel = MyViewModel(context: context, services: services)
    }

    func testFeature() async throws {
        // Use CoreDataTestUtilities for sample data
        let user = User(username: "test", email: "test@example.com", context: context)
        try context.save()

        // Test ViewModel behavior
        viewModel.doSomething()
        XCTAssertEqual(viewModel.viewState, .loaded)
    }
}
```

## Code Organization Rules

### File Structure
- **One type per file** - ViewModel, View, Service each in separate files
- **Extensions** go in `CoreDataExtensions/` for models, otherwise co-located
- **Protocols** live in `Services/Protocols/`, implementations in `Services/Implementations/`
- **Localization** keys in `L10n.swift`, translations in `Localizable.xcstrings`

### Naming Conventions
- ViewModels: `{Feature}ViewModel` (e.g., `LibraryViewModel`)
- Views: `{Feature}View` (e.g., `ArtistsView`) or descriptive names (e.g., `PlayerControlsView`)
- Services: `{Domain}Service` with matching protocol `{Domain}ServiceProtocol`
- Core Data extensions: `{Entity}+Extensions.swift`

### What NOT to Do
- ❌ Never use `print()` - SwiftLint will flag it
- ❌ Never store Core Data managed objects as `@Published` - use IDs instead
- ❌ Never access Core Data from Views directly - always through ViewModels
- ❌ Never access services directly from Views - inject through ViewModels
- ❌ Never use hardcoded strings - always use L10n enum
- ❌ Never access `ServiceContainer.shared` in ViewModels - inject via initializer
- ❌ Never create ViewModels directly in view body - use `@StateObject` in init
- ❌ Never forget `@MainActor` on ViewModels - required for thread safety

## Key Implementation Details

### Core Data Model
Seven main entities with relationships:
- User (1) → (N) Library → (N) Artist → (N) Album → (N) Track
- User → (N) Playlist → (N) PlaylistItem (join table with Track)

Convenience initializers handle UUID generation, timestamps, and relationship setup. See `docs/CoreDataModel.md` for complete schema.

### Service Protocols
Services must be protocol-based for testability:
- `LibraryServiceProtocol`: Library scanning, import, management
- `AudioPlayerServiceProtocol`: Playback control, queue management, state broadcasting
- `APIServerServiceProtocol`: Embedded REST API server (planned - Vapor integration)

### ViewState Enum
Track loading states in ViewModels:
```swift
enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}
```

### Background Operations
Heavy operations must use background contexts:
```swift
persistence.performBackgroundTask { context in
    // Import files, scan directories, etc.
    // Save periodically for large datasets
    if context.insertedObjects.count >= 100 {
        try? context.save()
        context.reset()
    }
    try? context.save()

    // Update UI on main thread
    DispatchQueue.main.async {
        viewModel.reload()
    }
}
```

## Documentation
- Architecture details: `docs/MVVMArchitecture.md`
- Core Data schema: `docs/CoreDataModel.md`
- Persistence layer: `docs/CoreDataStack.md`
- GitHub Issues track features and bugs
- SwiftLint config: `.swiftlint.yml`

## Common Workflows

### Adding a New View
1. Create View file in appropriate `Views/` subdirectory
2. Create corresponding ViewModel inheriting from `BaseViewModel`
3. Add to `ContentRouter` if it's a navigation destination
4. Add L10n keys for all user-facing strings
5. Update `NavigationItem.swift` if adding to sidebar
6. Write unit tests for ViewModel in `KanoraTests/ViewModelTests/`

### Adding Localization
1. Add keys to appropriate L10n enum in `L10n.swift`
2. Add translations to `Localizable.xcstrings`
3. Use in views: `Text(L10n.Category.key)`
4. For plurals: Define function in L10n that returns `LocalizedStringKey` with count
5. Never use `String(localized:)` in `@Published` properties - use in Text() directly

### Modifying Core Data Schema
1. Open `Kanora.xcdatamodeld` in Xcode
2. Create new model version (Editor → Add Model Version)
3. Make changes to new version
4. Set as current version
5. Add lightweight migration mapping if needed
6. Update entity extensions in `CoreDataExtensions/`
7. Run tests to verify migration works

### Creating a Service
1. Define protocol in `Services/Protocols/{Name}ServiceProtocol.swift`
2. Implement in `Services/Implementations/{Name}Service.swift`
3. Add to `ServiceContainer` as property and initialize in init
4. Add mock variant to `ServiceContainer.mock()` method
5. Inject via ServiceContainer in ViewModels
6. Never store state in services - they're shared across app
- This is a mac catalyst app. No macOS native. UIKit and SwiftUI all the way.
