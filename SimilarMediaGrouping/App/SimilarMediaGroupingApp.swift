//
//  SimilarMediaGroupingApp.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import SwiftUI

@main
struct SimilarMediaGroupingApp: App {
    private let container: AppContainer
    private let coordinator: AppCoordinator

    init() {
        do {
            self.container = try AppContainer()
            self.coordinator = AppCoordinator(container: container)
        } catch {
            fatalError("Failed to initialize AppContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if self.coordinator.shouldShowOnboarding {
                onboardingView
            }
            else {
                mediaGroupsView
            }
        }
    }
    
    private var onboardingView: some View {
        OnboardingView(
            viewModel: OnboardingViewModel(
                photoLibraryManager: container.photoLibraryManager,
                onCompleted: coordinator.onOnboardingCompleted,
                onOpenSettings: coordinator.onOpenSettings
            )
        )
    }
    
    private var mediaGroupsView: some View {
        // TODO: Media Groups UI
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}
