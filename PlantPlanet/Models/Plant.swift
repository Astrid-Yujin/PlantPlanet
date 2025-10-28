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
    private var wateringType: String
    private var wateringDaysInterval: Int?
    private var wateringWeeklyDaysRaw: [Int]?
    
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
