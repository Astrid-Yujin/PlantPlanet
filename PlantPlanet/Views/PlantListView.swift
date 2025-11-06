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
    @State private var showingLocationManagement = false
    @State private var grouping: GroupingType = .wateringGroup  // 默认改为 wateringGroup
    
    @State private var selectedPlant: Plant?
    
    var body: some View {
        NavigationStack {
            List {
                // 特殊处理 wateringGroup 分组
                if grouping == .wateringGroup {
                    wateringGroupView
                } else {
                    regularGroupView
                }
            }
            .navigationTitle("My Plants")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    groupingMenu
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add Plant", systemImage: "plus")
                        }
                        
                        Button {
                            showingLocationManagement = true
                        } label: {
                            Label("Manage Locations", systemImage: "location.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                PlantFormView(mode: .add)
            }
            .sheet(isPresented: $showingLocationManagement) {
                LocationManagementView()
            }
            .navigationDestination(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
        }
    }
    
    // MARK: - Subviews
    
    // 浇水分组视图（按紧急程度排序）
    private var wateringGroupView: some View {
        ForEach(groupedByWateringGroup, id: \.group) { item in
            Section {
                ForEach(item.plants) { plant in
                    Button {
                        selectedPlant = plant
                    } label: {
                        PlantRowView(plant: plant, grouping: grouping)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        // 左滑浇水功能，但如果今天已经浇过水则不显示
                        if !plant.wateredToday {
                            Button {
                                waterPlant(plant)
                            } label: {
                                Label("Water", systemImage: "drop.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
            } header: {
                // 带颜色和图标的分组标题
                HStack(spacing: 8) {
                    Image(systemName: item.group.icon)
                        .foregroundColor(item.group.color)
                        .font(.subheadline)
                    
                    Text(item.group.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // 在 overdue 和 today 组显示快速浇水按钮
                    if item.group == .overdue || item.group == .today {
                        Button {
                            waterAllPlantsInGroup(item.plants)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.caption2)
                                Text("Water")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        .disabled(item.plants.isEmpty)
                    } else {
                        // 其他组显示植物数量
                        Text("\(item.plants.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    // 常规分组视图
    private var regularGroupView: some View {
        ForEach(regularGroupedPlants.keys.sorted(), id: \.self) { key in
            Section(header: Text(key)) {
                ForEach(regularGroupedPlants[key] ?? []) { plant in
                    Button {
                        selectedPlant = plant
                    } label: {
                        PlantRowView(plant: plant, grouping: grouping)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        // 如果今天没有浇过水，才显示左滑浇水功能
                        if !plant.wateredToday {
                            Button {
                                waterPlant(plant)
                            } label: {
                                Label("Water", systemImage: "drop.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
    }
    
    private var groupingMenu: some View {
        Menu {
            // 添加浇水分组选项
            Button {
                grouping = .wateringGroup
            } label: {
                HStack {
                    Image(systemName: "drop.circle")
                        .frame(width: 20, alignment: .leading)
                    Text("Group by Watering")
                    Spacer()
                    if grouping == .wateringGroup {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Divider()
            
            Button {
                grouping = .location
            } label: {
                HStack {
                    Image(systemName: "location.circle")
                        .frame(width: 20, alignment: .leading)
                    Text("Group by Location")
                    Spacer()
                    if grouping == .location {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Button {
                grouping = .species
            } label: {
                HStack {
                    Image(systemName: "leaf.circle")
                        .frame(width: 20, alignment: .leading)
                    Text("Group by Species")
                    Spacer()
                    if grouping == .species {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Button {
                grouping = .wateringSchedule
            } label: {
                HStack {
                    Image(systemName: "calendar.circle")
                        .frame(width: 20, alignment: .leading)
                    Text("Group by Schedule")
                    Spacer()
                    if grouping == .wateringSchedule {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        } label: {
            // 显示当前选择的分组方式
            HStack(spacing: 6) {
                Image(systemName: currentGroupIcon)
                Text(currentGroupTitle)
                    .font(.caption)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // 当前分组的标题和图标
    private var currentGroupTitle: String {
        switch grouping {
        case .wateringGroup: return "Watering"
        case .location: return "Location"
        case .species: return "Species"
        case .wateringSchedule: return "Schedule"
        }
    }
    
    private var currentGroupIcon: String {
        switch grouping {
        case .wateringGroup: return "drop.circle"
        case .location: return "location.circle"
        case .species: return "leaf.circle"
        case .wateringSchedule: return "calendar.circle"
        }
    }
    
    // MARK: - Computed Properties
    
    // 浇水分组的计算属性
    private var groupedByWateringGroup: [(group: WateringGroup, plants: [Plant])] {
        // 按分组分类
        var grouped: [WateringGroup: [Plant]] = [:]
        for group in WateringGroup.allCases {
            grouped[group] = []
        }
        
        for plant in plants {
            grouped[plant.wateringGroup]?.append(plant)
        }
        
        // 在每个分组内按天数排序（最近的在前）
        for group in WateringGroup.allCases {
            grouped[group]?.sort {
                let days1 = $0.daysUntilNextWatering ?? -999
                let days2 = $1.daysUntilNextWatering ?? -999
                return days1 < days2
            }
        }
        
        // 只返回非空分组，按紧急程度排序
        return WateringGroup.allCases.compactMap { group in
            if let plants = grouped[group], !plants.isEmpty {
                return (group: group, plants: plants)
            }
            return nil
        }
    }
    
    // 常规分组的计算属性
    private var regularGroupedPlants: [String: [Plant]] {
        Dictionary(grouping: plants, by: groupingKey)
    }
    
    // MARK: - Helper Methods
    
    private func groupingKey(for plant: Plant) -> String {
        switch grouping {
        case .wateringGroup:
            return plant.wateringGroup.title
        case .location:
            return plant.location.isEmpty ? "Unspecified Location" : plant.location
        case .species:
            return plant.species.isEmpty ? "Unknown Species" : plant.species
        case .wateringSchedule:
            return plant.wateringSchedule.description
        }
    }
    
    private func waterPlant(_ plant: Plant) {
        let log = WateringLog(date: Date(), notes: "")
        plant.wateringLogs.append(log)
        
        // 可选：添加触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func waterAllPlantsInGroup(_ plants: [Plant]) {
        let currentDate = Date()
        
        for plant in plants {
            let log = WateringLog(date: currentDate, notes: "Batch watering")
            plant.wateringLogs.append(log)
        }
        
        // 添加触觉反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Plant Row View
struct PlantRowView: View {
    let plant: Plant
    let grouping: GroupingType
    
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
                
                if grouping == .wateringGroup {
                    // wateringGroup模式：显示种类和浇水频率
                    Text(plant.species)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "drop")
                            .font(.caption2)
                        Text(plant.wateringSchedule.shortDescription)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // 右侧信息
            VStack(alignment: .trailing, spacing: 6) {
                if grouping == .wateringGroup {
                    // wateringGroup模式：显示浇水相关信息
                    
                    // 上次浇水日期
                    if let lastDate = plant.lastWateringDate {
                        HStack(spacing: 4) {
                            Text("Last:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatDate(lastDate))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 状态图标和文字
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption2)
                        Text(statusText)
                            .font(.caption)
                    }
                    .foregroundColor(statusColor)
                
                } else {
                    // 其他分组模式：显示种类和浇水频率
                    Text(plant.species)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "drop")
                            .font(.caption2)
                        Text(plant.wateringSchedule.shortDescription)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
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

// MARK: - Preview Helper

private struct PlantListPreview: View {
    @State private var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Plant.self, Location.self, WateringLog.self, configurations: config)
        let context = container.mainContext
        
        // 创建默认位置
        LocationManager.createDefaultLocations(context: context)
        
        // 创建示例数据 - 与 PlantApp 中的数据保持一致
        let plants = [
            ("月季", "Rosa", "Balcony", WateringSchedule.days(1), 1),
            ("龟背竹", "Monstera", "Balcony", WateringSchedule.days(7), 12),
            ("山茶花", "Camellia", "Living Room", WateringSchedule.days(3), 2),
            ("杜鹃花", "Rhododendron", "Living Room", WateringSchedule.days(5), 0)
        ]
        
        for (name, species, location, schedule, daysAgo) in plants {
            let plant = Plant(name: name, species: species, location: location, wateringSchedule: schedule)
            plant.photoFilenames = []
            
            if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) {
                plant.wateringLogs.append(WateringLog(date: date, notes: "预览数据"))
            }
            
            context.insert(plant)
        }
        
        try? context.save()  // 别忘了保存
        return container
    }()
    
    var body: some View {
        PlantListView()
            .modelContainer(container)
    }
}

#Preview {
    PlantListPreview()
}
