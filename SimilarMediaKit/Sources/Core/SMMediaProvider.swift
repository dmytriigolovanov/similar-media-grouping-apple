//
//  SMMediaProvider.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import CoreGraphics

public protocol SMMediaProvider: Sendable {
    func fetchAssets() async throws -> [SMAsset]
    func loadCGImage(for asset: SMAsset, size: CGSize) async -> CGImage?
}
