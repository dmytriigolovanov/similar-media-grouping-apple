//
//  SimilarMediaManager.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Photos

protocol SimilarMediaManager {
    var totalMediaCount: Int { get }
    var processedMediaCount: Int { get }
    
    func fetchSimilarMedia() -> AsyncThrowingStream<[SimilarMediaGroup], Error>
}

final class DefaultSimilarMediaManager: SimilarMediaManager {
    
    private let photoLibraryManager: PhotoLibraryManager
    private let mediaLoadingService: MediaLoadingService
    private let groupingService: SimilarMediaGroupingService
    private let storageService: SimilarMediaStorageService
    
    private var processedIdentifiers: Set<String> = []
    private var groups: [SimilarMediaGroup] = []
    
    private let batchSize: Int = 100
    private let threshold: Float = 0.8
    private let imageSize = CGSize(width: 224, height: 224)
    
    var totalMediaCount: Int {
        return photoLibraryManager.fetchAllAssetsCount()
    }
    
    var processedMediaCount: Int {
        return processedIdentifiers.count
    }
    
    // MARK: Init
    
    init(
        photoLibraryManager: PhotoLibraryManager,
        mediaLoadingService: MediaLoadingService,
        groupingService: SimilarMediaGroupingService = DefaultSimilarMediaGroupingService(),
        storageService: SimilarMediaStorageService
    ) {
        self.photoLibraryManager = photoLibraryManager
        self.mediaLoadingService = mediaLoadingService
        self.groupingService = groupingService
        self.storageService = storageService
    }
    
    // MARK: Fetch
    
    func fetchSimilarMedia() -> AsyncThrowingStream<[SimilarMediaGroup], Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var groups = try storageService.loadGroups()
                    var processedIdentifiers = try storageService.loadProcessedIdentifiers()
                    
                    let currentIdentifiers = Set(
                        photoLibraryManager.fetchAssets(
                            mediaType: .image,
                            batchSize: Int.max,
                            offset: 0
                        ).map { $0.localIdentifier }
                    )
                    
                    groups = removeDeletedAssets(
                        from: groups,
                        existingIdentifiers: currentIdentifiers
                    )
                    processedIdentifiers = processedIdentifiers.intersection(currentIdentifiers)
                    
                    let unprocessed = Array(currentIdentifiers.subtracting(processedIdentifiers))
                    
                    guard !unprocessed.isEmpty else {
                        continuation.yield(groups)
                        continuation.finish()
                        return
                    }
                    
                    for batch in unprocessed.chunked(into: batchSize) {
                        let assets = photoLibraryManager.fetchAssets(byIdentifiers: batch)
                        
                        var images: [(identifier: String, image: CGImage)] = []
                        for asset in assets {
                            guard let cgImage = try await mediaLoadingService.loadCGImage(
                                for: asset,
                                size: imageSize
                            ) else {
                                continue
                            }
                            images.append((asset.localIdentifier, cgImage))
                        }
                        
                        let newGroups = try await groupingService.buildGroups(
                            from: images,
                            threshold: threshold
                        )
                        
                        processedIdentifiers.formUnion(batch)
                        groups.append(contentsOf: newGroups)
                        
                        try storageService.saveGroups(groups)
                        try storageService.saveProcessedIdentifiers(processedIdentifiers)
                        
                        continuation.yield(groups)
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func removeDeletedAssets(
        from groups: [SimilarMediaGroup],
        existingIdentifiers: Set<String>
    ) -> [SimilarMediaGroup] {
        groups.compactMap { group in
            let validIdentifiers = group.assetIdentifiers.filter { existingIdentifiers.contains($0) }
            guard validIdentifiers.count > 1 else {
                return nil
            }
            return SimilarMediaGroup(assetIdentifiers: validIdentifiers)
        }
    }
}
