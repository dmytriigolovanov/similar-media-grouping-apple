//
//  SMStoredEdge.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

/// Persistent edge — stores compact UInt32 node indices.
/// Stable between launches because SMStoredNodeEntry persists the index table.
@Model
final class SMStoredEdge {
    @Attribute(.unique) var edgeKey: UInt64  // nodeIndex1 << 32 | nodeIndex2
    var nodeIndex1: UInt32
    var nodeIndex2: UInt32
    var distance: Float

    init(edge: SMEdge) {
        self.nodeIndex1 = edge.nodeIndex1
        self.nodeIndex2 = edge.nodeIndex2
        self.edgeKey = edge.edgeKey
        self.distance = edge.distance
    }
}

extension SMStoredEdge {
    var toEdge: SMEdge {
        SMEdge(nodeIndex1: nodeIndex1, nodeIndex2: nodeIndex2, distance: distance)
    }
}
