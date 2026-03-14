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
    case storageFailure(underlying: Error)
    case processingCancelled

    public var errorDescription: String? {
        switch self {
        case .embeddingExtractionFailed:
            return "Failed to extract visual embedding from image."
        case .embeddingDeserializationFailed:
            return "Failed to deserialize stored embedding."
        case .storageFailure(let error):
            return "Storage error: \(error.localizedDescription)"
        case .processingCancelled:
            return "Processing was cancelled."
        }
    }
}
