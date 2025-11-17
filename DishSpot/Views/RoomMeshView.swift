//
//  RoomMeshView.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import SwiftUI
import RoomPlan
import SceneKit
import ARKit
import RealityKit

struct RoomMeshView: View {
    let capturedRoom: CapturedRoom
    @State private var showingARView = false
    
    var body: some View {
        VStack {
            Text("Room Scan Complete")
                .font(.title)
                .padding()
            
            SceneView(
                scene: createScene(from: capturedRoom),
                options: [.allowsCameraControl, .autoenablesDefaultLighting]
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Room Details")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Walls: \(capturedRoom.walls.count)")
                        Text("Floors: \(capturedRoom.floors.count)")
                        Text("Doors: \(capturedRoom.doors.count)")
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Windows: \(capturedRoom.windows.count)")
                        Text("Openings: \(capturedRoom.openings.count)")
                        Text("Objects: \(capturedRoom.objects.count)")
                    }
                }
                .font(.subheadline)
                
                Button {
                    showingARView = true
                } label: {
                    Label("View in AR", systemImage: "arkit")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showingARView) {
            RoomRelocalizationView(capturedRoom: capturedRoom)
        }
    }
    
    private func createScene(from room: CapturedRoom) -> SCNScene {
        let scene = SCNScene()
        
        // Add walls
        for wall in room.walls {
            let geometry = createGeometry(from: wall.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGray.withAlphaComponent(0.5)
            geometry.firstMaterial?.isDoubleSided = true
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(wall.transform)
            scene.rootNode.addChildNode(node)
        }
        
        // Add floors
        for surface in room.floors {
            let geometry = createGeometry(from: surface.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemBrown.withAlphaComponent(0.3)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(surface.transform)
            scene.rootNode.addChildNode(node)
        }
        
        // Add doors
        for door in room.doors {
            let geometry = createGeometry(from: door.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.6)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(door.transform)
            scene.rootNode.addChildNode(node)
        }
        
        // Add windows
        for window in room.windows {
            let geometry = createGeometry(from: window.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemCyan.withAlphaComponent(0.4)
            geometry.firstMaterial?.transparency = 0.4
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(window.transform)
            scene.rootNode.addChildNode(node)
        }
        
        // Add openings
        for opening in room.openings {
            let geometry = createGeometry(from: opening.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemYellow.withAlphaComponent(0.4)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(opening.transform)
            scene.rootNode.addChildNode(node)
        }
        
        // Add objects (furniture, fixtures, etc.)
        for object in room.objects {
            let geometry = createGeometry(from: object.dimensions)
            
            // Color objects based on their category
            let color: UIColor = {
                switch object.category {
                case .storage:
                    return .systemIndigo
                case .refrigerator:
                    return .systemTeal
                case .stove:
                    return .systemOrange
                case .bed:
                    return .systemPurple
                case .sink:
                    return .systemBlue
                case .washerDryer:
                    return .systemMint
                case .toilet:
                    return .systemPink
                case .bathtub:
                    return .systemCyan
                case .oven:
                    return .systemRed
                case .dishwasher:
                    return .systemTeal
                case .table:
                    return .systemBrown
                case .sofa:
                    return .systemIndigo
                case .chair:
                    return .systemPurple
                case .fireplace:
                    return .systemOrange
                case .television:
                    return .darkGray
                case .stairs:
                    return .systemGray
                @unknown default:
                    return .systemBlue
                }
            }()
            
            geometry.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.6)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(object.transform)
            scene.rootNode.addChildNode(node)
        }
        
        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 2, z: 5)
        scene.rootNode.addChildNode(cameraNode)
        
        return scene
    }
    
    private func createGeometry(from dimensions: simd_float3) -> SCNGeometry {
        return SCNBox(
            width: CGFloat(dimensions.x),
            height: CGFloat(dimensions.y),
            length: CGFloat(dimensions.z),
            chamferRadius: 0
        )
    }
}

struct SceneView: UIViewRepresentable {
    let scene: SCNScene
    let options: SCNView.Options
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = options.contains(.allowsCameraControl)
        scnView.autoenablesDefaultLighting = options.contains(.autoenablesDefaultLighting)
        scnView.backgroundColor = .black
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // No updates needed
    }
}

