//
//  AppCoordinator.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Photos
internal import UIKit.UIApplication

@Observable
final class AppCoordinator {
    private let container: AppContainer
    
    private(set) var shouldShowOnboarding: Bool
    
    init(container: AppContainer) {
        self.container = container
        self.shouldShowOnboarding = !container.photoLibraryManager.isAuthorizationDetermined
    }
    
    func onOnboardingCompleted() {
        shouldShowOnboarding = false
    }
    
    func onOpenSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(url)
    }
}
