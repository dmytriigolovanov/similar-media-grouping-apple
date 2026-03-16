//
//  SMError.swift
//  SimilarMediaKit
//
//  Created by Dmytrii Golovanov on 14.03.2026.
//  Copyright © 2026 Dmytrii Golovanov. All rights reserved.
//

import Foundation

public enum SMError: Error, LocalizedError {
    case embeddingExtractionFailed
    case embeddingDeserializationFailed
    case unsupportedEmbeddingElementType
    case differentVectorsLength(Int, Int)
    case imageLoadingFailed
    case storageFailure(underlying: Error)
    case processingCancelled

    public var errorDescription: String? {
        switch self {
        case .embeddingExtractionFailed:
            return "Failed to extract visual embedding from image."
        case .embeddingDeserializationFailed:
            return "Failed to deserialize stored embedding."
        case .unsupportedEmbeddingElementType:
            return "Unsupported embedding element type encountered."
        case .differentVectorsLength(let lhs, let rhs):
            return "Different vectors length: \(lhs) and \(rhs)."
        case .storageFailure(let error):
            return "Storage error: \(error.localizedDescription)"
        case .processingCancelled:
            return "Processing was cancelled."
        case .imageLoadingFailed:
            return "Image loading failed."
        }
    }
}
