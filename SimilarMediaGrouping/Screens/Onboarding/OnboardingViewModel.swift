//
//  OnboardingViewModel.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

@Observable
final class OnboardingViewModel {
    enum AuthorizationResult {
        case authorized
        case limited
        case denied
    }

    private let photoLibraryManager: PhotoLibraryManager
    private let onCompleted: () -> Void
    private let onOpenSettings: () -> Void

    private(set) var authorizationResult: AuthorizationResult? = nil

    init(
        photoLibraryManager: PhotoLibraryManager,
        onCompleted: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.photoLibraryManager = photoLibraryManager
        self.onCompleted = onCompleted
        self.onOpenSettings = onOpenSettings
        updateAuthorizationResult()
    }
    
    func onAppear() {
        updateAuthorizationResult()
    }

    func onGrantAccess() {
        Task {
            await photoLibraryManager.requestAuthorization()
            
            updateAuthorizationResult()
        }
    }

    func onLetsStart() {
        onCompleted()
    }

    func onChangeAccess() {
        onOpenSettings()
    }
    
    private func updateAuthorizationResult() {
        if !photoLibraryManager.isAuthorizationDetermined {
            authorizationResult = nil
        }
        else if photoLibraryManager.isAuthorized {
            guard photoLibraryManager.isAccessLimited else {
                authorizationResult = .authorized
                onCompleted()
                return
            }
            authorizationResult = .limited
        }
        else {
            authorizationResult = .denied
        }
    }
}
