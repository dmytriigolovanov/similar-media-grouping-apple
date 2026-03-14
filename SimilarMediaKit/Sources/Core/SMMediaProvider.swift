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
    // @MainActor ensures PHImageManager is always called from a thread with a run loop,
    // which is required for it to deliver its result-handler callback.
    @MainActor func loadCGImage(for asset: SMAsset, size: CGSize) async -> CGImage?
}
