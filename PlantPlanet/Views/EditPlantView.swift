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
    
    @State private var editedName: String = ""
    @State private var selectedSpeciesIndex = 0
    @State private var customSpecies = ""
    @State private var selectedLocationIndex = 0
    @State private var customLocation = ""
    @State private var editedWateringFrequency: Int = 3
    @State private var editedNotes: String = ""
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    
    @State private var speciesOptions: [String] = ["Rose", "Hydrangea", "Pothos", "Azalea", "Camellia", "Other"]
    @State private var locationOptions: [String] = ["Living Room", "Balcony", "Bedroom", "Add New"]
    
    var body: some View {
        NavigationView {
            Form {
                basicInfoSection
                wateringSection
                photosSection
                notesSection
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
        Section(header: Text("Watering Frequency")) {
            Stepper(value: $editedWateringFrequency, in: 1...30) {
                Text("Every \(editedWateringFrequency) day\(editedWateringFrequency > 1 ? "s" : "")")
            }
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
        editedWateringFrequency = plant.wateringFrequency
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
                if !locationOptions.contains(plant.location) {
                    locationOptions.insert(plant.location, at: locationOptions.count - 1)
                }
                selectedLocationIndex = locationOptions.firstIndex(of: plant.location) ?? 0
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
        plant.wateringFrequency = editedWateringFrequency
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
            if !finalLocation.isEmpty && !locationOptions.contains(finalLocation) {
                locationOptions.insert(finalLocation, at: locationOptions.count - 1)
            }
        } else {
            plant.location = locationOptions[selectedLocationIndex]
        }
        
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
    EditPlantView(plant: Plant(
        name: "Test Plant",
        species: "Rose",
        location: "Balcony",
        wateringFrequency: 3
    ))
    .modelContainer(for: Plant.self, inMemory: true)
}
