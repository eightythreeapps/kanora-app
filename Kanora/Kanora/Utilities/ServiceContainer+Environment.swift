//
//  ServiceContainer+Environment.swift
//  Kanora
//
//  Created by OpenAI on 2024-05-11.
//

import SwiftUI

private struct ServiceContainerEnvironmentKey: EnvironmentKey {
    static let defaultValue: ServiceContainer = .shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerEnvironmentKey.self] }
        set { self[ServiceContainerEnvironmentKey.self] = newValue }
    }
}

extension View {
    func serviceContainer(_ container: ServiceContainer) -> some View {
        environment(\.serviceContainer, container)
    }
}
