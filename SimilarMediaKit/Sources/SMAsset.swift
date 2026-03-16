//
//  SMAsset.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public struct SMAsset: Sendable, Identifiable, Hashable {
    public let id: String
    public let modificationDate: Date?
    
    public init(id: String, modificationDate: Date?) {
        self.id = id
        self.modificationDate = modificationDate
    }
}
