//
//  StoredMediaGroup.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class StoredMediaGroup {
    var id: UUID
    var assetIdentifiers: [String]

    init(id: UUID = UUID(), assetIdentifiers: [String]) {
        self.id = id
        self.assetIdentifiers = assetIdentifiers
    }
}
