//
//  AudioPlayerService.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import AVFoundation
import Combine

/// Default implementation of AudioPlayerServiceProtocol
class AudioPlayerService: AudioPlayerServiceProtocol {
    // MARK: - Properties

    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var queue: [Track] = []
    private var currentIndex: Int = 0

    // MARK: - AudioPlayerServiceProtocol

    var state: PlaybackState {
        stateSubject.value
    }

    var currentTrack: Track? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    var currentTime: TimeInterval {
        player?.currentTime ?? 0
    }

    var duration: TimeInterval {
        player?.duration ?? 0
    }

    var volume: Float {
        get { player?.volume ?? 1.0 }
        set { player?.volume = newValue }
    }

    var isMuted: Bool {
        get { player?.volume == 0 }
        set { player?.volume = newValue ? 0 : 1.0 }
    }

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var timePublisher: AnyPublisher<TimeInterval, Never> {
        timeSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    init() {
        // TODO: Initialize AVAudioPlayer and configure audio session
    }

    // MARK: - Playback Control

    func play(track: Track) throws {
        // TODO: Implement actual playback
        // For now, just update state
        stateSubject.send(.loading)

        guard let filePath = track.filePath,
              FileManager.default.fileExists(atPath: filePath) else {
            stateSubject.send(.error("File not found"))
            return
        }

        // Mock playback
        stateSubject.send(.playing)
        startTimer()
    }

    func play() {
        player?.play()
        stateSubject.send(.playing)
        startTimer()
    }

    func pause() {
        player?.pause()
        stateSubject.send(.paused)
        stopTimer()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        stateSubject.send(.stopped)
        stopTimer()
        timeSubject.send(0)
    }

    func seek(to time: TimeInterval) {
        player?.currentTime = time
        timeSubject.send(time)
    }

    func skipToNext() {
        guard currentIndex < queue.count - 1 else { return }
        currentIndex += 1
        if let track = currentTrack {
            try? play(track: track)
        }
    }

    func skipToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        if let track = currentTrack {
            try? play(track: track)
        }
    }

    func setQueue(tracks: [Track], startIndex: Int) {
        self.queue = tracks
        self.currentIndex = startIndex
    }

    func getQueue() -> [Track] {
        return queue
    }

    // MARK: - Private Helpers

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timeSubject.send(self.currentTime)
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
