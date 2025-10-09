//
//  PlayerViewModel.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import CoreData
import Combine

/// ViewModel for managing playback state and controls
@MainActor
class PlayerViewModel: BaseViewModel {
    // MARK: - Published Properties

    @Published var currentTrack: TrackViewData?
    @Published var currentTrackID: Track.ID?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7
    @Published var isMuted: Bool = false
    @Published var isPlaying: Bool = false

    private let logger = AppLogger.playerViewModel

    // MARK: - Computed Properties

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    // MARK: - Lifecycle

    private var hasSubscribedToPlayerState = false

    override func onAppear() {
        super.onAppear()
        guard !hasSubscribedToPlayerState else { return }
        hasSubscribedToPlayerState = true
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
        services.audioPlayerService.isMuted = isMuted
    }

    func playTrack(_ track: TrackViewData) {
        play(tracks: [track], startIndex: 0)
    }

    func play(tracks: [TrackViewData], startIndex: Int) {
        let trackIDs = tracks.map(\.id)
        let managedTracks = fetchTracks(for: trackIDs)

        guard !managedTracks.isEmpty else {
            logger.error("❌ No managed tracks found for requested queue")
            return
        }

        guard startIndex >= 0, startIndex < managedTracks.count else {
            logger.error("❌ Start index \(startIndex) out of bounds for queue of size \(managedTracks.count)")
            return
        }

        services.audioPlayerService.setQueue(tracks: managedTracks, startIndex: startIndex)

        do {
            try services.audioPlayerService.play(track: managedTracks[startIndex])
            updateCurrentTrack(with: managedTracks[startIndex])
        } catch {
            handleError(error, context: "Playing track queue")
        }
    }

    // MARK: - Private Methods

    private func subscribeToPlayerState() {
        logger.debug("🔗 PlayerViewModel subscribing to player state")

        // Subscribe to playback state changes
        services.audioPlayerService.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.logger.info("🎵 Playback state changed: \(state)")
                self?.isPlaying = state.isPlaying

                // Update current track from service
                if let currentTrack = self?.services.audioPlayerService.currentTrack {
                    self?.updateCurrentTrack(with: currentTrack)
                    if let trackViewData = self?.currentTrack {
                        self?.logger.debug("📀 Current track: \(trackViewData.title)")
                    }
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
                self?.logger.info("📊 Track changed in ViewModel: \(track.title)")
                self?.duration = track.duration
            }
            .store(in: &cancellables)

        // Sync volume changes
        $volume
            .sink { [weak self] newVolume in
                guard let self = self else { return }
                // Set volume on the audio player service
                self.services.audioPlayerService.volume = newVolume
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
            currentTrackID = nil
            duration = 0
            return
        }

        if track.id == nil {
            track.id = UUID()
        }

        guard let viewData = TrackViewData(track: track) else {
            logger.error("❌ Failed to create view data for track")
            currentTrack = nil
            currentTrackID = nil
            duration = 0
            return
        }

        currentTrack = viewData
        currentTrackID = viewData.id
        duration = viewData.duration
    }

    private func fetchTracks(for ids: [UUID]) -> [Track] {
        guard !ids.isEmpty else { return [] }

        let request: NSFetchRequest<Track> = Track.fetchRequest()
        request.predicate = NSPredicate(format: "id IN %@", ids as NSArray)

        let fetchedTracks = (try? context.fetch(request)) ?? []
        let tracksByID = Dictionary(uniqueKeysWithValues: fetchedTracks.compactMap { track -> (UUID, Track)? in
            guard let id = track.id else { return nil }
            return (id, track)
        })

        return ids.compactMap { id in
            guard let track = tracksByID[id] else {
                logger.warning("⚠️ Missing managed track for id \(id)")
                return nil
            }

            if track.id == nil {
                track.id = id
            }

            return track
        }
    }
}
