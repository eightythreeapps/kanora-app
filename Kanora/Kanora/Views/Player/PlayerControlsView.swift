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

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: PlayerViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Now playing info
            HStack(spacing: 12) {
                // Album art placeholder
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        if viewModel.currentTrack != nil {
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                        }
                    }

                if let track = viewModel.currentTrack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title ?? String(localized: "library.unknown_track"))
                            .font(.headline)
                            .lineLimit(1)
                        Text(track.album?.artist?.name ?? String(localized: "library.unknown_artist"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(L10n.Player.noTrackPlaying)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 250, alignment: .leading)

            Spacer()

            // Playback controls
            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    Button(action: viewModel.skipToPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 36))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)

                    Button(action: viewModel.skipToNext) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.currentTrack == nil)
                }

                // Progress bar
                HStack(spacing: 8) {
                    Text(viewModel.currentTimeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()

                    Slider(value: $viewModel.currentTime, in: 0...viewModel.duration) { editing in
                        if !editing {
                            viewModel.seek(to: viewModel.currentTime)
                        }
                    }
                    .frame(width: 300)
                    .disabled(viewModel.currentTrack == nil)

                    Text(viewModel.durationFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Volume control
            HStack(spacing: 12) {
                Button(action: viewModel.toggleMute) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .buttonStyle(.plain)

                Slider(value: $viewModel.volume, in: 0...1)
                    .frame(width: 100)
            }
            .frame(width: 250, alignment: .trailing)
        }
        .padding()
#if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
#else
        .background(Color(.systemBackground))
#endif
        .frame(height: 80)
    }
}

#Preview("Populated") {
    PreviewFactory.makePlayerControlsView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makePlayerControlsView(state: .empty)
}