extension SCNView {
    struct Options: OptionSet {
        let rawValue: Int
        
        static let allowsCameraControl = Options(rawValue: 1 << 0)
        static let autoenablesDefaultLighting = Options(rawValue: 1 << 1)
    }
}

// MARK: - AR Anchor Model

struct ARAnchorPoint: Identifiable {
    let id = UUID()
    let position: simd_float3
    let timestamp: Date
    var label: String
    var isAutoDetected: Bool = false
    var confidence: Float = 1.0
    var modelName: String? = nil
    var modelId: UUID? = nil
    
    init(
        position: simd_float3,
        label: String = "",
        isAutoDetected: Bool = false,
        confidence: Float = 1.0,
        modelName: String? = nil,
        modelId: UUID? = nil
    ) {
        self.position = position
        self.timestamp = Date()
        self.label = label
        self.isAutoDetected = isAutoDetected
        self.confidence = confidence
        self.modelName = modelName
        self.modelId = modelId
    }
}

// MARK: - AR Relocalization View

struct RoomRelocalizationView: View {
    let capturedRoom: CapturedRoom
    @Environment(\.dismiss) private var dismiss
    @State private var isRelocalized = false
    @State private var relocalizationConfidence: Float = 0.0
    @State private var anchors: [ARAnchorPoint] = []
    @State private var isPlacementMode = false
    @State private var showingAnchorsList = false
    @State private var editingAnchor: ARAnchorPoint?
    @State private var anchorLabel = ""
    @State private var isObjectDetectionEnabled = false // Start disabled until manager is initialized
    @State private var detectionManager: ObjectDetectionManager?
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            ARRelocalizationViewRepresentable(
                capturedRoom: capturedRoom,
                isRelocalized: $isRelocalized,
                confidence: $relocalizationConfidence,
                anchors: $anchors,
                isPlacementMode: $isPlacementMode,
                detectionManager: $detectionManager,
                isObjectDetectionEnabled: $isObjectDetectionEnabled
            )
            .ignoresSafeArea()
            
