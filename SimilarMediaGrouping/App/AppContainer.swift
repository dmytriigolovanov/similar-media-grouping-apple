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
    let similarMediaManager: SimilarMediaManager
    
    init() {
        self.photoLibraryManager = DefaultPhotoLibraryManager()
        self.mediaLoadingService = DefaultMediaLoadingService()
        self.similarMediaManager = DefaultSimilarMediaManager(
            photoLibraryManager: photoLibraryManager,
            mediaLoadingService: mediaLoadingService
        )
    }
}
