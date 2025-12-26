//
//  DeviceControls.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//

import SwiftUI

struct DeviceControlsView: View {
    let deepRacer: DeepRacer
    
    @State private var steeringAngle: Double = 0 // -1.0 (left) to 1.0 (right)
    @State private var throttle: Double = 0 // -1.0 (reverse) to 1.0 (forward)
    @State private var batteryLevel: Double = 85.0 // Percentage
    
    var body: some View {
        ZStack {
            // Video Layer
            VideoFeedView(ipAddress: deepRacer.ipAddress)
                .ignoresSafeArea()
            
            // Controls Overlay
            VStack {
                // Top Bar - Battery
                HStack {
                    Spacer()
                    BatteryIndicator(level: batteryLevel)
                        .padding()
                }
                
                Spacer()
                
                // Bottom Controls
                HStack(alignment: .bottom) {
                    // Steering Control - Lower Left
                    SteeringControl(angle: $steeringAngle)
                        .frame(width: 200, height: 200)
                        .padding(.leading, 40)
                        .padding(.bottom, 40)
                    
                    Spacer()
                    
                    // Throttle Control - Lower Right
                    ThrottleControl(throttle: $throttle)
                        .frame(width: 120, height: 280)
                        .padding(.trailing, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
    }
}

// MARK: - Video Feed View
struct VideoFeedView: View {
    let ipAddress: String
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.black, .gray.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                VStack {
                    Image(systemName: "video.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Video Feed: \(ipAddress)")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.caption)
                }
            }
    }
}

// MARK: - Battery Indicator
struct BatteryIndicator: View {
    let level: Double
    
    var batteryColor: Color {
        if level > 50 { return .green }
        if level > 20 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 60, height: 28)
                
                // Battery fill
                RoundedRectangle(cornerRadius: 2)
                    .fill(batteryColor)
                    .frame(width: max(0, (level / 100) * 54), height: 20)
                    .padding(.leading, 3)
                
                // Battery terminal
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: 12)
                    .offset(x: 62)
            }
            
            Text("\(Int(level))%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.6))
        .cornerRadius(12)
    }
}

// MARK: - Steering Control
struct SteeringControl: View {
    @Binding var angle: Double
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
            
            // Active arc indicator
            Circle()
                .trim(from: 0.5, to: 0.5 + abs(angle) * 0.25)
                .stroke(
                    angle < 0 ? Color.blue : Color.orange,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(angle < 0 ? -90 : 90))
            
            // Inner control circle
            Circle()
                .fill(Color.white.opacity(isDragging ? 0.3 : 0.2))
                .frame(width: 140, height: 140)
            
            // Steering indicator
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 60)
                .offset(y: -40)
                .rotationEffect(.degrees(angle * 45))
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let center = CGPoint(x: 100, y: 100)
                    let vector = CGPoint(x: value.location.x - center.x, y: value.location.y - center.y)
                    let radians = atan2(vector.y, vector.x)
                    var degrees = radians * 180 / .pi + 90
                    
                    if degrees > 180 { degrees -= 360 }
                    angle = max(-1.0, min(1.0, degrees / 45))
                }
                .onEnded { _ in
                    isDragging = false
                    withAnimation(.spring(response: 0.3)) {
                        angle = 0
                    }
                }
        )
    }
}

// MARK: - Throttle Control
struct ThrottleControl: View {
    @Binding var throttle: Double
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Track
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.2))
            
            // Forward section indicator
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.green.opacity(0.3))
                .frame(height: 140)
                .offset(y: -70)
            
            // Reverse section indicator
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.red.opacity(0.3))
                .frame(height: 140)
                .offset(y: 70)
            
            // Center line
            Rectangle()
                .fill(Color.white.opacity(0.5))
                .frame(height: 2)
            
            // Throttle handle
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 40, height: 4)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 40, height: 4)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 40, height: 4)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isDragging ? 0.9 : 0.7))
            )
            .offset(y: -throttle * 120)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let normalizedY = -value.location.y + 140
                        throttle = max(-1.0, min(1.0, normalizedY / 120))
                    }
                    .onEnded { _ in
                        isDragging = false
                        withAnimation(.spring(response: 0.3)) {
                            throttle = 0
                        }
                    }
            )
            
            // Labels
            VStack {
                Text("FWD")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 8)
                Spacer()
                Text("REV")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    DeviceControlsView(deepRacer: DeepRacer(name: "Test Racer", ipAddress: "192.168.1.100", password: "test123"))
        .previewInterfaceOrientation(.landscapeLeft)
}
