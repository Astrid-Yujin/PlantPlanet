//
//  AddPlantView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI
import SwiftData
import PhotosUI

struct AddPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query private var allLocations: [Location]
    @Query private var allPlants: [Plant]
    
    // 按照和 LocationManagementView 相同的排序逻辑
    private var sortedLocations: [Location] {
        return allLocations.sorted { location1, location2 in
            // First by starred status (starred first)
            if location1.isStarred != location2.isStarred {
                return location1.isStarred && !location2.isStarred
            }
            
            // Then by plant count (higher count first)
            let count1 = allPlants.filter { $0.location == location1.name }.count
            let count2 = allPlants.filter { $0.location == location2.name }.count
            if count1 != count2 {
                return count1 > count2
            }
            
            // Finally alphabetically (case insensitive)
            return location1.name.localizedCaseInsensitiveCompare(location2.name) == .orderedAscending
        }
    }
    
    @State private var name = ""
    @State private var selectedSpeciesIndex = 0
    @State private var customSpecies = ""
    @State private var selectedLocationIndex = 0
    @State private var customLocation = ""
    @State private var wateringSchedule = WateringSchedule.days(3)
    @State private var notes = ""
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    
    @State private var speciesOptions: [String] = ["Rose", "Hydrangea", "Pothos", "Azalea", "Camellia", "Other"]
    
    // 计算属性：位置选项
    private var locationOptions: [String] {
        var options = sortedLocations.map { $0.name }
        options.append("Add New")
        return options
    }
    
    // 确保在视图加载时创建默认位置
    private func ensureDefaultLocationsExist() {
        if allLocations.isEmpty {
            LocationManager.createDefaultLocations(context: modelContext)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                wateringSection
                photosSection
                notesSection
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlant()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                ensureDefaultLocationsExist()
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        Section(header: Text("Plant Information")) {
            TextField("Name (Required)", text: $name)
            
            Picker("Species", selection: $selectedSpeciesIndex) {
                ForEach(0..<speciesOptions.count, id: \.self) { index in
                    Text(speciesOptions[index]).tag(index)
                }
            }
            
            if speciesOptions[selectedSpeciesIndex] == "Other" {
                TextField("Enter custom species", text: $customSpecies)
            }
            
            Picker("Location", selection: $selectedLocationIndex) {
                ForEach(0..<locationOptions.count, id: \.self) { index in
                    Text(locationOptions[index]).tag(index)
                }
            }
            
            if locationOptions.indices.contains(selectedLocationIndex) && locationOptions[selectedLocationIndex] == "Add New" {
                TextField("Enter new location", text: $customLocation)
            }
        }
    }
    
    private var wateringSection: some View {
        Section(header: Text("Watering Schedule")) {
            WateringScheduleEditor(schedule: $wateringSchedule)
        }
    }
    
    private var photosSection: some View {
        Section(header: Text("Photos (Optional)")) {
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                Label("Add Photos", systemImage: "photo.on.rectangle.angled")
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                loadPhotos(from: newValue)
            }
            
            if !photoImages.isEmpty {
                PhotoPreviewGrid(images: $photoImages, selectedPhotos: $selectedPhotos)
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes (Optional)")) {
            TextEditor(text: $notes)
                .frame(height: 100)
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return false }
        
        if speciesOptions.indices.contains(selectedSpeciesIndex) && speciesOptions[selectedSpeciesIndex] == "Other" {
            let trimmedSpecies = customSpecies.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSpecies.isEmpty { return false }
        }
        
        if locationOptions.indices.contains(selectedLocationIndex) && locationOptions[selectedLocationIndex] == "Add New" {
            let trimmedLocation = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLocation.isEmpty { return false }
        }
        
        switch wateringSchedule.type {
         case .days:
             if wateringSchedule.daysInterval == nil || wateringSchedule.daysInterval! < 1 {
                 return false
             }
         case .weekly:
             if wateringSchedule.weeklyDays == nil || wateringSchedule.weeklyDays!.isEmpty {
                 return false
             }
         }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            photoImages.removeAll()
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoImages.append(image)
                }
            }
        }
    }
    
    private func savePlant() {
        var finalSpecies: String
        if speciesOptions.indices.contains(selectedSpeciesIndex) && speciesOptions[selectedSpeciesIndex] == "Other" {
            finalSpecies = customSpecies.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalSpecies.isEmpty && !speciesOptions.contains(finalSpecies) {
                speciesOptions.insert(finalSpecies, at: speciesOptions.count - 1)
            }
        } else if speciesOptions.indices.contains(selectedSpeciesIndex) {
            finalSpecies = speciesOptions[selectedSpeciesIndex]
        } else {
            finalSpecies = "Unknown"
        }
        
        var finalLocation: String
        if locationOptions.indices.contains(selectedLocationIndex) && locationOptions[selectedLocationIndex] == "Add New" {
            finalLocation = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalLocation.isEmpty {
                // 检查位置是否已存在
                let existingLocation = allLocations.first { $0.name.lowercased() == finalLocation.lowercased() }
                if existingLocation == nil {
                    // 创建新位置并保存到数据库
                    let newLocation = Location(name: finalLocation)
                    modelContext.insert(newLocation)
                }
            }
        } else if locationOptions.indices.contains(selectedLocationIndex) {
            finalLocation = locationOptions[selectedLocationIndex]
        } else {
            finalLocation = "Unknown"
        }
        
        // 保存照片
        var savedPhotoFilenames: [String] = []
        for image in photoImages {
            if let filename = PhotoManager.shared.savePhoto(image) {
                savedPhotoFilenames.append(filename)
            }
        }
        
        let newPlant = Plant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: finalSpecies.isEmpty ? "Unknown" : finalSpecies,
            location: finalLocation.isEmpty ? "Unknown" : finalLocation,
            photoFilenames: savedPhotoFilenames,
            notes: notes,
            wateringSchedule: wateringSchedule
        )
        
        modelContext.insert(newPlant)
        dismiss()
    }
}

// MARK: - Photo Preview Grid
struct PhotoPreviewGrid: View {
    @Binding var images: [UIImage]
    @Binding var selectedPhotos: [PhotosPickerItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        Button {
                            images.remove(at: index)
                            selectedPhotos.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white, .red)
                                .font(.title3)
                        }
                        .offset(x: 8, y: -8)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Location.self, WateringLog.self, configurations: config)
    let context = container.mainContext
    
    // 创建默认位置
    LocationManager.createDefaultLocations(context: context)
    try? context.save()
    
    return AddPlantView()
        .modelContainer(container)
}
