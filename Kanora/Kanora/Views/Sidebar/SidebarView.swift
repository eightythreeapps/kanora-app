//
//  SidebarView.swift
//  Kanora
//
//  Created by Ben Reed on 06/10/2025.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var navigationState: NavigationState

    var body: some View {
        List {
            ForEach(NavigationSection.allCases, id: \.self) { section in
                Section(LocalizedStringKey(section.rawValue)) {
                    if let items = navigationState.navigationItems[section] {
                        ForEach(items) { item in
                            if #available(iOS 16.0, macOS 13.0, *) {
                                NavigationLink(value: item.destination) {
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
                            } else {
                                Button(action: {
                                    navigationState.navigate(to: item.destination)
                                }) {
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
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.Common.appName)
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