            VStack {
                // Status indicator at the top
                HStack {
                    Circle()
                        .fill(isRelocalized ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                    
                    Text(isRelocalized ? "Relocalized" : "Searching for room...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Object detection indicator
                    if isObjectDetectionEnabled {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            Text("AI Detection")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Anchor count
                    if !anchors.isEmpty {
                        Button {
                            showingAnchorsList.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                Text("\(anchors.count)")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.horizontal)
                .padding(.top, 60)
                
                Spacer()
                
                // Instructions
                if !isRelocalized {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                        
                        Text("Move your device around")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("Point at walls and features from your scan")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 100)
                } else if isPlacementMode {
                    // Placement mode instructions
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                        
                        Text("Tap to place anchor")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("Tap on any surface in the room")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
                
                // Control buttons
                HStack(spacing: 16) {
                    if isRelocalized {
                        // Settings button
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(Color.gray.opacity(0.8), in: Circle())
                        }
                        
                        // Toggle placement mode
                        Button {
                            isPlacementMode.toggle()
                        } label: {
                            Image(systemName: isPlacementMode ? "xmark.circle.fill" : "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(isPlacementMode ? Color.red : Color.blue, in: Circle())
                        }
                        
                        // Clear all anchors
                        if !anchors.isEmpty {
                            Button {
                                anchors.removeAll()
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(12)
                                    .background(Color.red.opacity(0.8), in: Circle())
                            }
                        }
                    }
                    
                    // Close button
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingAnchorsList) {
            AnchorListView(anchors: $anchors)
        }
        .sheet(isPresented: $showingSettings) {
            DetectionSettingsView(
                isObjectDetectionEnabled: $isObjectDetectionEnabled,
                detectionManager: $detectionManager
            )
        }
        .alert("Label Anchor", isPresented: .init(
            get: { editingAnchor != nil },
            set: { if !$0 { editingAnchor = nil; anchorLabel = "" } }
        )) {
            TextField("Enter label", text: $anchorLabel)
            Button("Cancel", role: .cancel) {
                editingAnchor = nil
                anchorLabel = ""
            }
            Button("Save") {
                if let index = anchors.firstIndex(where: { $0.id == editingAnchor?.id }) {
                    anchors[index].label = anchorLabel
                }
                editingAnchor = nil
                anchorLabel = ""
            }
        } message: {
            Text("Give this anchor a descriptive label")
        }
    }
}

// MARK: - Detection Settings View

struct DetectionSettingsView: View {
    @Binding var isObjectDetectionEnabled: Bool
    @Binding var detectionManager: ObjectDetectionManager?
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey = "YOUR_ROBOFLOW_API_KEY" // https://docs.roboflow.com/developer/authentication/find-your-roboflow-api-key
    @State private var detectionInterval: Double = 2.0
    @State private var showingAddModel = false
    @State private var editingModel: ModelConfiguration?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Enable AI Object Detection", isOn: $isObjectDetectionEnabled)
                        .onChange(of: isObjectDetectionEnabled) { oldValue, newValue in
                            if !newValue {
                                detectionManager?.stopContinuousDetection()
                            }
                        }
                } header: {
                    Text("Detection")
                } footer: {
                    Text("Automatically detect and place anchors on objects using Roboflow AI")
                }
                
                if isObjectDetectionEnabled {
                    Section("Roboflow Configuration") {
                        SecureField("API Key", text: $apiKey)
                            .textContentType(.password)
                        
                        if detectionManager == nil {
                            Button("Initialize Detection Manager") {
                                initializeManager()
                            }
                            .disabled(apiKey.isEmpty)
                        }
                        
                        Slider(value: $detectionInterval, in: 0.5...5.0, step: 0.5) {
                            Text("Detection Interval")
                        }
                        Text("Run detection every \(String(format: "%.1f", detectionInterval)) seconds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let manager = detectionManager {
                        Section {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Manager initialized")
                            }
                            
                            HStack {
                                Text("Models loaded")
                                Spacer()
                                Text("\(manager.initializedModelCount) / \(manager.models.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Section {
                            ForEach(manager.models) { model in
                                ModelRow(model: model, manager: manager)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        editingModel = model
                                    }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    manager.removeModel(manager.models[index].id)
                                }
                            }
                            
                            Button {
                                showingAddModel = true
                            } label: {
                                Label("Add Model", systemImage: "plus.circle.fill")
                            }
                        } header: {
                            Text("Models (\(manager.models.count))")
                        }
                    }
                }
                
                Section {
                    Text("Example:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Model Name: kitchen-appliances")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Model Version: 1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Detection Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddModel) {
                if let manager = detectionManager {
                    AddModelView(manager: manager)
                }
            }
            .sheet(item: $editingModel) { model in
                if let manager = detectionManager {
                    EditModelView(model: model, manager: manager)
                }
            }
        }
    }
    
    private func initializeManager() {
        guard !apiKey.isEmpty else {
            print("DetectionSettingsView: API key is empty")
            return
        }
        
        print("DetectionSettingsView: Initializing ObjectDetectionManager with API key")
        detectionManager = ObjectDetectionManager()
        print("DetectionSettingsView: ObjectDetectionManager initialized: \(detectionManager != nil)")
    }
}

// MARK: - Model Row View

struct ModelRow: View {
    let model: ModelConfiguration
    let manager: ObjectDetectionManager
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: model.color) ?? .blue)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                
                Text("\(model.modelName) v\(model.modelVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 12) {
                    Label("\(Int(model.detectionThreshold * 100))%", systemImage: "dial.medium")
                        .font(.caption2)
                    Label("\(model.maxObjects)", systemImage: "square.grid.3x3")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { model.isEnabled },
                set: { _ in manager.toggleModel(model.id) }
            ))
            .labelsHidden()
        }
    }
}

// MARK: - Add Model View

