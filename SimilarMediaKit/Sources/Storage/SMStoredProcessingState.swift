//
//  SMStoredProcessingState.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class SMStoredProcessingState {
    /// localIdentifier of the last asset for which all pairs were computed
    var lastProcessedAssetID: String?
    /// Total number of assets at the time processing started
    var totalAssetCount: Int
    var updatedAt: Date

    init() {
        self.lastProcessedAssetID = nil
        self.totalAssetCount = 0
        self.updatedAt = Date()
    }
}
