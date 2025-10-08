//
//  PlayerControlsView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct PlayerControlsView: View {
    @StateObject private var viewModel: PlayerViewModel
    @ThemeAccess private var theme

    init(services: ServiceContainer) {
        // Use shared PlayerViewModel instance
        _viewModel = StateObject(wrappedValue: PlayerViewModel.shared(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Now playing info
            HStack(spacing: theme.spacing.sm) {
                // Album art placeholder
                RoundedRectangle(cornerRadius: theme.effects.radiusXS)
                    .fill(theme.colors.surfaceSecondary)
                    .frame(width: 50, height: 50)
                    .overlay {
                        if viewModel.currentTrack != nil {
                            Image(systemName: "music.note")
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                    }

                if let track = viewModel.currentTrack {
                    VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                        Text(track.title ?? String(localized: "library.unknown_track"))
                            .font(theme.typography.titleSmall)
                            .lineLimit(1)
                        Text(track.album?.artist?.name ?? String(localized: "library.unknown_artist"))
                            .font(theme.typography.bodySmall)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(L10n.Player.noTrackPlaying)
                        .font(theme.typography.bodySmall)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .frame(minWidth: 150, idealWidth: 250, maxWidth: 300)

            Spacer()

            // Playback controls
            VStack(spacing: theme.spacing.xs) {
                HStack(spacing: theme.spacing.md) {
                    Button(action: viewModel.skipToPrevious) {
                        Image(systemName: "backward.fill")
                            .font(theme.typography.titleSmall)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(theme.typography.displaySmall)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(theme.typography.titleSmall)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)
                }

                // Progress bar
                HStack(spacing: theme.spacing.xs) {
                    Text(viewModel.currentTimeFormatted)
                        .themedSecondaryLabel()
                        .monospacedDigit()

                    Slider(value: $viewModel.currentTime, in: 0...viewModel.duration) { editing in
                        if !editing {
                            viewModel.seek(to: viewModel.currentTime)
                        }
                    }
                    .frame(minWidth: 150, idealWidth: 300, maxWidth: 400)
                    .disabled(viewModel.currentTrack == nil)

                    Text(viewModel.durationFormatted)
                        .themedSecondaryLabel()
                        .monospacedDigit()
                }
            }

            Spacer()

            // Volume control
            HStack(spacing: theme.spacing.sm) {
                Button(action: viewModel.toggleMute) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(.plain)

                Slider(value: $viewModel.volume, in: 0...1)
                    .frame(minWidth: 60, idealWidth: 100, maxWidth: 120)
            }
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface)
        .frame(minHeight: 80, idealHeight: 80, maxHeight: 100)
    }
}

#Preview("Populated") {
    PreviewFactory.makePlayerControlsView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makePlayerControlsView(state: .empty)
}

