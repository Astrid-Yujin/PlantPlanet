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
    
    @State private var selectedPlant: Plant?
    
    var body: some View {
        NavigationStack {
            List {
                let grouped = Dictionary(grouping: plants, by: groupingKey)
                
                ForEach(grouped.keys.sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(grouped[key] ?? []) { plant in
                            Button {
                                selectedPlant = plant
                            } label: {
                                PlantRowView(plant: plant)
                            }
                            .buttonStyle(PlainButtonStyle())
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
            .navigationDestination(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
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
            
            // 左侧：植物信息
            VStack(alignment: .leading, spacing: 6) {
                // 植物名称
                Text(plant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // 种类
                Text(plant.species)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
            }
            
            Spacer()
            
            // 右侧：浇水状态（紧凑显示）
            VStack(alignment: .trailing, spacing: 6) {
                // 浇水频率
                HStack(spacing: 4) {
                    Image(systemName: "drop")
                        .font(.caption2)
                    Text(plant.wateringSchedule.shortDescription)
                        .font(.caption)
                }
                .foregroundColor(.green)
                
                // 状态图标和文字
                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption2)
                    Text(statusText)
                        .font(.caption)
                }
                .foregroundColor(statusColor)
                
                // 下次浇水日期
                if let nextDate = plant.nextWateringDate {
                    Text(formatDate(nextDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                

            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
    
    // MARK: - Helper Properties
    
    private var statusIcon: String {
        if plant.needsWatering {
            return "exclamationmark.triangle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        guard let days = plant.daysUntilNextWatering else {
            return .orange
        }
        
        if days < 0 {
            return .red  // 过期
        } else if days == 0 {
            return .orange  // 今天
        } else if days == 1 {
            return .yellow  // 明天
        } else {
            return .green  // 还早
        }
    }
    
    private var statusText: String {
        guard let days = plant.daysUntilNextWatering else {
            return "Not set"
        }
        
        if days < 0 {
            return "Overdue"
        } else if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days) day\(days > 1 ? "s" : "")"
        }
    }
    
    // 格式化日期（紧凑格式）
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        // 今天
        if calendar.isDateInToday(date) {
            return "Today"
        }
        
        // 明天
        if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        
        // 一周内：只显示星期几
        let daysAway = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        if abs(daysAway) < 7 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"  // Mon, Tue, Wed
            return formatter.string(from: date)
        }
        
        // 超过一周：显示简短日期
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"  // Oct 28
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    PlantListView()
        .modelContainer(for: Plant.self, inMemory: true)
}
