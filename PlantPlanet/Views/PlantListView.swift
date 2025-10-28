//
//  PlantListView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.createdAt, order: .reverse) private var plants: [Plant]
    
    @State private var showingAddSheet = false
    @State private var grouping: GroupingType = .location
    
    // 删除确认对话框相关状态
    @State private var showingDeleteAlert = false
    @State private var plantsToDelete: [Plant] = []
    @State private var deleteAction: (() -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                let grouped = Dictionary(grouping: plants, by: groupingKey)
                
                ForEach(grouped.keys.sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(grouped[key] ?? []) { plant in
                            NavigationLink(destination: PlantDetailView(plant: plant)) {
                                PlantRowView(plant: plant)
                            }
                        }
                        .onDelete { offsets in
                            prepareDelete(in: grouped[key] ?? [], at: offsets)
                        }
                    }
                }
            }
            .navigationTitle("My Plants")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    groupingMenu
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
                AddPlantView()
            }
            .alert("Confirm Delete", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAction?()  // 执行删除
                }
            } message: {
                Text(deleteMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var groupingMenu: some View {
        Menu {
            Button {
                grouping = .location
            } label: {
                Label("Group by Location", systemImage: grouping == .location ? "checkmark" : "")
            }
            Button {
                grouping = .species
            } label: {
                Label("Group by Species", systemImage: grouping == .species ? "checkmark" : "")
            }
            Button {
                grouping = .wateringSchedule
            } label: {
                Label("Group by Watering", systemImage: grouping == .wateringSchedule ? "checkmark" : "")
            }
        } label: {
            Label("Group", systemImage: "line.3.horizontal.decrease.circle")
        }
    }
    
    // MARK: - Helper Methods
    
    private func groupingKey(for plant: Plant) -> String {
        switch grouping {
        case .location:
            return plant.location.isEmpty ? "Unspecified Location" : plant.location
        case .species:
            return plant.species.isEmpty ? "Unknown Species" : plant.species
        case .wateringSchedule:
            return plant.wateringSchedule.description
        }
    }
    
    // 准备删除（显示确认对话框）
     private func prepareDelete(in plants: [Plant], at offsets: IndexSet) {
         // 收集要删除的植物
         plantsToDelete = offsets.map { plants[$0] }
         
         // 保存删除操作
         deleteAction = {
             for plant in plantsToDelete {
                 PhotoManager.shared.deletePhotos(plant.photoFilenames)
                 modelContext.delete(plant)
             }
             plantsToDelete.removeAll()
         }
         
         // 显示确认对话框
         showingDeleteAlert = true
     }
     
     // 生成删除确认消息
     private var deleteMessage: String {
         if plantsToDelete.count == 1 {
             return "Are you sure you want to delete \"\(plantsToDelete[0].name)\"? This action cannot be undone."
         } else {
             return "Are you sure you want to delete \(plantsToDelete.count) plants? This action cannot be undone."
         }
     }
}

// MARK: - Plant Row View
struct PlantRowView: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let firstPhoto = plant.photoFilenames.first,
               let image = PhotoManager.shared.loadPhoto(firstPhoto) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                Text(plant.species)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                    // 浇水频率
                    HStack(spacing: 4) {
                        Image(systemName: "drop")
                            .font(.caption2)
                        Text(plant.wateringSchedule.shortDescription)
                            .font(.caption)
                    }
                    .foregroundColor(.green)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PlantListView()
        .modelContainer(for: Plant.self, inMemory: true)
}
