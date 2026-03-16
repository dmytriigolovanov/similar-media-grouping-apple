//
//  SMStorage.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

@ModelActor
actor SMStorage {
    init() throws {
        let schema = Schema([
            SMStoredEmbedding.self,
            SMStoredEdge.self,
            SMStoredNodeEntry.self,
            SMStoredProcessingState.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, allowsSave: true)
        let modelContainer = try ModelContainer(for: schema, configurations: config)
        self.init(modelContainer: modelContainer)
    }

    // MARK: - Node Table

    func fetchNodeEntries() throws -> [(assetID: String, nodeIndex: UInt32)] {
        try modelContext.fetch(FetchDescriptor<SMStoredNodeEntry>())
            .map { (assetID: $0.assetID, nodeIndex: $0.nodeIndex) }
    }

    func saveNodeEntries(_ entries: [(assetID: String, nodeIndex: UInt32)]) throws {
        guard !entries.isEmpty else { return }
        let assetIDs = entries.map(\.assetID)
        let existing = try modelContext.fetch(
            FetchDescriptor<SMStoredNodeEntry>(predicate: #Predicate { assetIDs.contains($0.assetID) })
        )
        let existingIDs = Set(existing.map(\.assetID))
        for entry in entries where !existingIDs.contains(entry.assetID) {
            modelContext.insert(SMStoredNodeEntry(assetID: entry.assetID, nodeIndex: entry.nodeIndex))
        }
        try modelContext.save()
    }

    func deleteNodeEntries(for assetIDs: Set<String>) throws {
        guard !assetIDs.isEmpty else { return }
        let records = try modelContext.fetch(
            FetchDescriptor<SMStoredNodeEntry>(predicate: #Predicate { assetIDs.contains($0.assetID) })
        )
        records.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
    
    // MARK: - Processing State
    
    func fetchProcessedNodes() throws -> [SMNodeIndex] {
        let state = try modelContext.fetch(FetchDescriptor<SMStoredProcessingState>()).first
        return state?.processedNodes ?? []
    }
    
    func saveProcessedNode(_ nodeIndex: SMNodeIndex) throws {
        if let existing = try modelContext.fetch(FetchDescriptor<SMStoredProcessingState>()).first {
            existing.processedNodes.append(nodeIndex)
        } else {
            let state = SMStoredProcessingState(processedNodes: [nodeIndex])
            modelContext.insert(state)
        }
        try modelContext.save()
    }

    // MARK: - Edges

    func fetchAllEdges() throws -> [SMEdge] {
        try modelContext.fetch(FetchDescriptor<SMStoredEdge>()).map(\.toEdge)
    }

    func saveEdges(_ edges: [SMEdge]) throws {
        guard !edges.isEmpty else { return }
        let keys = edges.map(\.edgeKey)
        let existing = try modelContext.fetch(
            FetchDescriptor<SMStoredEdge>(predicate: #Predicate { keys.contains($0.edgeKey) })
        )
        let existingKeys = Set(existing.map(\.edgeKey))
        for edge in edges where !existingKeys.contains(edge.edgeKey) {
            modelContext.insert(SMStoredEdge(edge: edge))
        }
        try modelContext.save()
    }

    func deleteEdges(forNodes indices: Set<UInt32>) throws {
        guard !indices.isEmpty else { return }
        let records = try modelContext.fetch(
            FetchDescriptor<SMStoredEdge>(
                predicate: #Predicate { indices.contains($0.nodeIndex1) || indices.contains($0.nodeIndex2) }
            )
        )
        guard !records.isEmpty else { return }
        records.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    func deleteAllEdges() throws {
        let all = try modelContext.fetch(FetchDescriptor<SMStoredEdge>())
        all.forEach { modelContext.delete($0) }
        try modelContext.save()
    }

    // MARK: - Embeddings

    func fetchStoredEmbeddings() throws -> [SMEmbedding] {
        let stored = try modelContext.fetch(FetchDescriptor<SMStoredEmbedding>())
        return try stored.map { try $0.toEmbedding() }
    }

    /// Save embeddings — assetIDs passed separately since SMEmbedding no longer carries them
    func saveEmbeddings(_ embeddings: [SMEmbedding], assetIDs: [String]) throws {
        guard !embeddings.isEmpty, embeddings.count == assetIDs.count else { return }
        let pairs = zip(assetIDs, embeddings)

        let existing = try modelContext.fetch(
            FetchDescriptor<SMStoredEmbedding>(predicate: #Predicate { assetIDs.contains($0.assetID) })
        )
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.assetID, $0) })

        for (assetID, embedding) in pairs {
            if let record = existingByID[assetID] {
                try record.update(with: embedding)
            } else {
                modelContext.insert(try SMStoredEmbedding(from: embedding))
            }
        }
        try modelContext.save()
    }

    func deleteEmbeddings(for assetIDs: Set<String>) throws {
        guard !assetIDs.isEmpty else { return }
        let records = try modelContext.fetch(
            FetchDescriptor<SMStoredEmbedding>(predicate: #Predicate { assetIDs.contains($0.assetID) })
        )
        records.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}
