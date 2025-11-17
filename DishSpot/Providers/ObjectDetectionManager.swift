//
//  ObjectDetectionManager.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import ARKit
import Roboflow
import SwiftUI

/// Manages multiple Roboflow models and runs them concurrently
@MainActor
@Observable
class ObjectDetectionManager {
	
	// MARK: - Properties
	
	var models: [ModelConfiguration] = []
	var isDetecting = false
	
	private let apiKey: String = "YOUR_ROBOFLOW_API_KEY" // https://docs.roboflow.com/developer/authentication/find-your-roboflow-api-key
	private var modelManagers: [UUID: SingleModelManager] = [:]
	private var detectionTimer: Timer?
	
	init() {
		self.addModel(ModelConfiguration(name: "Dishes", modelName: "dishes-xuwup-zgkm3", modelVersion: 1))
	}
	
	// MARK: - Model Management
    
    func addModel(_ configuration: ModelConfiguration) {
        models.append(configuration)
        let manager = SingleModelManager(apiKey: apiKey, configuration: configuration)
        modelManagers[configuration.id] = manager
    }
    
    func removeModel(_ id: UUID) {
        models.removeAll { $0.id == id }
        modelManagers.removeValue(forKey: id)
    }
    
    func updateModel(_ configuration: ModelConfiguration) {
        if let index = models.firstIndex(where: { $0.id == configuration.id }) {
            models[index] = configuration
            modelManagers[configuration.id]?.updateConfiguration(configuration)
        }
    }
    
    func toggleModel(_ id: UUID) {
        if let index = models.firstIndex(where: { $0.id == id }) {
            models[index].isEnabled.toggle()
        }
    }
    
    var enabledModels: [ModelConfiguration] {
        models.filter { $0.isEnabled }
    }
    
    var initializedModelCount: Int {
        modelManagers.values.filter { $0.isInitialized }.count
    }
    
    // MARK: - Detection
    
    func detectObjects(
        in frame: ARFrame,
        session: ARSession,
        completion: @escaping ([DetectedObject]) -> Void
    ) {
        let enabledModels = self.enabledModels
        guard !enabledModels.isEmpty else {
            completion([])
            return
        }
        
        // Convert ARFrame to UIImage once
        guard let image = convertARFrameToUIImage(frame) else {
            print("ObjectDetectionManager: Failed to convert ARFrame to UIImage")
            completion([])
            return
        }
        
        // Run detection on all enabled models concurrently
        let group = DispatchGroup()
        var allDetections: [DetectedObject] = []
        let detectionsLock = NSLock()
        
        for modelConfig in enabledModels {
            guard let manager = modelManagers[modelConfig.id] else { continue }
            
            group.enter()
            manager.detectObjects(in: image) { [weak self] predictions in
                guard let self = self else {
                    group.leave()
                    return
                }
                
                // Convert 2D predictions to 3D world positions
                let detectedObjects = self.convert2DPredictionsTo3D(
                    predictions: predictions,
                    frame: frame,
                    session: session,
                    imageSize: image.size,
                    modelId: modelConfig.id,
                    modelName: modelConfig.name
                )
                
                detectionsLock.lock()
                allDetections.append(contentsOf: detectedObjects)
                detectionsLock.unlock()
                
                group.leave()
            }
        }
        
        // Wait for all detections to complete
        group.notify(queue: .main) {
            completion(allDetections)
        }
    }
    
    // MARK: - Helper Methods - ARFrame Conversion
    
    /// Converts ARFrame's camera image to UIImage
    private func convertARFrameToUIImage(_ frame: ARFrame) -> UIImage? {
        let pixelBuffer = frame.capturedImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        // Create UIImage with correct orientation
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        return image
    }
    
    // MARK: - Helper Methods - 3D Conversion
    
