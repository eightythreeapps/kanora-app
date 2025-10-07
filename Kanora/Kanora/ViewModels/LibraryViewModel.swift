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

    @Published var libraries: [Library] = []
    @Published var selectedLibrary: Library?
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
        selectedLibrary?.name ?? "No Library Selected"
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

            libraries = try services.libraryService.fetchLibraries(
                for: user,
                in: context
            )

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

            libraries.append(library)
            selectLibrary(library)
        } catch {
            errorMessage = error.localizedDescription
            handleError(error, context: "Creating library")
        }
    }

    /// Selects a library and loads its statistics
    func selectLibrary(_ library: Library) {
        selectedLibrary = library
        loadStatistics()
    }

    /// Deletes a library
    func deleteLibrary(_ library: Library) {
        do {
            try services.libraryService.deleteLibrary(library, in: context)

            if let index = libraries.firstIndex(where: { $0.id == library.id }) {
                libraries.remove(at: index)
            }

            if selectedLibrary?.id == library.id {
                selectedLibrary = libraries.first
                loadStatistics()
            }
        } catch {
            errorMessage = error.localizedDescription
            handleError(error, context: "Deleting library")
        }
    }

    /// Scans the selected library for audio files
    func scanLibrary() {
        guard let library = selectedLibrary else {
            errorMessage = "No library selected"
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
        guard let library = selectedLibrary else {
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
}

// MARK: - Errors

enum ViewModelError: LocalizedError {
    case userNotFound
    case libraryNotFound
    case invalidPath

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .libraryNotFound:
            return "Library not found"
        case .invalidPath:
            return "Invalid file path"
        }
    }
}
