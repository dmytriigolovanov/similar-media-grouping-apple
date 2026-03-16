//
//  SMEdgeBuilder.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Accelerate

struct SMEdgeBuildProgress: Sendable {
    let totalEdgesCount: Int
    let processedEdgesCount: Int
}

actor SMEdgeBuilder {
    private let graph: SMSimilarityGraph
    private let threshold: Float
    private let chunkSize: Int
    
    init(graph: SMSimilarityGraph,
         threshold: Float) {
        self.graph = graph
        self.threshold = threshold
        self.chunkSize = max(10, min(100, ProcessInfo.processInfo.activeProcessorCount * 8))
    }
    
    // MARK: - Public
    
    func build(for embeddings: [SMEmbedding]) -> AsyncThrowingStream<SMEdgeBuildProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let embeddingsCount = embeddings.count
                    var processedCount = 0
                    
                    // Build index: assetID → (nodeIndex, embedding)
                    var embeddingByNode: [SMNodeIndex: SMEmbedding] = [:]
                    for embedding in embeddings {
                        embeddingByNode[embedding.nodeIndex] = embedding
                    }
                    
                    for embedding in embeddings {
                        try Task.checkCancellation()
                        
                        guard await !graph.isProcessed(embedding.nodeIndex) else {
                            processedCount += 1
                            continue
                        }
                        
                        let sourceIdx = embedding.nodeIndex
                        
                        // Filter targets — skip already computed via graph O(1)
                        var targets: [(idx: SMNodeIndex, embedding: SMEmbedding)] = []
                        for (targetIdx, targetEmbedding) in embeddingByNode {
                            guard targetIdx != sourceIdx else { continue }
                            let edge = SMEdge(nodeIndex1: sourceIdx, nodeIndex2: targetIdx, distance: 0)
                            guard await !graph.hasEdge(edge) else { continue }
                            targets.append((idx: targetIdx, embedding: targetEmbedding))
                        }
                        
                        guard !targets.isEmpty else {
                            processedCount += 1
                            continuation.yield(makeProgress(
                                embeddingsCount: embeddingsCount,
                                processedCount: processedCount
                            ))
                            continue
                        }
                        
                        // Compute distances in parallel chunks
                        let newEdges = try await buildEdges(
                            sourceIdx: sourceIdx,
                            source: embedding,
                            targets: targets
                        )
                        
                        // Add to graph
                        try await graph.addEdges(newEdges)
                        try await graph.markProcessed(sourceIdx)
                        
                        processedCount += 1
                        continuation.yield(makeProgress(
                            embeddingsCount: embeddingsCount,
                            processedCount: processedCount
                        ))
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    private func buildEdges(sourceIdx: SMNodeIndex,
                            source: SMEmbedding,
                            targets: [(idx: SMNodeIndex, embedding: SMEmbedding)]) async throws -> [SMEdge] {
        return try await withThrowingTaskGroup(of: [SMEdge].self) { group in
            for chunkStart in stride(from: 0, to: targets.count, by: chunkSize) {
                let chunk = Array(targets[chunkStart..<min(chunkStart + chunkSize, targets.count)])
                
                group.addTask {
                    var chunkEdges: [SMEdge] = []
                    
                    for target in chunk {
                        var distance: Float = 0
                        try source.observation.computeDistance(
                            &distance,
                            to: target.embedding.observation,
                        )
                        
                        guard distance <= self.threshold else { continue }
                        chunkEdges.append(SMEdge(
                            nodeIndex1: sourceIdx,
                            nodeIndex2: target.idx,
                            distance: distance
                        ))
                    }
                    return chunkEdges
                }
            }
            
            var result: [SMEdge] = []
            for try await edges in group {
                result.append(contentsOf: edges)
            }
            return result
        }
    }
    
    // MARK: - Progress
    
    private func makeProgress(embeddingsCount: Int, processedCount: Int) -> SMEdgeBuildProgress {
        let processed = processedCount * (2 * embeddingsCount - processedCount - 1) / 2
        let total = embeddingsCount * (embeddingsCount - 1) / 2
        return SMEdgeBuildProgress(totalEdgesCount: total, processedEdgesCount: processed)
    }
}
