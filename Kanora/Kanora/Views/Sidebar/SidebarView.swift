//
//  SidebarView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI

enum SidebarNavigationMode {
    case stack  // Use NavigationLink for NavigationStack
    case split  // Use Button for NavigationSplitView
}

struct SidebarView: View {
    @ObservedObject var navigationState: NavigationState
    var navigationMode: SidebarNavigationMode = .split

    var body: some View {
        List {
            ForEach(NavigationSection.allCases, id: \.self) { section in
                Section(LocalizedStringKey(section.rawValue)) {
                    if let items = navigationState.navigationItems[section] {
                        ForEach(items) { item in
                            sidebarItem(item)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.Common.appName)
    }

    @ViewBuilder
    private func sidebarItem(_ item: NavigationItem) -> some View {
        switch navigationMode {
        case .stack:
            if #available(iOS 16.0, macOS 13.0, *) {
                NavigationLink(value: item.destination) {
                    sidebarItemLabel(item)
                }
            } else {
                Button(action: {
                    navigationState.navigate(to: item.destination)
                }) {
                    sidebarItemLabel(item)
                }
                .buttonStyle(.plain)
            }
        case .split:
            Button(action: {
                navigationState.navigate(to: item.destination)
            }) {
                sidebarItemLabel(item)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func sidebarItemLabel(_ item: NavigationItem) -> some View {
        HStack {
            Label {
                HStack {
                    Text(item.title)
                    Spacer()
                    if let badge = item.badge {
                        Text("\(badge)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            } icon: {
                Image(systemName: item.icon)
            }
        }
    }
}

#Preview("Populated") {
    NavigationView {
        PreviewFactory.makeSidebarView(state: .populated)
        Text(L10n.Common.selectItem)
    }
}

#Preview("Empty") {
    NavigationView {
        PreviewFactory.makeSidebarView(state: .empty)
        Text(L10n.Common.selectItem)
    }
}
