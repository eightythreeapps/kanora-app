//
//  LibraryViewModelTests.swift
//  KanoraTests
//
//  Created by Ben Reed on 06/10/2025.
//

import XCTest
import CoreData
import Combine
@testable import Kanora

@MainActor
final class LibraryViewModelTests: XCTestCase {
    // MARK: - Properties

    var viewModel: LibraryViewModel!
    var container: ServiceContainer!
    var context: NSManagedObjectContext!
    var cancellables: Set<AnyCancellable>!

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

        // Create test library
        let library = Library(
            name: "Test Library",
            path: "/Users/test/Music",
            user: user,
            context: context
        )

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
        XCTAssertNil(viewModel.selectedLibrary)
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
            library: managedLibrary,
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
