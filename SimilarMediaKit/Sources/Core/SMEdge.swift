//
//  SMEdge.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

typealias SMEdgeKey = UInt64

struct SMEdge: Sendable, Hashable {
    let nodeIndex1: SMNodeIndex
    let nodeIndex2: SMNodeIndex
    let distance: Float

    /// Canonical form — ensures (A,B) == (B,A)
    init(nodeIndex1: SMNodeIndex, nodeIndex2: SMNodeIndex, distance: Float) {
        if nodeIndex1 < nodeIndex2 {
            self.nodeIndex1 = nodeIndex1
            self.nodeIndex2 = nodeIndex2
        } else {
            self.nodeIndex1 = nodeIndex2
            self.nodeIndex2 = nodeIndex1
        }
        self.distance = distance
    }

    /// Packed UInt64 — canonical (lo << 32 | hi), O(1) lookup
    var edgeKey: SMEdgeKey {
        SMEdgeKey(nodeIndex1) << 32 | SMEdgeKey(nodeIndex2)
    }
}
