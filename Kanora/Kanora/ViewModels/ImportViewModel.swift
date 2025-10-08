//
//  ImportViewModel.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import Foundation
import Combine
import CoreData
import UniformTypeIdentifiers

@MainActor
class ImportViewModel: BaseViewModel {
    // MARK: - Published Properties

    private let logger = AppLogger.importViewModel

    @Published var viewState: ViewState = .idle
    @Published var selectedLibrary: LibraryViewData?
    @Published var availableLibraries: [LibraryViewData] = []
    @Published var importMode: ImportMode = .addToKanora
    @Published var importProgress: Double = 0.0
    @Published var currentFile: String?
    @Published var filesProcessed: Int = 0
    @Published var totalFiles: Int = 0
    @Published var importStatus: String = ""
    @Published var showFilePicker = false
    @Published var showDirectoryPicker = false
    @Published var selectedFiles: [URL] = []
    @Published var selectedDirectory: URL?
    @Published var importErrors: [String] = []

    // MARK: - Computed Properties

    var canImport: Bool {
        !selectedFiles.isEmpty && selectedLibraryID != nil && viewState != .loading
    }

    var statusMessage: String {
        switch viewState {
        case .idle:
            return selectedFiles.isEmpty ? "Select audio files to import" : "\(selectedFiles.count) files selected"
        case .loading:
            return importStatus
        case .loaded:
            return "\(filesProcessed) files imported successfully"
        case .error(let message):
            return message
        }
    }

    // MARK: - Lifecycle

    override func onAppear() {
        super.onAppear()
        loadLibraries()
    }

    // MARK: - Public Methods

    func loadLibraries() {
        do {
            // Fetch all libraries
            let fetchRequest: NSFetchRequest<Library> = Library.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Library.name, ascending: true)]
            let libraries = try context.fetch(fetchRequest)
            availableLibraries = libraries.map { LibraryViewData(library: $0) }

            if let selected = selectedLibrary,
               let updatedSelection = availableLibraries.first(where: { $0.id == selected.id }) {
                selectedLibrary = updatedSelection
            }

