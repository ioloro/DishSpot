//
//  SingleModelManager.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import Roboflow
import SwiftUI

class SingleModelManager {
    
    let configuration: ModelConfiguration
    private let apiKey: String
    
    private var roboflow: RoboflowMobile?
    private var model: RFModel?
    private(set) var isInitialized = false
    
    init(apiKey: String, configuration: ModelConfiguration) {
        self.apiKey = apiKey
        self.configuration = configuration
        
        // Initialize Roboflow SDK
        self.roboflow = RoboflowMobile(apiKey: apiKey)
        
        // Load model asynchronously
        Task {
            await loadModel()
        }
    }
    
    /// Load the Roboflow model
    private func loadModel() async {
        guard let roboflow = roboflow else { return }
        
        let result = await roboflow.load(
            model: configuration.modelName,
            modelVersion: configuration.modelVersion
        )
        
        if let loadedModel = result.0 {
            self.model = loadedModel
            
            // Configure model with parameters
            loadedModel.configure(
                threshold: Double(configuration.detectionThreshold),
                overlap: Double(configuration.overlapThreshold),
                maxObjects: Float(configuration.maxObjects)
            )
            
            self.isInitialized = true
            print("SingleModelManager: Model '\(configuration.modelName)' v\(configuration.modelVersion) loaded successfully")
        } else if let error = result.1 {
            print("SingleModelManager: Failed to load model '\(configuration.modelName)' - \(error.localizedDescription)")
        }
    }
    
    func updateConfiguration(_ newConfig: ModelConfiguration) {
        model?.configure(
            threshold: Double(newConfig.detectionThreshold),
            overlap: Double(newConfig.overlapThreshold),
            maxObjects: Float(newConfig.maxObjects)
        )
    }
    
    func detectObjects(
        in image: UIImage,
        completion: @escaping ([RFObjectDetectionPrediction]) -> Void
    ) {
        guard isInitialized, configuration.isEnabled, let model = model else {
            completion([])
            return
        }
        
        model.detect(image: image) { predictions, error in
            if let error = error {
                print("SingleModelManager: Detection error for '\(self.configuration.modelName)' - \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let predictions = predictions as? [RFObjectDetectionPrediction] else {
                completion([])
                return
            }
            
            completion(predictions)
        }
    }
}
