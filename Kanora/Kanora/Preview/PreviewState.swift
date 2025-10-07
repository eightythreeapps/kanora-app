//
//  PreviewState.swift
//  Kanora
//
//  Created by Ben Reed on 07/10/2025.
//

import Foundation

/// Defines the different states for SwiftUI preview data
enum PreviewState {
    /// Empty state with no data
    case empty

    /// Populated state with realistic test data
    case populated

    /// Loading state (same data as populated, used for loading UI)
    case loading

    /// Error state (same data as populated, used for error UI)
    case error
}
