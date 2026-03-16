//
//  SMGroup.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public struct SMGroup: Identifiable, Sendable, Hashable {
    public let id: UUID = UUID()
    public let assetIDs: [String]
}
