//
//  BatteryIndicator.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI

struct BatteryIndicator: View {
    // Access the central manager
    @State private var manager = DeepRacerManager.shared
    
    // Compute level from manager, handling the -1 (initial/error) state
    private var displayLevel: Double {
        manager.batteryLevel == -1 ? 0 : Double(manager.batteryLevel)
    }
    
    var batteryColor: Color {
        if displayLevel > 50 { return .green }
        if displayLevel > 20 { return .orange }
        return .red
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                // Battery outline
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 40, height: 20)
                
                // Battery fill - only show when battery is connected
                if manager.batteryLevel != -1 {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(batteryColor)
                        .frame(width: max(0, (displayLevel / 100) * 35), height: 15)
                        .padding(.leading, 3)
                        .animation(.spring, value: displayLevel)
                }
                
                // Battery terminal
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3, height: 9)
                    .offset(x: 41)
                
                // Slash through battery when not connected
                if manager.batteryLevel == -1 {
                    // Diagonal slash
                    Rectangle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 2, height: 25)
                        .rotationEffect(.degrees(45))
                        .offset(x: 20, y: 0)
                    
                    // Optional: Add a subtle background to make slash more visible
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 35, height: 15)
                        .padding(.leading, 3)
                }
            }
            
            Text(manager.batteryLevel == -1 ? "--%" : "\(manager.batteryLevel)%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
        .task {
            // This loop runs as long as the view is visible
            while !Task.isCancelled {
                if manager.isAuthenticated {
                    await manager.fetchBatteryLevel()
                }
                
                // Wait 5 seconds before the next check
                // 5 * 1,000,000,000 nanoseconds = 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }
}

#Preview {
    @Previewable @State var manager = DeepRacerManager.shared
    manager.batteryLevel = 85
    return BatteryIndicator()
}
