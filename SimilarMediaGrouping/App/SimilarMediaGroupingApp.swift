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
            let container = try AppContainer()
            self.container = container
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
                groupsView
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
    
    private var groupsView: some View {
        GroupsView(
            viewModel: GroupsViewModel(
                similarMediaManager: container.similarMediaManager
            )
        )
    }
}
