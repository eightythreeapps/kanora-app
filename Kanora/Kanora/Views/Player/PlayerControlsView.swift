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
    @EnvironmentObject private var viewModel: PlayerViewModel

    var body: some View {
        HStack(spacing: 12) {
            // Now playing info
            HStack(spacing: 12) {
                // Album art placeholder
                Group {
                    if let track = viewModel.currentTrack,
                       let artworkImage = track.artworkImage {
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
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundColor(.secondary)
                            }
                    }
                }
                .frame(width: 50, height: 50)
                .cornerRadius(4)

                if let track = viewModel.currentTrack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.headline)
                            .lineLimit(1)
                        Text(track.artistName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(L10n.Player.noTrackPlaying)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: 150, idealWidth: 250, maxWidth: 300)

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
                    .frame(minWidth: 150, idealWidth: 300, maxWidth: 400)
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
                    .frame(minWidth: 60, idealWidth: 100, maxWidth: 120)
            }
            .frame(minWidth: 100, idealWidth: 150, maxWidth: 200)
        }
        .padding()
#if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
#else
        .background(Color(.systemBackground))
#endif
        .frame(minHeight: 80, idealHeight: 80, maxHeight: 100)
    }
}

#Preview("Populated") {
    PreviewFactory.makePlayerControlsView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makePlayerControlsView(state: .empty)
}

