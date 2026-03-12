//
//  SimilarMediaStorageService.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

protocol SimilarMediaStorageService {
    func loadGroups() throws -> [SimilarMediaGroup]
    func saveGroups(_ groups: [SimilarMediaGroup]) throws
    func loadProcessedIdentifiers() throws -> Set<String>
    func saveProcessedIdentifiers(_ identifiers: Set<String>) throws
}

final class DefaultSimilarMediaStorageService: SimilarMediaStorageService {

    private let modelContainer: ModelContainer
    private var context: ModelContext {
        modelContainer.mainContext
    }

    init() throws {
        self.modelContainer = try ModelContainer(
            for: StoredMediaGroup.self, StoredProcessedMediaAsset.self
        )
    }

    // MARK: Groups

    func loadGroups() throws -> [SimilarMediaGroup] {
        let stored = try context.fetch(FetchDescriptor<StoredMediaGroup>())
        return stored.map {
            SimilarMediaGroup(
                id: $0.id,
                assetIdentifiers: $0.assetIdentifiers
            )
        }
    }

    func saveGroups(_ groups: [SimilarMediaGroup]) throws {
        let existing = try context.fetch(FetchDescriptor<StoredMediaGroup>())
        existing.forEach { context.delete($0) }

        groups.forEach { group in
            context.insert(
                StoredMediaGroup(
                    id: group.id,
                    assetIdentifiers: group.assetIdentifiers
                )
            )
        }

        try context.save()
    }

    // MARK: Processed Identifiers

    func loadProcessedIdentifiers() throws -> Set<String> {
        let stored = try context.fetch(FetchDescriptor<StoredProcessedMediaAsset>())
        return Set(stored.map { $0.localIdentifier })
    }

    func saveProcessedIdentifiers(_ identifiers: Set<String>) throws {
        let existing = try context.fetch(FetchDescriptor<StoredProcessedMediaAsset>())
        existing.forEach { context.delete($0) }

        identifiers.forEach { identifier in
            context.insert(StoredProcessedMediaAsset(localIdentifier: identifier))
        }

        try context.save()
    }
}
