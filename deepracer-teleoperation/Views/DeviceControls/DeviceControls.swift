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
            VideoFeedView()

            VStack {

                
                Spacer()
                
                // Bottom Controls
                HStack(alignment: .bottom) {
                    // Steering Control - Lower Left
                    SteeringControl()
                        .frame(width: 100, height: 100)

                    Spacer()
                    
                    // Throttle Control - Lower Right
                    ThrottleControl()
                        .frame(width: 60, height: 120)
                }
                .scenePadding(.horizontal)
            }
        }
        .preferredColorScheme(.dark)
        .statusBar(hidden: true)
    }
}





#Preview {
    DeviceControlsView(deepRacer: DeepRacer(name: "Test Racer", ipAddress: "192.168.1.100", password: "test123"))
}
