//
//  DeviceLoading.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//

import SwiftUI

enum ConnectionState {
    case connecting
    case connected
    case failed(String)
}

struct DeviceLoadingView: View {
    let deepRacer: DeepRacer
    
    // Access the central manager
    @State private var manager = DeepRacerManager.shared
    
    @State private var connectionState: ConnectionState = .connecting
    @State private var progress: Double = 0.0
    @State private var currentStep: String = "Authenticating"
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch connectionState {
            case .connecting:
                connectingView
            case .connected:
                DeviceControlsView(deepRacer: deepRacer)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                // Reset authentication state on disconnect if desired
                                manager.isAuthenticated = false
                                connectionState = .connecting
                                
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Disconnect")
                                }
                            }
                        }
                        

                        ToolbarItem(placement: .navigationBarTrailing) {
                            BatteryIndicator()
                                .padding()
                        }
                        
                    }
            case .failed(let error):
                failedView(error: error)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            connectToDevice()
        }
    }
    
    var connectingView: some View {
        VStack(spacing: 30) {
            Image(systemName: "car.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            Text("Connecting to \(deepRacer.name)")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(deepRacer.ipAddress)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .frame(width: 200)
                .tint(.blue)
            
            VStack(spacing: 8) {
                LoadingStep(title: "Authenticating", isActive: progress > 0.0, isComplete: progress > 0.4)
                LoadingStep(title: "Establishing connection", isActive: progress > 0.4, isComplete: progress > 0.7)
                LoadingStep(title: "Starting video feed", isActive: progress > 0.7, isComplete: progress >= 1.0)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    func failedView(error: String) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)
            
            Text("Connection Failed")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                connectionState = .connecting
                connectToDevice()
            }) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    // MARK: - Logic
    
    func connectToDevice() {
        progress = 0.0
        currentStep = "Authenticating"
        
        // Setup manager with this specific device's info
        manager.ipAddress = deepRacer.ipAddress
        manager.password = deepRacer.password
        
        Task {
            // Step 1: Authenticate (0.0 - 0.4)
            await updateProgress(0.2)
            
            // We call the manager's login
            await manager.login()
            
            if manager.isAuthenticated {
                await updateProgress(0.4)
                
                // Step 2: Establish connection (0.4 - 0.7)
                currentStep = "Establishing connection"
                await updateProgress(0.5)
                
                // You can perform a ping or battery fetch here to verify connection
                await manager.fetchBatteryLevel()
                
                await updateProgress(0.7)
                
                // Step 3: Start video feed (0.7 - 1.0)
                currentStep = "Starting video feed"
                await updateProgress(0.85)
                
                // Video initialization logic would go here
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                await updateProgress(1.0)
                
                // Finish
                try? await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run {
                    withAnimation {
                        connectionState = .connected
                    }
                }
            } else {
                // If login failed, use the error from the manager
                await MainActor.run {
                    withAnimation {
                        connectionState = .failed(manager.lastError ?? "Unknown Authentication Error")
                    }
                }
            }
        }
    }
    
    func updateProgress(_ value: Double) async {
        await MainActor.run {
            withAnimation {
                progress = value
            }
        }
    }
}

//import SwiftUI
//
//enum ConnectionState {
//    case connecting
//    case connected
//    case failed(String)
//}
//
//struct DeviceLoadingView: View {
//    let deepRacer: DeepRacer
//    
//    @State private var connectionState: ConnectionState = .connecting
//    @State private var progress: Double = 0.0
//    @State private var currentStep: String = "Authenticating"
//    
//    var body: some View {
//        Group {
//            switch connectionState {
//            case .connecting:
//                connectingView
//            case .connected:
//                DeviceControlsView(deepRacer: deepRacer)
//                    .navigationBarBackButtonHidden(true)
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarLeading) {
//                            Button(action: { connectionState = .connecting }) {
//                                HStack {
//                                    Image(systemName: "chevron.left")
//                                    Text("Disconnect")
//                                }
//                            }
//                        }
//                    }
//            case .failed(let error):
//                failedView(error: error)
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .onAppear {
//            connectToDevice()
//        }
//    }
//    
//    var connectingView: some View {
//        VStack(spacing: 30) {
//            Image(systemName: "car.fill")
//                .font(.system(size: 80))
//                .foregroundColor(.blue)
//                .symbolEffect(.pulse)
//            
//            Text("Connecting to \(deepRacer.name)")
//                .font(.title2)
//                .fontWeight(.semibold)
//            
//            Text(deepRacer.ipAddress)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            ProgressView(value: progress, total: 1.0)
//                .progressViewStyle(.linear)
//                .frame(width: 200)
//                .tint(.blue)
//            
//            VStack(spacing: 8) {
//                LoadingStep(title: "Authenticating", isActive: progress > 0.0, isComplete: progress > 0.4)
//                LoadingStep(title: "Establishing connection", isActive: progress > 0.4, isComplete: progress > 0.7)
//                LoadingStep(title: "Starting video feed", isActive: progress > 0.7, isComplete: progress >= 1.0)
//            }
//            .padding(.top, 20)
//        }
//        .padding()
//    }
//    
//    func failedView(error: String) -> some View {
//        VStack(spacing: 30) {
//            Image(systemName: "exclamationmark.triangle.fill")
//                .font(.system(size: 80))
//                .foregroundColor(.red)
//            
//            Text("Connection Failed")
//                .font(.title2)
//                .fontWeight(.semibold)
//            
//            Text(error)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//            
//            Button(action: {
//                connectionState = .connecting
//                connectToDevice()
//            }) {
//                Label("Retry", systemImage: "arrow.clockwise")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 30)
//                    .padding(.vertical, 12)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//        }
//        .padding()
//    }
//    
//    func connectToDevice() {
//        progress = 0.0
//        currentStep = "Authenticating"
//        
//        Task {
//            do {
//                // Step 1: Authenticate (0.0 - 0.4)
//                await updateProgress(0.2)
//                try await login()
//                await updateProgress(0.4)
//                
//                // Step 2: Establish connection (0.4 - 0.7)
//                currentStep = "Establishing connection"
//                await updateProgress(0.5)
//                try await Task.sleep(nanoseconds: 500_000_000) // Simulate connection check
//                await updateProgress(0.7)
//                
//                // Step 3: Start video feed (0.7 - 1.0)
//                currentStep = "Starting video feed"
//                await updateProgress(0.85)
//                try await Task.sleep(nanoseconds: 500_000_000) // Simulate video initialization
//                await updateProgress(1.0)
//                
//                // Connection successful
//                try await Task.sleep(nanoseconds: 300_000_000)
//                await MainActor.run {
//                    withAnimation {
//                        connectionState = .connected
//                    }
//                }
//                
//            } catch {
//                await MainActor.run {
//                    withAnimation {
//                        connectionState = .failed(error.localizedDescription)
//                    }
//                }
//            }
//        }
//    }
//    
//    func updateProgress(_ value: Double) async {
//        await MainActor.run {
//            withAnimation {
//                progress = value
//            }
//        }
//    }
//    
//}


struct LoadingStep: View {
    let title: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if isActive {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 20, height: 20)
                }
            }
            .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(isActive || isComplete ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationView {
        DeviceLoadingView(deepRacer: DeepRacer(name: "Test Racer", ipAddress: "192.168.1.100", password: "test123"))
    }
}
