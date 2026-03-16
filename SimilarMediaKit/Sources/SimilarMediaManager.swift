//
//  SimilarMediaManager.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public final class SimilarMediaManager: Sendable {
    public let configuration: SMConfiguration
    
    private let storage: SMStorage
    private let mediaProvider: SMMediaProvider
    private let nodeTable: SMNodeTable
    private let similarityGraph: SMSimilarityGraph
    private let clusteringEngine: SMClusteringEngine
    
    private nonisolated(unsafe) var processingTask: Task<Void, Error>?
    
    // MARK: - Init
    
    public init(configuration: SMConfiguration = SMConfiguration(),
                mediaProvider: SMMediaProvider) throws {
        self.configuration = configuration
        let storage = try SMStorage()
        self.storage = storage
        self.mediaProvider = mediaProvider
        self.nodeTable = SMNodeTable()
        self.similarityGraph = SMSimilarityGraph(storage: storage)
        self.clusteringEngine = SMClusteringEngine(configuration: configuration)
    }
    
    // MARK: - Public API
    
    public func start() -> AsyncThrowingStream<SMProgress, Error> {
        processingTask?.cancel()
        
        return AsyncThrowingStream { continuation in
            let task: Task<Void, Error> = Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                do {
                    try await self.run(continuation: continuation)
                } catch is CancellationError {
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            self.processingTask = task
            continuation.onTermination = { [weak self] _ in
                self?.processingTask?.cancel()
            }
        }
    }
    
    /// Returns current groups — converts internal SMCluster indices to assetIDs.
    public func currentGroups() async -> [SMGroup] {
        let clusters = await clusteringEngine.findClusters(in: similarityGraph)
        return await clusters.asyncCompactMap { cluster in
            let assetIDs = await nodeTable.assetIDs(for: cluster.nodes)
            guard assetIDs.count >= configuration.minimumGroupSize else { return nil }
            return SMGroup(assetIDs: assetIDs)
        }
    }
    
    public func cancel() {
        processingTask?.cancel()
        processingTask = nil
    }
    
    public func reset() async throws {
        cancel()
        await similarityGraph.clear()
        try await storage.deleteAllEdges()
    }
    
    // MARK: - Pipeline
    
    private func run(continuation: AsyncThrowingStream<SMProgress, Error>.Continuation) async throws {
        
        // 1. Restore node table from storage
        let storedEntries = try await storage.fetchNodeEntries()
        await nodeTable.restoreFrom(entries: storedEntries)
        
        // 2. Load edges and processed-node set from storage (read-only, no write-back)
        try await similarityGraph.load()
        
        // 3. Fetch assets
        let assets = try await mediaProvider.fetchAssets()
        
        // 4. Register new assets in node table
        let newAssetIDs = await assets.asyncFilter { asset in
            await !nodeTable.contains(asset.id)
        }.map(\.id)
        
        if !newAssetIDs.isEmpty {
            let newEntries = await nodeTable.registerAll(newAssetIDs)
            try await storage.saveNodeEntries(newEntries)
        }
        
        // 5. Extract embeddings
        let embeddingExtractor = SMEmbeddingExtractor(storage: storage,
                                                      nodeTable: nodeTable,
                                                      mediaProvider: mediaProvider)
        var embeddings: [SMEmbedding] = []
        for try await progress in await embeddingExtractor.extract(for: assets) {
            embeddings = progress.embeddings
            continuation.yield(await makeProgress(with: progress))
        }
        
        try Task.checkCancellation()
        
        // 6. Build edges
        let edgeBuilder = SMEdgeBuilder(graph: similarityGraph,
                                        threshold: configuration.similarityThreshold)
        for try await progress in await edgeBuilder.build(for: embeddings) {
            continuation.yield(await makeProgress(with: progress))
        }
        
        try Task.checkCancellation()
        
        // 7. Final clustering
        let finalGroups = await currentGroups()
        continuation.yield(SMProgress(stage: .done, groups: finalGroups))
        continuation.finish()
    }
    
    // MARK: - Progress
    
    private func makeProgress(with progress: SMEdgeBuildProgress) async -> SMProgress {
        SMProgress(
            stage: .buildingEdges(processed: progress.processedEdgesCount, total: progress.totalEdgesCount),
            groups: await currentGroups()
        )
    }
    
    private func makeProgress(with progress: SMEmbeddingExtractProgress) async -> SMProgress {
        SMProgress(
            stage: .extractingEmbeddings(completed: progress.processedCount, total: progress.totalCount),
            groups: await currentGroups()
        )
    }
}

// MARK: - Async helpers

private extension Array {
    func asyncFilter(_ predicate: (Element) async -> Bool) async -> [Element] {
        var result: [Element] = []
        for element in self {
            if await predicate(element) { result.append(element) }
        }
        return result
    }
    
    func asyncCompactMap<T>(_ transform: (Element) async -> T?) async -> [T] {
        var result: [T] = []
        for element in self {
            if let value = await transform(element) { result.append(value) }
        }
        return result
    }
}
