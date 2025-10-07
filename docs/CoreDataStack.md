# Core Data Stack Documentation

## Overview

The Kanora Core Data stack is managed by the `PersistenceController` struct, which provides a comprehensive and robust solution for data persistence and context management.

## Architecture

### Singleton Pattern

```swift
let persistence = PersistenceController.shared
```

The shared instance is used throughout the app for consistent data access.

### Preview Support

```swift
@MainActor
static let preview: PersistenceController
```

A separate preview instance with sample data for SwiftUI previews and testing.

## Core Components

### 1. Persistent Container

The `NSPersistentContainer` manages the Core Data stack:

```swift
let container: NSPersistentContainer
```

**Store Location:**
- Production: `~/Library/Application Support/Kanora/Kanora.sqlite`
- Testing: In-memory store

**Configuration:**
- Automatic lightweight migrations enabled
- Persistent history tracking enabled
- Remote change notifications enabled

### 2. View Context

The main context for UI operations:

```swift
var viewContext: NSManagedObjectContext
```

**Properties:**
- Runs on main queue
- Automatically merges changes from parent
- Merge policy: `NSMergeByPropertyObjectTrumpMergePolicy`
- Undo manager enabled for user actions
- Named "ViewContext" for debugging

## Context Management

### Background Context

For long-running operations that shouldn't block the UI:

```swift
// Create a new background context
let context = persistence.newBackgroundContext()
context.perform {
    // Perform work here
    try? context.save()
}

// Or use the convenience method
persistence.performBackgroundTask { context in
    // Perform work here
    try? context.save()
}
```

**Use Cases:**
- Importing large datasets
- Batch processing
- File scanning
- Network synchronization

### Child Context

For temporary operations that can be discarded:

```swift
let childContext = persistence.newChildContext()
// Make changes
try? childContext.save() // Saves to parent (viewContext)
try? persistence.saveViewContext() // Persists to disk
```

**Use Cases:**
- Form editing with cancel option
- Multi-step operations
- Temporary calculations

## Save Operations

### Basic Save

```swift
// Save view context
try persistence.saveViewContext()

// Save any context
try persistence.save(context: backgroundContext)
```

### Hierarchical Save

For child contexts, save through the hierarchy:

```swift
try persistence.saveWithParent(context: childContext)
```

This saves the child context and all parent contexts up to the persistent store.

## Batch Operations

### Batch Delete

Efficiently delete multiple objects:

```swift
let fetchRequest = Track.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "playCount == 0")

try persistence.batchDelete(
    fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>
)
```

**Benefits:**
- Much faster than deleting individually
- Lower memory footprint
- Automatically merges changes into view context

### Batch Update

Update multiple objects efficiently:

```swift
let batchUpdate = NSBatchUpdateRequest(entityName: "Track")
batchUpdate.predicate = NSPredicate(format: "playCount < 5")
batchUpdate.propertiesToUpdate = ["rating": 0]

try persistence.batchUpdate(request: batchUpdate)
```

## Error Handling

### Comprehensive Error Logging

```swift
do {
    try persistence.saveViewContext()
} catch {
    persistence.handleError(error, context: "Saving tracks")
}
```

The `handleError` method provides detailed logging:
- Error domain and code
- Localized description
- Failure reason
- Recovery suggestions
- Affected objects

### Error Output Example

```
❌ Core Data error in Saving tracks
   Domain: NSCocoaErrorDomain
   Code: 133000
   Description: The operation couldn't be completed
   Reason: Database is locked
   Suggestion: Try closing other apps
   Affected objects: 5
     - Track: "Come Together"
     - Track: "Something"
     ...
```

## Best Practices

### 1. Use Appropriate Contexts

```swift
// UI updates - Use view context
persistence.viewContext.perform {
    track.playCount += 1
    try? persistence.saveViewContext()
}

// Background work - Use background context
persistence.performBackgroundTask { context in
    let track = context.object(with: objectID) as? Track
    track?.analyze()
    try? context.save()
}
```

### 2. Always Check for Changes

The save methods automatically check `hasChanges`:

```swift
func save(context: NSManagedObjectContext) throws {
    guard context.hasChanges else { return }
    try context.save()
}
```

### 3. Use Batch Operations for Large Datasets

