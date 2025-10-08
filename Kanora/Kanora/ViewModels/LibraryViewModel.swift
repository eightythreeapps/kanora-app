//
//  LibraryViewModel.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import CoreData
import Combine

/// ViewModel for managing library operations and state
@MainActor
class LibraryViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published private(set) var libraries: [LibrarySummary] = [] {
        didSet { refreshSelectedLibrarySummary() }
    }
    @Published var selectedLibraryID: Library.ID? {
        didSet { refreshSelectedLibrarySummary() }
    }
    @Published private(set) var selectedLibrarySummary: LibrarySummary?
    @Published var viewState: ViewState = .idle
    @Published var statistics: LibraryStatistics?
    @Published var scanProgress: ScanProgress?
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var currentUser: User?
    private var libraryCache: [Library.ID: Library] = [:]

    // MARK: - Computed Properties

    var hasLibraries: Bool {
        !libraries.isEmpty
    }

    var selectedLibraryName: String {
        selectedLibrary?.name ?? L10n.Library.unknownLibraryName
    }

    // MARK: - Lifecycle

    override func onAppear() {
        super.onAppear()
        loadLibraries()
    }

    // MARK: - Library Operations

    /// Loads all libraries for the current user
    func loadLibraries() {
        viewState = .loading

        do {
            // Get or create default user
            if currentUser == nil {
                currentUser = getOrCreateDefaultUser()
            }

            guard let user = currentUser else {
                throw ViewModelError.userNotFound
            }

            let fetchedLibraries = try services.libraryService.fetchLibraries(
                for: user,
                in: context
            )

            libraryCache = [:]
            libraries = fetchedLibraries.compactMap { library in
                guard let summary = LibrarySummary(library: library) else { return nil }
                libraryCache[summary.id] = library
                return summary
            }

            if let currentSelection = selectedLibraryID,
               libraries.contains(where: { $0.id == currentSelection }) {
                loadStatistics()
            } else if let first = libraries.first {
                selectLibrary(id: first.id)
            } else {
                selectedLibraryID = nil
                statistics = nil
            }

            viewState = .loaded
        } catch {
            viewState = .error(error.localizedDescription)
            handleError(error, context: "Loading libraries")
        }
    }

    /// Creates a new library
    func createLibrary(name: String, path: String) {
        guard let user = currentUser else {
            errorMessage = L10n.Errors.noUserFoundMessage
            return
        }

        do {
            let library = try services.libraryService.createLibrary(
                name: name,
                path: path,
                user: user,
                in: context
            )

            guard let summary = LibrarySummary(library: library) else {
                throw ViewModelError.libraryNotFound
            }

            libraryCache[summary.id] = library
            libraries.append(summary)
            selectLibrary(id: summary.id)
        } catch {
            errorMessage = error.localizedDescription
            handleError(error, context: "Creating library")
        }
    }

    /// Selects a library and loads its statistics
    func selectLibrary(id: Library.ID) {
        guard selectedLibraryID != id else {
            loadStatistics()
            return
        }

        selectedLibraryID = id
        loadStatistics()
    }

    /// Deletes a library
    func deleteLibrary(id: Library.ID) {
        do {
            let library = try requireLibrary(withID: id)
            try services.libraryService.deleteLibrary(library, in: context)

            libraries.removeAll(where: { $0.id == id })
            libraryCache[id] = nil

            if selectedLibraryID == id {
                if let first = libraries.first {
                    selectLibrary(id: first.id)
                } else {
                    selectedLibraryID = nil
                    statistics = nil
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            handleError(error, context: "Deleting library")
        }
    }

    /// Provides the managed library for a given identifier
    func library(withID id: Library.ID) throws -> Library {
        try requireLibrary(withID: id)
    }

    /// Scans the selected library for audio files
    func scanLibrary() {
        guard let library = selectedLibrary else {
            errorMessage = L10n.Errors.noLibrarySelectedMessage
            return
        }

        viewState = .loading

        services.libraryService.scanLibrary(
            library,
            in: context,
            progressHandler: { [weak self] progress in
                self?.scanProgress = ScanProgress(
                    filesScanned: 0,
                    totalFiles: 0,
                    currentFile: nil,
                    percentage: progress
                )
            }
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                switch completion {
                case .finished:
                    self.viewState = .loaded
                    self.scanProgress = nil
                    self.loadStatistics()
                case .failure(let error):
                    self.viewState = .error(error.localizedDescription)
                    self.errorMessage = error.localizedDescription
                    self.handleError(error, context: "Scanning library")
                }
            },
            receiveValue: { [weak self] progress in
                self?.scanProgress = progress
            }
        )
        .store(in: &cancellables)
    }

    // MARK: - Statistics

    /// Loads statistics for the selected library
    func loadStatistics() {
        guard let selectedLibraryID,
              let library = try? requireLibrary(withID: selectedLibraryID) else {
            statistics = nil
            return
        }

        statistics = services.libraryService.getLibraryStatistics(
            for: library,
            in: context
        )
    }

    // MARK: - Private Helpers

    private func getOrCreateDefaultUser() -> User {
        let request = User.fetchRequest()
        request.fetchLimit = 1

        if let existingUser = try? context.fetch(request).first {
            return existingUser
        }

        let user = User(
            username: "default",
            email: "user@kanora.local",
            context: context
        )

        save()
        return user
    }

    private func refreshSelectedLibrarySummary() {
        if let selectedLibraryID,
           let summary = libraries.first(where: { $0.id == selectedLibraryID }) {
            selectedLibrarySummary = summary
        } else {
            selectedLibrarySummary = nil
        }
    }

    private func requireLibrary(withID id: Library.ID) throws -> Library {
        if let cached = libraryCache[id] {
            return cached
        }

        let request = Library.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        guard let library = try context.fetch(request).first else {
            throw ViewModelError.libraryNotFound
        }

        libraryCache[id] = library
        return library
    }
}

// MARK: - Errors

enum ViewModelError: LocalizedError {
    case userNotFound
    case libraryNotFound
    case trackNotFound
    case invalidPath

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return L10n.Errors.noUserFoundMessage
        case .libraryNotFound:
            return L10n.Errors.libraryNotFoundMessage
        case .invalidPath:
            return L10n.Errors.invalidPathMessage
        }
    }
}
