//
//  Plant.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI
import SwiftData

@Model
final class Plant {
    var id: UUID
    var name: String
    var species: String
    var location: String
    var createdAt: Date
    var photoFilenames: [String]
    var notes: String
    var groupIds: [UUID]
    
    // 浇水计划
    private var wateringType: String
    private var wateringDaysInterval: Int?
    private var wateringWeeklyDaysRaw: [Int]?
    
    // 浇水记录
    @Relationship(deleteRule: .cascade, inverse: \WateringLog.plant)
    var wateringLogs: [WateringLog] = []
    
    var wateringSchedule: WateringSchedule {
        get {
            let type = WateringFrequencyType(rawValue: wateringType) ?? .days
            
            switch type {
            case .days:
                return .days(wateringDaysInterval ?? 3)
            case .weekly:
                if let rawDays = wateringWeeklyDaysRaw, !rawDays.isEmpty {
                    let weekdays = Set(rawDays.compactMap { Weekday(rawValue: $0) })
                    return .weekly(weekdays)
                }
                // 默认周一和周四
                return .weekly([.monday, .thursday])
            }
        }
        set {
            wateringType = newValue.type.rawValue
            
            switch newValue.type {
            case .days:
                wateringDaysInterval = newValue.daysInterval
                wateringWeeklyDaysRaw = nil
            case .weekly:
                wateringDaysInterval = nil
                if let weekdays = newValue.weeklyDays, !weekdays.isEmpty {
                    wateringWeeklyDaysRaw = weekdays.map { $0.rawValue }.sorted()
                } else {
                    // 默认周一和周四
                    wateringWeeklyDaysRaw = [1, 4]
                }
            }
        }
    }
    
    // 最后浇水日期
     var lastWateringDate: Date? {
         wateringLogs.sorted(by: { $0.date > $1.date }).first?.date
     }
     
     // 下次浇水日期
     var nextWateringDate: Date? {
         guard let lastDate = lastWateringDate else {
             // 如果从未浇水，返回今天
             return Date()
         }
         
         return wateringSchedule.calculateNextWateringDate(from: lastDate)
     }
     
     // 是否需要浇水
     var needsWatering: Bool {
         guard let nextDate = nextWateringDate else { return true }
         
         // 如果今天已经浇过水了，则认为不需要浇水
         let calendar = Calendar.current
         if let lastDate = lastWateringDate,
            calendar.isDateInToday(lastDate) {
             return false
         }
         
         return Date() >= nextDate
     }
     
     // 距离下次浇水的天数
     var daysUntilNextWatering: Int? {
         guard let nextDate = nextWateringDate else { return nil }
         
         let calendar = Calendar.current
         let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: nextDate)).day
         return days
     }
     
     // 今天是否已经浇过水
     var wateredToday: Bool {
         guard let lastDate = lastWateringDate else { return false }
         return Calendar.current.isDateInToday(lastDate)
     }
    
    init(id: UUID = UUID(), 
         name: String, 
         species: String, 
         location: String, 
         createdAt: Date = Date(), 
         photoFilenames: [String] = [], 
         notes: String = "", 
         groupIds: [UUID] = [], 
         wateringSchedule: WateringSchedule = .days(3)) {
        self.id = id
        self.name = name
        self.species = species
        self.location = location
        self.createdAt = createdAt
        self.photoFilenames = photoFilenames
        self.notes = notes
        self.groupIds = groupIds
        self.wateringType = wateringSchedule.type.rawValue
        
        switch wateringSchedule.type {
        case .days:
            self.wateringDaysInterval = wateringSchedule.daysInterval ?? 3
            self.wateringWeeklyDaysRaw = nil
        case .weekly:
            self.wateringDaysInterval = nil
            if let weekdays = wateringSchedule.weeklyDays, !weekdays.isEmpty {
                self.wateringWeeklyDaysRaw = weekdays.map { $0.rawValue }.sorted()
            } else {
                self.wateringWeeklyDaysRaw = [1, 4] // 默认周一和周四
            }
        }
    }
}

// MARK: - ValueTransformer for WateringSchedule
@objc(WateringScheduleTransformer)
class WateringScheduleTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let schedule = value as? WateringSchedule else { return nil }
        return try? JSONEncoder().encode(schedule)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode(WateringSchedule.self, from: data)
    }
}

// 注册 Transformer
extension WateringScheduleTransformer {
    static func register() {
        let transformer = WateringScheduleTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: NSValueTransformerName("WateringScheduleTransformer"))
    }
}
