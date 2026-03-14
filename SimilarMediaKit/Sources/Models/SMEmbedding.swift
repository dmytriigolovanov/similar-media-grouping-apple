//
//  SMEmbedding.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//

import Foundation

struct SMEmbedding: Sendable {
    let id: String
    let data: Data
    let modificationDate: Date?
    let computedAt: Date
    
    init(id: String,
         data: Data,
         modificationDate: Date?,
         computedAt: Date = Date()) {
        self.id = id
        self.data = data
        self.modificationDate = modificationDate
        self.computedAt = computedAt
    }
}

