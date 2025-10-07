//
//  ServiceContainer.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import CoreData

/// Dependency injection container for managing services
@MainActor
class ServiceContainer {
    // MARK: - Singleton

    /// Shared instance for the application
    static let shared = ServiceContainer(persistence: .shared)

    /// Preview instance for SwiftUI previews
    static let preview = ServiceContainer(persistence: .preview)

    // MARK: - Services

    /// Library management service
    let libraryService: LibraryServiceProtocol

    /// Audio player service
    let audioPlayerService: AudioPlayerServiceProtocol

    /// API server service
    let apiServerService: APIServerServiceProtocol

    /// Persistence controller for Core Data
    let persistence: PersistenceController

    // MARK: - Initialization

    init(
        persistence: PersistenceController,
        libraryService: LibraryServiceProtocol? = nil,
        audioPlayerService: AudioPlayerServiceProtocol? = nil,
        apiServerService: APIServerServiceProtocol? = nil
    ) {
        self.persistence = persistence

        // Initialize services with defaults or provided implementations
        self.libraryService = libraryService ?? LibraryService(persistence: persistence)
        self.audioPlayerService = audioPlayerService ?? AudioPlayerService()
        self.apiServerService = apiServerService ?? APIServerService()
    }

}

// MARK: - Test Helpers

extension ServiceContainer {
    /// Creates a container for testing with mock services
    static func mock(
        libraryService: LibraryServiceProtocol? = nil,
        audioPlayerService: AudioPlayerServiceProtocol? = nil,
        apiServerService: APIServerServiceProtocol? = nil
    ) -> ServiceContainer {
        let persistence = PersistenceController(inMemory: true)
        return ServiceContainer(
            persistence: persistence,
            libraryService: libraryService,
            audioPlayerService: audioPlayerService,
            apiServerService: apiServerService
        )
    }
}
