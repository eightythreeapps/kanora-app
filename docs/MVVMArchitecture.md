# MVVM Architecture Documentation

## Overview

Kanora implements the Model-View-ViewModel (MVVM) architectural pattern to ensure clean separation of concerns, testability, and maintainability. This document outlines the architecture, conventions, and best practices.

## Architecture Layers

### 1. Model Layer

**Location:** `Kanora/Models/`

The Model layer consists of:
- Core Data entities (User, Library, Artist, Album, Track, Playlist, PlaylistItem)
- Core Data extensions with convenience methods
- Data models and DTOs

**Responsibilities:**
- Data representation
- Business logic related to data
- Core Data entity management
- Data validation

**Example:**
```swift
extension Track {
    convenience init(
        title: String,
        filePath: String,
        duration: Double,
        format: String,
        album: Album,
        context: NSManagedObjectContext
    ) {
        self.init(context: context)
        self.id = UUID()
        self.title = title
        self.filePath = filePath
        // ...
    }
}
```

### 2. View Layer

**Location:** `Kanora/Views/`

The View layer consists of SwiftUI views that display data and handle user interactions.

**Responsibilities:**
- UI presentation
- User input handling
- Binding to ViewModel state
- Navigation

**Best Practices:**
- Views should be dumb and declarative
- No business logic in views
- Use `@ObservedObject` or `@StateObject` for ViewModels
- Use `@Environment` for dependencies

**Example:**
```swift
struct LibraryListView: View {
    @StateObject private var viewModel: LibraryViewModel

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        List(viewModel.libraries) { library in
            Text(library.name ?? "Unknown")
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
```

### 3. ViewModel Layer

**Location:** `Kanora/ViewModels/`

ViewModels act as the bridge between Views and Models, managing state and business logic.

**Responsibilities:**
- Presentation logic
- State management
- Coordinating service calls
- Data transformation for views
- Handling user actions

**Key Components:**

#### BaseViewModel

The foundation for all ViewModels:

```swift
@MainActor
class BaseViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    let context: NSManagedObjectContext
    let services: ServiceContainer

    init(context: NSManagedObjectContext, services: ServiceContainer) {
        self.context = context
        self.services = services
    }

    func onAppear() { }
    func onDisappear() { }
    func save() { }
    func handleError(_ error: Error, context: String) { }
}
```

**Features:**
- `@MainActor` ensures all ViewModel operations run on main thread
- Combines subscription management with `cancellables`
- Core Data context access
- Service container for dependencies
- Lifecycle methods
- Error handling utilities

#### ViewState

Enum for tracking view loading states:

```swift
enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool { ... }
    var errorMessage: String? { ... }
}
```

### 4. Service Layer

**Location:** `Kanora/Services/`

Services encapsulate business logic and external interactions.

**Structure:**
```
Services/
├── Protocols/
│   ├── LibraryServiceProtocol.swift
│   ├── AudioPlayerServiceProtocol.swift
│   └── APIServerServiceProtocol.swift
└── Implementations/
    ├── LibraryService.swift
    ├── AudioPlayerService.swift
    └── APIServerService.swift
```

**Responsibilities:**
- Business logic implementation
- External API interactions
- File system operations
- Audio playback management
- Server operations

**Example:**
```swift
protocol LibraryServiceProtocol {
    func fetchLibraries(
        for user: User,
        in context: NSManagedObjectContext
    ) throws -> [Library]

    func scanLibrary(
        _ library: Library,
        in context: NSManagedObjectContext,
        progressHandler: ((Double) -> Void)?
    ) -> AnyPublisher<ScanProgress, Error>
}

class LibraryService: LibraryServiceProtocol {
    private let persistence: PersistenceController

    init(persistence: PersistenceController) {
        self.persistence = persistence
    }

    func fetchLibraries(
        for user: User,
        in context: NSManagedObjectContext
    ) throws -> [Library] {
        let request = Library.librariesForUser(user)
        return try context.fetch(request)
    }
}
```

## Dependency Injection

### ServiceContainer

The `ServiceContainer` manages all service dependencies and provides them to ViewModels.

**Location:** `Kanora/Utilities/ServiceContainer.swift`

