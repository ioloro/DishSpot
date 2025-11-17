//
//  ContentView.swift
//  DishSpot
//
//  Created by John Marc on 11/16/25.
//

import SwiftUI
import RoomPlan

struct ContentView: View {
    @State private var showingScanner = false
    @State private var capturedRoom: CapturedRoom?
    @State private var isRoomPlanSupported = RoomCaptureSession.isSupported
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let room = capturedRoom {
                    // Show the captured room mesh
                    RoomMeshView(capturedRoom: room)
                    
                    Button {
                        capturedRoom = nil
                    } label: {
                        Label("Scan Again", systemImage: "camera.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(.blue, in: Capsule())
                    }
                    .padding(.bottom)
                } else {
                    // Initial state
                    Spacer()
                    
                    Image(systemName: "viewfinder.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(.blue)
                    
                    Text("DishSpot")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Scan your room to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isRoomPlanSupported {
                        Button {
                            showingScanner = true
                        } label: {
                            Text("Start")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            
                            Text("Room Scanning Not Supported")
                                .font(.headline)
                            
                            Text("This device doesn't support RoomPlan. You need a device with a LiDAR scanner (iPhone 12 Pro or later, iPad Pro 2020 or later).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("DishSpot")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showingScanner) {
                RoomScannerView(capturedRoom: $capturedRoom)
            }
        }
    }
}

#Preview {
    ContentView()
}
