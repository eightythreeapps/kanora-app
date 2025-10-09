//
//  Persistence.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import CoreData
import Foundation

/// Manages the Core Data stack for the Kanora application
struct PersistenceController {
    /// Shared instance for the application
    static let shared = PersistenceController()

    /// Preview instance with sample data for SwiftUI previews
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for previews
        CoreDataTestUtilities.createSampleData(in: viewContext)

        return result
    }()

    /// The persistent container for the Core Data stack
    let container: NSPersistentContainer

    private let logger = AppLogger.persistence

    /// Main context for UI operations (runs on main queue)
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Kanora")

        // Configure persistent store description
        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                // Configure store location
                configureStoreLocation(description)
            }

            // Enable automatic lightweight migrations
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true

            // Performance optimizations
            description.setOption(true as NSNumber,
                                forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber,
                                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        // Load persistent stores
        let logger = self.logger
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                logger.error("❌ Core Data error: \(error)")
                logger.debug("   Store: \(storeDescription)")
                logger.error("   User info: \(error.userInfo)")

                // In production, you might want to handle this more gracefully
                // For now, we'll just log it
            } else {
                logger.info("✅ Core Data loaded successfully")
                if let url = storeDescription.url {
                    logger.debug("   Store location: \(url.path)")
                }
            }
        }

        // Configure view context
        configureViewContext()
    }

    // MARK: - Configuration

    private func configureStoreLocation(_ description: NSPersistentStoreDescription) {
        // Get the Application Support directory
        guard let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            return
        }

        // Create Kanora directory if needed
        let kanoraDir = appSupport.appendingPathComponent("Kanora")
        try? FileManager.default.createDirectory(
            at: kanoraDir,
            withIntermediateDirectories: true
        )

        // Set store URL
        let storeURL = kanoraDir.appendingPathComponent("Kanora.sqlite")
        description.url = storeURL
    }

    private func configureViewContext() {
        // Automatically merge changes from parent
        viewContext.automaticallyMergesChangesFromParent = true

        // Set merge policy to resolve conflicts
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Name for debugging
        viewContext.name = "ViewContext"

        // Undo manager for user actions
        viewContext.undoManager = UndoManager()
    }

    // MARK: - Background Context

    /// Creates a new background context for performing work off the main queue
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.name = "BackgroundContext-\(UUID().uuidString.prefix(8))"
        return context
    }

    /// Performs a block on a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { context in
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.name = "BackgroundTask-\(UUID().uuidString.prefix(8))"
            block(context)
        }
    }

    // MARK: - Child Context

    /// Creates a child context for temporary operations
    func newChildContext(
        concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType
    ) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.parent = viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.name = "ChildContext-\(UUID().uuidString.prefix(8))"
        return context
    }

    // MARK: - Save Operations

    /// Saves the view context if it has changes
    func saveViewContext() throws {
        try save(context: viewContext)
    }

    /// Saves a context if it has changes
    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
            logger.info("✅ Context saved: \(context.name ?? "unnamed")")
        } catch {
            let nsError = error as NSError
            logger.error("❌ Failed to save context: \(context.name ?? "unnamed")")
            logger.error("   Error: \(nsError)")
            logger.error("   User info: \(nsError.userInfo)")
            throw error
        }
    }

    /// Saves a context and its parent recursively
    func saveWithParent(context: NSManagedObjectContext) throws {
        try save(context: context)

        if let parent = context.parent {
            try parent.performAndWait {
                try saveWithParent(context: parent)
            }
        }
    }

    // MARK: - Batch Operations

    /// Performs a batch delete request
    @discardableResult
    func batchDelete(
        fetchRequest: NSFetchRequest<NSFetchRequestResult>,
        in context: NSManagedObjectContext? = nil
    ) throws -> NSBatchDeleteResult {
        let contextToUse = context ?? viewContext
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs

        let result = try contextToUse.execute(deleteRequest) as? NSBatchDeleteResult

        // Merge changes into view context if needed
        if let objectIDArray = result?.result as? [NSManagedObjectID],
           context == nil {
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [viewContext]
            )
        }

        return result ?? NSBatchDeleteResult()
    }

    /// Performs a batch update request
    @discardableResult
    func batchUpdate(
        request: NSBatchUpdateRequest,
        in context: NSManagedObjectContext? = nil
    ) throws -> NSBatchUpdateResult {
        let contextToUse = context ?? viewContext
        request.resultType = .updatedObjectIDsResultType

        let result = try contextToUse.execute(request) as? NSBatchUpdateResult

        // Merge changes into view context if needed
        if let objectIDArray = result?.result as? [NSManagedObjectID],
           context == nil {
            let changes = [NSUpdatedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: changes,
                into: [viewContext]
            )
        }

        return result ?? NSBatchUpdateResult()
    }

    // MARK: - Error Handling

    /// Handles Core Data errors with appropriate logging
    func handleError(_ error: Error, context: String) {
        let nsError = error as NSError
        logger.error("❌ Core Data error in \(context)")
        logger.error("   Domain: \(nsError.domain)")
        logger.error("   Code: \(nsError.code)")
        logger.error("   Description: \(nsError.localizedDescription)")

        if let detailed = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String {
            logger.debug("   Reason: \(detailed)")
        }

        if let recovery = nsError.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String {
            logger.debug("   Suggestion: \(recovery)")
        }

        // Log affected objects if available
        if let affectedObjects = nsError.userInfo[NSAffectedObjectsErrorKey] as? [NSManagedObject] {
            logger.debug("   Affected objects: \(affectedObjects.count)")
            for object in affectedObjects {
                logger.debug("     - \(object)")
            }
        }
    }

    // MARK: - Debugging

    /// Prints statistics about the Core Data stack
    func printStatistics() {
        logger.info("📊 Core Data Statistics")
        logger.debug("   View Context:")
        logger.debug("     - Has changes: \(viewContext.hasChanges)")
        logger.debug("     - Inserted: \(viewContext.insertedObjects.count)")
        logger.debug("     - Updated: \(viewContext.updatedObjects.count)")
        logger.debug("     - Deleted: \(viewContext.deletedObjects.count)")

        if let storeCoordinator = container.persistentStoreCoordinator.persistentStores.first {
            logger.debug("   Store:")
            logger.debug("     - Type: \(storeCoordinator.type)")
            if let url = storeCoordinator.url {
                logger.debug("     - URL: \(url.path)")
                if let fileSize = try? FileManager.default.attributesOfItem(
                    atPath: url.path
                )[.size] as? Int64 {
                    let formatter = ByteCountFormatter()
                    logger.debug("     - Size: \(formatter.string(fromByteCount: fileSize))")
                }
            }
        }
    }

    /// Resets the Core Data stack (useful for testing)
    func reset() throws {
        // Delete all entities
        let entities = container.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            try viewContext.execute(deleteRequest)
        }

        try saveViewContext()
        viewContext.reset()

        logger.info("✅ Core Data stack reset")
    }

    // MARK: - Development

    /// Clears all application data (Core Data + files in Kanora directories)
    /// Only deletes files in ~/Music/Kanora/ - leaves other files untouched
    func clearAllData() throws {
        logger.debug("🗑️ Starting clearAllData...")

        // 1. Delete all Core Data entities
        logger.debug("📦 Deleting Core Data entities...")
        let entities = container.managedObjectModel.entities
        for entity in entities {
            guard let entityName = entity.name else { continue }

            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            try viewContext.execute(deleteRequest)
            logger.info("   ✅ Deleted all \(entityName) records")
        }

        try saveViewContext()
        viewContext.reset()

        // 2. Delete files in Kanora directories
        logger.debug("📁 Deleting Kanora files...")
        let musicDirectory = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first!
        let kanoraBaseURL = musicDirectory.appendingPathComponent("Kanora")

        if FileManager.default.fileExists(atPath: kanoraBaseURL.path) {
            logger.debug("   📂 Removing: \(kanoraBaseURL.path)")
            try FileManager.default.removeItem(at: kanoraBaseURL)
            logger.info("   ✅ Kanora directory removed")
        } else {
            logger.info("   ℹ️ Kanora directory doesn't exist")
        }

        // 3. Clear UserDefaults (settings)
        logger.debug("⚙️ Clearing UserDefaults...")
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            logger.info("   ✅ UserDefaults cleared")
        }

        // 4. Recreate default user and library
        logger.debug("🔄 Recreating default user and library...")
        try createDefaultUserAndLibrary()

        logger.info("✅ All data cleared successfully")
    }

    /// Creates a default user and library for initial setup
    func createDefaultUserAndLibrary() throws {
        let context = viewContext

        // Create default user
        let user = User(context: context)
        user.id = UUID()
        user.username = "DefaultUser"
        user.email = "user@kanora.app"
        user.createdAt = Date()
        user.isActive = true
        user.lastLoginAt = Date()

        // Create default library
        let library = Library(context: context)
        library.id = UUID()
        library.name = "My Music"
        library.path = FileManager.default.urls(for: .musicDirectory, in: .userDomainMask).first?.path ?? "/Music"
        library.type = "local"
        library.isDefault = true
        library.createdAt = Date()
        library.updatedAt = Date()
        library.user = user

        try context.save()
        logger.info("   ✅ Created default user and library")
    }
}
