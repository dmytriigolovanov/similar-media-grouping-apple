//
//  SMClusteringEngine.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

/// Internal cluster — works with compact UInt32 node indices.
struct SMCluster {
    var nodes: [SMNodeIndex]
}

struct SMClusteringEngine {
    let configuration: SMConfiguration

    init(configuration: SMConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Public

    /// Finds groups in the graph using clique-aware clustering.
    /// Returns internal SMCluster — caller converts to SimilarMediaGroup using node table.
    func findClusters(in graph: SMSimilarityGraph) async -> [SMCluster] {
        let threshold = configuration.similarityThreshold
        let matchRatio = configuration.minimumMemberMatchRatio
        let minSize = configuration.minimumGroupSize

        let allNodes = await graph.allNodes()
        guard !allNodes.isEmpty else { return [] }

        // Build neighbour sets for O(1) canJoin lookups
        var neighborSets: [SMNodeIndex: Set<SMNodeIndex>] = [:]
        for node in allNodes {
            let neighbours = await graph.neighborsWithDistance(of: node)
            neighborSets[node] = Set(
                neighbours
                    .filter { $0.distance <= threshold }
                    .map(\.node)
            )
        }

        // Sort by degree descending — highly connected nodes become seeds first
        let sorted = allNodes.sorted {
            (neighborSets[$0]?.count ?? 0) > (neighborSets[$1]?.count ?? 0)
        }

        var assigned: Set<SMNodeIndex> = []
        var clusters: [[SMNodeIndex]] = []
        var memberToClusterIndex: [SMNodeIndex: Int] = [:]

        for node in sorted {
            guard !assigned.contains(node) else { continue }

            let neighbours = neighborSets[node] ?? []
            let candidateIndices = Set(neighbours.compactMap { memberToClusterIndex[$0] }).sorted()

            var placed = false
            for i in candidateIndices {
                if canJoin(node: node, cluster: clusters[i], neighborSets: neighborSets, ratio: matchRatio) {
                    clusters[i].append(node)
                    assigned.insert(node)
                    memberToClusterIndex[node] = i
                    placed = true
                    break
                }
            }

            if !placed {
                let newIndex = clusters.count
                clusters.append([node])
                assigned.insert(node)
                memberToClusterIndex[node] = newIndex
            }
        }

        return clusters
            .filter { $0.count >= minSize }
            .map { SMCluster(nodes: $0) }
    }

    // MARK: - Private

    private func canJoin(
        node: SMNodeIndex,
        cluster: [SMNodeIndex],
        neighborSets: [SMNodeIndex: Set<SMNodeIndex>],
        ratio: Float
    ) -> Bool {
        guard !cluster.isEmpty else { return true }
        let neighbours = neighborSets[node] ?? []
        let needed = Int((ratio * Float(cluster.count)).rounded(.up))
        var matched = 0

        for (offset, member) in cluster.enumerated() {
            if neighbours.contains(member) {
                matched += 1
                if matched >= needed { return true }
            }
            let remaining = cluster.count - offset - 1
            if matched + remaining < needed { return false }
        }
        return false
    }
}
