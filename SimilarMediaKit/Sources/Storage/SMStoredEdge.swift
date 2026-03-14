//
//  SMStoredEdge.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class SMStoredEdge {
    @Attribute(.unique) var edgeID: String  // "assetID1|assetID2" canonical sorted
    var assetID1: String
    var assetID2: String
    var distance: Float
    
    init(edgeID: String,
         assetID1: String,
         assetID2: String,
         distance: Float) {
        self.edgeID = edgeID
        // Canonical form — ensures (A,B) == (B,A)
        if assetID1 < assetID2 {
            self.assetID1 = assetID1
            self.assetID2 = assetID2
        } else {
            self.assetID1 = assetID2
            self.assetID2 = assetID1
        }
        self.distance = distance
    }
}

extension SMStoredEdge {
    convenience init(from edge: SMEdge) {
        self.init(edgeID: edge.edgeID,
                  assetID1: edge.assetID1,
                  assetID2: edge.assetID2,
                  distance: edge.distance)
    }
    
    var toEdge: SMEdge {
        SMEdge(assetID1: assetID1,
               assetID2: assetID2,
               distance: distance)
    }
}
