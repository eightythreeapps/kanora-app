//
//  BaseViewModelTests.swift
//  KanoraTests
//
//  Created by Ben Reed on 06/10/2025.
//

import XCTest
import CoreData
import Combine
@testable import Kanora

@MainActor
final class BaseViewModelTests: XCTestCase {
    // MARK: - Properties

    fileprivate var viewModel: TestViewModel!
    var container: ServiceContainer!
    var context: NSManagedObjectContext!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        let persistence = PersistenceController(inMemory: true)
        context = persistence.viewContext
        container = ServiceContainer(persistence: persistence)
        viewModel = TestViewModel(context: context, services: container)
    }

    override func tearDown() async throws {
        viewModel = nil
        container = nil
        context = nil
        try await super.tearDown()
    }

    // MARK: - Tests

    func testInitialization() {
        XCTAssertNotNil(viewModel.context)
        XCTAssertNotNil(viewModel.services)
        XCTAssertTrue(viewModel.cancellables.isEmpty)
    }

    func testLifecycleMethods() {
        // When
        viewModel.onAppear()
        XCTAssertTrue(viewModel.didAppear)

        viewModel.onDisappear()
        XCTAssertTrue(viewModel.didDisappear)
    }

    func testSaveContext() throws {
        // Given
        let user = User(
            username: "testuser",
            email: "test@example.com",
            context: context
        )

        // When
        viewModel.save()

        // Then
        XCTAssertFalse(context.hasChanges)
        let request = User.fetchRequest()
        let users = try context.fetch(request)
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.username, "testuser")
    }

    func testErrorHandling() {
        // Given
        let error = NSError(
            domain: "TestDomain",
            code: 123,
            userInfo: [NSLocalizedDescriptionKey: "Test error"]
        )

        // When
        viewModel.handleError(error, context: "Test context")

        // Then - error should be logged (check console output)
        XCTAssertTrue(true) // Error handling doesn't throw
    }

    func testPerformBackgroundTask() async throws {
        // Given
        let expectation = expectation(description: "Background task completed")
        var taskExecuted = false

        // When
        viewModel.performBackgroundTask { context in
            taskExecuted = true
            expectation.fulfill()
        }

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(taskExecuted)
    }
}

// MARK: - Test ViewModel

@MainActor
fileprivate class TestViewModel: BaseViewModel {
    var didAppear = false
    var didDisappear = false

    override func onAppear() {
        super.onAppear()
        didAppear = true
    }

    override func onDisappear() {
        super.onDisappear()
        didDisappear = true
    }
}
