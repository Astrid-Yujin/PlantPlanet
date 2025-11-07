//
//  SpeciesPickerView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import SwiftUI
import SwiftData

struct SpeciesPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allSpecies: [Species]
    @Query private var allPlants: [Plant]
    
    @Binding var selectedSpecies: String
    
    @State private var searchText = ""
    @State private var showingAddNew = false
    @State private var newSpeciesName = ""
    @State private var expandedGroups: Set<String> = []
    @State private var fixedMostUsedSpecies: [String] = []
    
    // 计算属性：按分组的品种
    private var groupedSpecies: [String: [Species]] {
        return SpeciesManager.speciesGroupedByCategory(
            SpeciesManager.searchSpecies(allSpecies, searchText: searchText)
        )
    }
    
    // 计算属性：星标品种
    private var starredSpecies: [Species] {
        let searchedSpecies = SpeciesManager.searchSpecies(allSpecies, searchText: searchText)
        return searchedSpecies.filter { $0.isStarred }.sorted { $0.name < $1.name }
    }
    
    // 计算属性：排序后的分组名称
    private var sortedGroupNames: [String] {
        let hasStarredSpecies = !searchText.isEmpty ? false : !fixedMostUsedSpecies.isEmpty
        return SpeciesManager.sortedGroupNames(from: filteredGroupedSpecies, hasStarredSpecies: hasStarredSpecies)
    }
    
    // 计算属性：过滤掉星标品种后的分组（避免重复显示）
    private var filteredGroupedSpecies: [String: [Species]] {
        var filtered: [String: [Species]] = [:]
        let starredSpeciesNames = Set(starredSpecies.map { $0.name })
        
        for (groupName, speciesInGroup) in groupedSpecies {
            // 过滤掉已经在星标分组中显示的品种
            let filteredGroup = speciesInGroup.filter { !starredSpeciesNames.contains($0.name) }
            if !filteredGroup.isEmpty {
                filtered[groupName] = filteredGroup
            }
        }
        
        return filtered
    }
    
    // 计算属性：最常用的品种（已废弃，使用固定的 fixedMostUsedSpecies）
    private var mostUsedSpecies: [String] {
        return SpeciesManager.getMostUsedSpecies(from: allPlants, limit: 5)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchSection
            speciesListSection
        }
        .navigationTitle("Select Species")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            ensureDefaultSpeciesExist()
            initializeMostUsedSpecies()
            autoExpandSelectedSpeciesGroup()
        }
    }
    
    // MARK: - View Components
    
    private var searchSection: some View {
        VStack(spacing: 12) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search species", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 快速添加新品种按钮
            if !searchText.isEmpty && !speciesExists(searchText) {
                Button {
                    addNewSpecies(searchText.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                        Text("Add \"\(searchText)\" as new species")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    private var speciesListSection: some View {
        List {
            // 最常用品种段
            if searchText.isEmpty && !fixedMostUsedSpecies.isEmpty {
                Section("🔥 Most Used") {
                    ForEach(fixedMostUsedSpecies, id: \.self) { speciesName in
                        SpeciesRow(
                            name: speciesName,
                            isSelected: selectedSpecies == speciesName,
                            plantCount: plantsCount(for: speciesName)
                        ) {
                            selectSpecies(speciesName)
                        }
                    }
                }
            }
            
            // 星标品种段
            if !starredSpecies.isEmpty {
                Section("⭐ Starred") {
                    ForEach(starredSpecies) { species in
                        SpeciesRow(
                            name: species.name,
                            isSelected: selectedSpecies == species.name,
                            isStarred: species.isStarred,
                            plantCount: plantsCount(for: species.name)
                        ) {
                            selectSpecies(species.name)
                        } onStarTap: {
                            toggleStar(species)
                        }
                    }
                }
            }
            
            // 按分组显示品种
            ForEach(sortedGroupNames, id: \.self) { groupName in
                if let speciesInGroup = filteredGroupedSpecies[groupName], !speciesInGroup.isEmpty {
                    Section(header: collapsibleGroupHeaderView(for: groupName)) {
                        if expandedGroups.contains(groupName) || !searchText.isEmpty {
                            ForEach(speciesInGroup) { species in
                                SpeciesRow(
                                    name: species.name,
                                    isSelected: selectedSpecies == species.name,
                                    isStarred: species.isStarred,
                                    plantCount: plantsCount(for: species.name)
                                ) {
                                    selectSpecies(species.name)
                                } onStarTap: {
                                    toggleStar(species)
                                }
                            }
                        }
                    }
                }
            }
            
            // 无结果显示
            if filteredGroupedSpecies.isEmpty && starredSpecies.isEmpty && !searchText.isEmpty {
                Text("No species found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    private func collapsibleGroupHeaderView(for groupName: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                if expandedGroups.contains(groupName) {
                    expandedGroups.remove(groupName)
                } else {
                    expandedGroups.insert(groupName)
                }
            }
        } label: {
            HStack {
                Text(SpeciesGroup.fromString(groupName).icon)
                    .font(.title2)
                
                Text(groupName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // 显示品种数量
                if let speciesInGroup = filteredGroupedSpecies[groupName] {
                    Text("\(speciesInGroup.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                }
                
                // 展开/折叠图标
                Image(systemName: expandedGroups.contains(groupName) ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(expandedGroups.contains(groupName) ? 0 : 0))
                    .animation(.easeInOut(duration: 0.3), value: expandedGroups.contains(groupName))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func initializeMostUsedSpecies() {
        // 在视图出现时固定 Most Used 的顺序，之后不再改变
        fixedMostUsedSpecies = SpeciesManager.getMostUsedSpecies(from: allPlants, limit: 5)
    }
    
    private func ensureDefaultSpeciesExist() {
        if allSpecies.isEmpty {
            SpeciesManager.createDefaultSpecies(context: modelContext)
        }
    }
    
    private func autoExpandSelectedSpeciesGroup() {
        // 如果已选择品种，自动展开包含该品种的分组
        if !selectedSpecies.isEmpty {
            for species in allSpecies {
                if species.name == selectedSpecies {
                    expandedGroups.insert(species.group)
                    break
                }
            }
        }
    }
    
    private func speciesExists(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return allSpecies.contains { $0.name.lowercased() == trimmedName.lowercased() }
    }
    
    private func addNewSpecies(_ name: String) {
        guard !name.isEmpty, !speciesExists(name) else { return }
        
        // 用户新增的品种自动归类到自定义分组
        let newSpecies = Species(name: name, group: SpeciesGroup.custom.rawValue, isUserDefined: true)
        SpeciesManager.addSpecies(newSpecies, context: modelContext)
        
        // 设置为选中状态但不关闭页面
        selectedSpecies = name
        
        // 清除搜索文本以便用户看到新添加的品种
        searchText = ""
        
        // 自动展开自定义分组以显示新添加的品种
        expandedGroups.insert(SpeciesGroup.custom.rawValue)
    }
    
    private func selectSpecies(_ name: String) {
        selectedSpecies = name
        dismiss()
    }
    
    private func plantsCount(for speciesName: String) -> Int {
        return allPlants.filter { $0.species == speciesName }.count
    }
    
    private func toggleStar(_ species: Species) {
        species.isStarred.toggle()
        try? modelContext.save()
    }
}

// MARK: - Species Row Component

struct SpeciesRow: View {
    let name: String
    let isSelected: Bool
    let isStarred: Bool
    let plantCount: Int
    let onTap: () -> Void
    let onStarTap: (() -> Void)?
    
    init(name: String, isSelected: Bool, isStarred: Bool = false, plantCount: Int = 0, onTap: @escaping () -> Void, onStarTap: (() -> Void)? = nil) {
        self.name = name
        self.isSelected = isSelected
        self.isStarred = isStarred
        self.plantCount = plantCount
        self.onTap = onTap
        self.onStarTap = onStarTap
    }
    
    var body: some View {
        HStack {
            // 星标按钮（如果有星标功能）
            if let onStarTap = onStarTap {
                Button {
                    onStarTap()
                } label: {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundColor(isStarred ? .yellow : .gray)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if plantCount > 0 {
                    Text("\(plantCount) plant\(plantCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
        }
        .contentShape(Rectangle()) // 确保整行都可以点击
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedSpecies = "Rose"
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Species.self, Plant.self, Location.self, WateringLog.self, configurations: config)
    let context = container.mainContext
    
    // 创建示例数据
    SpeciesManager.createDefaultSpecies(context: context)
    
    // 创建一些示例植物
    let plant1 = Plant(name: "Rose 1", species: "Rose", location: "Garden", wateringSchedule: .days(3))
    let plant2 = Plant(name: "Rose 2", species: "Rose", location: "Garden", wateringSchedule: .days(3))
    let plant3 = Plant(name: "Tulip", species: "Tulip", location: "Garden", wateringSchedule: .days(2))
    
    context.insert(plant1)
    context.insert(plant2)
    context.insert(plant3)
    
    try? context.save()
    
    return SpeciesPickerView(selectedSpecies: .constant("Rose"))
        .modelContainer(container)
}
