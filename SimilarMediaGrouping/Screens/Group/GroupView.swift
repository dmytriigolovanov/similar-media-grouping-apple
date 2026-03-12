//
//  GroupView.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import SwiftUI

struct GroupView: View {
    let viewModel: GroupViewModel
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Group")
        }

    }
        
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.itemsIds, id: \.self) { id in
                    GroupItemView(thumbnail: viewModel.thumbnail(for: id))
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
    }
}

private struct GroupItemView: View {
    let thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnailView
        }
        .aspectRatio(1, contentMode: .fit)
        .clipped()
    }
    
    @ViewBuilder
    private var thumbnailView: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFit()
        }
        else {
            Rectangle()
                .fill(Color(.systemFill))
        }
    }
}
