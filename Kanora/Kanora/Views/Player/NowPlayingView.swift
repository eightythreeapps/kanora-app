//
//  NowPlayingView.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct NowPlayingView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 600
            let showQueue = geometry.size.width > 800

            HStack(spacing: 0) {
                // Main now playing area
                mainContent(isCompact: isCompact, geometry: geometry)
                    .frame(maxWidth: .infinity)

                // Queue sidebar
                if showQueue {
                    queueSidebar
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }

    // MARK: - Main Content

    private func mainContent(isCompact: Bool, geometry: GeometryProxy) -> some View {
        VStack(spacing: isCompact ? 16 : 32) {
            if let track = viewModel.currentTrack {
                // Album artwork
                albumArtwork(for: track, geometry: geometry, isCompact: isCompact)
                    .padding(.top, isCompact ? 20 : 40)

                // Track info
                trackInfo(track)

                // Progress bar
                progressBar(isCompact: isCompact)

                // Playback controls
                playbackControls

                // Additional controls
                if !isCompact {
                    additionalControls
                }
            } else {
                emptyState
            }

            Spacer()
        }
        .padding(.horizontal, isCompact ? 20 : 60)
    }

    private func albumArtwork(for track: TrackViewData, geometry: GeometryProxy, isCompact: Bool) -> some View {
        let maxSize: CGFloat = isCompact ? min(geometry.size.width - 40, 250) : min(geometry.size.width * 0.5, 400)
        let artworkSize = min(maxSize, geometry.size.height * 0.4)

        return Group {
            if let artworkImage = track.artworkImage {
                #if os(macOS)
                Image(nsImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                #else
                Image(uiImage: artworkImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                #endif
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: artworkSize * 0.3))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
            }
        }
        .frame(width: artworkSize, height: artworkSize)
        .cornerRadius(12)
        .clipped()
        .shadow(radius: 20, y: 10)
    }

    private func trackInfo(_ track: TrackViewData) -> some View {
        VStack(spacing: 8) {
            Text(track.title)
                .font(.system(size: 32, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(track.artistName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)

            Text(track.albumTitle)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 40)
    }

    private func progressBar(isCompact: Bool) -> some View {
        VStack(spacing: 12) {
            // Time slider
            Slider(
                value: $viewModel.currentTime,
                in: 0...max(viewModel.duration, 1)
            ) { editing in
                if !editing {
                    viewModel.seek(to: viewModel.currentTime)
                }
            }
            .accentColor(.primary)

            // Time labels
            HStack {
                Text(viewModel.currentTimeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Spacer()

                Text("-" + formatRemainingTime())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, isCompact ? 0 : 40)
    }

    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Previous
            Button(action: viewModel.skipToPrevious) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 36))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentTrack == nil)
            .help(String(localized: "actions.previous"))

            // Play/Pause
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 80))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentTrack == nil)
            .help(viewModel.isPlaying ? String(localized: "actions.pause") : String(localized: "actions.play"))

            // Next
            Button(action: viewModel.skipToNext) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 36))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentTrack == nil)
            .help(String(localized: "actions.next"))
        }
        .foregroundColor(.primary)
    }

    private var additionalControls: some View {
        HStack(spacing: 60) {
            // Left side controls
            HStack(spacing: 24) {
                // Shuffle
                Button(action: {}) {
                    Image(systemName: "shuffle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help(String(localized: "player.shuffle_off"))

                // Repeat
                Button(action: {}) {
                    Image(systemName: "repeat")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help(String(localized: "player.repeat_off"))
            }

            Spacer()

            // Right side controls
            HStack(spacing: 16) {
                // Queue
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help(String(localized: "player.queue"))

                // Volume
                HStack(spacing: 12) {
                    Button(action: viewModel.toggleMute) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Slider(value: $viewModel.volume, in: 0...1)
                        .accentColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))

            Text(L10n.Player.noTrackPlaying)
                .font(.title2)
                .foregroundColor(.secondary)

            Text(L10n.Player.selectTrackToPlay)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Queue Sidebar

    private var queueSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text(L10n.Player.upNext)
                .font(.headline)
                .padding(.horizontal)

            Divider()

            // Queue list (placeholder)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        queueItem(title: "Track \(index + 1)", artist: "Artist Name")
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical)
#if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
#else
        .background(Color(.secondarySystemBackground))
#endif
    }

    private func queueItem(title: String, artist: String) -> some View {
        HStack(spacing: 12) {
            // Mini artwork
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "music.note")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Play this track
        }
    }

    // MARK: - Helper Methods

    private func formatRemainingTime() -> String {
        let remaining = max(0, viewModel.duration - viewModel.currentTime)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#Preview("Populated") {
    PreviewFactory.makeNowPlayingView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makeNowPlayingView(state: .empty)
}
