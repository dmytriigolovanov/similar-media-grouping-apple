//
//  GroupsView.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import SwiftUI

struct GroupsView: View {
    let viewModel: GroupsViewModel
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Similar Media")
                .navigationDestination(for: SimilarMediaGroup.self) { group in
                    GroupView(viewModel: GroupViewModel(group: group))
                }
                .overlay(alignment: .bottom) {
                    overlayView
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: viewModel.showsOverlay)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    // MARK: Content
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                if viewModel.showsSkeletonPlaceholder {
                    ForEach(0..<99, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(.systemFill))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                else {
                    ForEach(viewModel.groups) { group in
                        NavigationLink(value: group) {
                            GroupPreviewView(
                                group: group,
                                thumbnail: viewModel.thumbnail(for: group)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
        .scrollDisabled(viewModel.showsSkeletonPlaceholder)
    }
    
    // MARK: Overlay
    
    @ViewBuilder
    private var overlayView: some View {
        switch viewModel.state {
        case .loading:
            loadingOverlayView
        case .idle:
            idleOverlayView
        case .grouping:
            groupingOverlayView
        case .grouped:
            EmptyView()
        }
    }
    
    private func overlayContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }
    
    private var loadingOverlayView: some View {
        overlayContainer {
            VStack(spacing: 4) {
                Text("Please stand by...")
                    .font(.headline)
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var idleOverlayView: some View {
        overlayContainer {
            VStack(spacing: 4) {
                Text("You have \(viewModel.totalMediaCount) photos")
                    .font(.headline)
                Text(idleOverlayDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button(
                action: viewModel.onStart,
                label: {
                    Text(idleOverlayActionTitle)
                        .frame(maxWidth: .infinity)
                }
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
    
    private var idleOverlayDescription: String {
        if viewModel.processedMediaCount > 0 {
            return "\(viewModel.processedMediaCount) already processed. Continue?"
        }
        else {
            return "Ready to find similar ones?"
        }
    }
    
    private var idleOverlayActionTitle: String {
        if viewModel.processedMediaCount > 0 {
            return "Continue"
        }
        else {
            return "Start Grouping"
        }
    }
    
    private var groupingOverlayView: some View {
        overlayContainer {
            Text("Grouping...")
        }
    }
}

private struct GroupPreviewView: View {
    let group: SimilarMediaGroup
    let thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnailView
            countBadge
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
    
    private var countBadge: some View {
        Text("\(group.count)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(6)
    }
}
