//
//  Location.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/6/25.
//

import SwiftUI
import SwiftData
import Combine

@Model
final class Location {
    var id: UUID
    var name: String
    var createdAt: Date
    var isStarred: Bool  // 用于标记星标位置
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), isStarred: Bool = false) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.isStarred = isStarred
    }
    
    // Convenience initializer for when only name is provided
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.isStarred = false
    }
    
    // Convenience initializer for name and isStarred
    init(name: String, isStarred: Bool) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.isStarred = isStarred
    }
}

// MARK: - Location Manager
class LocationManager: ObservableObject {
    @Published var locations: [Location] = []
    
    // 获取所有位置，按照星标优先，然后按创建时间排序
    func getSortedLocations(with plants: [Plant]) -> [Location] {
        return locations.sorted { location1, location2 in
            // 首先按星标排序（星标的在前）
            if location1.isStarred != location2.isStarred {
                return location1.isStarred
            }
            
            // 然后按创建时间排序（早创建的在前）
            return location1.createdAt < location2.createdAt
        }
    }
    
    // 添加新位置
    func addLocation(_ location: Location, context: ModelContext) {
        context.insert(location)
        locations.append(location)
        try? context.save()
    }
    
    // 创建默认位置（常用的位置标记为星标）
    static func createDefaultLocations(context: ModelContext) {
        let defaultLocationData: [(name: String, isStarred: Bool)] = [
            ("Balcony", true),       // 星标
            ("Living Room", false),  // 普通
            ("Bedroom", false)       // 普通
        ]
        
        for (name, isStarred) in defaultLocationData {
            let location = Location(name: name, isStarred: isStarred)
            context.insert(location)
        }
        
        try? context.save()
    }
    
    // 检查是否已存在某个位置名
    func locationExists(name: String) -> Bool {
        return locations.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    // 切换位置的星标状态
    func toggleStar(for location: Location, context: ModelContext) {
        location.isStarred.toggle()
        try? context.save()
    }
}
