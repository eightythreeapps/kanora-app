//
//  ImportFilesView.swift
//  Kanora
//
//  Created by Claude on 07/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportFilesView: View {
    @StateObject private var viewModel: ImportViewModel
    private let logger = AppLogger.importView

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: ImportViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)

                Text(L10n.Navigation.importFiles)
                    .font(.title.bold())

                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            // Library Selector
            if !viewModel.availableLibraries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Import.selectLibrary)
                        .font(.headline)

                    Picker("", selection: $viewModel.selectedLibrary) {
                        ForEach(viewModel.availableLibraries, id: \.self) { library in
                            Text(library.name ?? String(localized: "library.unknown"))
                                .tag(library as Library?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
            }

            // Import Mode Selector - Card-based
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Import Method")
                    .font(.headline)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    ForEach(ImportMode.allCases, id: \.self) { mode in
                        ImportModeCard(
                            mode: mode,
                            isSelected: viewModel.importMode == mode,
                            action: {
                                viewModel.importMode = mode
                                if mode == .pointAtDirectory {
                                    viewModel.showDirectoryPicker = true
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Drop Zone or File List
            if viewModel.selectedFiles.isEmpty {
                dropZone
            } else {
                fileList
            }

            // Progress Indicator
            if viewModel.viewState.isLoading {
                progressView
            }

            Spacer()

            // Actions
            actionButtons
        }
        .padding(.bottom, 100) // Space for floating player
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [
                .mp3,
                .mpeg4Audio,
                .wav,
                UTType(filenameExtension: "flac") ?? .audio,
                UTType(filenameExtension: "aac") ?? .audio
            ],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                logger.debug("🔍 File picker returned \(urls.count) files")
                // Start accessing security-scoped resources
                let accessibleURLs = urls.compactMap { url -> URL? in
                    let didStartAccessing = url.startAccessingSecurityScopedResource()
                    logger.debug("🔐 Security access for \(url.lastPathComponent): \(didStartAccessing)")
                    return didStartAccessing ? url : nil
                }
                logger.info("✅ Accessible files: \(accessibleURLs.count)")
                viewModel.selectFiles(accessibleURLs)
            case .failure(let error):
                logger.error("❌ File picker error: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $viewModel.showDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let directoryURL = urls.first {
                    logger.debug("📂 Directory selected: \(directoryURL.path)")
                    _ = directoryURL.startAccessingSecurityScopedResource()
                    viewModel.selectDirectory(directoryURL)
                }
            case .failure(let error):
                logger.error("❌ Directory picker error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Import Mode Card

    struct ImportModeCard: View {
        let mode: ImportMode
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: mode.icon)
                            .font(.title)
                            .foregroundColor(isSelected ? .accentColor : .secondary)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(mode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Drop Zone

    private var dropZone: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(L10n.Import.dropFilesHere)
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Supported formats: MP3, FLAC, M4A, WAV, AAC")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                viewModel.showFilePicker = true
            }) {
                Label(L10n.Import.selectFiles, systemImage: "folder")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundColor(.secondary.opacity(0.5))
        )
        .padding(.horizontal)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            viewModel.handleDrop(providers: providers)
        }
    }

    // MARK: - File List

    private var fileList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(viewModel.selectedFiles.count) files selected")
                    .font(.headline)
                Spacer()
                Button(action: viewModel.clearFiles) {
                    Text(L10n.Import.clearSelection)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.viewState.isLoading)
            }
            .padding(.horizontal)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(viewModel.selectedFiles.enumerated()), id: \.element) { index, url in
                        FileRow(
                            url: url,
                            onRemove: {
                                viewModel.removeFile(at: index)
                            },
                            isEnabled: !viewModel.viewState.isLoading
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 400)
        }
    }

    // MARK: - Progress View

    private var progressView: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.importProgress)
                .progressViewStyle(.linear)

            if let currentFile = viewModel.currentFile {
                Text(currentFile)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Text("\(viewModel.filesProcessed) / \(viewModel.totalFiles)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            if !viewModel.selectedFiles.isEmpty && !viewModel.viewState.isLoading {
                Button(action: {
                    viewModel.showFilePicker = true
                }) {
                    Label(L10n.Actions.add, systemImage: "plus")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if viewModel.canImport {
                Button(action: viewModel.startImport) {
                    Label(L10n.Import.startImport, systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.viewState.isLoading)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}

// MARK: - File Row

struct FileRow: View {
    let url: URL
    let onRemove: () -> Void
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.body)
                    .lineLimit(1)

                Text(url.pathExtension.uppercased())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Previews

#Preview("Empty") {
    ImportFilesView(services: ServiceContainer.preview)
}

#Preview("With Files") {
    ImportFilesView(services: ServiceContainer.preview)
}