struct AddModelView: View {
    let manager: ObjectDetectionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var modelName = ""
    @State private var modelVersion = 1
    @State private var detectionThreshold: Float = 0.5
    @State private var overlapThreshold: Float = 0.5
    @State private var maxObjects = 20
    @State private var selectedColor = Color.blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Model Info") {
                    TextField("Display Name", text: $name)
                    TextField("Model Name", text: $modelName)
                        .textInputAutocapitalization(.never)
                    Stepper("Version: \(modelVersion)", value: $modelVersion, in: 1...100)
                }
                
                Section("Detection Parameters") {
                    VStack(alignment: .leading) {
                        Text("Confidence Threshold: \(Int(detectionThreshold * 100))%")
                            .font(.subheadline)
                        Slider(value: $detectionThreshold, in: 0.1...1.0, step: 0.05)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Overlap Threshold: \(Int(overlapThreshold * 100))%")
                            .font(.subheadline)
                        Slider(value: $overlapThreshold, in: 0.1...1.0, step: 0.05)
                    }
                    
                    Stepper("Max Objects: \(maxObjects)", value: $maxObjects, in: 1...50)
                }
                
                Section("Visualization") {
                    ColorPicker("Marker Color", selection: $selectedColor)
                }
            }
            .navigationTitle("Add Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addModel()
                        dismiss()
                    }
                    .disabled(name.isEmpty || modelName.isEmpty)
                }
            }
        }
    }
    
    private func addModel() {
        let configuration = ModelConfiguration(
            name: name,
            modelName: modelName,
            modelVersion: modelVersion,
            isEnabled: true,
            detectionThreshold: detectionThreshold,
            overlapThreshold: overlapThreshold,
            maxObjects: maxObjects,
            color: selectedColor.toHex() ?? "#007AFF"
        )
        
        manager.addModel(configuration)
    }
}

// MARK: - Edit Model View

struct EditModelView: View {
    var model: ModelConfiguration
    let manager: ObjectDetectionManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var detectionThreshold: Float = 0.5
    @State private var overlapThreshold: Float = 0.5
    @State private var maxObjects = 20
    @State private var selectedColor = Color.blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Model Info") {
                    TextField("Display Name", text: $name)
                    
                    HStack {
                        Text("Model")
                        Spacer()
                        Text("\(model.modelName) v\(model.modelVersion)")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Detection Parameters") {
                    VStack(alignment: .leading) {
                        Text("Confidence Threshold: \(Int(detectionThreshold * 100))%")
                            .font(.subheadline)
                        Slider(value: $detectionThreshold, in: 0.1...1.0, step: 0.05)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Overlap Threshold: \(Int(overlapThreshold * 100))%")
                            .font(.subheadline)
                        Slider(value: $overlapThreshold, in: 0.1...1.0, step: 0.05)
                    }
                    
                    Stepper("Max Objects: \(maxObjects)", value: $maxObjects, in: 1...50)
                }
                
