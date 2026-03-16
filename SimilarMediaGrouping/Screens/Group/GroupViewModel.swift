//
//  GroupViewModel.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import UIKit.UIImage
internal import SimilarMediaKit

@Observable
@MainActor
final class GroupViewModel {
    private let group: SMGroup
    private let photoLibraryManager: PhotoLibraryManager
    
    var itemsIds: [String] {
        group.assetIDs
    }
    
    // MARK: Init
    
    init(group: SMGroup, photoLibraryManager: PhotoLibraryManager) {
        self.group = group
        self.photoLibraryManager = photoLibraryManager
    }
    
    // MARK: Images
    
    private var thumbnails: [String: UIImage] = [:]
    private var loadingIDs: Set<String> = []
    
    func thumbnail(for itemId: String) -> UIImage? {
        if let cached = thumbnails[itemId] { return cached }
        guard !loadingIDs.contains(itemId) else { return nil }
        loadingIDs.insert(itemId)
        Task { [weak self] in
            guard let self else { return }
            let asset = SMAsset(id: itemId, modificationDate: nil)
            if let cgImage = await self.photoLibraryManager.loadCGImage(
                for: asset,
                size: CGSize(width: 300, height: 300)
            ) {
                self.thumbnails[itemId] = UIImage(cgImage: cgImage)
            }
            self.loadingIDs.remove(itemId)
        }
        return nil
    }
}
