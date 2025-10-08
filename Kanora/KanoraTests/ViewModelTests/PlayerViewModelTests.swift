//
//  PlayerViewModelTests.swift
//  KanoraTests
//
//  Created by OpenAI on 2024.
//

import XCTest
import CoreData
import Combine
@testable import Kanora

@MainActor
final class PlayerViewModelTests: XCTestCase {
    private var viewModel: PlayerViewModel!
    private var container: ServiceContainer!
    private var context: NSManagedObjectContext!
    private var audioService: MockAudioPlayerService!
    private var cancellables: Set<AnyCancellable>!
    private var album: Album!

    override func setUp() async throws {
        try await super.setUp()

        audioService = MockAudioPlayerService()
        container = ServiceContainer.mock(audioPlayerService: audioService)
        context = container.persistence.viewContext
        viewModel = PlayerViewModel(context: context, services: container)
        cancellables = Set<AnyCancellable>()

        // Seed required Core Data objects
        let user = User(username: "tester", email: "tester@example.com", context: context)
        let library = Library(name: "Test Library", path: "/", user: user, context: context)
        let artist = Artist(name: "Test Artist", library: library, context: context)
        album = Album(title: "Test Album", artist: artist, year: 2024, context: context)

        try context.save()
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        container = nil
        context = nil
        audioService = nil
        album = nil
        try await super.tearDown()
    }

    func testCurrentTrackPublishesViewData() async throws {
        // Given
        let track = makeTrack(title: "Sample Track", trackNumber: 1)
        let expectedViewData = try XCTUnwrap(TrackViewData(track: track))

        let expectation = expectation(description: "Publishes current track view data")
        viewModel.$currentTrack
            .dropFirst()
            .sink { viewData in
                guard let viewData else { return }
                XCTAssertEqual(viewData, expectedViewData)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        viewModel.onAppear()

        // When
        audioService.currentTrack = track
        audioService.emit(state: .playing)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.currentTrackID, expectedViewData.id)
    }

    func testPlayTracksQueuesAndPlaysUsingViewData() async throws {
        // Given
        let firstTrack = makeTrack(title: "First", trackNumber: 1)
        let secondTrack = makeTrack(title: "Second", trackNumber: 2)
        let queue = [firstTrack, secondTrack].compactMap { TrackViewData(track: $0) }
        let expectedCurrent = try XCTUnwrap(queue.last)

        let expectation = expectation(description: "Playback starts for selected view data")
        viewModel.$currentTrack
            .dropFirst()
            .sink { viewData in
                guard let viewData else { return }
                if viewData.id == expectedCurrent.id {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.onAppear()

        // When
        viewModel.play(tracks: queue, startIndex: 1)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(audioService.lastQueue?.compactMap(\.id), [firstTrack.id, secondTrack.id])
        XCTAssertEqual(audioService.lastQueueIndex, 1)
        XCTAssertEqual(audioService.playedTrackIDs.last, expectedCurrent.id)
        XCTAssertEqual(viewModel.currentTrackID, expectedCurrent.id)
    }

    // MARK: - Helpers

    @discardableResult
    private func makeTrack(title: String, trackNumber: Int) -> Track {
        let track = Track(
            title: title,
            filePath: "/tmp/\(title).mp3",
            duration: 180,
            format: "mp3",
            album: album,
            context: context
        )
        track.trackNumber = Int16(trackNumber)
        track.discNumber = 1
        try? context.save()
        return track
    }
}

// MARK: - Mock Audio Player Service

final class MockAudioPlayerService: AudioPlayerServiceProtocol {
    var state: PlaybackState = .idle
    var currentTrack: Track?
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var volume: Float = 1.0
    var isMuted: Bool = false

    private let stateSubject = PassthroughSubject<PlaybackState, Never>()
    private let timeSubject = PassthroughSubject<TimeInterval, Never>()

    private(set) var lastQueue: [Track]?
    private(set) var lastQueueIndex: Int?
    private(set) var playedTrackIDs: [UUID] = []

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var timePublisher: AnyPublisher<TimeInterval, Never> {
        timeSubject.eraseToAnyPublisher()
    }

    func play(track: Track) throws {
        currentTrack = track
        duration = track.duration
        if let id = track.id {
            playedTrackIDs.append(id)
        }
        emit(state: .playing)
    }

    func play() {
        emit(state: .playing)
    }

    func pause() {
        emit(state: .paused)
    }

    func stop() {
        emit(state: .stopped)
    }

    func seek(to time: TimeInterval) {
        currentTime = time
        timeSubject.send(time)
    }

    func skipToNext() {}

    func skipToPrevious() {}

    func setQueue(tracks: [Track], startIndex: Int) {
        lastQueue = tracks
        lastQueueIndex = startIndex
    }

    func getQueue() -> [Track] {
        lastQueue ?? []
    }

    func emit(state: PlaybackState) {
        self.state = state
        stateSubject.send(state)
    }
}
