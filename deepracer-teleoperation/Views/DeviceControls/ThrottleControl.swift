//
//  ThrottleControl.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI


import SwiftUI

struct ThrottleControl: View {
    @State private var manager = DeepRacerManager.shared
    
    @State private var throttle: Double = 0
    @State private var isDragging = false
    @State private var showPulse = false
    @State private var engineRumble: Double = 0
    
    private let trackHeight: CGFloat = 280
    private let handleHeight: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Background glow effect
            RoundedRectangle(cornerRadius: 30)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.blue.opacity(0.1),
                            Color.purple.opacity(0.05),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 100, height: trackHeight + 40)
                .blur(radius: 10)
            
            // Main track container
            ZStack {
                // Track background with metallic finish
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                Color.gray.opacity(0.1),
                                Color.gray.opacity(0.3)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.gray.opacity(0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                
                // Track groove lines
                ForEach(0..<9) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 60, height: 1)
                        .offset(y: CGFloat(i * 35 - 140))
                }
                

                // Center neutral zone
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 70, height: 6)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                
                // Notches for throttle levels
                ForEach(0..<5) { i in
                    let position = CGFloat(i) * 60 - 120
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 40, height: 1)
                        Text("\(i * 25)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .offset(y: position)
                }
                
                // Throttle handle
                ThrottleHandle(
                    throttle: throttle,
                    isDragging: isDragging,
                    engineRumble: engineRumble
                )
                .offset(y: -throttle * (trackHeight - handleHeight) / 2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.7)) {
                                let normalizedY = -value.location.y
                                throttle = max(-1.0, min(1.0, normalizedY / (trackHeight / 2)))
                            }
                            
                            // Engine rumble effect
                            if throttle != 0 {
                                withAnimation(.easeInOut(duration: 0.1).repeatForever()) {
                                    engineRumble = throttle > 0 ? 2 : -2
                                }
                            }
                            manager.updateThrottle(throttle: throttle)
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                engineRumble = 0
                                throttle = 0
                            }
                            manager.updateThrottle(throttle: 0)
                        }
                )
                
                // Value display
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(String(format: "%03.0f%%", abs(throttle) * 100))
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(throttle >= 0 ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                            )
                        Spacer()
                    }
                    .padding(.bottom, 8)
                }
                .frame(height: trackHeight)
                
                // Direction indicators with animation
                VStack {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(throttle > 0.1 ? .green : .white.opacity(0.3))
                        .scaleEffect(throttle > 0.1 ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: throttle > 0.1)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(throttle < -0.1 ? .red : .white.opacity(0.3))
                        .scaleEffect(throttle < -0.1 ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: throttle < -0.1)
                }
                .padding(.vertical, 20)
            }
            .frame(width: 80, height: trackHeight)
            
            // LED indicator lights
            VStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(throttle > CGFloat(i + 1) * 0.33 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .padding(.vertical, 2)
                }
                
                Spacer()
                    .frame(height: trackHeight / 2 - 20)
                
                ForEach(0..<3) { i in
                    Circle()
                        .fill(throttle < -CGFloat(i + 1) * 0.33 ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 4)
                        .padding(.vertical, 2)
                }
            }
            .offset(x: 45)
        }
        .onChange(of: throttle) { _, newValue in
            if newValue != 0 {
                showPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showPulse = false
                }
            }
        }
    }
}

struct ThrottleHandle: View {
    let throttle: Double
    let isDragging: Bool
    let engineRumble: Double
    
    var body: some View {
        ZStack {
            // Handle shadow
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .blur(radius: 4)
                .offset(y: 3)
            
            // Main handle with gradient
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white,
                            Color.gray.opacity(0.9),
                            Color.gray.opacity(0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.8),
                                    Color.gray.opacity(0.4)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .overlay(
                    // Grip pattern
                    HStack(spacing: 3) {
                        ForEach(0..<5) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.2))
                                .frame(width: 2, height: 40)
                        }
                    }
                )
                .rotationEffect(.degrees(engineRumble))
                .scaleEffect(isDragging ? 1.05 : 1.0)
            
            // Throttle indicator on handle
            Circle()
                .fill(throttle >= 0 ?
                    LinearGradient(gradient: Gradient(colors: [.green, .green.opacity(0.7)]), startPoint: .top, endPoint: .bottom) :
                    LinearGradient(gradient: Gradient(colors: [.red, .red.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                )
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                .offset(y: throttle >= 0 ? -20 : 20)
                .shadow(color: throttle >= 0 ? .green.opacity(0.8) : .red.opacity(0.8), radius: 2)
        }
    }
}



#Preview {
    DeviceControlsView(deepRacer: DeepRacer(name: "Test Racer", ipAddress: "192.168.1.100", password: "test123"))
}
