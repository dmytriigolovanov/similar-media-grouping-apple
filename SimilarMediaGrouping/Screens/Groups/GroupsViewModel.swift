//
//  GroupsViewModel.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import UIKit.UIImage
internal import SimilarMediaKit

enum GroupsViewState {
    case loading
    case idle
    case grouping
    case grouped
}

@Observable
@MainActor
final class GroupsViewModel {
    private let similarMediaManager: SimilarMediaManager
    
    private(set) var state: GroupsViewState = .loading
    private(set) var groups: [SMGroup] = []
    private(set) var totalMediaCount: Int = 0
    private(set) var processedMediaCount: Int = 0
    private(set) var progressFraction: Double = 0
    
    var showsOverlay: Bool {
        return state != .grouped
    }
    var showsSkeletonPlaceholder: Bool {
        return groups.count == 0
    }
    
    // MARK: Init
    
    init(similarMediaManager: SimilarMediaManager) {
        self.similarMediaManager = similarMediaManager
    }
    
    // MARK: Images
    
    func thumbnail(for group: SMGroup) -> UIImage? {
        // TODO: Add thumbnail loading
        return nil
    }
    
    // MARK: Actions
    
    func onAppear() {
        Task {
            groups = await similarMediaManager.currentGroups()
            state = .idle
        }
    }
    
    func onStart() {
        guard state != .grouping else {
            return
        }
        state = .grouping
        Task {
            do {
                for try await progress in similarMediaManager.start() {
                    update(with: progress)
                }
                state = .grouped
            }
            catch {
                // TODO: Handle error
                state = .idle
            }
        }
    }
    
    private func update(with progress: SMProgress) {
        groups = progress.groups
        progressFraction = progress.fractionCompleted
        switch progress.stage {
        case .extractingEmbeddings(let completed, let total),
             .calculatingDistances(let completed, let total):
            processedMediaCount = completed
            totalMediaCount = total
        case .clustering:
            break
        case .done:
            processedMediaCount = totalMediaCount
        }
    }
}
