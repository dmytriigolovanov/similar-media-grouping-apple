//
//  GroupViewModel.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
import UIKit.UIImage

@Observable
final class GroupViewModel {
    private let group: SimilarMediaGroup
    
    var itemsIds: [String] {
        group.assetIdentifiers
    }
    
    // MARK: Init
    
    init(group: SimilarMediaGroup) {
        self.group = group
    }
    
    // MARK: Images
    
    func thumbnail(for itemId: String) -> UIImage? {
        // TODO: Add thumbnail loading
        return nil
    }
}
