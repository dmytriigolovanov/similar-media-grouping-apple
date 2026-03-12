//
//  OnboardingView.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {

    @State var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Similar Media")
                    .font(.largeTitle.bold())

                Text("Grant access to your photo library to start grouping similar photos")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            switch viewModel.authorizationResult {
            case .none:
                grantAccessButton
            case .authorized:
                letsStartButton
            case .limited:
                limitedAccessView
            case .denied:
                deniedAccessView
            }
        }
        .padding()
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var limitedAccessView: some View {
        VStack(spacing: 16) {
            Text("Results may be incomplete due to limited access")
                .font(.footnote)
                .foregroundStyle(.orange)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                letsStartButton
                
                changeAccessButton
            }
        }
    }

    private var deniedAccessView: some View {
        VStack(spacing: 16) {
            Text("Photo library access is required for the app to work")
                .font(.footnote)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)

            changeAccessButton
        }
    }
    
    private var grantAccessButton: some View {
        Button(
            action: viewModel.onGrantAccess,
            label: {
                Text("Grant Access")
                    .frame(maxWidth: .infinity)
            }
        )
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    private var letsStartButton: some View {
        Button(
            action: viewModel.onLetsStart,
            label: {
                Text("Let's Start")
                    .frame(maxWidth: .infinity)
            }
        )
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    
    private var changeAccessButton: some View {
        Button(
            action: viewModel.onChangeAccess,
            label: {
                Text("Change Access")
                    .frame(maxWidth: .infinity)
            }
        )
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingViewModel(
            photoLibraryManager: DefaultPhotoLibraryManager(),
            onCompleted: {},
            onOpenSettings: {}
        )
    )
}
