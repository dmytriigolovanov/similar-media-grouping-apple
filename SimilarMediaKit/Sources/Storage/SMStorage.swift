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
            SMStoredProcessingState.self
        ])
        let config = ModelConfiguration(schema: schema,
                                        isStoredInMemoryOnly: false,
                                        allowsSave: true)
        let modelContainer = try ModelContainer(for: schema,
                                                configurations: config)
        self.init(modelContainer: modelContainer)
    }
    
    // MARK: Embeddings
    
    func saveEmbedding(_ embedding: SMEmbedding) throws {
        try saveEmbeddings([embedding])
    }

    /// Upserts a batch of embeddings in a single transaction.
    func saveEmbeddings(_ embeddings: [SMEmbedding]) throws {
        guard !embeddings.isEmpty else { return }
        let ids = embeddings.map(\.id)
        let existing = try modelContext.fetch(
            FetchDescriptor<SMStoredEmbedding>(
                predicate: #Predicate { ids.contains($0.id) }
            )
        )
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        for embedding in embeddings {
            if let record = existingByID[embedding.id] {
                record.update(with: embedding)
            } else {
                modelContext.insert(SMStoredEmbedding(from: embedding))
            }
        }
        try modelContext.save()
    }
    
    func fetchEmbedding(id: String) throws -> SMEmbedding? {
        let stored = try modelContext.fetch(
            FetchDescriptor<SMStoredEmbedding>(
                predicate: #Predicate { $0.id == id }
            )
        ).first
        return stored?.toEmbedding
    }
    
    func fetchAllEmbeddings() throws -> [SMEmbedding] {
        let stored = try modelContext.fetch(FetchDescriptor<SMStoredEmbedding>())
        return stored.map { $0.toEmbedding }
    }
    
    func deleteEmbeddings(ids: [String]) throws {
        let records = try modelContext.fetch(
            FetchDescriptor<SMStoredEmbedding>(
                predicate: #Predicate { ids.contains($0.id) }
            )
        )
        records.forEach {
            modelContext.delete($0)
        }
        try modelContext.save()
    }
    
    // MARK: Edges
    
    func saveEdges(_ edges: [SMEdge]) throws {
        guard !edges.isEmpty else {
            return
        }
        
        // Fetch existing edge IDs in one query to avoid duplicates
        let edgeIDs = edges.map { $0.edgeID }
        let existing = try modelContext.fetch(
            FetchDescriptor<SMStoredEdge>(
                predicate: #Predicate { edgeIDs.contains($0.edgeID) }
            )
        )
        let existingIDs = Set(existing.map(\.edgeID))
        
        // Insert all new edges, then save once — avoids per-insert overhead
        for edge in edges {
            guard !existingIDs.contains(edge.edgeID) else {
                continue
            }
            modelContext.insert(SMStoredEdge(from: edge))
        }
        try modelContext.save()
    }
    
    func deleteEdges(forAssetIDs ids: Set<String>) throws {
        guard !ids.isEmpty else {
            return
        }
        let records = try modelContext.fetch(
            FetchDescriptor<SMStoredEdge>(
                predicate: #Predicate { ids.contains($0.assetID1) || ids.contains($0.assetID2) }
            )
        )
        guard !records.isEmpty else {
            return
        }
        records.forEach {
            modelContext.delete($0)
        }
        try modelContext.save()
    }
    
    func fetchAllEdges() throws -> [SMEdge] {
        let storedEdges = try modelContext.fetch(FetchDescriptor<SMStoredEdge>())
        return storedEdges.map(\.toEdge)
    }
    
    func deleteAllEdges() throws {
        let all = try modelContext.fetch(FetchDescriptor<SMStoredEdge>())
        all.forEach {
            modelContext.delete($0)
        }
        try modelContext.save()
    }
    
    // MARK: Processing State
    
    func fetchProcessingState() throws -> (lastProcessedAssetID: String?, totalAssetCount: Int?, updateDate: Date?)? {
        let processedState = try modelContext.fetch(FetchDescriptor<SMStoredProcessingState>()).first
        return (processedState?.lastProcessedAssetID, processedState?.totalAssetCount, processedState?.updatedAt)
    }
    
    func saveProcessingState(lastProcessedAssetID: String?,
                             totalAssetCount: Int) throws {
        if let existing = try modelContext.fetch(FetchDescriptor<SMStoredProcessingState>()).first {
            existing.lastProcessedAssetID = lastProcessedAssetID
            existing.totalAssetCount = totalAssetCount
            existing.updatedAt = Date()
        } else {
            let state = SMStoredProcessingState()
            state.lastProcessedAssetID = lastProcessedAssetID
            state.totalAssetCount = totalAssetCount
            state.updatedAt = Date()
            modelContext.insert(state)
        }
        try modelContext.save()
    }
    
    func resetProcessingState() throws {
        let all = try modelContext.fetch(FetchDescriptor<SMStoredProcessingState>())
        all.forEach {
            modelContext.delete($0)
        }
        try modelContext.save()
    }
}
