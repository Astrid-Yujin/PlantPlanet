//
//  SpeciesManagementView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import SwiftUI
import SwiftData

struct SpeciesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var allSpecies: [Species]
    @Query private var allPlants: [Plant]
    

    
    @State private var searchText = ""
    @State private var newSpeciesName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingAddSpecies = false
    
    // 编辑功能的状态
    @State private var editingSpecies: Species?
    @State private var editingSpeciesName = ""
    
    // 计算属性：搜索结果
    private var searchResults: [Species] {
        return SpeciesManager.searchSpecies(allSpecies, searchText: searchText)
    }
    
    // 计算属性：是否显示"添加新品种"选项
    private var shouldShowAddNewOption: Bool {
        return !searchText.isEmpty && 
               searchResults.isEmpty && 
               !allSpecies.contains(where: { $0.name.lowercased() == searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() })
    }
    
    // 计算属性：按分组的品种
    private var groupedSpecies: [String: [Species]] {
        return SpeciesManager.speciesGroupedByCategory(searchResults)
    }
    
    // 计算属性：排序后的分组名称
    private var sortedGroupNames: [String] {
        return SpeciesManager.sortedGroupNames(from: groupedSpecies)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                mainContentView
                if searchText.isEmpty {
                    floatingButtonOverlay
                }
            }
        }
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            searchSection
            speciesListSection
        }
        .navigationTitle("Manage Species")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent
        }
        .alert("Species Management", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onTapGesture {
            handleBackgroundTap()
        }
    }
    
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                dismiss()
            }
        }
    }
    
    private var floatingButtonOverlay: some View {
        VStack {
            Spacer()
            HStack {
                if showingAddSpecies {
                    floatingAddSpeciesInput
                }
                Spacer()
                floatingAddButton
            }
            .padding()
        }
    }
    
    private func handleBackgroundTap() {
        // Cancel editing when tapping outside
        if editingSpecies != nil {
            cancelEditing()
        }
        // Hide add species section when tapping outside
        if showingAddSpecies && newSpeciesName.isEmpty {
            withAnimation(.easeInOut(duration: 0.3)) {
                showingAddSpecies = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchSection: some View {
        VStack(spacing: 8) {
            HStack {
                searchIcon
                searchTextField
                clearButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 搜索状态提示
            if !searchText.isEmpty {
                searchStatusText
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var searchStatusText: some View {
        HStack {
            if searchResults.isEmpty {
                Text("No results found.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("\(searchResults.count) species found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
    }
    
    private var searchIcon: some View {
        Image(systemName: "magnifyingglass")
            .foregroundColor(.gray)
    }
    
    private var searchTextField: some View {
        TextField("Search species", text: $searchText)
            .textFieldStyle(.plain)
    }
    
    @ViewBuilder
    private var clearButton: some View {
        if !searchText.isEmpty {
            Button {
                searchText = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var speciesListSection: some View {
        List {
            // 如果搜索无结果且可以添加新品种，显示添加选项
            if shouldShowAddNewOption {
                addNewSpeciesFromSearchSection
            }
            
            speciesGroupSections
        }
        .listStyle(.plain)
    }
    
    private var addNewSpeciesFromSearchSection: some View {
        Section {
            Button {
                addSpeciesFromSearch()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add \"\(searchText.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text("Create new species")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var speciesGroupSections: some View {
        ForEach(sortedGroupNames, id: \.self) { groupName in
            if let speciesInGroup = groupedSpecies[groupName], !speciesInGroup.isEmpty {
                speciesGroupSection(groupName: groupName, species: speciesInGroup)
            }
        }
    }
    
    private func speciesGroupSection(groupName: String, species: [Species]) -> some View {
        Section(header: groupHeaderView(for: groupName)) {
            ForEach(species) { species in
                speciesRow(for: species)
            }
            .onDelete { offsets in
                deleteSpeciesInGroup(at: offsets, in: groupName)
            }
        }
    }
    
    @ViewBuilder
    private func groupHeaderView(for groupName: String) -> some View {
        HStack {
            groupIcon(for: groupName)
            groupTitle(for: groupName)
        }
    }
    
    private func groupIcon(for groupName: String) -> some View {
        Text(SpeciesGroup.fromString(groupName).icon)
            .font(.title2)
    }
    
    private func groupTitle(for groupName: String) -> some View {
        Text(groupName)
            .font(.headline)
            .foregroundColor(.primary)
    }
    
    private var floatingAddButton: some View {
        Button {
            toggleAddSpeciesSection()
        } label: {
            addButtonContent
        }
        .rotationEffect(.degrees(showingAddSpecies && !shouldShowAddNewOption ? 45 : 0))
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingAddSpecies)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: shouldShowAddNewOption)
    }
    
    private var addButtonContent: some View {
        Image(systemName: buttonIcon)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(addButtonBackground)
    }
    
    private var buttonIcon: String {
        if shouldShowAddNewOption {
            return "checkmark"
        } else if showingAddSpecies {
            return "xmark"
        } else {
            return "plus"
        }
    }
    
    private var addButtonBackground: some View {
        Circle()
            .fill(shouldShowAddNewOption ? Color.blue : Color.green)
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private func toggleAddSpeciesSection() {
        // 如果有搜索结果且可以添加，直接添加
        if shouldShowAddNewOption && !showingAddSpecies {
            addSpeciesFromSearch()
            return
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingAddSpecies.toggle()
            if showingAddSpecies {
                // Clear previous input when opening
                newSpeciesName = ""
            }
        }
    }
    
    private var floatingAddSpeciesInput: some View {
        HStack(spacing: 12) {
            speciesNameTextField
            confirmButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(inputBackground)
        .transition(inputTransition)
    }
    
    private var speciesNameTextField: some View {
        TextField("Enter species name", text: $newSpeciesName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .submitLabel(.done)
            .onSubmit {
                handleTextFieldSubmit()
            }
    }
    
    private var confirmButton: some View {
        Button {
            addNewSpecies()
            hideAddSpeciesSection()
        } label: {
            Image(systemName: "checkmark")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(confirmButtonBackground)
        }
        .disabled(isNewSpeciesNameEmpty)
    }
    
    private var confirmButtonBackground: some View {
        Circle()
            .fill(isNewSpeciesNameEmpty ? Color.gray : Color.blue)
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)
    }
    
    private var inputTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
    
    private var isNewSpeciesNameEmpty: Bool {
        newSpeciesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleTextFieldSubmit() {
        if !isNewSpeciesNameEmpty {
            addNewSpecies()
            hideAddSpeciesSection()
        }
    }
    
    private func hideAddSpeciesSection() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingAddSpecies = false
        }
    }
    
    private func speciesRow(for species: Species) -> some View {
        HStack {
            starButton(for: species)
            speciesNameSection(for: species)
            Spacer()
            if editingSpecies?.id != species.id {
                plantCountBadge(for: species)
            }
        }
    }
    
    private func starButton(for species: Species) -> some View {
        Button {
            toggleStar(species)
        } label: {
            Image(systemName: species.isStarred ? "star.fill" : "star")
                .foregroundColor(species.isStarred ? .yellow : .gray)
                .font(.title3)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func speciesNameSection(for species: Species) -> some View {
        VStack(alignment: .leading) {
            if editingSpecies?.id == species.id {
                editingModeView
            } else {
                displayModeView(for: species)
            }
        }
    }
    
    private var editingModeView: some View {
        HStack {
            editingTextField
            saveButton
            cancelButton
        }
    }
    
    private var editingTextField: some View {
        TextField("Species name", text: $editingSpeciesName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    private var saveButton: some View {
        Button {
            saveSpeciesName()
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .disabled(editingSpeciesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    private var cancelButton: some View {
        Button {
            cancelEditing()
        } label: {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .foregroundColor(.gray)
                .font(.title3)
        }
    }
    
    private func displayModeView(for species: Species) -> some View {
        HStack {
            speciesNameText(for: species)
            editButton(for: species)
        }
    }
    
    private func speciesNameText(for species: Species) -> some View {
        Text(species.name)
            .font(.body)
            .foregroundColor(.primary)
    }
    
    @ViewBuilder
    private func editButton(for species: Species) -> some View {
        if species.isUserDefined {
            Button {
                startEditing(species)
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func plantCountBadge(for species: Species) -> some View {
        Text("\(plantsCount(for: species.name))")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color(.systemGray5))
            .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func addSpeciesFromSearch() {
        let trimmedName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        addNewSpecies(name: trimmedName, clearSearchText: true)
    }
    
    private func addNewSpecies() {
        let trimmedName = newSpeciesName.trimmingCharacters(in: .whitespacesAndNewlines)
        addNewSpecies(name: trimmedName, clearSearchText: false)
        newSpeciesName = ""
    }
    
    private func addNewSpecies(name: String, clearSearchText: Bool) {
        // 检查是否已存在
        if allSpecies.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            alertMessage = "A species with this name already exists."
            showingAlert = true
            return
        }
        
        // 用户新增的品种自动归类到自定义分组
        let newSpecies = Species(name: name, group: SpeciesGroup.custom.rawValue, isUserDefined: true)
        SpeciesManager.addSpecies(newSpecies, context: modelContext)
        
        // 根据来源清除相应的文本
        if clearSearchText {
            searchText = ""
        }
    }
    
    private func deleteSpeciesInGroup(at offsets: IndexSet, in groupName: String) {
        guard let speciesInGroup = groupedSpecies[groupName] else { return }
        
        for index in offsets {
            let species = speciesInGroup[index]
            
            // 只能删除用户自定义的品种
            if !species.isUserDefined {
                alertMessage = "Cannot delete '\(species.name)' because it's a built-in species. Only custom species can be deleted."
                showingAlert = true
                continue
            }
            
            // 检查是否有植物使用这个品种
            let plantsUsingSpecies = plantsCount(for: species.name)
            if plantsUsingSpecies > 0 {
                alertMessage = "Cannot delete '\(species.name)' because \(plantsUsingSpecies) plant(s) are using this species."
                showingAlert = true
                continue
            }
            
            modelContext.delete(species)
        }
    }
    
    private func deleteSpecies(at offsets: IndexSet) {
        // 这个方法保留用于向后兼容，但现在使用分组删除
        // 实际上不会被调用，因为我们使用 deleteSpeciesInGroup
    }
    
    private func plantsCount(for speciesName: String) -> Int {
        return allPlants.filter { $0.species == speciesName }.count
    }
    
    private func toggleStar(_ species: Species) {
        species.isStarred.toggle()
        try? modelContext.save()
    }
    
    // MARK: - 编辑品种名称功能
    
    private func startEditing(_ species: Species) {
        editingSpecies = species
        editingSpeciesName = species.name
    }
    
    private func cancelEditing() {
        editingSpecies = nil
        editingSpeciesName = ""
    }
    
    private func saveSpeciesName() {
        guard let species = editingSpecies else { return }
        
        let trimmedName = editingSpeciesName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 检查新名称是否与其他品种重复（除了当前编辑的品种）
        if allSpecies.contains(where: { $0.id != species.id && $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "A species with this name already exists."
            showingAlert = true
            return
        }
        
        // 获取所有使用旧名称的植物
        let plantsToUpdate = allPlants.filter { $0.species == species.name }
        
        // 更新品种名称
        species.name = trimmedName
        
        // 更新所有相关植物的品种
        for plant in plantsToUpdate {
            plant.species = trimmedName
        }
        
        try? modelContext.save()
        
        // 退出编辑模式
        cancelEditing()
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Species.self, Plant.self, Location.self, WateringLog.self, configurations: config)
    let context = container.mainContext
    
    // 创建示例数据
    SpeciesManager.createDefaultSpecies(context: context)
    
    // 创建一些示例植物
    let plant1 = Plant(name: "Rose Garden", species: "Rose", location: "Garden", wateringSchedule: .days(3))
    context.insert(plant1)
    
    try? context.save()
    
    return SpeciesManagementView()
        .modelContainer(container)
}
