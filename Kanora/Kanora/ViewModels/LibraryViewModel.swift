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

    @Published var libraries: [LibraryViewData] = []
    @Published var selectedLibrary: LibraryViewData?
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
        selectedLibrarySummary?.name ?? "No Library Selected"
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

            libraries = fetchedLibraries.map { LibraryViewData(library: $0) }

            if let selected = selectedLibrary,
               let updatedSelection = libraries.first(where: { $0.id == selected.id }) {
                selectedLibrary = updatedSelection
            }

            // Select first library if none selected
            if selectedLibrary == nil, let first = libraries.first {
                selectLibrary(first)
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
            errorMessage = "No user found"
            return
        }

        do {
            let library = try services.libraryService.createLibrary(
                name: name,
                path: path,
                user: user,
                in: context
            )

            let viewData = LibraryViewData(library: library)
            libraries.append(viewData)
            selectLibrary(viewData)
        } catch {
            errorMessage = error.localizedDescription
            handleError(error, context: "Creating library")
        }
    }

    /// Selects a library and loads its statistics
    func selectLibrary(_ library: LibraryViewData) {
        selectedLibrary = library
        loadStatistics()
    }

    /// Deletes a library
    func deleteLibrary(_ library: LibraryViewData) {
        do {
            guard let managedLibrary = fetchLibrary(with: library.id) else {
                throw ViewModelError.libraryNotFound
            }

            try services.libraryService.deleteLibrary(managedLibrary, in: context)

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
        guard let library = selectedLibrary, let managedLibrary = fetchLibrary(with: library.id) else {
            errorMessage = "No library selected"
            return
        }

        viewState = .loading

        services.libraryService.scanLibrary(
            managedLibrary,
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
        guard let library = selectedLibrary, let managedLibrary = fetchLibrary(with: library.id) else {
            statistics = nil
            return
        }

        statistics = services.libraryService.getLibraryStatistics(
            for: managedLibrary,
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

    private func fetchLibrary(with id: Library.ID) -> Library? {
        let request: NSFetchRequest<Library> = Library.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
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
            return "User not found"
        case .libraryNotFound:
            return "Library not found"
        case .trackNotFound:
            return "Track not found"
        case .invalidPath:
            return "Invalid file path"
        }
    }
}
