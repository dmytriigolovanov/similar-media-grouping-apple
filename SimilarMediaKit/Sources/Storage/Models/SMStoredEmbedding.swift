//
//  SMStoredEmbedding.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

/// Persistent embedding — stores assetID (stable PHAsset identifier)
/// and nodeIndex (restored from SMStoredNodeEntry).
/// assetID stays in storage layer only — never leaks into runtime graph.
@Model
final class SMStoredEmbedding {
    @Attribute(.unique) var assetID: String
    var nodeIndex: UInt32
    var observationData: Data
    var modificationDate: Date?

    init(from embedding: SMEmbedding) throws {
        self.assetID = embedding.assetID
        self.nodeIndex = embedding.nodeIndex
        self.observationData = try embedding.observation.toData()
        self.modificationDate = embedding.modificationDate
    }

    func update(with embedding: SMEmbedding) throws {
        observationData = try embedding.observation.toData()
        modificationDate = embedding.modificationDate
    }
}

extension SMStoredEmbedding {
    func toEmbedding() throws -> SMEmbedding {
        let observation = try VNFeaturePrintObservation.from(observationData)
        return SMEmbedding(assetID: assetID,
                           nodeIndex: nodeIndex,
                           observation: observation,
                           modificationDate: modificationDate)
    }
}

internal import Vision

extension VNFeaturePrintObservation {
    func toData() throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: true)
    }
    
    static func from(_ data: Data) throws -> VNFeaturePrintObservation {
        guard let obs = try NSKeyedUnarchiver.unarchivedObject(
            ofClass: VNFeaturePrintObservation.self,
            from: data
        ) else {
            throw SMError.embeddingDeserializationFailed
        }
        return obs
    }
}
