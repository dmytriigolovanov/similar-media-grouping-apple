//
//  SMClusteringEngine.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

/// Computes groups from the similarity graph using clique-aware clustering.
/// All methods are pure (no state) so they are safe to call from any context.
struct SMClusteringEngine {
    private let configuration: SMConfiguration

    init(configuration: SMConfiguration) {
        self.configuration = configuration
    }

    // MARK: - Public

    /// Computes groups from an adjacency snapshot.
    /// A photo joins a group only if it is similar to at least
    /// `minimumMemberMatchRatio` of the group's existing members.
    func computeGroups(adjacency: [String: [(id: String, distance: Float)]]) -> [SMGroup] {
        let threshold = configuration.similarityThreshold
        let matchRatio = configuration.minimumMemberMatchRatio
        let minSize = configuration.minimumGroupSize

        // Build neighbor sets for O(1) lookup
        var neighborSets: [String: Set<String>] = [:]
        for (id, neighbors) in adjacency {
            neighborSets[id] = Set(neighbors.filter { $0.distance <= threshold }.map(\.id))
        }

        // Sort by degree descending — highly connected nodes become group seeds first,
        // producing more stable and deterministic results across runs
        let allIDs = adjacency.keys.sorted { lhs, rhs in
            (neighborSets[lhs]?.count ?? 0) > (neighborSets[rhs]?.count ?? 0)
        }
        var assigned: Set<String> = []
        var groups: [[String]] = []

        for assetID in allIDs {
            guard !assigned.contains(assetID) else {
                continue
            }

            // Try to place into existing group
            var placed = false
            for i in 0..<groups.endIndex {
                if canJoin(assetID: assetID, group: groups[i], neighborSets: neighborSets, ratio: matchRatio) {
                    groups[i].append(assetID)
                    assigned.insert(assetID)
                    placed = true
                    break
                }
            }

            // Start new group
            if !placed {
                groups.append([assetID])
                assigned.insert(assetID)
            }
        }

        return groups
            .filter { $0.count >= minSize }
            .map { SMGroup(assetIDs: $0) }
    }

    // MARK: - Private

    /// Returns true if assetID is similar to at least `ratio` of group members
    private func canJoin(
        assetID: String,
        group: [String],
        neighborSets: [String: Set<String>],
        ratio: Float
    ) -> Bool {
        guard !group.isEmpty else {
            return true
        }
        let neighbors = neighborSets[assetID] ?? []
        let matches = group.filter { neighbors.contains($0) }.count
        return Float(matches) / Float(group.count) >= ratio
    }
}
