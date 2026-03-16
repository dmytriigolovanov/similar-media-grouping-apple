//
//  SMSimilarityGraph.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

/// In-memory similarity graph backed by two compact tables:
///
/// - `edges:     [SMEdgeKey: Float]`          — weight per unique edge (UInt64, stored once).
/// - `adjacency: [SMNodeIndex: [SMNodeIndex]]` — neighbour indices per node (UInt32).
///
/// All String ↔ UInt32 mapping is handled externally by the caller.
/// Thread-safe via actor isolation.
actor SMSimilarityGraph {
    private let storage: SMStorage
    
    private var edges: [SMEdgeKey: Float] = [:]
    private var adjacency: [SMNodeIndex: [SMNodeIndex]] = [:]
    private var processedNodes: Set<SMNodeIndex> = []
    
    // MARK: Init
    
    init(storage: SMStorage) {
        self.storage = storage
    }
    
    func markProcessed(_ node: SMNodeIndex) async throws {
        processedNodes.insert(node)
        try await storage.saveProcessedNode(node)
    }

    func isProcessed(_ node: SMNodeIndex) -> Bool {
        processedNodes.contains(node)
    }
    
    func load() async throws {
        let stored = try await storage.fetchAllEdges()
        stored.forEach { addEdge($0) }
        
        let storedNodes = try await storage.fetchProcessedNodes()
        processedNodes = Set(storedNodes)
    }

    // MARK: - Mutation

    func addEdge(_ edge: SMEdge) {
        guard edges[edge.edgeKey] == nil else { return }
        edges[edge.edgeKey] = edge.distance
        adjacency[edge.nodeIndex1, default: []].append(edge.nodeIndex2)
        adjacency[edge.nodeIndex2, default: []].append(edge.nodeIndex1)
    }

    func addEdges(_ newEdges: [SMEdge]) async throws {
        for edge in newEdges {
            addEdge(edge)
        }
        try await storage.saveEdges(newEdges)
    }

    func removeEdges(forNode node: SMNodeIndex) {
        guard let neighbours = adjacency[node] else { return }
        for neighbour in neighbours {
            let key = SMEdge(nodeIndex1: node, nodeIndex2: neighbour, distance: 0).edgeKey
            edges.removeValue(forKey: key)
            adjacency[neighbour]?.removeAll { $0 == node }
        }
        adjacency.removeValue(forKey: node)
    }

    func clear() {
        edges.removeAll()
        adjacency.removeAll()
    }

    // MARK: - Read

    /// O(1) — checks if edge exists
    func hasEdge(_ edge: SMEdge) -> Bool {
        edges[edge.edgeKey] != nil
    }

    /// O(1) — returns distance between two nodes
    func distance(from i: SMNodeIndex, to j: SMNodeIndex) -> Float? {
        edges[SMEdge(nodeIndex1: i, nodeIndex2: j, distance: 0).edgeKey]
    }

    /// O(degree) — returns neighbour indices
    func neighbors(of node: SMNodeIndex) -> [SMNodeIndex] {
        adjacency[node] ?? []
    }

    /// O(degree) — returns neighbours with distances
    func neighborsWithDistance(of node: SMNodeIndex) -> [(node: SMNodeIndex, distance: Float)] {
        guard let neighbours = adjacency[node] else { return [] }
        return neighbours.compactMap { neighbour in
            let key = SMEdge(nodeIndex1: node, nodeIndex2: neighbour, distance: 0).edgeKey
            guard let dist = edges[key] else { return nil }
            return (node: neighbour, distance: dist)
        }
    }

    func allNodes() -> Set<SMNodeIndex> {
        Set(adjacency.keys)
    }

    var edgesCount: Int { edges.count }
    var nodesCount: Int { adjacency.count }
}
