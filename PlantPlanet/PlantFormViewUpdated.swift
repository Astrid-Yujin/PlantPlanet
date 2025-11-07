//
//  PlantFormView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import SwiftUI
import SwiftData
import PhotosUI

enum PlantFormMode {
    case add
    case edit(Plant)
    
    var title: String {
        switch self {
        case .add:
            return "Add Plant"
        case .edit:
            return "Edit Plant"
        }
    }
    
    var saveButtonText: String {
        switch self {
        case .add:
            return "Add"
        case .edit:
            return "Save"
        }
    }
}

struct PlantFormView: View {
    let mode: PlantFormMode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query private var allLocations: [Location]
    @Query private var allSpecies: [Species]
    @Query private var allPlants: [Plant]
    
    // 使用 LocationManager 的统一排序方法
    private var sortedLocations: [Location] {
        return LocationManager.sortedLocations(allLocations)
    }
    
    // 表单状态
    @State private var name = ""
    @State private var species = ""
    @State private var selectedLocationIndex = 0
    @State private var customLocation = ""
    @State private var wateringSchedule = WateringSchedule.days(3)
    @State private var notes = ""
    
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var showingDeleteAlert = false
    @State private var showingSpeciesPicker = false
    
    // 计算属性：位置选项
    private var locationOptions: [String] {
        var options = sortedLocations.map { $0.name }
        options.append("Add New")
        return options
    }
    
    // 获取当前编辑的植物（仅在编辑模式下）
    private var editingPlant: Plant? {
        if case .edit(let plant) = mode {
            return plant
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Plant Information Section
                Section(header: Text("Plant Information")) {
                    TextField("Name (Required)", text: $name)
                    
                    // 品种选择按钮
                    Button {
                        showingSpeciesPicker = true
                    } label: {
                        HStack {
                            Text("Species")
                                .foregroundColor(.primary)
                            Spacer()
                            if species.isEmpty {
                                Text("Select species")
                                    .foregroundColor(.secondary)
                            } else {
                                Text(species)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
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
                
                // Watering Schedule Section
                Section(header: Text("Watering Schedule")) {
                    WateringScheduleEditor(schedule: $wateringSchedule)
                }
                
                // Photos Section
                Section(header: Text("Photos \(photosHeaderText)")) {
                    // 显示现有照片（仅编辑模式）
                    if case .edit(let plant) = mode, !plant.photoFilenames.isEmpty {
                        ExistingPhotosGrid(plant: plant)
                    }
                    
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                        Label(photoButtonText, systemImage: photoButtonIcon)
                    }
                    .onChange(of: selectedPhotos) { oldValue, newValue in
                        loadPhotos(from: newValue)
                    }
                    
                    // 显示新选择的照片
                    if !photoImages.isEmpty {
                        PhotoPreviewGrid(images: $photoImages, selectedPhotos: $selectedPhotos)
                    }
                }
                
                // Notes Section
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                // 只在编辑模式下显示删除按钮
                if case .edit = mode {
                    Section {
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
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.saveButtonText) {
                        savePlant()
                    }
                    .disabled(!isValid)
                }
            }
            }
            .onAppear {
                ensureDefaultDataExist()
                initializeFields()
            }
            .sheet(isPresented: $showingSpeciesPicker) {
                NavigationStack {
                    SpeciesPickerView(selectedSpecies: $species)
                }
            }
            .alert("Delete Plant", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePlant()
                }
            } message: {
                if let plant = editingPlant {
                    Text("Are you sure you want to delete \"\(plant.name)\"? This will also delete all watering records and photos. This action cannot be undone.")
                }
            }
        }
    
    // MARK: - Computed Properties
    
    private var photosHeaderText: String {
        if case .edit(let plant) = mode {
            return "(\(plant.photoFilenames.count + photoImages.count))"
        } else {
            return photoImages.isEmpty ? "(Optional)" : "(\(photoImages.count))"
        }
    }
    
    private var photoButtonText: String {
        if case .edit = mode {
            return "Add More Photos"
        } else {
            return "Add Photos"
        }
    }
    
    private var photoButtonIcon: String {
        if case .edit = mode {
            return "photo.badge.plus"
        } else {
            return "photo.on.rectangle.angled"
        }
    }
    
    // MARK: - Validation
    
    private var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return false }
        
        if species.isEmpty { return false }
        
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
    
    private func ensureDefaultDataExist() {
        if allLocations.isEmpty {
            LocationManager.createDefaultLocations(context: modelContext)
        }
        if allSpecies.isEmpty {
            SpeciesManager.createDefaultSpecies(context: modelContext)
        }
    }
    
