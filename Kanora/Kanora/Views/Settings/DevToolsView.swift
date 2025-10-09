//
//  DevToolsView.swift
//  Kanora
//
//  Created by Claude on 08/10/2025.
//

import SwiftUI

struct DevToolsView: View {
    @StateObject private var viewModel: DevToolsViewModel
    @ThemeAccess private var theme

    init(services: ServiceContainer) {
        _viewModel = StateObject(wrappedValue: DevToolsViewModel(
            context: services.persistence.viewContext,
            services: services
        ))
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text(L10n.Development.clearAllData)
                        .font(theme.typography.titleSmall)

                    Text(L10n.Development.clearAllDataDescription)
                        .font(theme.typography.bodySmall)
                        .foregroundStyle(theme.colors.textSecondary)

                    Button(role: .destructive) {
                        viewModel.showingClearDataConfirmation = true
                    } label: {
                        Label(L10n.Development.clearAllData, systemImage: "trash.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, theme.spacing.xs)
            } header: {
                Text(L10n.Development.title)
            }
        }
        .navigationTitle(L10n.Development.title)
        .alert(
            L10n.Development.clearDataConfirm,
            isPresented: $viewModel.showingClearDataConfirmation
        ) {
            Button(L10n.Actions.cancel, role: .cancel) { }
            Button(L10n.Development.clearAllData, role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text(L10n.Development.clearDataWarning)
        }
        .alert(
            viewModel.alertTitle,
            isPresented: $viewModel.showingAlert
        ) {
            Button(L10n.Actions.done, role: .cancel) { }
        } message: {
            if let message = viewModel.alertMessage {
                Text(message)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

#Preview("Development Tools") {
    NavigationView {
        PreviewFactory.makeDevToolsView(state: .populated)
    }
}
