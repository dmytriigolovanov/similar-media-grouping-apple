//
//  SMDistanceCalculator.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import Vision

// VNFeaturePrintObservation is immutable after creation — safe to share across tasks.
extension VNFeaturePrintObservation: @retroactive @unchecked Sendable {}

actor SMDistanceCalculator {
    private let configuration: SMConfiguration
    
    init(configuration: SMConfiguration) {
        self.configuration = configuration
    }
    
    /// Computes all pairs above similarity threshold.
    /// Resumes from lastProcessedIndex if provided (for crash recovery).
    func computeEdges(embeddings: [(id: String, observation: VNFeaturePrintObservation)],
                      startingFromIndex lastProcessedIndex: Int?,
                      progressHandler: @Sendable (Int, Int) async -> Void,
                      edgesHandler: @Sendable ([SMEdge]) async -> Void) async throws {
        
        let n = embeddings.count
        let resumeFrom = (lastProcessedIndex ?? -1) + 1
        let threshold = configuration.similarityThreshold
        
        // Total pairs = N*(N-1)/2, pairs already covered by resumed rows
        let totalPairs = n * (n - 1) / 2
        let skippedPairs: Int = resumeFrom > 0
        ? resumeFrom * (2 * n - resumeFrom - 1) / 2
        : 0
        var completedPairs = skippedPairs
        
        // Process row by row — each row i is compared against all j > i
        // Rows are independent so we can parallelize in chunks
        let chunkSize = 50
        
        var i = resumeFrom
        while i < n - 1 {
            let chunkEnd = min(i + chunkSize, n - 1)
            let chunkIndices = Array(i..<chunkEnd)
            
            // Compute chunk rows in parallel
            let chunkEdges = try await withThrowingTaskGroup(of: [SMEdge].self) { group in
                for rowIndex in chunkIndices {
                    let rowEmbedding = embeddings[rowIndex]
                    let tail = Array(embeddings[(rowIndex + 1)...])
                    
                    group.addTask {
                        var rowEdges: [SMEdge] = []
                        for colEmbedding in tail {
                            var distance: Float = 0
                            try rowEmbedding.observation.computeDistance(
                                &distance,
                                to: colEmbedding.observation
                            )
                            if distance <= threshold {
                                rowEdges.append(SMEdge(
                                    assetID1: rowEmbedding.id,
                                    assetID2: colEmbedding.id,
                                    distance: distance
                                ))
                            }
                        }
                        return rowEdges
                    }
                }
                
                var all: [SMEdge] = []
                for try await edges in group {
                    all.append(contentsOf: edges)
                }
                return all
            }
            
            // Emit edges for this chunk so storage and clustering can proceed
            if !chunkEdges.isEmpty {
                await edgesHandler(chunkEdges)
            }
            
            // Count pairs processed in this chunk
            for rowIndex in chunkIndices {
                completedPairs += n - rowIndex - 1
            }
            
            i = chunkEnd
            await progressHandler(completedPairs, totalPairs)
        }
    }
}
