//
//  SMEdge.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

struct SMEdge: Sendable, Hashable {
    let edgeID: String
    let assetID1: String
    let assetID2: String
    let distance: Float
    
    /// Canonical form — ensures (A,B) == (B,A)
    init(assetID1: String,
         assetID2: String,
         distance: Float) {
        if assetID1 < assetID2 {
            self.assetID1 = assetID1
            self.assetID2 = assetID2
            self.edgeID = "\(assetID1)|\(assetID2)"
        } else {
            self.assetID1 = assetID2
            self.assetID2 = assetID1
            self.edgeID = "\(assetID2)|\(assetID1)"
        }
        self.distance = distance
    }
}