            if let selectedLibraryID,
               availableLibraries.contains(where: { $0.id == selectedLibraryID }) {
                // Keep current selection
            } else {
                selectedLibraryID = availableLibraries.first?.id
            }
        } catch {
            handleError(error, context: "Loading libraries")
            viewState = .error("Failed to load libraries")
        }
    }

    func selectFiles(_ urls: [URL]) {
        logger.debug("🎵 selectFiles called with \(urls.count) URLs")
        for url in urls {
            logger.debug("  - \(url.lastPathComponent) (\(url.pathExtension))")
        }

        // Filter for valid audio files
        let validFiles = urls.filter { url in
            let isValid = services.fileImportService.isValidAudioFile(url)
            logger.debug("  - \(url.lastPathComponent): valid = \(isValid)")
            return isValid
        }

        logger.info("✅ Valid files: \(validFiles.count)")
        selectedFiles = validFiles

        if validFiles.count != urls.count {
            let invalidCount = urls.count - validFiles.count
            importErrors.append("\(invalidCount) invalid files skipped")
        }

        logger.debug("📁 selectedFiles now contains: \(selectedFiles.count) files")
    }

    func removeFile(at index: Int) {
        guard index < selectedFiles.count else { return }
        selectedFiles.remove(at: index)
    }

    func clearFiles() {
        selectedFiles.removeAll()
        selectedDirectory = nil
        importErrors.removeAll()
        viewState = .idle
    }

    func selectDirectory(_ directoryURL: URL) {
        logger.debug("📂 selectDirectory called: \(directoryURL.path)")
        selectedDirectory = directoryURL

        // Scan directory for audio files
        let audioFiles = services.fileImportService.scanDirectory(directoryURL)
        selectedFiles = audioFiles

        logger.debug("🎵 Found \(audioFiles.count) audio files in directory")
    }

    func startImport() {
        logger.debug("🚀 startImport called")
        logger.debug("📁 Selected files count: \(selectedFiles.count)")
        logger.debug("📂 Import mode: \(importMode.displayName)")
        logger.debug("📚 Selected library: \(selectedLibrary?.name ?? "nil")")

        guard let libraryViewData = selectedLibrary,
              let library = fetchLibrary(with: libraryViewData.id) else {
            print("❌ No library selected")
            viewState = .error("No library selected")
            return
        }

        // For "Point at Directory" mode, use the pointAtDirectory method
        if importMode == .pointAtDirectory {
            guard let directory = selectedDirectory else {
                logger.error("❌ No directory selected")
                viewState = .error("No directory selected for Point at Directory mode")
                return
            }

            logger.debug("📍 Pointing library at directory: \(directory.path)")
            viewState = .loading
            importProgress = 0.0
            filesProcessed = 0
            importErrors.removeAll()

            services.fileImportService
                .pointAtDirectory(directory, library: library, in: context)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }
                        switch completion {
                        case .finished:
                            self.viewState = .loaded
                            self.importStatus = "Library successfully pointed at \(directory.lastPathComponent)"
                            self.selectedFiles.removeAll()
                            self.selectedDirectory = nil
                        case .failure(let error):
                            self.viewState = .error(error.localizedDescription)
                            self.handleError(error, context: "Pointing at directory")
                        }
                    },
                    receiveValue: { [weak self] progress in
                        guard let self = self else { return }
                        self.importProgress = progress.percentage
                        self.filesProcessed = progress.filesProcessed
                        self.totalFiles = progress.totalFiles
                        self.currentFile = progress.currentFile
                        self.importStatus = self.statusForProgress(progress)
                    }
                )
                .store(in: &cancellables)
            return
        }

        // For "Add to Kanora" mode, files must be selected
        guard !selectedFiles.isEmpty else {
            logger.error("❌ No files selected")
            viewState = .error("No files selected")
            return
        }

        logger.info("✅ Starting import of \(selectedFiles.count) files")
        viewState = .loading
        importProgress = 0.0
        filesProcessed = 0
        totalFiles = selectedFiles.count
        importErrors.removeAll()

        logger.debug("🔄 Calling fileImportService.importFiles with mode: \(importMode.displayName)")
        services.fileImportService
            .importFiles(selectedFiles, into: library, in: context, mode: importMode)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    logger.info("🏁 Import completion: \(completion)")
                    switch completion {
                    case .finished:
                        logger.info("✅ Import finished successfully - \(self.filesProcessed) files")
                        self.viewState = .loaded
                        self.importStatus = "\(self.filesProcessed) files imported successfully"
                        self.selectedFiles.removeAll()
                    case .failure(let error):
                        logger.error("❌ Import failed: \(error.localizedDescription)")
                        self.viewState = .error(error.localizedDescription)
                        self.handleError(error, context: "Importing files")
                    }
                },
                receiveValue: { [weak self] progress in
                    guard let self = self else { return }
                    logger.debug("📊 Progress: \(progress.filesProcessed)/\(progress.totalFiles) - \(progress.status)")
                    self.importProgress = progress.percentage
                    self.filesProcessed = progress.filesProcessed
                    self.currentFile = progress.currentFile
                    self.importStatus = self.statusForProgress(progress)
                }
            )
            .store(in: &cancellables)
        logger.debug("💾 Publisher stored in cancellables")
    }

    // MARK: - Drag and Drop

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        var urls: [URL] = []

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    }
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.selectFiles(urls)
        }

        return true
    }

    // MARK: - Private Methods

    private func statusForProgress(_ progress: ImportProgress) -> String {
        switch progress.status {
        case .preparing:
            return "Preparing..."
        case .importing:
            if let file = progress.currentFile {
                return "Importing \(file)"
            }
            return "Importing files..."
        case .extractingMetadata:
            return "Extracting metadata..."
        case .copyingFile:
            return "Copying files..."
        case .complete:
            return "\(progress.filesProcessed) files imported"
        case .error(let message):
            return message
        }
    }

    private func fetchLibrary(with id: Library.ID) -> Library? {
        let request: NSFetchRequest<Library> = Library.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
}