```swift
// ❌ Slow - loads all objects into memory
let tracks = try context.fetch(fetchRequest)
tracks.forEach { context.delete($0) }
try context.save()

// ✅ Fast - batch delete
try persistence.batchDelete(fetchRequest: fetchRequest)
```

### 4. Handle Errors Appropriately

```swift
// In production
do {
    try persistence.saveViewContext()
} catch {
    // Show user-friendly error
    showError("Failed to save changes")
    // Log for debugging
    persistence.handleError(error, context: "User action")
}

// In development
do {
    try persistence.saveViewContext()
} catch {
    // Detailed logging
    persistence.handleError(error, context: "Development")
    // Break to debugger
    assertionFailure("Core Data save failed")
}
```

## Debugging

### Print Statistics

```swift
persistence.printStatistics()
```

**Output:**
```
📊 Core Data Statistics
   View Context:
     - Has changes: true
     - Inserted: 5
     - Updated: 12
     - Deleted: 2
   Store:
     - Type: SQLite
     - URL: /Users/.../Kanora.sqlite
     - Size: 2.4 MB
```

### Reset Stack (Testing Only)

```swift
try persistence.reset()
```

**Warning:** This deletes all data. Only use in tests.

## Performance Optimization

### 1. Persistent History Tracking

Enabled by default for syncing changes between contexts:

```swift
description.setOption(
    true as NSNumber,
    forKey: NSPersistentHistoryTrackingKey
)
```

### 2. Merge Policy

Configured to favor property-level merges:

```swift
context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
```

### 3. Automatic Merging

View context automatically merges changes from background:

```swift
viewContext.automaticallyMergesChangesFromParent = true
```

## Migration Strategy

### Lightweight Migrations

Enabled automatically for simple changes:

```swift
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
```

**Supported Changes:**
- Adding new entities
- Adding new attributes
- Removing attributes
- Renaming with mapping
- Changing optional/required

### Custom Migrations

For complex changes, implement custom migration:

1. Create new model version
2. Create mapping model
3. Implement migration policy if needed

## Testing

### In-Memory Store

```swift
let controller = PersistenceController(inMemory: true)
```

**Benefits:**
- No disk I/O
- Faster tests
- No cleanup needed
- Isolated from production data

### Sample Data

```swift
CoreDataTestUtilities.createSampleData(in: context)
```

Creates realistic test data for all entities.

### Verify Integrity

```swift
let issues = CoreDataTestUtilities.verifyDataIntegrity(in: context)
if !issues.isEmpty {
    print("Data integrity issues found:")
    issues.forEach { print("  - \($0)") }
}
```

## Common Patterns

### Import Large Dataset

```swift
persistence.performBackgroundTask { context in
    for item in largeDataset {
        let track = Track(/* ... */, context: context)

        // Save periodically to limit memory
        if context.insertedObjects.count >= 100 {
            try? context.save()
            context.reset()
        }
    }

    try? context.save()
}
```

### Update UI from Background

```swift
persistence.performBackgroundTask { context in
    // Do work
    let track = fetchTrack(in: context)
    track.analyze()

    try? context.save()

    // Update UI on main thread
    DispatchQueue.main.async {
        // View context automatically merges changes
        // SwiftUI views will update automatically
    }
}
```

### Undo/Redo Support

```swift
// Undo manager is enabled on view context
persistence.viewContext.undoManager?.undo()
persistence.viewContext.undoManager?.redo()
```

## Troubleshooting

### Store Not Loading

Check console output:
```
❌ Core Data error: Error Domain=...
   Store: file:///...
   User info: {...}
```

Common causes:
- Incompatible model version
- Corrupted database file
- Permission issues
- Disk full

### Memory Issues

- Use batch operations for large datasets
- Save and reset contexts periodically during imports
- Use background contexts for heavy work

### Thread Safety

- Never pass `NSManagedObject` between threads
- Pass `NSManagedObjectID` instead
- Use `context.object(with:)` to fetch on target thread

## See Also

- [Core Data Model Documentation](CoreDataModel.md)
- [Entity Extensions](../Kanora/Kanora/Models/CoreDataExtensions/)
- [Apple Core Data Documentation](https://developer.apple.com/documentation/coredata)
