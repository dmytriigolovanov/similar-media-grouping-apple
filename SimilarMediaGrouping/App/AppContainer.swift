//
//  AppContainer.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

final class AppContainer {
    let photoLibraryManager: PhotoLibraryManager
    let mediaLoadingService: MediaLoadingService
    let storageService: SimilarMediaStorageService
    let similarMediaManager: SimilarMediaManager

    init() throws {
        self.photoLibraryManager = DefaultPhotoLibraryManager()
        self.mediaLoadingService = DefaultMediaLoadingService()
        self.storageService = try DefaultSimilarMediaStorageService()
        self.similarMediaManager = DefaultSimilarMediaManager(
            photoLibraryManager: photoLibraryManager,
            mediaLoadingService: mediaLoadingService,
            storageService: storageService
        )
    }
}
