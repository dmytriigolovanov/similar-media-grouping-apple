//
//  GroupViewModel.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import UIKit.UIImage
internal import SimilarMediaKit

@Observable
@MainActor
final class GroupViewModel {
    private let group: SMGroup
    
    var itemsIds: [String] {
        group.assetIDs
    }
    
    // MARK: Init
    
    init(group: SMGroup) {
        self.group = group
    }
    
    // MARK: Images
    
    func thumbnail(for itemId: String) -> UIImage? {
        // TODO: Add thumbnail loading
        return nil
    }
}
