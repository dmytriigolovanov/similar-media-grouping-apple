//
//  SimilarMediaGroup.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

struct SimilarMediaGroup: Identifiable {
    let id: UUID = UUID()
    var assetIdentifiers: [String]
}
