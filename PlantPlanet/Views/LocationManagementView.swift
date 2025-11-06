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
        return LocationManager.sortedLocations(allLocations)
    }
    
    @Query private var allPlants: [Plant]
    
    @State private var newLocationName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 编辑功能的状态
    @State private var editingLocation: Location?
    @State private var editingLocationName = ""
    @State private var showingAddLocation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                locationListSection
                .navigationTitle("Manage Locations")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .alert("Location Management", isPresented: $showingAlert) {
                    Button("OK") { }
                } message: {
                    Text(alertMessage)
                }
                .onTapGesture {
                    // Cancel editing when tapping outside
                    if editingLocation != nil {
                        cancelEditing()
                    }
                    // Hide add location section when tapping outside
                    if showingAddLocation && newLocationName.isEmpty {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAddLocation = false
                        }
                    }
                }
                
                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        if showingAddLocation {
                            floatingAddLocationInput
                        }
                        Spacer()
                        floatingAddButton
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var floatingAddButton: some View {
        Button {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingAddLocation.toggle()
                if showingAddLocation {
                    // Clear previous input when opening
                    newLocationName = ""
                }
            }
        } label: {
            Image(systemName: showingAddLocation ? "xmark" : "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color.green)
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .rotationEffect(.degrees(showingAddLocation ? 45 : 0))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingAddLocation)
    }
    
    private var floatingAddLocationInput: some View {
        HStack(spacing: 12) {
            TextField("Enter location name", text: $newLocationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .submitLabel(.done)
                .onSubmit {
                    if !newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        addNewLocation()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingAddLocation = false
                        }
                    }
                }
            
            Button {
                addNewLocation()
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingAddLocation = false
                }
            } label: {
                Image(systemName: "checkmark")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    )
            }
            .disabled(newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)
        )
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
    }
    
    private var locationListSection: some View {
        List {
            ForEach(locations) { location in
                locationRow(for: location)
            }
            .onDelete(perform: deleteLocations)
        }
    }
    
    private func locationRow(for location: Location) -> some View {
        HStack {
            starButton(for: location)
            locationNameSection(for: location)
            Spacer()
            if editingLocation?.id != location.id {
                plantCountBadge(for: location)
            }
        }
    }
    
    private func starButton(for location: Location) -> some View {
        Button {
            toggleStar(location)
        } label: {
            Image(systemName: location.isStarred ? "star.fill" : "star")
                .foregroundColor(location.isStarred ? .yellow : .gray)
                .font(.title3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func locationNameSection(for location: Location) -> some View {
        VStack(alignment: .leading) {
            if editingLocation?.id == location.id {
                editingModeView
            } else {
                displayModeView(for: location)
            }
        }
    }
    
    private var editingModeView: some View {
        HStack {
            TextField("Location name", text: $editingLocationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button {
                saveLocationName()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
            .disabled(editingLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Button {
                cancelEditing()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(.gray)
                    .font(.title3)
            }
        }
    }
    
    private func displayModeView(for location: Location) -> some View {
        Button {
            startEditing(location)
        } label: {
            Text(location.name)
                .font(.body)
                .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func plantCountBadge(for location: Location) -> some View {
        Text("\(plantsCount(for: location.name))")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(.systemGray5))
            .cornerRadius(8)
    }
    
    private func addNewLocation() {
        let trimmedName = newLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查是否已存在
        if allLocations.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "A location with this name already exists."
            showingAlert = true
            return
        }
        
        // 使用 LocationManager 创建新位置
        let newLocation = Location(name: trimmedName)
        LocationManager.addLocation(newLocation, context: modelContext)
        
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
    
    // MARK: - 编辑位置名称功能
    
    private func startEditing(_ location: Location) {
        editingLocation = location
        editingLocationName = location.name
    }
    
    private func cancelEditing() {
        editingLocation = nil
        editingLocationName = ""
    }
    
    private func saveLocationName() {
        guard let location = editingLocation else { return }
        
        let trimmedName = editingLocationName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查新名称是否与其他位置重复（除了当前编辑的位置）
        if allLocations.contains(where: { $0.id != location.id && $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "A location with this name already exists."
            showingAlert = true
            return
        }
        
        // 获取所有使用旧名称的植物
        let plantsToUpdate = allPlants.filter { $0.location == location.name }
        
        // 更新位置名称
        location.name = trimmedName
        
        // 更新所有相关植物的位置
        for plant in plantsToUpdate {
            plant.location = trimmedName
        }
        
        try? modelContext.save()
        
        // 退出编辑模式
        cancelEditing()
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
