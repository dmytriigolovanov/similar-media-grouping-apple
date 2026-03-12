//
//  StoredProcessedMediaAsset.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class StoredProcessedMediaAsset {
    var localIdentifier: String

    init(localIdentifier: String) {
        self.localIdentifier = localIdentifier
    }
}