**Features:**
- Singleton pattern for app-wide access
- Preview instance for SwiftUI previews
- Mock instance for testing
- Centralized service management

**Usage:**

```swift
// In production
let services = ServiceContainer.shared

// In previews
let services = ServiceContainer.preview

// In tests
let services = ServiceContainer.mock(
    libraryService: MockLibraryService()
)

// Creating ViewModels
let viewModel = LibraryViewModel(
    context: services.persistence.viewContext,
    services: services
)
```

## Data Flow

### Unidirectional Data Flow

```
User Action → View → ViewModel → Service → Model
                ↑                           ↓
                └─────── Observe ←──────────┘
```

1. **User Action**: User interacts with View
2. **View → ViewModel**: View calls ViewModel method
3. **ViewModel → Service**: ViewModel calls Service
4. **Service → Model**: Service updates Model (Core Data)
5. **Model → ViewModel**: ViewModel observes changes via Combine
6. **ViewModel → View**: View updates via `@Published` properties

### Example Flow

```swift
// 1. User taps "Create Library" button
Button("Create Library") {
    viewModel.createLibrary(name: name, path: path)
}

// 2. View calls ViewModel
func createLibrary(name: String, path: String) {
    // 3. ViewModel calls Service
    let library = try services.libraryService.createLibrary(
        name: name,
        path: path,
        user: currentUser,
        in: context
    )

    // 4. Service updates Model (Core Data)
    // 5. ViewModel updates published property
    libraries.append(library)
}

// 6. View automatically updates via @Published
@Published var libraries: [Library] = []
```

## State Management

### Published Properties

ViewModels expose state via `@Published` properties:

```swift
@MainActor
class LibraryViewModel: BaseViewModel {
    @Published var libraries: [Library] = []
    @Published var selectedLibrary: Library?
    @Published var viewState: ViewState = .idle
    @Published var statistics: LibraryStatistics?
    @Published var errorMessage: String?
}
```

### Computed Properties

Use computed properties for derived state:

```swift
var hasLibraries: Bool {
    !libraries.isEmpty
}

var selectedLibraryName: String {
    selectedLibrary?.name ?? "No Library Selected"
}
```

### Lifecycle Management

ViewModels implement lifecycle methods:

```swift
override func onAppear() {
    super.onAppear()
    loadLibraries()
}

override func onDisappear() {
    super.onDisappear()
    // Cancel ongoing operations
    cancellables.removeAll()
}
```

## Testing

### Unit Testing ViewModels

ViewModels are highly testable due to dependency injection:

```swift
@MainActor
final class LibraryViewModelTests: XCTestCase {
    var viewModel: LibraryViewModel!
    var container: ServiceContainer!
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        let persistence = PersistenceController(inMemory: true)
        context = persistence.viewContext
        container = ServiceContainer(persistence: persistence)
        viewModel = LibraryViewModel(context: context, services: container)
    }

    func testLoadLibraries() async throws {
        // Given
        let user = User(username: "test", email: "test@example.com", context: context)
        _ = Library(name: "Test", path: "/test", user: user, context: context)
        try context.save()

        // When
        viewModel.loadLibraries()

        // Then
        XCTAssertEqual(viewModel.libraries.count, 1)
        XCTAssertEqual(viewModel.viewState, .loaded)
    }
}
```

### Mocking Services

Create mock services for isolated testing:

```swift
class MockLibraryService: LibraryServiceProtocol {
    var fetchLibrariesCalled = false
    var librariesToReturn: [Library] = []

    func fetchLibraries(
        for user: User,
        in context: NSManagedObjectContext
    ) throws -> [Library] {
        fetchLibrariesCalled = true
        return librariesToReturn
    }
}

// Use in tests
let mockService = MockLibraryService()
mockService.librariesToReturn = [testLibrary]
let container = ServiceContainer.mock(libraryService: mockService)
```

## Best Practices

### 1. ViewModel Guidelines

**✅ Do:**
- Inherit from `BaseViewModel`
- Mark as `@MainActor`
- Use `@Published` for observable state
- Implement lifecycle methods
- Handle errors gracefully
- Use dependency injection
- Keep ViewModels focused (single responsibility)

