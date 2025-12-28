//
//  DeviceList.swift
//  deepracer-teleoperation
//
//  Created by Charles Wolfe on 12/26/25.
//

import SwiftUI
import SwiftData


struct DeepRacerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var deepRacers: [DeepRacer]
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(deepRacers) { racer in
                    NavigationLink(destination: DeviceLoadingView(deepRacer: racer)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(racer.name)
                                .font(.headline)
                            Text(racer.ipAddress)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteRacers)
            }
            .navigationTitle("DeepRacers")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddDeepRacerView()
            }
            .overlay {
                if deepRacers.isEmpty {
                    ContentUnavailableView(
                        "No DeepRacers",
                        systemImage: "car.fill",
                        description: Text("Add a DeepRacer to get started")
                    )
                }
            }
        }
    }
    
    func deleteRacers(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(deepRacers[index])
        }
    }
}

struct AddDeepRacerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var ipAddress = ""
    @State private var password = ""
    @State private var showPassword = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("DeepRacer Details") {
                    TextField("Name", text: $name)
                    TextField("IP Address", text: $ipAddress)
                        .keyboardType(.decimalPad)
                        .autocapitalization(.none)
                }
                
                Section("Credentials") {
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add DeepRacer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addDeepRacer()
                    }
                    .disabled(!isValidForm)
                }
            }
        }
    }
    
    var isValidForm: Bool {
        !name.isEmpty && !ipAddress.isEmpty && !password.isEmpty
    }
    
    func addDeepRacer() {
        let newRacer = DeepRacer(
            name: name,
            ipAddress: ipAddress,
            password: password
        )
        modelContext.insert(newRacer)
        dismiss()
    }
}


#Preview {
    DeepRacerListView()
        .modelContainer(for: DeepRacer.self, inMemory: true)
}
