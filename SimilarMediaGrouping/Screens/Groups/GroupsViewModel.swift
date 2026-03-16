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
    private let photoLibraryManager: PhotoLibraryManager
    
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
    
    init(similarMediaManager: SimilarMediaManager, photoLibraryManager: PhotoLibraryManager) {
        self.similarMediaManager = similarMediaManager
        self.photoLibraryManager = photoLibraryManager
    }
    
    // MARK: Images
    
    private var thumbnails: [String: UIImage] = [:]
    private var loadingIDs: Set<String> = []
    
    func thumbnail(for group: SMGroup) -> UIImage? {
        guard let firstID = group.assetIDs.first else { return nil }
        return loadThumbnail(for: firstID)
    }
    
    private func loadThumbnail(for assetID: String) -> UIImage? {
        if let cached = thumbnails[assetID] { return cached }
        guard !loadingIDs.contains(assetID) else { return nil }
        loadingIDs.insert(assetID)
        Task { [weak self] in
            guard let self else { return }
            let asset = SMAsset(id: assetID, modificationDate: nil)
            if let cgImage = await self.photoLibraryManager.loadCGImage(
                for: asset,
                size: CGSize(width: 512, height: 512)
            ) {
                self.thumbnails[assetID] = UIImage(cgImage: cgImage)
            }
            self.loadingIDs.remove(assetID)
        }
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
        case .extractingEmbeddings(let completed, let total):
            processedMediaCount = completed
            totalMediaCount = total
        case .buildingEdges(let processed, let total):
            processedMediaCount = processed
            totalMediaCount = total
        case .clustering:
            break
        case .done:
            processedMediaCount = totalMediaCount
        }
    }
    
    func groupViewModel(for group: SMGroup) -> GroupViewModel {
        GroupViewModel(group: group, photoLibraryManager: photoLibraryManager)
    }
}
