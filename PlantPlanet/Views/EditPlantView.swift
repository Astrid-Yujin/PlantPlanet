//
//  EditPlantView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI
import PhotosUI
import SwiftData

struct EditPlantView: View {
    @Bindable var plant: Plant
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var allLocations: [Location]
    @Query private var allPlants: [Plant]
    
    @State private var showingDeleteAlert = false
    
    @State private var editedName: String = ""
    @State private var selectedSpeciesIndex = 0
    @State private var customSpecies = ""
    @State private var selectedLocationIndex = 0
    @State private var customLocation = ""
    @State private var editedWateringSchedule: WateringSchedule = .days(3)
    @State private var editedNotes: String = ""
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @State private var speciesOptions: [String] = ["Rose", "Hydrangea", "Pothos", "Azalea", "Camellia", "Other"]
    
    // 使用 LocationManager 的统一排序方法
    private var sortedLocations: [Location] {
        return LocationManager.sortedLocations(allLocations)
    }
    
    // 计算属性：位置选项
    private var locationOptions: [String] {
        var options = sortedLocations.map { $0.name }
        options.append("Add New")
        return options
    }
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                wateringSection
                photosSection
                notesSection
               
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete Plant")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Edit Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlant()
                    }
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                initializeFields()
            }
            .alert("Delete Plant", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePlant()
                }
            } message: {
                Text("Are you sure you want to delete \"\(plant.name)\"? This will also delete all watering records and photos. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        Section(header: Text("Basic Information")) {
            TextField("Name", text: $editedName)
            
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
            
            if locationOptions[selectedLocationIndex] == "Add New" {
                TextField("Enter new location", text: $customLocation)
            }
        }
    }
    
    private var wateringSection: some View {
        Section(header: Text("Watering Schedule")) {
            WateringScheduleEditor(schedule: $editedWateringSchedule)
        }
    }
    
    private var photosSection: some View {
        Section(header: Text("Photos (\(plant.photoFilenames.count))")) {
            if !plant.photoFilenames.isEmpty {
                ExistingPhotosGrid(plant: plant)
            }
            
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                Label("Add More Photos", systemImage: "photo.badge.plus")
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                addNewPhotos(from: newValue)
            }
        }
    }
    
    private var notesSection: some View {
        Section(header: Text("Notes")) {
            TextEditor(text: $editedNotes)
                .frame(height: 100)
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return false }
        
        if speciesOptions[selectedSpeciesIndex] == "Other" {
            let trimmedSpecies = customSpecies.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSpecies.isEmpty { return false }
        }
        
        if locationOptions[selectedLocationIndex] == "Add New" {
            let trimmedLocation = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLocation.isEmpty { return false }
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func initializeFields() {
        editedName = plant.name
        editedWateringSchedule = plant.wateringSchedule
        editedNotes = plant.notes
        
        // 设置种类
        if let index = speciesOptions.firstIndex(of: plant.species) {
            selectedSpeciesIndex = index
        } else {
            if !plant.species.isEmpty && plant.species != "Unknown" {
                if !speciesOptions.contains(plant.species) {
                    speciesOptions.insert(plant.species, at: speciesOptions.count - 1)
                }
                selectedSpeciesIndex = speciesOptions.firstIndex(of: plant.species) ?? 0
            } else {
                selectedSpeciesIndex = speciesOptions.count - 1
            }
        }
        
        // 设置位置
        if let index = locationOptions.firstIndex(of: plant.location) {
            selectedLocationIndex = index
        } else {
            if !plant.location.isEmpty && plant.location != "Unknown" {
                // 如果植物的位置不在列表中，检查是否存在于数据库中
                if allLocations.first(where: { $0.name == plant.location }) != nil {
                    // 位置存在于数据库但不在当前排序列表中，创建新的位置到数据库
                    selectedLocationIndex = locationOptions.firstIndex(of: plant.location) ?? (locationOptions.count - 1)
                } else {
                    // 位置不存在，创建新位置
                    let newLocation = Location(name: plant.location)
                    LocationManager.addLocation(newLocation, context: modelContext)
                    // 选择"Add New"选项，并设置自定义位置
                    selectedLocationIndex = locationOptions.count - 1
                    customLocation = plant.location
                }
            } else {
                selectedLocationIndex = locationOptions.count - 1
            }
        }
    }
    
    private func addNewPhotos(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let filename = PhotoManager.shared.savePhoto(image) {
                    plant.photoFilenames.append(filename)
                }
            }
            selectedPhotos.removeAll()
        }
    }
    
    private func savePlant() {
        plant.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.wateringSchedule = editedWateringSchedule
        plant.notes = editedNotes
        
        // 处理种类
        if speciesOptions[selectedSpeciesIndex] == "Other" {
            let finalSpecies = customSpecies.trimmingCharacters(in: .whitespacesAndNewlines)
            plant.species = finalSpecies.isEmpty ? "Unknown" : finalSpecies
            if !finalSpecies.isEmpty && !speciesOptions.contains(finalSpecies) {
                speciesOptions.insert(finalSpecies, at: speciesOptions.count - 1)
            }
        } else {
            plant.species = speciesOptions[selectedSpeciesIndex]
        }
        
        // 处理位置
        if locationOptions[selectedLocationIndex] == "Add New" {
            let finalLocation = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            plant.location = finalLocation.isEmpty ? "Unknown" : finalLocation
            if !finalLocation.isEmpty {
                // 检查位置是否已存在于数据库
                let existingLocation = allLocations.first { $0.name.lowercased() == finalLocation.lowercased() }
                if existingLocation == nil {
                    // 使用 LocationManager 创建新位置
                    let newLocation = Location(name: finalLocation)
                    LocationManager.addLocation(newLocation, context: modelContext)
                }
            }
        } else {
            plant.location = locationOptions[selectedLocationIndex]
        }
        
        dismiss()
    }
    
    
    private func deletePlant() {
        // 删除照片文件
        PhotoManager.shared.deletePhotos(plant.photoFilenames)
        
        // 删除植物数据
        modelContext.delete(plant)
        
        // 关闭编辑页面（会自动返回列表）
        dismiss()
    }
}

// MARK: - Existing Photos Grid
struct ExistingPhotosGrid: View {
    @Bindable var plant: Plant
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(plant.photoFilenames.enumerated()), id: \.offset) { index, filename in
                    if let image = PhotoManager.shared.loadPhoto(filename) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button {
                                PhotoManager.shared.deletePhoto(filename)
                                plant.photoFilenames.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.white, .red)
                                    .font(.title3)
                            }
                            .offset(x: 8, y: -8)
                        }
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
    
    return     EditPlantView(plant: Plant(
        name: "Test Plant",
        species: "Rose",
        location: "Balcony",
        wateringSchedule: .days(3)
    ))
        .modelContainer(container)
}
