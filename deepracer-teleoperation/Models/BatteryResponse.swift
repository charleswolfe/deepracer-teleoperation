//
//  BatteryResponse.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//

struct BatteryResponse: Codable {
    let batteryLevel: Int
    let success: Bool
    
    enum CodingKeys: String, CodingKey {
        case batteryLevel = "battery_level"
        case success
    }
}