                Section("Visualization") {
                    ColorPicker("Marker Color", selection: $selectedColor)
                }
            }
            .navigationTitle("Edit Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadModelData()
            }
        }
    }
    
    private func loadModelData() {
        name = model.name
        detectionThreshold = model.detectionThreshold
        overlapThreshold = model.overlapThreshold
        maxObjects = model.maxObjects
        selectedColor = Color(hex: model.color) ?? .blue
    }
    
    private func saveChanges() {
        var updatedModel = model
        updatedModel.name = name
        updatedModel.detectionThreshold = detectionThreshold
        updatedModel.overlapThreshold = overlapThreshold
        updatedModel.maxObjects = maxObjects
        updatedModel.color = selectedColor.toHex() ?? "#007AFF"
        
        manager.updateModel(updatedModel)
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

// MARK: - Anchor List View

struct AnchorListView: View {
    @Binding var anchors: [ARAnchorPoint]
    @Environment(\.dismiss) private var dismiss
    @State private var editingAnchor: ARAnchorPoint?
    @State private var editLabel = ""
    
    var manualAnchors: [ARAnchorPoint] {
        anchors.filter { !$0.isAutoDetected }
    }
    
    var detectedAnchors: [ARAnchorPoint] {
        anchors.filter { $0.isAutoDetected }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !detectedAnchors.isEmpty {
                    Section("AI Detected Objects") {
                        ForEach(Array(detectedAnchors.enumerated()), id: \.element.id) { index, anchor in
                            anchorRow(for: anchor, index: anchors.firstIndex(where: { $0.id == anchor.id }) ?? index)
                        }
                        .onDelete { indexSet in
                            deleteDetectedAnchors(at: indexSet)
                        }
                    }
                }
                
                if !manualAnchors.isEmpty {
                    Section("Manual Anchors") {
                        ForEach(Array(manualAnchors.enumerated()), id: \.element.id) { index, anchor in
                            anchorRow(for: anchor, index: anchors.firstIndex(where: { $0.id == anchor.id }) ?? index)
                        }
                        .onDelete { indexSet in
                            deleteManualAnchors(at: indexSet)
                        }
                    }
                }
                
                if anchors.isEmpty {
                    ContentUnavailableView(
                        "No Anchors",
                        systemImage: "mappin.slash",
                        description: Text("Place anchors manually or enable AI detection")
                    )
                }
            }
            .navigationTitle("Anchors (\(anchors.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if !anchors.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                }
            }
            .alert("Edit Label", isPresented: .init(
                get: { editingAnchor != nil },
                set: { if !$0 { editingAnchor = nil; editLabel = "" } }
            )) {
                TextField("Enter label", text: $editLabel)
                Button("Cancel", role: .cancel) {
                    editingAnchor = nil
                    editLabel = ""
                }
                Button("Save") {
                    if let index = anchors.firstIndex(where: { $0.id == editingAnchor?.id }) {
                        anchors[index].label = editLabel
                    }
                    editingAnchor = nil
                    editLabel = ""
                }
            } message: {
                Text("Give this anchor a descriptive label")
            }
        }
    }
    
    @ViewBuilder
    private func anchorRow(for anchor: ARAnchorPoint, index: Int) -> some View {
        Button {
            editingAnchor = anchor
            editLabel = anchor.label
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(anchor.label.isEmpty ? "Anchor \(index + 1)" : anchor.label)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if anchor.isAutoDetected {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    if anchor.isAutoDetected {
                        HStack(spacing: 4) {
                            Text("Confidence:")
                            Text("\(Int(anchor.confidence * 100))%")
                                .foregroundStyle(anchor.confidence > 0.7 ? .green : .orange)
                        }
                        .font(.caption)
                        
                        if let modelName = anchor.modelName {
                            Text("Model: \(modelName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Position: (\(String(format: "%.2f", anchor.position.x)), \(String(format: "%.2f", anchor.position.y)), \(String(format: "%.2f", anchor.position.z)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(anchor.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func deleteDetectedAnchors(at indexSet: IndexSet) {
        let idsToRemove = indexSet.map { detectedAnchors[$0].id }
        anchors.removeAll { idsToRemove.contains($0.id) }
    }
    
    private func deleteManualAnchors(at indexSet: IndexSet) {
        let idsToRemove = indexSet.map { manualAnchors[$0].id }
        anchors.removeAll { idsToRemove.contains($0.id) }
    }
}

// MARK: - AR View Representable

class ARRelocalizationCoordinator: NSObject, ARSessionDelegate {
    var isRelocalized: Binding<Bool>
    var confidence: Binding<Float>
    var anchors: Binding<[ARAnchorPoint]>
    var isPlacementMode: Binding<Bool>
    var detectionManager: Binding<ObjectDetectionManager?>
    var isObjectDetectionEnabled: Binding<Bool>
    weak var arView: ARSCNView?
    weak var arSession: ARSession?
    var anchorNodes: [UUID: SCNNode] = [:]
    private var lastDetectionTime: Date?
    
    init(isRelocalized: Binding<Bool>, confidence: Binding<Float>, anchors: Binding<[ARAnchorPoint]>, isPlacementMode: Binding<Bool>, detectionManager: Binding<ObjectDetectionManager?>, isObjectDetectionEnabled: Binding<Bool>) {
        self.isRelocalized = isRelocalized
        self.confidence = confidence
        self.anchors = anchors
        self.isPlacementMode = isPlacementMode
        self.detectionManager = detectionManager
        self.isObjectDetectionEnabled = isObjectDetectionEnabled
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Check tracking quality
        switch frame.camera.trackingState {
        case .normal:
            // We're tracking normally, consider it relocalized
            DispatchQueue.main.async {
                self.isRelocalized.wrappedValue = true
                self.confidence.wrappedValue = 1.0
            }
            
            // Run object detection if enabled and manager exists
            let detectionEnabled = isObjectDetectionEnabled.wrappedValue
            let managerExists = detectionManager.wrappedValue != nil
            
            if !detectionEnabled {
                // Detection is disabled, skip
                return
            }
            
            if !managerExists {
                // Manager not initialized yet
                return
            }
            
            guard let manager = detectionManager.wrappedValue else {
                print("ARCoordinator: Manager unexpectedly nil")
                return
            }
            
            if shouldRunDetection() {
                lastDetectionTime = Date()
                
                guard let session = self.arSession else {
                    print("ARCoordinator: arSession is nil")
                    return
                }
                
                print("ARCoordinator: Running detection on \(manager.enabledModels.count) enabled models")
                manager.detectObjects(in: frame, session: session) { [weak self] detected in
                    print("ARCoordinator: Detected \(detected.count) objects")
                    self?.handleDetectedObjects(detected)
                }
            }
            
        case .limited(let reason):
            DispatchQueue.main.async {
                self.isRelocalized.wrappedValue = false
                // Adjust confidence based on reason
                switch reason {
                case .initializing:
                    self.confidence.wrappedValue = 0.3
                case .relocalizing:
                    self.confidence.wrappedValue = 0.5
                case .excessiveMotion:
                    self.confidence.wrappedValue = 0.2
                case .insufficientFeatures:
                    self.confidence.wrappedValue = 0.1
                @unknown default:
                    self.confidence.wrappedValue = 0.0
                }
            }
        case .notAvailable:
            DispatchQueue.main.async {
                self.isRelocalized.wrappedValue = false
                self.confidence.wrappedValue = 0.0
            }
        }
    }
    
    private func shouldRunDetection() -> Bool {
        guard let lastTime = lastDetectionTime else { return true }
        return Date().timeIntervalSince(lastTime) > 2.0 // Run every 2 seconds
    }
    
    private func handleDetectedObjects(_ detected: [DetectedObject]) {
        DispatchQueue.main.async {
            // Remove old auto-detected anchors
            let oldAutoDetectedIds = self.anchors.wrappedValue.filter { $0.isAutoDetected }.map { $0.id }
            self.anchors.wrappedValue.removeAll { $0.isAutoDetected }
            
            // Remove corresponding nodes
            for id in oldAutoDetectedIds {
                if let node = self.anchorNodes[id] {
                    node.removeFromParentNode()
                    self.anchorNodes.removeValue(forKey: id)
                }
            }
            
            // Add new detected objects as anchors
            for obj in detected {
                let anchor = ARAnchorPoint(
                    position: obj.position,
                    label: obj.className,
                    isAutoDetected: true,
                    confidence: obj.confidence,
                    modelName: obj.modelName,
                    modelId: obj.modelId
                )
                self.anchors.wrappedValue.append(anchor)
                
                // Add visual node with model-specific color
                let position = SCNVector3(obj.position.x, obj.position.y, obj.position.z)
                self.addAnchorNode(anchor: anchor, at: position)
            }
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isPlacementMode.wrappedValue, let arView = arView else { return }
        
        let location = gesture.location(in: arView)
        
        // Perform hit test against existing geometry and detected planes
        let hitTestResults = arView.hitTest(location, options: [
            SCNHitTestOption.searchMode: SCNHitTestSearchMode.all.rawValue
        ])
        
        if let result = hitTestResults.first {
            // Get world position from hit test
            let position = result.worldCoordinates
            let simdPosition = simd_float3(position.x, position.y, position.z)
            
            // Create anchor
            let anchor = ARAnchorPoint(position: simdPosition, isAutoDetected: false)
            
            // Add to anchors array
            DispatchQueue.main.async {
                self.anchors.wrappedValue.append(anchor)
                self.addAnchorNode(anchor: anchor, at: position)
            }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } else {
            // Try AR raycast as fallback
            let raycastQuery = arView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any)
            if let query = raycastQuery {
                let results = arView.session.raycast(query)
                if let result = results.first {
                    let position = result.worldTransform.columns.3
                    let simdPosition = simd_float3(position.x, position.y, position.z)
                    
                    let anchor = ARAnchorPoint(position: simdPosition, isAutoDetected: false)
                    
                    DispatchQueue.main.async {
                        self.anchors.wrappedValue.append(anchor)
                        self.addAnchorNode(anchor: anchor, at: SCNVector3(position.x, position.y, position.z))
                    }
                    
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                }
            }
        }
    }
    
    func addAnchorNode(anchor: ARAnchorPoint, at position: SCNVector3) {
        guard let arView = arView else { return }
        
        // Choose color based on whether it's auto-detected and model color
        let baseColor: UIColor
        let topColor: UIColor
        
        if anchor.isAutoDetected {
            // Use model-specific color if available
            if let modelId = anchor.modelId,
               let manager = detectionManager.wrappedValue,
               let modelConfig = manager.models.first(where: { $0.id == modelId }),
               let color = Color(hex: modelConfig.color) {
                baseColor = UIColor(color)
                topColor = baseColor.withAlphaComponent(0.8)
            } else {
                baseColor = .systemBlue
                topColor = .systemPurple
            }
        } else {
            baseColor = .systemYellow
            topColor = .systemRed
        }
        
        // Create anchor visualization
        let sphere = SCNSphere(radius: 0.03)
        sphere.firstMaterial?.diffuse.contents = baseColor
        sphere.firstMaterial?.emission.contents = baseColor
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        
        // Add a cone on top to make it more visible
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.02, height: 0.06)
        cone.firstMaterial?.diffuse.contents = topColor
        cone.firstMaterial?.emission.contents = topColor
        
        let coneNode = SCNNode(geometry: cone)
        coneNode.position = SCNVector3(0, 0.05, 0)
        sphereNode.addChildNode(coneNode)
        
        // Add text label if available
        if !anchor.label.isEmpty {
            let text = SCNText(string: anchor.label, extrusionDepth: 0.5)
            text.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            text.firstMaterial?.diffuse.contents = UIColor.white
            text.firstMaterial?.emission.contents = UIColor.white
            text.flatness = 0.1
            
            let textNode = SCNNode(geometry: text)
            textNode.scale = SCNVector3(0.002, 0.002, 0.002)
            textNode.position = SCNVector3(0, 0.1, 0)
            
            // Billboard constraint to always face camera
            let billboardConstraint = SCNBillboardConstraint()
            billboardConstraint.freeAxes = .Y
            textNode.constraints = [billboardConstraint]
            
            sphereNode.addChildNode(textNode)
        }
        
        // Add to scene
        arView.scene.rootNode.addChildNode(sphereNode)
        anchorNodes[anchor.id] = sphereNode
        
        // Add animation
        let pulseAction = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 0.3),
            SCNAction.scale(to: 1.0, duration: 0.3)
        ])
        sphereNode.runAction(pulseAction)
    }
    
    func removeAnchorNode(id: UUID) {
        if let node = anchorNodes[id] {
            node.removeFromParentNode()
            anchorNodes.removeValue(forKey: id)
        }
    }
    
    func clearAllAnchors() {
        for node in anchorNodes.values {
            node.removeFromParentNode()
        }
        anchorNodes.removeAll()
    }
}

