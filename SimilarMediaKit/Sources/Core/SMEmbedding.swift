//
//  SMEmbedding.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Vision

extension VNFeaturePrintObservation: @retroactive @unchecked Sendable {}

/// Runtime embedding — uses compact UInt32 node index.
/// String assetID never crosses this boundary.
struct SMEmbedding: Sendable, Hashable {
    let assetID: String
    let nodeIndex: SMNodeIndex
    let observation: VNFeaturePrintObservation
    let modificationDate: Date?
    let computedAt: Date

    init(assetID: String,
         nodeIndex: SMNodeIndex,
         observation: VNFeaturePrintObservation,
         modificationDate: Date?,
         computedAt: Date = Date()) {
        self.assetID = assetID
        self.nodeIndex = nodeIndex
        self.observation = observation
        self.modificationDate = modificationDate
        self.computedAt = computedAt
    }
}
