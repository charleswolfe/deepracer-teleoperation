//
//  SteeringControl.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI
import SwiftUI

struct SteeringControl: View {
    @State private var manager = DeepRacerManager.shared
    
    
    @State private var angle: Double = 0
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    private let baseSize: CGFloat = 160
    private let knobSize: CGFloat = 70
    
    var body: some View {
        ZStack {
            // 1. The Outer Track (The "Socket")
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(LinearGradient(colors: [.white.opacity(0.4), .black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // 2. Decorative D-Pad Style Markers
            Group {
                Capsule().frame(width: 4, height: 12).offset(y: -baseSize/2 + 10)
                Capsule().frame(width: 4, height: 12).offset(y: baseSize/2 - 10)
                Capsule().frame(width: 12, height: 4).offset(x: -baseSize/2 + 10)
                Capsule().frame(width: 12, height: 4).offset(x: baseSize/2 - 10)
            }
            .foregroundColor(.white.opacity(0.3))

            // 3. The Interactive Knob
            ZStack {
                // Outer glow when active
                Circle()
                    .fill(Color.blue.opacity(isDragging ? 0.3 : 0))
                    .frame(width: knobSize + 10, height: knobSize + 10)
                    .blur(radius: 8)
                
                // The Main Knob Body
                Circle()
                    .fill(
                        RadialGradient(colors: [Color(white: 0.3), Color(white: 0.1)], center: .center, startRadius: 0, endRadius: 40)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Tactile Texture (Thumb Grip)
                Circle()
                    .strokeBorder(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 4, dash: [1, 3]))
                    .frame(width: knobSize * 0.7, height: knobSize * 0.7)
            }
            .frame(width: knobSize, height: knobSize)
            .offset(dragOffset) // Moves with the thumb
            .shadow(color: .black.opacity(0.5), radius: 5, x: dragOffset.width / 5, y: dragOffset.height / 5)
        }
        .frame(width: baseSize, height: baseSize)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let translation = value.translation
                    let maxDistance = baseSize / 2 - 10
                    
                    // Calculate distance from center
                    let distance = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
                    let clampedDistance = min(distance, maxDistance)
                    let angleInRadians = atan2(translation.height, translation.width)
                    
                    // Update visual knob position
                    dragOffset = CGSize(
                        width: clampedDistance * cos(angleInRadians),
                        height: clampedDistance * sin(angleInRadians)
                    )
                    
                    // Update steering angle logic (X-axis focus)
                    angle = Double(dragOffset.width / maxDistance)

                    manager.updateSteering(angle: angle)
                }
                .onEnded { _ in
                    isDragging = false
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dragOffset = .zero
                        angle = 0
                    }
                    manager.updateSteering(angle: 0)
                }
        )
    }
}




#Preview {
    DeviceControlsView(deepRacer: DeepRacer(name: "Test Racer", ipAddress: "192.168.1.100", password: "test123"))
}
