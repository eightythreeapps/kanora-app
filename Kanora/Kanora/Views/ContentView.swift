//
//  ContentView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var navigationState = NavigationState()
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    private let services: ServiceContainer

    init(services: ServiceContainer) {
        self.services = services
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            if #available(iOS 16.0, macOS 13.0, *) {
                // Use NavigationStack on iPhone, NavigationSplitView on iPad/Mac
                if horizontalSizeClass == .compact {
                    compactLayout
                } else {
                    splitViewLayout
                }
            } else {
                // Fallback for macOS 12
                fallbackLayout
            }

            // Floating mini player (only show when not on Now Playing view)
            if navigationState.selectedDestination != .nowPlaying {
                FloatingMiniPlayer()
            }
        }
    }

    // MARK: - Layout Variants

    @available(iOS 16.0, macOS 13.0, *)
    private var splitViewLayout: some View {
        NavigationSplitView(
            sidebar: {
                SidebarView(navigationState: navigationState, navigationMode: .split)
            },
            detail: {
                contentColumn
            }
        )
        .environment(\.managedObjectContext, viewContext)
        .environment(\.serviceContainer, services)
        .environmentObject(navigationState)
    }

    @available(iOS 16.0, macOS 13.0, *)
    private var compactLayout: some View {
        NavigationStack {
            SidebarView(navigationState: navigationState, navigationMode: .stack)
                .navigationDestination(for: NavigationDestination.self) { destination in
                    // Update navigation state
                    DispatchQueue.main.async {
                        navigationState.navigate(to: destination)
                    }
                    // Return the appropriate view via the shared router
                    return ContentRouter(destination: destination, navigationState: navigationState)
                }
        }
        .environment(\.managedObjectContext, viewContext)
        .environment(\.serviceContainer, services)
        .environmentObject(navigationState)
    }

    private var fallbackLayout: some View {
        HStack(spacing: 0) {
            SidebarView(navigationState: navigationState, navigationMode: .split)

            Divider()

            contentColumn
        }
        .environment(\.managedObjectContext, viewContext)
        .environment(\.serviceContainer, services)
        .environmentObject(navigationState)
    }

    // MARK: - Column Views

    @ViewBuilder
    private var contentColumn: some View {
        let destination = navigationState.selectedDestination

        if #available(iOS 16.0, macOS 13.0, *), requiresNestedNavigation(for: destination) {
            NavigationStack {
                ContentRouter(destination: destination, navigationState: navigationState)
            }
        } else {
            ContentRouter(destination: destination, navigationState: navigationState)
        }
    }

    @available(iOS 16.0, macOS 13.0, *)
    private func requiresNestedNavigation(for destination: NavigationDestination) -> Bool {
        destination == .artists || destination == .albums
    }
}

#Preview("Populated") {
    PreviewFactory.makeContentView(state: .populated)
}

#Preview("Empty") {
    PreviewFactory.makeContentView(state: .empty)
}
