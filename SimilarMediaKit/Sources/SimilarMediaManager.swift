//
//  SimilarMediaManager.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import Vision

public protocol SimilarMediaManager: AnyObject, Sendable {
    func currentGroups() async -> [SMGroup]
    
    func start() -> AsyncThrowingStream<SMProgress, Error>
    func cancel()
    func reset() async throws
}

/// Main entry point for the Similar Photos Kit.
///
/// Usage:
/// ```swift
/// let manager = try DefaultSimilarMediaManager()
/// do {
///     for try await progress in manager.fetchSimilarMedia() {
///         print(progress.fractionCompleted, progress.groups.count)
///     }
/// } catch SMError.photoLibraryAccessDenied {
///     // handle permission error
/// } catch {
///     // handle other errors
/// }
/// ```
public final class DefaultSimilarMediaManager: SimilarMediaManager, Sendable {
    public let configuration: SMConfiguration
    
    private let storage: SMStorage
    private let mediaProvider: SMMediaProvider
    private let embeddingCache: SMEmbeddingCache
    private let distanceCalculator: SMDistanceCalculator
    private let similarityGraph: SMSimilarityGraph
    private let clusteringEngine: SMClusteringEngine
    
    // nonisolated(unsafe) — mutation only happens on the calling thread
    // before any async work begins, so this is safe
    private nonisolated(unsafe) var processingTask: Task<Void, Error>?
    
    // MARK: Init
    
    public init(configuration: SMConfiguration = SMConfiguration(),
                mediaProvider: SMMediaProvider) throws {
        self.configuration = configuration
        let storage = try SMStorage()
        self.storage = storage
        self.mediaProvider = mediaProvider
        self.embeddingCache = SMEmbeddingCache(storage: storage, mediaProvider: mediaProvider)
        self.distanceCalculator = SMDistanceCalculator(configuration: configuration)
        self.similarityGraph = SMSimilarityGraph(storage: storage)
        self.clusteringEngine = SMClusteringEngine(configuration: configuration)
    }
    
    // MARK: Fetch
    
    /// Starts processing and returns an AsyncThrowingStream of progress updates.
    /// Safe to call multiple times — cancels any in-flight processing first.
    public func start() -> AsyncThrowingStream<SMProgress, Error> {
        processingTask?.cancel()
        
        return AsyncThrowingStream { continuation in
            let task: Task<Void, Error> = Task.detached(priority: .background) { [weak self] in
                guard let self else {
                    return
                }
                do {
                    try await self.run(continuation: continuation)
                }
                catch is CancellationError {
                    continuation.finish()
                }
                catch {
                    continuation.finish(throwing: error)
                }
            }
            self.processingTask = task
            continuation.onTermination = { [weak self] _ in
                self?.processingTask?.cancel()
            }
        }
    }
    
    /// Returns the current groups from the cached graph without triggering reprocessing.
    /// Useful on subsequent launches when the graph is already fully built.
    public func currentGroups() async -> [SMGroup] {
        let adjacency = await similarityGraph.snapshot()
        return clusteringEngine.computeGroups(adjacency: adjacency)
    }
    
    /// Cancels any in-progress processing.
    public func cancel() {
        processingTask?.cancel()
        processingTask = nil
    }
    
    /// Clears all stored embeddings and edges, forcing a full reprocess on next start.
    public func reset() async throws {
        cancel()
        try await storage.deleteAllEdges()
        try await storage.resetProcessingState()
    }
    
    // MARK: Core Pipeline
    
    private func run(continuation: AsyncThrowingStream<SMProgress, Error>.Continuation) async throws {
        // 1. Load graph from storage (resume support)
        try await similarityGraph.loadFromStorage()
        
        // 2. Fetch all assets
        let assets = try await mediaProvider.fetchAssets()
        let assetIDs = Set(assets.map(\.id))
        
        // 3. Purge embeddings and graph edges for deleted assets
        let purgedIDs = try await embeddingCache.purgeStale(keeping: assetIDs)
        if !purgedIDs.isEmpty {
            try await similarityGraph.removeEdges(forAssetIDs: purgedIDs)
        }
        
        // 4. Extract embeddings (uses cache)
        let embeddings = try await embeddingCache.embeddings(
            for: assets,
            progressHandler: { [weak self] done, total in
                guard let self else {
                    return
                }
                let groups = await self.currentGroups()
                continuation.yield(SMProgress(
                    stage: .extractingEmbeddings(completed: done, total: total),
                    groups: groups
                ))
            }
        )
        
        try Task.checkCancellation()
        
        // 5. Build ordered list — determines resume point
        let orderedEmbeddings: [(id: String, observation: VNFeaturePrintObservation)] = assets
            .compactMap { asset in
                guard let obs = embeddings[asset.id] else {
                    return nil
                }
                return (id: asset.id, observation: obs)
            }
        
        // 6. Determine resume index from persisted state
        let processingState = try await storage.fetchProcessingState()
        let resumeIndex: Int?
        if let lastID = processingState?.lastProcessedAssetID {
            resumeIndex = orderedEmbeddings.firstIndex(where: { $0.id == lastID })
        } else {
            resumeIndex = nil
        }
        
        try await storage.saveProcessingState(
            lastProcessedAssetID: nil,
            totalAssetCount: assets.count
        )
        
        // 7. Compute distances — stream edges into graph as they are found,
        //    yielding calculatingDistances progress after each chunk
        try await distanceCalculator.computeEdges(
            embeddings: orderedEmbeddings,
            startingFromIndex: resumeIndex,
            progressHandler: { [weak self] done, total in
                guard let self else {
                    return
                }
                
                // Save resume checkpoint every 500 rows
                if done % 500 == 0, done < orderedEmbeddings.count {
                    let lastID = orderedEmbeddings[done].id
                    try? await self.storage.saveProcessingState(
                        lastProcessedAssetID: lastID,
                        totalAssetCount: assets.count
                    )
                }
                
                let groups = await self.currentGroups()
                continuation.yield(SMProgress(
                    stage: .calculatingDistances(completed: done, total: total),
                    groups: groups
                ))
            },
            edgesHandler: { [weak self] edges in
                guard let self else {
                    return
                }
                try? await self.similarityGraph.addEdges(edges)
            }
        )
        
        try Task.checkCancellation()
        
        // 8. Final snapshot
        try await storage.saveProcessingState(lastProcessedAssetID: orderedEmbeddings.last?.id,
                                              totalAssetCount: assets.count)
        
        let finalGroups = await currentGroups()
        continuation.yield(SMProgress(stage: .done, groups: finalGroups))
        continuation.finish()
    }
}
