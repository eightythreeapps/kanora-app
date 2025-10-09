//
//  LibraryViewModelTests.swift
//  KanoraTests
//
//  Created by Ben Reed on 06/10/2025.
//

import XCTest
import CoreData
import Combine
import Foundation
@testable import Kanora

@MainActor
final class LibraryViewModelTests: XCTestCase {
    // MARK: - Properties

    var viewModel: LibraryViewModel!
    var container: ServiceContainer!
    var context: NSManagedObjectContext!
    var testLibrary: Library!
    var cancellables: Set<AnyCancellable>!
    var libraryDirectoryURL: URL!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory Core Data stack
        let persistence = PersistenceController(inMemory: true)
        context = persistence.viewContext

        // Create test user
        let user = User(
            username: "testuser",
            email: "test@example.com",
            context: context
        )

        // Create temporary directory with audio files for scanning tests
        libraryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("LibraryViewModelTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: libraryDirectoryURL, withIntermediateDirectories: true)

        let audioFileURLs = [
            libraryDirectoryURL.appendingPathComponent("track1.mp3"),
            libraryDirectoryURL.appendingPathComponent("track2.flac")
        ]

        for url in audioFileURLs {
            let created = FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)
            XCTAssertTrue(created, "Failed to create test audio file at \(url.path)")
        }

        // Create a non-audio file to ensure it is ignored during scanning
        _ = FileManager.default.createFile(
            atPath: libraryDirectoryURL.appendingPathComponent("notes.txt").path,
            contents: Data(),
            attributes: nil
        )

        // Create test library
        let library = Library(
            name: "Test Library",
            path: libraryDirectoryURL.path,
            user: user,
            context: context
        )
        testLibrary = library

        try context.save()

        // Create service container with test data
        container = ServiceContainer(persistence: persistence)

        // Create view model
        viewModel = LibraryViewModel(context: context, services: container)

        // Initialize cancellables
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        container = nil
        context = nil
        testLibrary = nil
        if let directoryURL = libraryDirectoryURL {
            try? FileManager.default.removeItem(at: directoryURL)
            libraryDirectoryURL = nil
        }
        try await super.tearDown()
    }

    // MARK: - Tests

    func testLoadLibraries() async throws {
        // When
        viewModel.loadLibraries()

        // Wait for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertEqual(viewModel.viewState, .loaded)
        XCTAssertEqual(viewModel.libraries.count, 1)
        XCTAssertEqual(viewModel.libraries.first?.name, "Test Library")
    }

    func testSelectLibrary() async throws {
        // Given
        viewModel.loadLibraries()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let library = viewModel.libraries.first else {
            XCTFail("No libraries found")
            return
        }

        // When
        viewModel.selectLibrary(library)

        // Then
        XCTAssertEqual(viewModel.selectedLibraryID, library.id)
        XCTAssertEqual(viewModel.selectedLibrary?.id, library.id)
        XCTAssertNotNil(viewModel.statistics)
    }

    func testCreateLibrary() async throws {
        // When
        viewModel.loadLibraries()
        try await Task.sleep(nanoseconds: 100_000_000)

        viewModel.createLibrary(name: "New Library", path: "/Users/test/NewMusic")

        // Then
        XCTAssertEqual(viewModel.libraries.count, 2)
        XCTAssertTrue(viewModel.libraries.contains { $0.name == "New Library" })
    }

    func testDeleteLibrary() async throws {
        // Given
        viewModel.loadLibraries()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let library = viewModel.libraries.first else {
            XCTFail("No libraries found")
            return
        }

        // When
        viewModel.deleteLibrary(library)

        // Then
        XCTAssertEqual(viewModel.libraries.count, 0)
        XCTAssertNil(viewModel.selectedLibraryID)
    }

    func testStatistics() async throws {
        // Given
        viewModel.loadLibraries()
        try await Task.sleep(nanoseconds: 100_000_000)

        guard let library = viewModel.libraries.first else {
            XCTFail("No libraries found")
            return
        }

        // Create test data
        let managedLibrary = try XCTUnwrap(fetchLibrary(with: library.id))
        let artist = Artist(
            name: "Test Artist",
            library: testLibrary,
            context: context
        )
        let album = Album(
            title: "Test Album",
            artist: artist,
            year: 2025,
            context: context
        )
        _ = Track(
            title: "Test Track",
            filePath: "/test/track.mp3",
            duration: 180.0,
            format: "mp3",
            album: album,
            context: context
        )
        try context.save()

        // When
        viewModel.selectLibrary(library)

        // Then
        XCTAssertNotNil(viewModel.statistics)
        XCTAssertEqual(viewModel.statistics?.artistCount, 1)
        XCTAssertEqual(viewModel.statistics?.albumCount, 1)
        XCTAssertEqual(viewModel.statistics?.trackCount, 1)
    }

    func testViewStateTransitions() async throws {
        // Given
        XCTAssertEqual(viewModel.viewState, .idle)

        // When loading
        viewModel.loadLibraries()
        XCTAssertTrue(viewModel.viewState.isLoading || viewModel.viewState == .loaded)

        // Wait for completion
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then loaded
        XCTAssertEqual(viewModel.viewState, .loaded)
    }

    func testScanLibraryPublishesProgress() async throws {
        // Given
        viewModel.loadLibraries()
        try await Task.sleep(nanoseconds: 100_000_000)

        let expectation = expectation(description: "Scan completes")
        expectation.assertForOverFulfill = false

        var progressUpdates: [ScanProgress] = []

        viewModel.$scanProgress
            .compactMap { $0 }
            .sink { progress in
                progressUpdates.append(progress)
                if progress.isComplete {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        viewModel.scanLibrary()

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)

        XCTAssertEqual(viewModel.viewState, .loaded)
        XCTAssertEqual(progressUpdates.last?.percentage, 1.0, accuracy: 0.0001)
        XCTAssertEqual(progressUpdates.last?.filesScanned, 2)
        XCTAssertEqual(progressUpdates.last?.totalFiles, 2)
        XCTAssertTrue(progressUpdates.contains { $0.percentage > 0 && $0.percentage < 1.0 })
    }
}

private extension LibraryViewModelTests {
    func fetchLibrary(with id: Library.ID) throws -> Library {
        let request: NSFetchRequest<Library> = Library.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let libraries = try context.fetch(request)
        guard let library = libraries.first else {
            XCTFail("Library with id \(id) not found")
            throw NSError(domain: "LibraryViewModelTests", code: 0)
        }
        return library
    }
}
