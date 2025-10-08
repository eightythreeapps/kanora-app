//
//  PlayerViewModel.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import CoreData
import Combine

struct TrackViewData: Identifiable, Equatable {
    let id: Track.ID
    let title: String
    let artistName: String
    let albumTitle: String
    let albumArtistName: String
    let albumArtworkPath: String?
    let duration: TimeInterval

    init(track: Track) {
        let identifier = track.id ?? UUID()
        if track.id == nil {
            track.id = identifier
        }

        self.id = identifier
        self.title = track.title ?? ""
        self.artistName = track.artistName
        self.albumTitle = track.album?.title ?? ""
        self.albumArtistName = track.album?.artist?.name ?? ""
        self.albumArtworkPath = track.album?.artworkPath
        self.duration = track.duration
    }
}

/// ViewModel for managing playback state and controls
@MainActor
class PlayerViewModel: BaseViewModel {
    // MARK: - Shared Instance

    private static var sharedInstance: PlayerViewModel?

    static func shared(context: NSManagedObjectContext, services: ServiceContainer) -> PlayerViewModel {
        if let existing = sharedInstance {
            return existing
        }
        let instance = PlayerViewModel(context: context, services: services)
        sharedInstance = instance
        return instance
    }

    // MARK: - Published Properties

    @Published var currentTrack: TrackViewData?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7
    @Published var isMuted: Bool = false
    @Published var isPlaying: Bool = false

    // MARK: - Computed Properties

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    // MARK: - Lifecycle

    override func onAppear() {
        super.onAppear()
        subscribeToPlayerState()
    }

    // MARK: - Playback Control

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        services.audioPlayerService.play()
    }

    func pause() {
        services.audioPlayerService.pause()
    }

    func stop() {
        services.audioPlayerService.stop()
        updateCurrentTrack(with: nil)
        currentTime = 0
        duration = 0
        isPlaying = false
    }

    func skipToNext() {
        services.audioPlayerService.skipToNext()
    }

    func skipToPrevious() {
        services.audioPlayerService.skipToPrevious()
    }

    func seek(to time: TimeInterval) {
        services.audioPlayerService.seek(to: time)
    }

    func toggleMute() {
        isMuted.toggle()
        if let service = services.audioPlayerService as? AudioPlayerService {
            service.isMuted = isMuted
        }
    }

    func playTrack(_ track: Track) {
        do {
            try services.audioPlayerService.play(track: track)
            updateCurrentTrack(with: track)
        } catch {
            handleError(error, context: "Playing track")
        }
    }

    // MARK: - Private Methods

    private func subscribeToPlayerState() {
        print("🔗 PlayerViewModel subscribing to player state")

        // Subscribe to playback state changes
        services.audioPlayerService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                print("🎵 Playback state changed: \(state)")
                self?.isPlaying = state.isPlaying

                // Update current track from service
                if let currentTrack = self?.services.audioPlayerService.currentTrack {
                    print("📀 Current track: \(currentTrack.title ?? "Unknown")")
                    self?.updateCurrentTrack(with: currentTrack)
                } else if state == .idle || state == .stopped {
                    self?.updateCurrentTrack(with: nil)
                }
            }
            .store(in: &cancellables)

        // Subscribe to time updates
        services.audioPlayerService.timePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)

        // Update duration when track changes
        $currentTrack
            .compactMap { $0 }
            .sink { [weak self] track in
                let displayTitle = track.title.isEmpty ? "Unknown" : track.title
                print("📊 Track changed in ViewModel: \(displayTitle)")
                self?.duration = track.duration
            }
            .store(in: &cancellables)

        // Sync volume changes
        $volume
            .sink { [weak self] newVolume in
                guard let self = self else { return }
                // Set volume on the audio player service
                if let service = self.services.audioPlayerService as? AudioPlayerService {
                    service.volume = newVolume
                }
            }
            .store(in: &cancellables)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func updateCurrentTrack(with track: Track?) {
        guard let track else {
            currentTrack = nil
            duration = 0
            return
        }

        currentTrack = TrackViewData(track: track)
        duration = track.duration
    }
}
