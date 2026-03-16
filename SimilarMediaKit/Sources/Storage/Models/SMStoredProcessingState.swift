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
    var processedNodes: [UInt32]

    init(processedNodes: [UInt32]) {
        self.processedNodes = processedNodes
    }
}
