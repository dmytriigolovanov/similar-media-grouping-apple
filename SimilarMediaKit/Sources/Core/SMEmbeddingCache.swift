//
//  SMEmbeddingCache.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import Vision
import CoreGraphics

actor SMEmbeddingCache {
    private let storage: SMStorage
    private let mediaProvider: SMMediaProvider
    
    init(storage: SMStorage, mediaProvider: SMMediaProvider) {
        self.storage = storage
        self.mediaProvider = mediaProvider
    }
    
    /// Returns embeddings for all assets.
    /// Loads from cache where possible, computes only missing or stale entries.
    func embeddings(
        for assets: [SMAsset],
        progressHandler: @Sendable (Int, Int) async -> Void
    ) async throws -> [String: VNFeaturePrintObservation] {

        let total = assets.count
        var result: [String: VNFeaturePrintObservation] = [:]
        var toCompute: [SMAsset] = []

        // Single bulk fetch instead of N individual queries
        let allCached = try await storage.fetchAllEmbeddings()
        let cacheByID = Dictionary(uniqueKeysWithValues: allCached.map { ($0.id, $0) })

        for asset in assets {
            if let cached = cacheByID[asset.id],
               cached.modificationDate == asset.modificationDate,
               let observation = try? SMEmbeddingCache.deserialize(cached.data) {
                result[asset.id] = observation
            } else {
                toCompute.append(asset)
            }
        }

        guard !toCompute.isEmpty else {
            await progressHandler(total, total)
            return result
        }

        // Sequential batches — avoids creating tens-of-thousands of Swift tasks at once.
        // Each batch runs its assets concurrently via a task group:
        //   • loadImage hops to @MainActor so PHImageManager has a run-loop.
        //   • extractEmbedding runs on a GCD global queue (see extractEmbeddingAsync).
        //     VNGenerateImageFeaturePrintRequest uses CoreML/ANE internally and requires a
        //     thread with an active run-loop to receive hardware callbacks. Swift's
        //     cooperative thread-pool threads have no run-loop, so Vision hangs there.
        //     Bridging through a GCD queue (which does have a run-loop) fixes this.
        // Embeddings are batch-saved after each batch; progress is reported once per batch.
        let batchSize = 8
        var done = result.count

        for batchStart in stride(from: 0, to: toCompute.count, by: batchSize) {
            try Task.checkCancellation()
            let batch = Array(toCompute[batchStart ..< min(batchStart + batchSize, toCompute.count)])

            let batchItems = try await withThrowingTaskGroup(
                of: (String, VNFeaturePrintObservation, Date?)?.self
            ) { group in
                for asset in batch {
                    group.addTask {
                        guard let image = await self.loadImage(for: asset) else {
                            return nil
                        }
                        do {
                            let observation = try await SMEmbeddingCache.extractEmbeddingAsync(from: image)
                            return (asset.id, observation, asset.modificationDate)
                        } catch {
                            return nil
                        }
                    }
                }
                var items: [(String, VNFeaturePrintObservation, Date?)] = []
                for try await item in group {
                    if let item { items.append(item) }
                }
                return items
            }

            // Persist the whole batch in one transaction
            let toSave = batchItems.compactMap { id, obs, modDate -> SMEmbedding? in
                guard let data = try? SMEmbeddingCache.serialize(obs) else { return nil }
                return SMEmbedding(id: id, data: data, modificationDate: modDate)
            }
            if !toSave.isEmpty {
                try await storage.saveEmbeddings(toSave)
            }

            // Merge into result
            for (id, observation, _) in batchItems {
                result[id] = observation
            }

            // Advance counter and report progress once for the whole batch
            done += batch.count
            await progressHandler(done, total)
        }

        return result
    }
    
    /// Removes embeddings for deleted assets.
    /// Returns the set of identifiers that were purged so the caller can clean the graph.
    @discardableResult
    func purgeStale(keeping identifiers: Set<String>) async throws -> Set<String> {
        let all = try await storage.fetchAllEmbeddings()
        let toDelete = all
            .map(\.id)
            .filter { !identifiers.contains($0) }
        guard !toDelete.isEmpty else {
            return []
        }
        try await storage.deleteEmbeddings(ids: toDelete)
        return Set(toDelete)
    }
    
    /// Async wrapper for `extractEmbedding` that runs on a GCD global queue.
    ///
    /// `VNGenerateImageFeaturePrintRequest` uses CoreML/ANE internally and expects a thread
    /// with an active run-loop to receive hardware callbacks. Swift's cooperative thread-pool
    /// threads have no run-loop, so calling `VNImageRequestHandler.perform` from a plain
    /// `Task.detached` hangs indefinitely. Bridging through `DispatchQueue.global` gives
    /// Vision the run-loop-backed thread it needs.
    private static func extractEmbeddingAsync(from image: CGImage) async throws -> VNFeaturePrintObservation {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try extractEmbedding(from: image))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func extractEmbedding(from image: CGImage) throws -> VNFeaturePrintObservation {
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])
        
        guard let result = request.results?.first as? VNFeaturePrintObservation else {
            throw SMError.embeddingExtractionFailed
        }
        return result
    }
    
    private static func serialize(_ observation: VNFeaturePrintObservation) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: observation, requiringSecureCoding: true)
    }
    
    private static func deserialize(_ data: Data) throws -> VNFeaturePrintObservation {
        guard let obs = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: VNFeaturePrintObservation.self,
            from: data
        ) else {
            throw SMError.embeddingDeserializationFailed
        }
        return obs
    }
    
    private func loadImage(for asset: SMAsset) async -> CGImage? {
        return await mediaProvider.loadCGImage(
            for: asset,
            size: CGSize(width: 224, height: 224)
        )
    }
}
