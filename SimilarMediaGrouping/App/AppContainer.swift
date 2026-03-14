//
//  AppContainer.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import SimilarMediaKit

final class AppContainer {
    let photoLibraryManager: PhotoLibraryManager
    let similarMediaManager: SimilarMediaManager

    init() throws {
        let photoLibraryManager = DefaultPhotoLibraryManager()
        let similarMediaManager = try DefaultSimilarMediaManager(mediaProvider: photoLibraryManager)
        self.photoLibraryManager = photoLibraryManager
        self.similarMediaManager = similarMediaManager
    }
}
