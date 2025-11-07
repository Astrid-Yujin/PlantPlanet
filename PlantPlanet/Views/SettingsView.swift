//
//  SettingsView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingLocationManagement = false
    @State private var showingSpeciesManagement = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Management") {
                    Button {
                        showingLocationManagement = true
                    } label: {
                        HStack {
                            Image(systemName: "location")
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            Text("Manage Locations")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        showingSpeciesManagement = true
                    } label: {
                        HStack {
                            Image(systemName: "leaf")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Manage Species")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        Text("App Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingLocationManagement) {
            LocationManagementView()
        }
        .sheet(isPresented: $showingSpeciesManagement) {
            SpeciesManagementView()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Location.self, WateringLog.self, Species.self, configurations: config)
    
    return SettingsView()
        .modelContainer(container)
}