    private func initializeFields() {
        switch mode {
        case .add:
            // 添加模式的默认值已经在状态变量中设置
            break
        case .edit(let plant):
            // 编辑模式：从植物对象初始化字段
            name = plant.name
            species = plant.species
            wateringSchedule = plant.wateringSchedule
            notes = plant.notes
            
            // 设置位置
            if let index = locationOptions.firstIndex(of: plant.location) {
                selectedLocationIndex = index
            } else {
                if !plant.location.isEmpty && plant.location != "Unknown" {
                    // 位置不在列表中，选择"Add New"选项，并设置自定义位置
                    selectedLocationIndex = locationOptions.count - 1
                    customLocation = plant.location
                } else {
                    selectedLocationIndex = locationOptions.count - 1
                }
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            // 在添加模式下，清除之前的图片
            if case .add = mode {
                photoImages.removeAll()
            }
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    if case .edit(let plant) = mode {
                        // 编辑模式：直接保存到植物
                        if let filename = PhotoManager.shared.savePhoto(image) {
                            plant.photoFilenames.append(filename)
                        }
                    } else {
                        // 添加模式：添加到临时数组
                        photoImages.append(image)
                    }
                }
            }
            selectedPhotos.removeAll()
        }
    }
    
    private func savePlant() {
        switch mode {
        case .add:
            saveNewPlant()
        case .edit(let plant):
            updateExistingPlant(plant)
        }
        dismiss()
    }
    
    private func saveNewPlant() {
        let finalLocation = getFinalLocation()
        
        // 保存照片
        var savedPhotoFilenames: [String] = []
        for image in photoImages {
            if let filename = PhotoManager.shared.savePhoto(image) {
                savedPhotoFilenames.append(filename)
            }
        }
        
        // 创建新品种（如果不存在）
        ensureSpeciesExists(species)
        
        let newPlant = Plant(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            species: species.isEmpty ? "Unknown" : species,
            location: finalLocation.isEmpty ? "Unknown" : finalLocation,
            photoFilenames: savedPhotoFilenames,
            notes: notes,
            wateringSchedule: wateringSchedule
        )
        
        modelContext.insert(newPlant)
    }
    
    private func updateExistingPlant(_ plant: Plant) {
        plant.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.species = species
        plant.wateringSchedule = wateringSchedule
        plant.notes = notes
        plant.location = getFinalLocation()
        
        // 创建新品种（如果不存在）
        ensureSpeciesExists(species)
    }
    
    private func getFinalLocation() -> String {
        if locationOptions.indices.contains(selectedLocationIndex) && locationOptions[selectedLocationIndex] == "Add New" {
            let finalLocation = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
            if !finalLocation.isEmpty {
                // 检查位置是否已存在
                let existingLocation = allLocations.first { $0.name.lowercased() == finalLocation.lowercased() }
                if existingLocation == nil {
                    // 使用 LocationManager 创建新位置
                    let newLocation = Location(name: finalLocation)
                    LocationManager.addLocation(newLocation, context: modelContext)
                }
            }
            return finalLocation
        } else if locationOptions.indices.contains(selectedLocationIndex) {
            return locationOptions[selectedLocationIndex]
        } else {
            return "Unknown"
        }
    }
    
    private func ensureSpeciesExists(_ speciesName: String) {
        guard !speciesName.isEmpty else { return }
        
        // 检查品种是否已存在
        let existingSpecies = allSpecies.first { $0.name.lowercased() == speciesName.lowercased() }
        if existingSpecies == nil {
            // 用户新增的品种自动归类到自定义分组
            let newSpecies = Species(name: speciesName, group: SpeciesGroup.custom.rawValue, isUserDefined: true)
            SpeciesManager.addSpecies(newSpecies, context: modelContext)
        }
    }
    
    private func deletePlant() {
        guard case .edit(let plant) = mode else { return }
        
        // 删除照片文件
        PhotoManager.shared.deletePhotos(plant.photoFilenames)
        
        // 删除植物数据
        modelContext.delete(plant)
        
        // 关闭编辑页面
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
                            if selectedPhotos.indices.contains(index) {
                                selectedPhotos.remove(at: index)
                            }
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
#Preview("Add Plant") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Location.self, WateringLog.self, Species.self, configurations: config)
    let context = container.mainContext
    
    // 创建默认数据
    LocationManager.createDefaultLocations(context: context)
    SpeciesManager.createDefaultSpecies(context: context)
    try? context.save()
    
    return PlantFormView(mode: .add)
        .modelContainer(container)
}

#Preview("Edit Plant") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, Location.self, WateringLog.self, Species.self, configurations: config)
    let context = container.mainContext
    
    // 创建默认数据
    LocationManager.createDefaultLocations(context: context)
    SpeciesManager.createDefaultSpecies(context: context)
    
    let testPlant = Plant(
        name: "Test Plant",
        species: "Rose",
        location: "Balcony",
        wateringSchedule: .days(3)
    )
    context.insert(testPlant)
    try? context.save()
    
    return PlantFormView(mode: .edit(testPlant))
        .modelContainer(container)
}
