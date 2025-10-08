//
//  DevToolsViewModel.swift
//  Kanora
//
//  Created by Claude on 08/10/2025.
//

import Foundation
import CoreData
import Combine

@MainActor
class DevToolsViewModel: BaseViewModel {
    @Published var showingClearDataConfirmation = false
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage: String?

    override func onAppear() {
        super.onAppear()
    }

    // MARK: - Actions

    func clearAllData() {
        do {
            try services.persistence.clearAllData()
            alertTitle = String(localized: "development.data_cleared")
            alertMessage = nil
            showingAlert = true
        } catch {
            alertTitle = String(localized: "development.clear_data_failed")
            alertMessage = error.localizedDescription
            showingAlert = true
            handleError(error, context: "Clearing all data")
        }
    }
}
