//
//  SMStoredNodeTable.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 16.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

/// Persistent entry in the node index table.
/// One record per asset — maps assetID (String) to stable UInt32 index.
@Model
final class SMStoredNodeEntry {
    @Attribute(.unique) var assetID: String
    var nodeIndex: UInt32

    init(assetID: String, nodeIndex: UInt32) {
        self.assetID = assetID
        self.nodeIndex = nodeIndex
    }
}
