//
//  DetectedObject.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import Foundation
import simd

struct DetectedObject: Identifiable {
    let id: UUID
    let className: String
    let confidence: Float
    let position: simd_float3
    let boundingBox: CGRect
    let timestamp: Date
    let modelId: UUID // Which model detected this
    let modelName: String
    
    init(
        id: UUID = UUID(),
        className: String,
        confidence: Float,
        position: simd_float3,
        boundingBox: CGRect,
        timestamp: Date = Date(),
        modelId: UUID,
        modelName: String
    ) {
        self.id = id
        self.className = className
        self.confidence = confidence
        self.position = position
        self.boundingBox = boundingBox
        self.timestamp = timestamp
        self.modelId = modelId
        self.modelName = modelName
    }
}
