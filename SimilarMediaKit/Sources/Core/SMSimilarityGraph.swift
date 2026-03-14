//
//  SMSimilarityGraph.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

/// In-memory adjacency list representation of the similarity graph.
/// Thread-safe via actor isolation.
actor SMSimilarityGraph {

    // adjacency: assetID → [(neighborID, distance)]
    private var adjacency: [String: [(id: String, distance: Float)]] = [:]
    private let storage: SMStorage

    init(storage: SMStorage) {
        self.storage = storage
    }

    // MARK: Loading

    /// Loads persisted edges from SwiftData into memory
    func loadFromStorage() async throws {
        let storedEdges = try await storage.fetchAllEdges()
        for edge in storedEdges {
            addEdgeToMemory(edge)
        }
    }

    // MARK: Mutation

    /// Adds a batch of edges to memory and persists them
    func addEdges(_ edges: [SMEdge]) async throws {
        for edge in edges {
            addEdgeToMemory(edge)
        }
        try await storage.saveEdges(edges)
    }

    /// Removes all edges involving any of the given photo IDs and persists the change
    func removeEdges(forAssetIDs ids: Set<String>) async throws {
        for id in ids {
            if let neighbors = adjacency[id] {
                for neighbor in neighbors {
                    adjacency[neighbor.id]?.removeAll { $0.id == id }
                }
            }
            adjacency.removeValue(forKey: id)
        }
        try await storage.deleteEdges(forAssetIDs: ids)
    }

    // MARK: Read

    func neighbors(of assetID: String) -> [(id: String, distance: Float)] {
        adjacency[assetID] ?? []
    }

    func allAssetIDs() -> Set<String> {
        Set(adjacency.keys)
    }

    /// Returns a snapshot of the adjacency list safe to use outside this actor
    func snapshot() -> [String: [(id: String, distance: Float)]] {
        adjacency
    }

    // MARK: Private

    private func addEdgeToMemory(_ edge: SMEdge) {
        adjacency[edge.assetID1, default: []].append((id: edge.assetID2, distance: edge.distance))
        adjacency[edge.assetID2, default: []].append((id: edge.assetID1, distance: edge.distance))
    }
}

