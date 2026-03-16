//
//  SMNodeTable.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 16.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

/// Maps assetID (String) ↔ SMNodeIndex (UInt32).
/// Append-only — indices never change once assigned.
/// Thread-safe via actor isolation.
actor SMNodeTable {
    private var assetToNode: [String: SMNodeIndex] = [:]
    private var nodeToAsset: [SMNodeIndex: String] = [:]
    private var nextIndex: SMNodeIndex = 0

    // MARK: - Restore

    /// Restores table from persisted entries — call once at startup.
    func restoreFrom(entries: [(assetID: String, nodeIndex: SMNodeIndex)]) {
        for entry in entries {
            assetToNode[entry.assetID] = entry.nodeIndex
            nodeToAsset[entry.nodeIndex] = entry.assetID
            if entry.nodeIndex >= nextIndex {
                nextIndex = entry.nodeIndex + 1
            }
        }
    }

    // MARK: - Registration

    /// Returns existing index or registers a new one.
    @discardableResult
    func index(for assetID: String) -> SMNodeIndex {
        if let existing = assetToNode[assetID] { return existing }
        let index = nextIndex
        assetToNode[assetID] = index
        nodeToAsset[index] = assetID
        nextIndex += 1
        return index
    }

    /// Registers multiple assetIDs — returns only newly created entries for persistence.
    func registerAll(_ assetIDs: [String]) -> [(assetID: String, nodeIndex: SMNodeIndex)] {
        var newEntries: [(assetID: String, nodeIndex: SMNodeIndex)] = []
        for id in assetIDs where assetToNode[id] == nil {
            let idx = nextIndex
            assetToNode[id] = idx
            nodeToAsset[idx] = id
            nextIndex += 1
            newEntries.append((assetID: id, nodeIndex: idx))
        }
        return newEntries
    }

    // MARK: - Lookup

    func assetID(for index: SMNodeIndex) -> String? {
        nodeToAsset[index]
    }

    func assetIDs(for indices: [SMNodeIndex]) -> [String] {
        indices.compactMap { nodeToAsset[$0] }
    }

    // MARK: - Removal

    func remove(_ assetID: String) {
        guard let index = assetToNode.removeValue(forKey: assetID) else { return }
        nodeToAsset.removeValue(forKey: index)
    }

    // MARK: - Info

    var count: Int { assetToNode.count }

    func contains(_ assetID: String) -> Bool {
        assetToNode[assetID] != nil
    }
}
