//
//  BaseViewModel.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import Combine
import CoreData

/// Base protocol for all ViewModels in the app
protocol ViewModelProtocol: ObservableObject {
    /// Lifecycle: Called when the view appears
    func onAppear()

    /// Lifecycle: Called when the view disappears
    func onDisappear()
}

/// Base class for ViewModels providing common functionality
@MainActor
class BaseViewModel: ObservableObject {
    // MARK: - Properties

    /// Set of cancellables for Combine subscriptions
    var cancellables = Set<AnyCancellable>()

    /// The managed object context for Core Data operations
    let context: NSManagedObjectContext

    /// Services container for dependency injection
    let services: ServiceContainer

    // MARK: - Initialization

    init(context: NSManagedObjectContext, services: ServiceContainer) {
        self.context = context
        self.services = services
    }

    // MARK: - Lifecycle

    /// Called when the view appears
    func onAppear() {
        // Override in subclasses
    }

    /// Called when the view disappears
    func onDisappear() {
        // Override in subclasses
    }

    // MARK: - Error Handling

    /// Handles errors with logging and user notification
    func handleError(_ error: Error, context: String) {
        print("❌ Error in \(context): \(error.localizedDescription)")
        // Can be extended to show user-facing error messages
    }

    // MARK: - Core Data Operations

    /// Saves the managed object context
    func save() {
        guard context.hasChanges else { return }

        do {
            try context.save()
            print("✅ Context saved from \(String(describing: type(of: self)))")
        } catch {
            handleError(error, context: "Saving context")
        }
    }

    /// Performs a background task
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let persistence = PersistenceController.shared
        persistence.performBackgroundTask(block)
    }
}

/// ViewState enum for tracking view loading states
enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
