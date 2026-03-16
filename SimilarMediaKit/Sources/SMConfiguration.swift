//
//  SMConfiguration.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public struct SMConfiguration: Sendable {
    /// Similarity threshold: lower = stricter (0.0 - 1.0)
    public var similarityThreshold: Float
    /// Minimum number of photos to form a group
    public var minimumGroupSize: Int
    /// Minimum percentage of group members a photo must match to join (clique-aware)
    public var minimumMemberMatchRatio: Float

    public init(
        similarityThreshold: Float = 0.25,
        minimumGroupSize: Int = 3,
        minimumMemberMatchRatio: Float = 0.5
    ) {
        self.similarityThreshold = similarityThreshold
        self.minimumGroupSize = minimumGroupSize
        self.minimumMemberMatchRatio = minimumMemberMatchRatio
    }
}
