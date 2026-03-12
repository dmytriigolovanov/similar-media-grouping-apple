//
//  PhotoLibraryManager.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Photos

protocol PhotoLibraryManager {
    var authorizationStatus: PHAuthorizationStatus { get }
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchAssetsCount(withType mediaType: PHAssetMediaType?) -> Int
}

extension PhotoLibraryManager {
    func fetchAllAssetsCount() -> Int {
        fetchAssetsCount(withType: nil)
    }
}

final class DefaultPhotoLibraryManager: PhotoLibraryManager {
    
    var authorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    // MARK: Fetching
    
    private func fetchOptions(mediaType: PHAssetMediaType?, limit: Int?) -> PHFetchOptions? {
        guard let mediaType else {
            return nil
        }
        var options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType == %d",
            mediaType.rawValue
        )
        if let limit {
            options.fetchLimit = limit
        }
        return options
    }
    
    func fetchAssetsCount(withType mediaType: PHAssetMediaType?) -> Int {
        let options = fetchOptions(mediaType: mediaType, limit: nil)
        return PHAsset.fetchAssets(with: options).count
    }
}
