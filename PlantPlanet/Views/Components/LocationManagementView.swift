//
//  LocationManagementView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import SwiftUI
import SwiftData

struct LocationManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allLocations: [Location]
    
    // Computed property to get properly sorted locations
    private var locations: [Location] {
        // Sort by starred first, then by createdAt
        return allLocations.sorted { location1, location2 in
            // First by starred status (starred first)
            if location1.isStarred != location2.isStarred {
                return location1.isStarred && !location2.isStarred
            }
            
            // Then by creation date
            return location1.createdAt < location2.createdAt
        }
    }
    
    @Query private var allPlants: [Plant]
    
    @State private var newLocationName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // 添加新位置
                HStack {
                    TextField("New location name", text: $newLocationName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        addNewLocation()
                    }
                    .disabled(newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                
                // 位置列表
                List {
                    ForEach(locations) { location in
                        HStack {
                            // 星标按钮
                            Button {
                                toggleStar(location)
                            } label: {
                                Image(systemName: location.isStarred ? "star.fill" : "star")
                                    .foregroundColor(location.isStarred ? .yellow : .gray)
                                    .font(.title3)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            VStack(alignment: .leading) {
                                Text(location.name)
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            // 显示使用该位置的植物数量
                            Text("\(plantsCount(for: location.name))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                    .onDelete(perform: deleteLocations)
                }
            }
            .navigationTitle("Manage Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert(" ", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func addNewLocation() {
        let trimmedName = newLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否已存在
        if allLocations.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "A location with this name already exists."
            showingAlert = true
            return
        }
        
        // 创建新位置，不需要指定sortOrder
        let newLocation = Location(name: trimmedName)
        modelContext.insert(newLocation)
        
        newLocationName = ""
    }
    
    private func deleteLocations(at offsets: IndexSet) {
        for index in offsets {
            let location = locations[index]
            
            // 检查是否有植物使用这个位置
            let plantsUsingLocation = plantsCount(for: location.name)
            if plantsUsingLocation > 0 {
                alertMessage = "Cannot delete '\(location.name)' because \(plantsUsingLocation) plant(s) are using this location."
                showingAlert = true
                continue
            }
            
            modelContext.delete(location)
        }
    }
    
    private func plantsCount(for locationName: String) -> Int {
        return allPlants.filter { $0.location == locationName }.count
    }
    
    private func toggleStar(_ location: Location) {
        location.isStarred.toggle()
        try? modelContext.save()
    }

}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Location.self, Plant.self, WateringLog.self, configurations: config)
    let context = container.mainContext
    
    // 创建一些示例数据
    LocationManager.createDefaultLocations(context: context)
    
    // 创建一些示例植物
    let plant1 = Plant(name: "Test Plant", species: "Test", location: "Living Room", wateringSchedule: WateringSchedule.days(3))
    context.insert(plant1)
    
    try? context.save()
    
    return LocationManagementView()
        .modelContainer(container)
}
