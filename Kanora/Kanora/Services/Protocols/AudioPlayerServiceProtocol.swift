//
//  AudioPlayerServiceProtocol.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import Foundation
import AVFoundation
import Combine

/// Protocol defining audio playback operations
protocol AudioPlayerServiceProtocol: AnyObject {
    /// Current playback state
    var state: PlaybackState { get }

    /// Currently playing track
    var currentTrack: Track? { get }

    /// Current playback time in seconds
    var currentTime: TimeInterval { get }

    /// Total duration of current track in seconds
    var duration: TimeInterval { get }

    /// Current volume (0.0 to 1.0)
    var volume: Float { get set }

    /// Whether playback is muted
    var isMuted: Bool { get set }

    /// Publisher for playback state changes
    var statePublisher: AnyPublisher<PlaybackState, Never> { get }

    /// Publisher for playback time updates
    var timePublisher: AnyPublisher<TimeInterval, Never> { get }

    /// Plays a track
    /// - Parameter track: The track to play
    func play(track: Track) throws

    /// Resumes playback
    func play()

    /// Pauses playback
    func pause()

    /// Stops playback
    func stop()

    /// Seeks to a specific time
    /// - Parameter time: Time in seconds
    func seek(to time: TimeInterval)

    /// Skips to next track in queue
    func skipToNext()

    /// Skips to previous track in queue
    func skipToPrevious()

    /// Sets the playback queue
    /// - Parameters:
    ///   - tracks: Array of tracks to queue
    ///   - startIndex: Index to start playing from
    func setQueue(tracks: [Track], startIndex: Int)

    /// Gets the current queue
    /// - Returns: Array of tracks in queue
    func getQueue() -> [Track]
}

// MARK: - Supporting Types

/// Playback state enumeration
enum PlaybackState: Equatable {
    case idle
    case loading
    case playing
    case paused
    case stopped
    case error(String)

    var isPlaying: Bool {
        if case .playing = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message) = self {
            return message
        }
        return nil
    }
}
