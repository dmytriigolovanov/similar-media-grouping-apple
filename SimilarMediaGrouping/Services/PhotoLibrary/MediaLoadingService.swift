//
//  MediaLoadingService.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Photos
internal import UIKit

protocol MediaLoadingService {
    func loadCGImage(for asset: PHAsset, size: CGSize) async throws -> CGImage?
}

final class DefaultMediaLoadingService: MediaLoadingService {

    // MARK: CGImage

    func loadCGImage(for asset: PHAsset, size: CGSize) async throws -> CGImage? {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isNetworkAccessAllowed = false
            options.isSynchronous = false

            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: image?.cgImage)
            }
        }
    }
}
