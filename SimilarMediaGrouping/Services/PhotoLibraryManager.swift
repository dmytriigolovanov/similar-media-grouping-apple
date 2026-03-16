//
//  PhotoLibraryManager.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Photos
internal import SimilarMediaKit
internal import UIKit.UIImage

enum PhotoLibraryError: Error {
    case unauthorized
}

protocol PhotoLibraryManager: SMMediaProvider {
    var authorizationStatus: PHAuthorizationStatus { get }
    var isAuthorizationDetermined: Bool { get }
    var isAuthorized: Bool { get }
    var isAccessLimited: Bool { get }
    
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus
}

final class DefaultPhotoLibraryManager: PhotoLibraryManager {
    var authorizationStatus: PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    var isAuthorizationDetermined: Bool {
        return authorizationStatus != .notDetermined
    }
    var isAuthorized: Bool {
        return authorizationStatus == .authorized || authorizationStatus == .limited
    }
    var isAccessLimited: Bool {
        return authorizationStatus == .limited
    }
    
    @discardableResult
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }
    
    // MARK: SMMediaProvider
    
    func fetchAssets() async throws -> [SMAsset] {
        guard isAuthorized else {
            throw PhotoLibraryError.unauthorized
        }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets.map {
            SMAsset(id: $0.localIdentifier,
                    modificationDate: $0.modificationDate)
        }
    }
    
    // PHAsset.fetchAssets is synchronous — no async/continuation needed
    private func fetchAsset(forLocalIdentifier identifier: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }
    
    func loadCGImage(for asset: SMAsset, size: CGSize) async -> CGImage? {
        guard let phAsset = fetchAsset(forLocalIdentifier: asset.id) else {
            return nil
        }
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .fastFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = false

        return await withCheckedContinuation { continuation in
            // PHImageManager delivers its callback on an internal background queue when
            // called from a non-main thread; continuation.resume is thread-safe.
            // The `resumed` guard handles the rare case where Photos fires more than once.
            nonisolated(unsafe) var resumed = false
            PHImageManager.default().requestImage(
                for: phAsset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard !resumed else { return }
                resumed = true
                continuation.resume(returning: image?.cgImage)
            }
        }
    }
}
