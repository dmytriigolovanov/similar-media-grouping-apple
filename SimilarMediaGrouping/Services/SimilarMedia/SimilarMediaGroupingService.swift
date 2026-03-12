//
//  SimilarMediaGroupingService.swift
//  SimilarMediaGrouping
//
//  Created by Dmytrii Golovanov on 12.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation
internal import Vision

protocol SimilarMediaGroupingService {
    func buildGroups(
        from images: [(identifier: String, image: CGImage)],
        threshold: Float
    ) async throws -> [SimilarMediaGroup]
}

final class DefaultSimilarMediaGroupingService: SimilarMediaGroupingService {
    
    func buildGroups(
        from images: [(identifier: String, image: CGImage)],
        threshold: Float
    ) async throws -> [SimilarMediaGroup] {
        var prints: [(identifier: String, print: VNFeaturePrintObservation)] = []

        for item in images {
            guard let featurePrint = try await extractFeaturePrint(from: item.image) else { continue }
            prints.append((item.identifier, featurePrint))
        }

        return cluster(
            prints: prints,
            threshold: threshold
        )
    }

    // MARK: Feature Print

    private func extractFeaturePrint(from cgImage: CGImage) async throws -> VNFeaturePrintObservation? {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateImageFeaturePrintRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let result = request.results?.first as? VNFeaturePrintObservation
                continuation.resume(returning: result)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: Union-Find Clustering

    private func cluster(
        prints: [(identifier: String, print: VNFeaturePrintObservation)],
        threshold: Float
    ) -> [SimilarMediaGroup] {
        let count = prints.count
        var parent = Array(0..<count)

        func find(_ i: Int) -> Int {
            var i = i
            while parent[i] != i { i = parent[i] }
            return i
        }

        func union(_ a: Int, _ b: Int) {
            parent[find(a)] = find(b)
        }

        for i in 0..<count {
            for j in (i + 1)..<count {
                var distance: Float = 0
                try? prints[i].print.computeDistance(&distance, to: prints[j].print)
                if distance < threshold {
                    union(i, j)
                }
            }
        }

        var groups: [Int: [String]] = [:]
        for i in 0..<count {
            let root = find(i)
            groups[root, default: []].append(prints[i].identifier)
        }

        return groups.values
            .filter { $0.count > 1 }
            .map { SimilarMediaGroup(assetIdentifiers: $0) }
    }
}