struct ARRelocalizationViewRepresentable: UIViewRepresentable {
    let capturedRoom: CapturedRoom
    @Binding var isRelocalized: Bool
    @Binding var confidence: Float
    @Binding var anchors: [ARAnchorPoint]
    @Binding var isPlacementMode: Bool
    @Binding var detectionManager: ObjectDetectionManager?
    @Binding var isObjectDetectionEnabled: Bool
    
    func makeCoordinator() -> ARRelocalizationCoordinator {
        ARRelocalizationCoordinator(
            isRelocalized: $isRelocalized,
            confidence: $confidence,
            anchors: $anchors,
            isPlacementMode: $isPlacementMode,
            detectionManager: $detectionManager,
            isObjectDetectionEnabled: $isObjectDetectionEnabled
        )
    }
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        
        // Configure AR session
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arView.session.delegate = context.coordinator
        arView.session.run(configuration)
        
        // Store references in coordinator
        context.coordinator.arView = arView
        context.coordinator.arSession = arView.session
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Add the captured room to the scene
        addCapturedRoomToScene(arView: arView, capturedRoom: capturedRoom)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // Update anchor nodes when anchors array changes
        let currentAnchorIDs = Set(anchors.map { $0.id })
        let nodeAnchorIDs = Set(context.coordinator.anchorNodes.keys)
        
