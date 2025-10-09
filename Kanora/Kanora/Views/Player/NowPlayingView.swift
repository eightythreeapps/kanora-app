//
//  NowPlayingView.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct NowPlayingView: View {
    @EnvironmentObject private var viewModel: PlayerViewModel
    @ThemeAccess private var theme

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
        VStack(spacing: isCompact ? theme.spacing.lg : theme.spacing.xxxl) {
            if let track = viewModel.currentTrack {
                // Album artwork
                albumArtwork(for: track, geometry: geometry, isCompact: isCompact)
                    .padding(.top, isCompact ? theme.spacing.xl : theme.spacing.xxxl)

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
        .padding(.horizontal, isCompact ? theme.spacing.contentPadding : theme.spacing.xxxl)
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
                RoundedRectangle(cornerRadius: theme.effects.radiusXL)
                    .fill(theme.colors.surfaceSecondary)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(theme.typography.headlineSmall)
                            .foregroundColor(theme.colors.textSecondary.opacity(0.5))
                    }
            }
        }
        .frame(width: artworkSize, height: artworkSize)
        .cornerRadius(theme.effects.radiusXL)
        .clipped()
        .shadow(
            color: theme.effects.shadowLarge.color,
            radius: theme.effects.shadowLarge.radius,
            x: theme.effects.shadowLarge.x,
            y: theme.effects.shadowLarge.y
        )
    }

    private func trackInfo(_ track: TrackViewData) -> some View {
        VStack(spacing: theme.spacing.xs) {
            Text(track.title)
                .font(theme.typography.headlineMedium)
                .foregroundColor(theme.colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(track.artistName)
                .font(theme.typography.titleMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)

            Text(track.albumTitle)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, theme.spacing.xxxl)
    }

    private func progressBar(isCompact: Bool) -> some View {
        VStack(spacing: theme.spacing.xs) {
            // Time slider
            Slider(
                value: $viewModel.currentTime,
                in: 0...max(viewModel.duration, 1)
            ) { editing in
                if !editing {
                    viewModel.seek(to: viewModel.currentTime)
                }
            }
            .disabled(viewModel.currentTrack == nil)
            .tint(theme.colors.accent)

            // Time labels
            HStack {
                Text(viewModel.currentTimeFormatted)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .monospacedDigit()

                Spacer()

                Text("-" + formatRemainingTime())
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, isCompact ? 0 : theme.spacing.xxxl)
    }

    private var playbackControls: some View {
        HStack(spacing: theme.spacing.xxxl) {
            // Previous
            Button(action: viewModel.skipToPrevious) {
                Image(systemName: "backward.fill")
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentTrack == nil)
            .help(L10n.Actions.previous)

            // Play/Pause
            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(theme.typography.headlineLarge)
                    .foregroundColor(theme.colors.accent)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentTrack == nil)
            .help(viewModel.isPlaying ? L10n.Actions.pause : L10n.Actions.play)

            // Next
            Button(action: viewModel.skipToNext) {
                Image(systemName: "forward.fill")
                    .font(theme.typography.titleLarge)
                    .foregroundColor(theme.colors.textPrimary)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentTrack == nil)
            .help(L10n.Actions.next)
        }
    }

    private var additionalControls: some View {
        HStack(spacing: theme.spacing.xxxl) {
            // Left side controls
            HStack(spacing: theme.spacing.lg) {
                // Shuffle
                Button(action: {}) {
                    Image(systemName: "shuffle")
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L10n.Player.shuffleOff)

                // Repeat
                Button(action: {}) {
                    Image(systemName: "repeat")
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L10n.Player.repeatOff)
            }

            Spacer()

            // Right side controls
            HStack(spacing: theme.spacing.md) {
                // Queue
                Button(action: {}) {
                    Image(systemName: "list.bullet")
                        .font(theme.typography.titleSmall)
                        .foregroundColor(theme.colors.textSecondary)
                }
                .buttonStyle(.plain)
                .help(L10n.Player.queue)

                // Volume
                HStack(spacing: theme.spacing.xs) {
                    Button(action: viewModel.toggleMute) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(theme.typography.titleSmall)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Slider(value: $viewModel.volume, in: 0...1)
                        .tint(theme.colors.accent)
                }
            }
        }
        .padding(.horizontal, theme.spacing.xxxl)
    }

    private var emptyState: some View {
        VStack(spacing: theme.spacing.lg) {
            Image(systemName: "music.note")
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.textSecondary.opacity(0.4))

            Text(L10n.Player.noTrackPlaying)
                .font(theme.typography.titleLarge)
                .foregroundColor(theme.colors.textSecondary)

            Text(L10n.Player.selectTrackToPlay)
                .font(theme.typography.bodyMedium)
                .foregroundColor(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(theme.spacing.xxxl)
    }

    // MARK: - Queue Sidebar

    private var queueSidebar: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            // Header
            Text(L10n.Player.upNext)
                .font(theme.typography.titleSmall)
                .foregroundColor(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.md)

            Divider()

            // Queue list (placeholder)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { index in
                        queueItem(
                            title: L10n.Player.queuePlaceholderTitleName(index + 1),
                            artist: L10n.Player.queuePlaceholderArtistName()
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, theme.spacing.lg)
        .background(theme.colors.surfaceSecondary)
    }

    private func queueItem(title: String, artist: String) -> some View {
        HStack(spacing: theme.spacing.sm) {
            // Mini artwork
            RoundedRectangle(cornerRadius: theme.effects.radiusSM)
                .fill(theme.colors.surface)
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "music.note")
                        .font(theme.typography.labelMedium)
                        .foregroundColor(theme.colors.textSecondary)
                }

            // Track info
            VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                Text(title)
                    .font(theme.typography.bodyMedium)
                    .lineLimit(1)

                Text(artist)
                    .font(theme.typography.bodySmall)
                    .foregroundColor(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(theme.typography.labelSmall)
                .foregroundColor(theme.colors.textSecondary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.xs)
        .contentShape(Rectangle())
        .onTapGesture {
            // Play this track
        }
    }

    // MARK: - Helper Methods

    private func formatRemainingTime() -> String {
        let remaining = max(0, viewModel.duration - viewModel.currentTime)
        return DurationFormatter.string(from: remaining)
    }
}

// MARK: - Previews

#Preview("Populated") {
    PreviewFactory.makeNowPlayingView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makeNowPlayingView(state: .empty)
}
