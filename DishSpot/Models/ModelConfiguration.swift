//
//  ModelConfiguration.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import SwiftUI

struct ModelConfiguration: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var modelName: String
    var modelVersion: Int
    var isEnabled: Bool
    var detectionThreshold: Float
    var overlapThreshold: Float
    var maxObjects: Int
    var color: String // Hex color for visualization
    
    init(
        id: UUID = UUID(),
        name: String,
        modelName: String,
        modelVersion: Int,
        isEnabled: Bool = true,
        detectionThreshold: Float = 0.5,
        overlapThreshold: Float = 0.5,
        maxObjects: Int = 20,
        color: String = "#007AFF"
    ) {
        self.id = id
        self.name = name
        self.modelName = modelName
        self.modelVersion = modelVersion
        self.isEnabled = isEnabled
        self.detectionThreshold = detectionThreshold
        self.overlapThreshold = overlapThreshold
        self.maxObjects = maxObjects
        self.color = color
    }
}
