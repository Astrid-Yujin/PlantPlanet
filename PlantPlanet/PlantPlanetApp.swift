//
//  PlantPlanetApp.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 9/29/25.
//

import SwiftUI
import SwiftData

@main
struct PlantApp: App {
    var body: some Scene {
        WindowGroup {
            PlantListView()
        }
        .modelContainer(for: [Plant.self, WateringLog.self])
    }
}

// MARK: - App Preview

#Preview("Complete PlantPlanet App") {
    AppPreviewWrapper()
}

// 包装器视图来避免编译器类型检查问题
private struct AppPreviewWrapper: View {
    var body: some View {
        PlantListView()
            .modelContainer(createSimplePreviewContainer())
    }
}

// 创建简化的预览数据容器
private func createSimplePreviewContainer() -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Plant.self, WateringLog.self, configurations: config)
    let context = container.mainContext
    
    // 简化的示例数据
    createSamplePlant(context: context, name: "月季", species: "Rosa", location: "Balcony", days: 2, daysAgo: 1)
    createSamplePlant(context: context, name: "龟背竹", species: "Monstera", location: "Balcony", days: 7, daysAgo: 1)
    createSamplePlant(context: context, name: "山茶花", species: "Camellia", location: "Reading Room", days: 3, daysAgo: 1)
    createSamplePlant(context: context, name: "杜鹃花", species: "Rhododendron", location: "Dining Room", days: 5, daysAgo: 1)
    
    try? context.save()
    return container
}

// 辅助函数创建单个植物
private func createSamplePlant(context: ModelContext, name: String, species: String, location: String, days: Int, daysAgo: Int) {
    let plant = Plant(
        name: name,
        species: species,
        location: location,
        wateringSchedule: WateringSchedule.days(days)
    )
    
    // 添加一条浇水记录
    if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) {
        let log = WateringLog(date: date, notes: "预览数据")
        plant.wateringLogs.append(log)
    }
    
    context.insert(plant)
}
