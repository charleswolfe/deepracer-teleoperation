//
//  Device.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//
import SwiftUI
import SwiftData

@Model
class DeepRacer {
    var id: UUID
    var name: String
    var ipAddress: String
    var password: String
    
    init(name: String, ipAddress: String, password: String) {
        self.id = UUID()
        self.name = name
        self.ipAddress = ipAddress
        self.password = password
    }
}
