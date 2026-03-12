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
    func fetchAssets(mediaType: PHAssetMediaType?, batchSize: Int, offset: Int) -> [PHAsset]
    func fetchAssets(byIdentifiers identifiers: [String]) -> [PHAsset]
}

extension PhotoLibraryManager {
    func fetchAllAssetsCount() -> Int {
        fetchAssetsCount(withType: nil)
    }
    
    func fetchAllAssets(batchSize: Int, offset: Int) -> [PHAsset] {
        fetchAssets(mediaType: nil, batchSize: batchSize, offset: offset)
    }
}

final class DefaultPhotoLibraryManager: PhotoLibraryManager {
    
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    // MARK: Fetch
    
    private func makeFetchOptions(mediaType: PHAssetMediaType?) -> PHFetchOptions {
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        if let mediaType {
            options.predicate = NSPredicate(
                format: "mediaType == %d",
                mediaType.rawValue
            )
        }
        return options
    }
    
    func fetchAssetsCount(withType mediaType: PHAssetMediaType?) -> Int {
        PHAsset.fetchAssets(with: makeFetchOptions(mediaType: mediaType)).count
    }
    
    func fetchAssets(mediaType: PHAssetMediaType?, batchSize: Int, offset: Int) -> [PHAsset] {
        let result = PHAsset.fetchAssets(with: makeFetchOptions(mediaType: mediaType))
        let end = min(offset + batchSize, result.count)
        
        guard offset < end else {
            return []
        }
        
        var assets: [PHAsset] = []
        result.enumerateObjects(
            at: IndexSet(integersIn: offset..<end),
            options: []
        ) { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
    
    func fetchAssets(byIdentifiers identifiers: [String]) -> [PHAsset] {
        let result = PHAsset.fetchAssets(
            withLocalIdentifiers: identifiers,
            options: nil
        )
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
}
