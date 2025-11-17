//
//  RoomCaptureView.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import SwiftUI
import RoomPlan

// Move Coordinator outside the struct to avoid nested class archiving issues
class RoomCaptureCoordinator: NSObject, RoomCaptureViewDelegate, NSCoding {
    var capturedRoom: Binding<CapturedRoom?>
    var onDismiss: (() -> Void)?
    
    init(capturedRoom: Binding<CapturedRoom?>) {
        self.capturedRoom = capturedRoom
        super.init()
    }
    
    // NSCoding implementation - this coordinator should never be archived
    func encode(with coder: NSCoder) {
        fatalError("RoomCaptureCoordinator does not support encoding")
    }
    
    required init?(coder: NSCoder) {
        fatalError("RoomCaptureCoordinator does not support decoding")
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        return true
    }
    
    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        capturedRoom.wrappedValue = processedResult
        // Dismiss after we have the captured room
        onDismiss?()
    }
}

struct RoomScannerView: View {
    @Binding var capturedRoom: CapturedRoom?
    @Environment(\.dismiss) private var dismiss
    @State private var captureView: RoomPlan.RoomCaptureView?
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            RoomCaptureViewWrapper(capturedRoom: $capturedRoom, captureView: $captureView, onDismiss: {
                dismiss()
            })
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button {
                    // Stop the capture session to trigger processing
                    isProcessing = true
                    captureView?.captureSession.stop()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isProcessing ? "Processing..." : "Done")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(isProcessing ? Color.gray : Color.blue, in: Capsule())
                }
                .disabled(isProcessing)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Wrapper to capture the UIView reference
struct RoomCaptureViewWrapper: UIViewRepresentable {
    @Binding var capturedRoom: CapturedRoom?
    @Binding var captureView: RoomPlan.RoomCaptureView?
    var onDismiss: () -> Void
    
    func makeCoordinator() -> RoomCaptureCoordinator {
        let coordinator = RoomCaptureCoordinator(capturedRoom: $capturedRoom)
        coordinator.onDismiss = onDismiss
        return coordinator
    }
    
    func makeUIView(context: Context) -> RoomPlan.RoomCaptureView {
        let view = RoomPlan.RoomCaptureView(frame: .zero)
        view.delegate = context.coordinator
        view.captureSession.run(configuration: RoomCaptureSession.Configuration())
        
        // Store reference to the capture view
        DispatchQueue.main.async {
            self.captureView = view
        }
        
        return view
    }
    
    func updateUIView(_ uiView: RoomPlan.RoomCaptureView, context: Context) {
        // No updates needed
    }
    
    static func dismantleUIView(_ uiView: RoomPlan.RoomCaptureView, coordinator: RoomCaptureCoordinator) {
        uiView.captureSession.stop()
    }
}
