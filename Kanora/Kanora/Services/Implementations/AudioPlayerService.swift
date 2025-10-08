//
//  AudioPlayerService.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import AVFoundation
import Combine

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Default implementation of AudioPlayerServiceProtocol
class AudioPlayerService: NSObject, AudioPlayerServiceProtocol, AVAudioPlayerDelegate {
    // MARK: - Properties

    private let stateSubject = CurrentValueSubject<PlaybackState, Never>(.idle)
    private let timeSubject = CurrentValueSubject<TimeInterval, Never>(0)

    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var queue: [Track] = []
    private var currentIndex: Int = 0
    private var savedVolume: Float = 1.0

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
        set {
            if newValue {
                savedVolume = player?.volume ?? 1.0
                player?.volume = 0
            } else {
                player?.volume = savedVolume
            }
        }
    }

    var statePublisher: AnyPublisher<PlaybackState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var timePublisher: AnyPublisher<TimeInterval, Never> {
        timeSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    override init() {
        super.init()
        configureAudioSession()
    }

    deinit {
        stopTimer()
        player?.stop()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        #if os(macOS)
        // macOS doesn't require explicit audio session configuration
        print("🔊 Audio session configured for macOS")
        #else
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            print("🔊 Audio session configured for iOS")
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
            stateSubject.send(.error("Audio session configuration failed"))
        }
        #endif
    }

    // MARK: - Playback Control

    func play(track: Track) throws {
        print("🎵 AudioPlayerService.play(track:) called")
        print("📂 Track: \(track.title ?? "Unknown") - \(track.filePath ?? "no path")")

        stateSubject.send(.loading)

        guard let filePath = track.filePath else {
            print("❌ No file path for track")
            stateSubject.send(.error("No file path"))
            throw PlaybackError.noFilePath
        }

        let fileURL = URL(fileURLWithPath: filePath)

        guard FileManager.default.fileExists(atPath: filePath) else {
            print("❌ File not found at path: \(filePath)")
            stateSubject.send(.error("File not found: \(fileURL.lastPathComponent)"))
            throw PlaybackError.fileNotFound
        }

        print("✅ File exists, creating AVAudioPlayer")

        do {
            // Stop current playback
            player?.stop()
            stopTimer()

            // Create new player
            let newPlayer = try AVAudioPlayer(contentsOf: fileURL)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            newPlayer.volume = savedVolume

            player = newPlayer

            print("✅ AVAudioPlayer created successfully")
            print("⏱️ Duration: \(newPlayer.duration)s")
            print("🎚️ Volume: \(newPlayer.volume)")

            // Start playback
            let success = newPlayer.play()

            if success {
                print("✅ Playback started")
                stateSubject.send(.playing)
                startTimer()
            } else {
                print("❌ Failed to start playback")
                stateSubject.send(.error("Failed to start playback"))
                throw PlaybackError.playbackFailed
            }

        } catch {
            print("❌ AVAudioPlayer error: \(error.localizedDescription)")
            stateSubject.send(.error("Playback error: \(error.localizedDescription)"))
            throw error
        }
    }

    func play() {
        print("▶️ Resume playback")
        guard let player = player else {
            print("❌ No player available")
            return
        }

        player.play()
        stateSubject.send(.playing)
        startTimer()
    }

    func pause() {
        print("⏸️ Pause playback")
        guard let player = player else {
            print("❌ No player available")
            return
        }

        player.pause()
        stateSubject.send(.paused)
        stopTimer()
    }

    func stop() {
        print("⏹️ Stop playback")
        guard let player = player else {
            print("❌ No player available")
            return
        }

        player.stop()
        player.currentTime = 0
        stateSubject.send(.stopped)
        stopTimer()
        timeSubject.send(0)
    }

    func seek(to time: TimeInterval) {
        print("⏩ Seek to \(time)s")
        guard let player = player else {
            print("❌ No player available")
            return
        }

        guard time >= 0 && time <= player.duration else {
            print("❌ Invalid seek time: \(time)")
            return
        }

        player.currentTime = time
        timeSubject.send(time)
    }

    func skipToNext() {
        print("⏭️ Skip to next track")
        guard currentIndex < queue.count - 1 else {
            print("⚠️ Already at last track")
            return
        }

        currentIndex += 1
        print("📍 Now at index \(currentIndex)/\(queue.count)")

        if let track = currentTrack {
            try? play(track: track)
        }
    }

    func skipToPrevious() {
        print("⏮️ Skip to previous track")
        guard currentIndex > 0 else {
            print("⚠️ Already at first track")
            return
        }

        currentIndex -= 1
        print("📍 Now at index \(currentIndex)/\(queue.count)")

        if let track = currentTrack {
            try? play(track: track)
        }
    }

    func setQueue(tracks: [Track], startIndex: Int) {
        print("📝 Setting queue with \(tracks.count) tracks, starting at index \(startIndex)")
        self.queue = tracks
        self.currentIndex = startIndex
    }

    func getQueue() -> [Track] {
        return queue
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🏁 Audio finished playing, success: \(flag)")

        if flag {
            // Auto-advance to next track if available
            if currentIndex < queue.count - 1 {
                print("⏭️ Auto-advancing to next track")
                skipToNext()
            } else {
                print("🔚 Reached end of queue")
                stateSubject.send(.stopped)
                stopTimer()
                timeSubject.send(0)
            }
        } else {
            stateSubject.send(.error("Playback did not complete successfully"))
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ Decode error: \(error?.localizedDescription ?? "unknown")")
        stateSubject.send(.error("Decode error: \(error?.localizedDescription ?? "unknown")"))
        stopTimer()
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

// MARK: - Playback Errors

enum PlaybackError: LocalizedError {
    case noFilePath
    case fileNotFound
    case playbackFailed
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .noFilePath:
            return "Track has no file path"
        case .fileNotFound:
            return "Audio file not found"
        case .playbackFailed:
            return "Failed to start playback"
        case .unsupportedFormat:
            return "Unsupported audio format"
        }
    }
}
