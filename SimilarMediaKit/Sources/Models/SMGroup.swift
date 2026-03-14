//
//  SMGroup.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public struct SMGroup: Sendable, Identifiable, Hashable {
    public let id: String
    public let assetIDs: [String]
    
    public var assetsCount: Int {
        return assetIDs.count
    }

    init(assetIDs: [String]) {
        self.assetIDs = assetIDs.sorted()
        self.id = self.assetIDs.joined(separator: "|")
    }
}
