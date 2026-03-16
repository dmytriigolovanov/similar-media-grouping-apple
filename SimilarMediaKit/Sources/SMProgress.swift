//
//  SMProgress.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public struct SMProgress: Sendable {
    public enum Stage: Sendable {
        case extractingEmbeddings(completed: Int, total: Int)
        case buildingEdges(processed: Int, total: Int)
        case clustering
        case done
    }

    public let stage: Stage
    public let groups: [SMGroup]

    public var fractionCompleted: Double {
        switch stage {
        case .extractingEmbeddings(let completed, let total):
            return total > 0 ? Double(completed) / Double(total) * 0.3 : 0
        case .buildingEdges(let processed, let total):
            return total > 0 ? 0.3 + Double(processed) / Double(total) * 0.7 : 0.3
        case .clustering, .done:
            return 1.0
        }
    }
}