    /// Converts 2D bounding box predictions to 3D world positions
    private func convert2DPredictionsTo3D(
        predictions: [RFObjectDetectionPrediction],
        frame: ARFrame,
        session: ARSession,
        imageSize: CGSize,
        modelId: UUID,
        modelName: String
    ) -> [DetectedObject] {
        var detectedObjects: [DetectedObject] = []
        
        for prediction in predictions {
            let centerX = prediction.x
            let centerY = prediction.y
            
            // Convert to normalized coordinates (0-1 range)
            // Note: Roboflow predictions are already in pixel coordinates
            let normalizedX = CGFloat(centerX) / imageSize.width
            let normalizedY = CGFloat(centerY) / imageSize.height
            
            // Convert to view coordinates for raycasting
            // ARKit uses portrait orientation, so we need to adjust
            let viewX = 1.0 - normalizedY  // Swap and flip for landscape
            let viewY = normalizedX
            
            let screenPoint = CGPoint(x: viewX, y: viewY)
            
            // Try to get 3D position using raycast
            if let position = raycastTo3DPosition(point: screenPoint, frame: frame, session: session) {
                let detectedObject = DetectedObject(
                    className: prediction.className,
                    confidence: prediction.confidence,
                    position: position,
                    boundingBox: prediction.box,
                    modelId: modelId,
                    modelName: modelName
                )
                detectedObjects.append(detectedObject)
            } else {
                // Fallback: Estimate position based on camera transform
                if let estimatedPosition = estimatePositionFromCamera(
                    point: screenPoint,
                    frame: frame
                ) {
                    let detectedObject = DetectedObject(
                        className: prediction.className,
                        confidence: prediction.confidence,
                        position: estimatedPosition,
                        boundingBox: prediction.box,
                        modelId: modelId,
                        modelName: modelName
                    )
                    detectedObjects.append(detectedObject)
                }
            }
        }
        
        return detectedObjects
    }
    
    /// Perform raycast to get 3D position from 2D screen point
    private func raycastTo3DPosition(point: CGPoint, frame: ARFrame, session: ARSession) -> simd_float3? {
        // Create raycast query for estimated plane
        let query = ARRaycastQuery(
            origin: frame.camera.transform.columns.3.xyz,
            direction: directionFromScreenPoint(point, frame: frame),
            allowing: .estimatedPlane,
            alignment: .any
        )
        
        // Perform raycast using the session
        let results = session.raycast(query)
        
        if let firstResult = results.first {
            let position = firstResult.worldTransform.columns.3
            return simd_float3(position.x, position.y, position.z)
        }
        
        return nil
    }
    
    /// Calculate ray direction from 2D screen point
    private func directionFromScreenPoint(_ point: CGPoint, frame: ARFrame) -> simd_float3 {
        let camera = frame.camera
        let cameraTransform = camera.transform
        
        // Unproject screen point to get direction
        // This is a simplified version - for more accuracy, you'd use full camera intrinsics
        let viewportSize = camera.imageResolution
        
        // Convert normalized coordinates to NDC (Normalized Device Coordinates)
        let ndcX = (Float(point.x) * 2.0) - 1.0
        let ndcY = (Float(point.y) * 2.0) - 1.0
        
        // Get camera's forward, right, and up vectors
        let forward = -simd_float3(cameraTransform.columns.2.x,
                                    cameraTransform.columns.2.y,
                                    cameraTransform.columns.2.z)
        let right = simd_float3(cameraTransform.columns.0.x,
                                cameraTransform.columns.0.y,
                                cameraTransform.columns.0.z)
        let up = simd_float3(cameraTransform.columns.1.x,
                            cameraTransform.columns.1.y,
                            cameraTransform.columns.1.z)
        
        // Compute ray direction with field of view approximation
        let fovAdjust: Float = 0.5 // Approximate FOV adjustment
        let direction = normalize(forward + (right * ndcX * fovAdjust) + (up * ndcY * fovAdjust))
        
        return direction
    }
    
    /// Estimate 3D position from camera transform (fallback method)
    private func estimatePositionFromCamera(
        point: CGPoint,
        frame: ARFrame,
        estimatedDistance: Float = 1.5
    ) -> simd_float3? {
        let cameraTransform = frame.camera.transform
        let cameraPosition = simd_float3(cameraTransform.columns.3.x,
                                         cameraTransform.columns.3.y,
                                         cameraTransform.columns.3.z)
        
        // Get ray direction
        let direction = directionFromScreenPoint(point, frame: frame)
        
        // Estimate position at given distance
        let estimatedPosition = cameraPosition + (direction * estimatedDistance)
        
        return estimatedPosition
    }
    
    // MARK: - Continuous Detection
    
    func startContinuousDetection(arSession: ARSession, interval: TimeInterval = 2.0, completion: @escaping ([DetectedObject]) -> Void) {
        stopContinuousDetection()
        
        detectionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self, let frame = arSession.currentFrame else { return }
            Task { @MainActor in
                self.detectObjects(in: frame, session: arSession, completion: completion)
            }
        }
    }
    
    func stopContinuousDetection() {
        detectionTimer?.invalidate()
        detectionTimer = nil
    }
}