**❌ Don't:**
- Access UI components directly
- Perform heavy synchronous operations
- Store Core Data objects as `@Published` (use IDs instead for cross-context safety)
- Forget to manage Combine subscriptions

### 2. Service Guidelines

**✅ Do:**
- Define protocol interfaces
- Use protocols for testability
- Return publishers for async operations
- Handle errors appropriately
- Document complex operations

**❌ Don't:**
- Store state in services
- Access ViewModels from services
- Perform UI operations
- Create tight coupling between services

### 3. View Guidelines

**✅ Do:**
- Use `@StateObject` for owned ViewModels
- Use `@ObservedObject` for passed ViewModels
- Call lifecycle methods in `.onAppear()` / `.onDisappear()`
- Handle loading states
- Display error messages

**❌ Don't:**
- Put business logic in views
- Create ViewModels directly in view body
- Access Core Data directly
- Call services directly

### 4. Dependency Injection

**✅ Do:**
- Use `ServiceContainer` for all dependencies
- Inject dependencies through initializers
- Use protocol types for flexibility
- Create mock containers for testing

**❌ Don't:**
- Use singletons directly in ViewModels
- Hard-code dependencies
- Access `ServiceContainer.shared` in ViewModels (inject instead)

## Common Patterns

### Pattern: Loading List Data

```swift
@MainActor
class ItemListViewModel: BaseViewModel {
    @Published var items: [Item] = []
    @Published var viewState: ViewState = .idle

    override func onAppear() {
        super.onAppear()
        loadItems()
    }

    func loadItems() {
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

### Pattern: Async Operations with Combine

```swift
func performAsyncOperation() {
    viewState = .loading

    services.asyncService.performOperation()
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                switch completion {
                case .finished:
                    self.viewState = .loaded
                case .failure(let error):
                    self.viewState = .error(error.localizedDescription)
                    self.handleError(error, context: "Async operation")
                }
            },
            receiveValue: { [weak self] result in
                self?.handleResult(result)
            }
        )
        .store(in: &cancellables)
}
```

### Pattern: Background Operations

```swift
func importLargeDataset() {
    viewState = .loading

    performBackgroundTask { context in
        // Heavy work on background thread
        for item in largeDataset {
            let entity = Entity(/* ... */, context: context)

            // Save periodically
            if context.insertedObjects.count >= 100 {
                try? context.save()
                context.reset()
            }
        }

        try? context.save()

        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            self?.loadItems()
        }
    }
}
```

### Pattern: Form Handling with Child Context

```swift
class EditViewModel: BaseViewModel {
    private var childContext: NSManagedObjectContext!

    func startEditing(item: Item) {
        // Create child context for editing
        childContext = services.persistence.newChildContext()

        // Get item in child context
        let childItem = childContext.object(with: item.objectID) as? Item
        // Edit childItem...
    }

    func save() {
        do {
            try services.persistence.saveWithParent(context: childContext)
            // Changes saved to view context and disk
        } catch {
            handleError(error, context: "Saving changes")
        }
    }

    func cancel() {
        // Discard changes by not saving
        childContext = nil
    }
}
```

## Migration Guide

### Updating Existing Views

**Before (No MVVM):**
```swift
struct LibraryView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) var libraries: FetchedResults<Library>

    var body: some View {
        List(libraries) { library in
            Text(library.name ?? "")
        }
        .onAppear {
            // Direct Core Data access
            let newLibrary = Library(context: context)
            try? context.save()
        }
    }
}
```

**After (MVVM):**
```swift
struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        List(viewModel.libraries) { library in
            Text(library.name ?? "")
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

@MainActor
class LibraryViewModel: BaseViewModel {
    @Published var libraries: [Library] = []

    override func onAppear() {
        super.onAppear()
        loadLibraries()
    }

    func loadLibraries() {
        let request = Library.fetchRequest()
        libraries = (try? context.fetch(request)) ?? []
    }
}
```

## See Also

- [Core Data Stack Documentation](CoreDataStack.md)
- [Core Data Model Documentation](CoreDataModel.md)
- [Service Layer Documentation](Services.md) (to be created)
- [Testing Guide](Testing.md) (to be created)
