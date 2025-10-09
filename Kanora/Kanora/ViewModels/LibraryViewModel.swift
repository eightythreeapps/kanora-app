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
    @Published var selectedLibraryID: Library.ID?
    @Published var viewState: ViewState = .idle
    @Published var statistics: LibraryStatistics?
    @Published var scanProgress: ScanProgress?
    @Published var errorMessage: String?

    // MARK: - Private Properties

    private var currentUser: User?

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

            libraries = fetchedLibraries.map { LibraryViewData(library: $0) }

            if libraries.isEmpty {
                selectedLibrary = nil
                selectedLibraryID = nil
                statistics = nil
            }

            if let selected = selectedLibrary,
               let updatedSelection = libraries.first(where: { $0.id == selected.id }) {
                selectedLibrary = updatedSelection
                selectedLibraryID = updatedSelection.id
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
        selectedLibraryID = library.id
        loadStatistics()
    }

    /// Deletes a library
    func deleteLibrary(_ library: LibraryViewData) {
        do {
            guard let managedLibrary = fetchLibrary(with: library.id) else {
                throw ViewModelError.libraryNotFound
            }

            try services.libraryService.deleteLibrary(managedLibrary, in: context)

            libraries.removeAll(where: { $0.id == library.id })

            if selectedLibrary?.id == library.id {
                if let first = libraries.first {
                    selectLibrary(first)
                } else {
                    selectedLibrary = nil
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
        guard let library = fetchLibrary(with: id) else {
            throw ViewModelError.libraryNotFound
        }

        return library
    }

    /// Scans the selected library for audio files
    func scanLibrary() {
        guard let library = selectedLibrary, let managedLibrary = fetchLibrary(with: library.id) else {
            errorMessage = L10n.Errors.noLibrarySelectedMessage
            return
        }

        viewState = .loading

        services.libraryService.scanLibrary(
            managedLibrary,
            in: context,
            progressHandler: { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self else { return }

                    if let current = self.scanProgress {
                        self.scanProgress = ScanProgress(
                            filesScanned: current.filesScanned,
                            totalFiles: current.totalFiles,
                            currentFile: current.currentFile,
                            percentage: progress
                        )
                    } else {
                        self.scanProgress = ScanProgress(
                            filesScanned: 0,
                            totalFiles: 0,
                            currentFile: nil,
                            percentage: progress
                        )
                    }
                }
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
            return L10n.Errors.noUserFoundMessage
        case .libraryNotFound:
            return L10n.Errors.libraryNotFoundMessage
        case .trackNotFound:
            return L10n.Errors.trackNotFoundMessage
        case .invalidPath:
            return L10n.Errors.invalidPathMessage
        }
    }
}
