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
    
    @State private var connectionState: ConnectionState = .connecting
    @State private var progress: Double = 0.0
    
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
                            Button(action: { connectionState = .connecting }) {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Disconnect")
                                }
                            }
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
                LoadingStep(title: "Authenticating", isActive: progress > 0.2, isComplete: progress > 0.4)
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
    
    func connectToDevice() {
        progress = 0.0
        
        // Simulate connection process
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            progress += 0.2
            
            if progress >= 1.0 {
                timer.invalidate()
                // Simulate random connection success/failure for demo
                if Bool.random() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            connectionState = .connected
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            connectionState = .failed("Unable to reach device at \(deepRacer.ipAddress). Please check the IP address and try again.")
                        }
                    }
                }
            }
        }
    }
}

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
