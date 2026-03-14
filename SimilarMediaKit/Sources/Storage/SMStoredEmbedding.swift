//
//  SMStoredEmbedding.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import SwiftData

@Model
final class SMStoredEmbedding {
    @Attribute(.unique) var id: String
    var embeddingData: Data
    var modificationDate: Date?
    var computedAt: Date
    
    init(id: String,
         embeddingData: Data,
         modificationDate: Date?,
         computedAt: Date) {
        self.id = id
        self.embeddingData = embeddingData
        self.modificationDate = modificationDate
        self.computedAt = computedAt
    }
}

extension SMStoredEmbedding {
    convenience init(from embedding: SMEmbedding) {
        self.init(id: embedding.id,
                  embeddingData: embedding.data,
                  modificationDate: embedding.modificationDate,
                  computedAt: embedding.computedAt)
    }
    
    func update(with embedding: SMEmbedding) {
        embeddingData = embedding.data
        modificationDate = embedding.modificationDate
        computedAt = Date()
    }
    
    var toEmbedding: SMEmbedding {
        SMEmbedding(id: id,
                    data: embeddingData,
                    modificationDate: modificationDate,
                    computedAt: computedAt)
    }
}
