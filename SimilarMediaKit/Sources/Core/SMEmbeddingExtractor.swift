//
//  SMEmbeddingExtractor.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Vision
import CoreGraphics

struct SMEmbeddingExtractProgress: Sendable {
    let processedCount: Int
    let totalCount: Int
    let embeddings: [SMEmbedding]
}

actor SMEmbeddingExtractor {
    private let storage: SMStorage
    private let nodeTable: SMNodeTable
    private let mediaProvider: SMMediaProvider

    init(storage: SMStorage, nodeTable: SMNodeTable, mediaProvider: SMMediaProvider) {
        self.storage = storage
        self.nodeTable = nodeTable
        self.mediaProvider = mediaProvider
    }

    func extract(for assets: [SMAsset]) -> AsyncThrowingStream<SMEmbeddingExtractProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // assetID used here only for storage lookup — doesn't leave this scope
                    let assetsByID = Dictionary(uniqueKeysWithValues: assets.map { ($0.id, $0) })
                    let stored = try await storage.fetchStoredEmbeddings()

                    // Remove embeddings for deleted assets
                    let toDelete = Set(stored.map(\.assetID)).subtracting(assetsByID.keys)
                    if !toDelete.isEmpty {
                        try await storage.deleteEmbeddings(for: toDelete)
                    }

                    // Split into cached vs needs extraction
                    let storedByAssetID = Dictionary(uniqueKeysWithValues: stored.map { ($0.assetID, $0) })
                    var embeddings: [SMEmbedding] = []
                    var toExtract: [SMAsset] = []

                    for asset in assets {
                        if let cached = storedByAssetID[asset.id],
                           cached.modificationDate == asset.modificationDate {
                            // Convert stored → runtime: assetID stays in storage, nodeIndex crosses boundary
                            embeddings.append(cached)
                        } else {
                            toExtract.append(asset)
                        }
                    }

                    continuation.yield(makeProgress(totalCount: assets.count, embeddings: embeddings))

                    guard !toExtract.isEmpty else {
                        continuation.finish()
                        return
                    }

                    // Extract in chunks
                    let chunkSize = 48
                    for chunkStart in stride(from: 0, to: toExtract.count, by: chunkSize) {
                        let chunk = Array(toExtract[chunkStart..<min(chunkStart + chunkSize, toExtract.count)])

                        let chunkEmbeddings = try await withThrowingTaskGroup(of: SMEmbedding.self) { group in
                            for asset in chunk {
                                group.addTask { try await self.extract(for: asset) }
                            }
                            var result: [SMEmbedding] = []
                            for try await embedding in group { result.append(embedding) }
                            return result
                        }

                        // Save to storage — assetID needed here, resolved via nodeTable reverse lookup
                        try await storage.saveEmbeddings(chunkEmbeddings, assetIDs: chunk.map(\.id))

                        embeddings.append(contentsOf: chunkEmbeddings)
                        continuation.yield(makeProgress(totalCount: assets.count, embeddings: embeddings))
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func extract(for asset: SMAsset) async throws -> SMEmbedding {
        guard let image = await mediaProvider.loadCGImage(for: asset, size: CGSize(width: 224, height: 224)) else {
            throw SMError.imageLoadingFailed
        }
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        guard let result = request.results?.first as? VNFeaturePrintObservation else {
            throw SMError.embeddingExtractionFailed
        }
        // assetID → nodeIndex conversion happens here — last point where assetID exists
        let nodeIndex = await nodeTable.index(for: asset.id)
        return SMEmbedding(assetID: asset.id,
                           nodeIndex: nodeIndex,
                           observation: result,
                           modificationDate: asset.modificationDate)
    }

    private func makeProgress(totalCount: Int, embeddings: [SMEmbedding]) -> SMEmbeddingExtractProgress {
        SMEmbeddingExtractProgress(processedCount: embeddings.count, totalCount: totalCount, embeddings: embeddings)
    }
}