        // Remove nodes for deleted anchors
        let removedIDs = nodeAnchorIDs.subtracting(currentAnchorIDs)
        for id in removedIDs {
            context.coordinator.removeAnchorNode(id: id)
        }
        
        // Update labels for existing anchors
        for anchor in anchors {
            if let node = context.coordinator.anchorNodes[anchor.id] {
                // Update node appearance based on label if needed
                // This could be expanded to show text labels
            }
        }
    }
    
    static func dismantleUIView(_ uiView: ARSCNView, coordinator: ARRelocalizationCoordinator) {
        uiView.session.pause()
        coordinator.clearAllAnchors()
    }
    
    private func addCapturedRoomToScene(arView: ARSCNView, capturedRoom: CapturedRoom) {
        let rootNode = SCNNode()
        
        // Add walls
        for wall in capturedRoom.walls {
            let geometry = createGeometry(from: wall.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.3)
            geometry.firstMaterial?.isDoubleSided = true
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(wall.transform)
            rootNode.addChildNode(node)
        }
        
        // Add floors
        for surface in capturedRoom.floors {
            let geometry = createGeometry(from: surface.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.2)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(surface.transform)
            rootNode.addChildNode(node)
        }
        
        // Add doors
        for door in capturedRoom.doors {
            let geometry = createGeometry(from: door.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.5)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(door.transform)
            rootNode.addChildNode(node)
        }
        
        // Add windows
        for window in capturedRoom.windows {
            let geometry = createGeometry(from: window.dimensions)
            geometry.firstMaterial?.diffuse.contents = UIColor.systemCyan.withAlphaComponent(0.3)
            geometry.firstMaterial?.transparency = 0.5
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(window.transform)
            rootNode.addChildNode(node)
        }
        
        // Add objects (furniture, fixtures, etc.)
        for object in capturedRoom.objects {
            let geometry = createGeometry(from: object.dimensions)
            
            // Color objects based on their category
            let color: UIColor = {
                switch object.category {
                case .storage:
                    return .systemIndigo
                case .refrigerator:
                    return .systemTeal
                case .stove:
                    return .systemOrange
                case .bed:
                    return .systemPurple
                case .sink:
                    return .systemBlue
                case .washerDryer:
                    return .systemMint
                case .toilet:
                    return .systemPink
                case .bathtub:
                    return .systemCyan
                case .oven:
                    return .systemRed
                case .dishwasher:
                    return .systemTeal
                case .table:
                    return .systemBrown
                case .sofa:
                    return .systemIndigo
                case .chair:
                    return .systemPurple
                case .fireplace:
                    return .systemOrange
                case .television:
                    return .darkGray
                case .stairs:
                    return .systemGray
                @unknown default:
                    return .systemBlue
                }
            }()
            
            geometry.firstMaterial?.diffuse.contents = color.withAlphaComponent(0.5)
            
            let node = SCNNode(geometry: geometry)
            node.transform = SCNMatrix4(object.transform)
            rootNode.addChildNode(node)
        }
        
        arView.scene.rootNode.addChildNode(rootNode)
    }
    
    private func createGeometry(from dimensions: simd_float3) -> SCNGeometry {
        return SCNBox(
            width: CGFloat(dimensions.x),
            height: CGFloat(dimensions.y),
            length: CGFloat(dimensions.z),
            chamferRadius: 0
        )
    }
}
