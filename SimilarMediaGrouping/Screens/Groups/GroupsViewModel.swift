//
//  GroupsViewModel.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import UIKit.UIImage

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
    private(set) var groups: [SimilarMediaGroup] = []
    
    var showsOverlay: Bool {
        return state != .grouped
    }
    var totalMediaCount: Int {
        return similarMediaManager.totalMediaCount
    }
    var processedMediaCount: Int {
        return similarMediaManager.processedMediaCount
    }
    var showsSkeletonPlaceholder: Bool {
        return groups.count == 0
    }
    
    // MARK: Init
    
    init(similarMediaManager: SimilarMediaManager) {
        self.similarMediaManager = similarMediaManager
    }
    
    // MARK: Images
    
    func thumbnail(for group: SimilarMediaGroup) -> UIImage? {
        // TODO: Add thumbnail loading
        return nil
    }
    
    // MARK: Actions
    
    func onAppear() {
        state = .idle
        // TODO: Add preload cached
    }
    
    func onStart() {
        Task {
            do {
                for try await groups in similarMediaManager.fetchSimilarMedia() {
                    update(with: groups)
                }
                state = .grouped
            }
            catch {
                // TODO: Handle error
                state = .idle
            }
        }
    }
    
    private func update(with groups: [SimilarMediaGroup]) {
        self.groups = groups
    }
}
