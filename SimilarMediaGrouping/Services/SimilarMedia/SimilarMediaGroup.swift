//
//  SimilarMediaGroup.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

struct SimilarMediaGroup: Identifiable, Hashable {
    let id: UUID
    var assetIdentifiers: [String]
    
    var count: Int {
        assetIdentifiers.count
    }
    
    init(
        id: UUID = UUID(),
        assetIdentifiers: [String]
    ) {
        self.id = id
        self.assetIdentifiers = assetIdentifiers
    }
}
