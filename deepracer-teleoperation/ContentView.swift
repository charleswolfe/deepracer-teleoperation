//
//  ContentView.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//

import SwiftUI
import SwiftData


struct ContentView: View {
    var body: some View {
        DeepRacerListView()
        .modelContainer(for: DeepRacer.self)
    }
}

#Preview {
    ContentView()
}
