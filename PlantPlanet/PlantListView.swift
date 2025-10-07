import SwiftUI

// MARK: - Models
struct Plant: Identifiable {
    let id: UUID
    var name: String
    var species: String
    var location: String
    var createdAt: Date
    var photos: [String]
    var notes: String
    var groupIds: [UUID]
    var wateringFrequency: Int?   // 单位：天，可选
}

// MARK: - Grouping Type
enum GroupingType {
    case location
    case species
    case wateringFrequency
}

// MARK: - Main View
struct PlantListView: View {
    @State private var plants: [Plant] = [
        Plant(id: UUID(), name: "小白", species: "月季", location: "阳台", createdAt: Date(), photos: [], notes: "", groupIds: [], wateringFrequency: 3),
        Plant(id: UUID(), name: "大绿", species: "绿萝", location: "客厅", createdAt: Date(), photos: [], notes: "", groupIds: [], wateringFrequency: 3),
        Plant(id: UUID(), name: "小球", species: "绣球", location: "阳台", createdAt: Date(), photos: [], notes: "", groupIds: [], wateringFrequency: 3)
    ]
    @State private var showingAddSheet = false
    @State private var grouping: GroupingType = .location
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedPlants.keys.sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(groupedPlants[key] ?? []) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                VStack(alignment: .leading) {
                                    Text(plant.name)
                                        .font(.headline)
                                    
                                }
                            }
                        }

                    }
                }
            }
            .navigationTitle("我的植物")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                         Button("按位置分组") { grouping = .location }
                         Button("按种类分组") { grouping = .species }
                         Button("按浇水频率分组") { grouping = .wateringFrequency }
                     } label: {
                         Label("分组", systemImage: "line.3.horizontal.decrease.circle")
                     }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddPlantView { newPlant in
                    plants.append(newPlant)
                }
            }
        }
    }
    
    // 动态分组
    private var groupedPlants: [String: [Plant]] {
        switch grouping {
        case .location:
            return Dictionary(grouping: plants, by: { $0.location.isEmpty ? "未指定位置" : $0.location })
        case .species:
            return Dictionary(grouping: plants, by: { $0.species.isEmpty ? "未知种类" : $0.species })
        case .wateringFrequency:
            return Dictionary(grouping: plants, by: {
                if let freq = $0.wateringFrequency {
                    return "每 \(freq) 天浇水"
                } else {
                    return "未设置频率"
                }
            })
        }
    }
}

// MARK: - Add Plant Sheet
struct AddPlantView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var location = ""
    @State private var selectedSpeciesIndex = 0
    @State private var customSpecies = ""
    @State private var selectedLocationIndex = 0
    @State private var customLocation = ""
    @State private var wateringFrequency: Int = 3   // 默认 3 天一次
    
    @State private var speciesOptions: [String] = ["月季", "绣球", "绿萝", "杜鹃", "山茶花", "其他"]
    @State private var locationOptions: [String] = ["客厅", "阳台", "卧室", "新增"]
    
    var onSave: (Plant) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("植物信息")) {
                    TextField("昵称 (必填)", text: $name)
                    
                    Picker("种类", selection: $selectedSpeciesIndex) {
                        ForEach(0..<speciesOptions.count, id: \.self) { index in
                            Text(speciesOptions[index])
                        }
                    }
                    
                    if speciesOptions[selectedSpeciesIndex] == "其他" {
                        TextField("请输入自定义种类", text: $customSpecies)
                    }
                    
                    Picker("位置", selection: $selectedLocationIndex) {
                        ForEach(0..<locationOptions.count, id: \.self) { index in
                            Text(locationOptions[index])
                        }
                    }
                    
                    if locationOptions[selectedLocationIndex] == "新增" {
                        TextField("输入新位置", text: $customLocation)
                    }
                }
                
                Section(header: Text("浇水频率")) {
                    Stepper(value: $wateringFrequency, in: 1...30) {
                        Text("\(wateringFrequency) 天一次")
                    }
                }
            }
            .navigationTitle("添加植物")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        var finalSpecies: String
                        if speciesOptions[selectedSpeciesIndex] == "其他" {
                            finalSpecies = customSpecies.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !finalSpecies.isEmpty && !speciesOptions.contains(finalSpecies) {
                                speciesOptions.insert(finalSpecies, at: speciesOptions.count - 1)
                            }
                        } else {
                            finalSpecies = speciesOptions[selectedSpeciesIndex]
                        }
                        
                        var finalLocation: String
                        if locationOptions[selectedLocationIndex] == "新增" {
                            finalLocation = customLocation.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !finalLocation.isEmpty && !locationOptions.contains(finalLocation) {
                                locationOptions.insert(finalLocation, at: locationOptions.count - 1)
                            }
                        } else {
                            finalLocation = locationOptions[selectedLocationIndex]
                        }
                        
                        let newPlant = Plant(
                            id: UUID(),
                            name: name,
                            species: finalSpecies.isEmpty ? "未知" : finalSpecies,
                            location: finalLocation.isEmpty ? "未知" : finalLocation,
                            createdAt: Date(),
                            photos: [],
                            notes: "",
                            groupIds: [],
                            wateringFrequency: wateringFrequency
                        )
                        onSave(newPlant)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              (speciesOptions[selectedSpeciesIndex] == "其他" && customSpecies.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                }
            }
        }
    }
}



// MARK: - PlantDetailView
struct PlantDetailView: View {
    let plant: Plant
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(plant.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("种类")
                    Spacer()
                    Text(plant.species)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("位置")
                    Spacer()
                    Text(plant.location)
                        .foregroundColor(.secondary)
                }
                if let freq = plant.wateringFrequency {
                    HStack {
                        Text("浇水频率")
                        Spacer()
                        Text("每 \(freq) 天一次")
                            .foregroundColor(.secondary)
                    }
                }
                HStack {
                    Text("创建时间")
                    Spacer()
                    Text(plant.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("备注")) {
                if plant.notes.isEmpty {
                    Text("暂无备注")
                        .foregroundColor(.secondary)
                } else {
                    Text(plant.notes)
                }
            }
        }
        .navigationTitle(plant.name)
    }
}

// MARK: - Preview
struct PlantListView_Previews: PreviewProvider {
    static var previews: some View {
        PlantListView()
    }
}
