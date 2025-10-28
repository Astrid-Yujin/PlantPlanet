//
//  WateringFrequencyType.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import Foundation

// MARK: - 浇水频率类型
enum WateringFrequencyType: String, Codable {
    case days       // 每N天一次
    case weekly     // 每周N次（指定具体日期）
}

// MARK: - 浇水计划
struct WateringSchedule: Codable, Equatable {
    var type: WateringFrequencyType
    var daysInterval: Int?              // 当 type = .days 时使用
    var weeklyDays: Set<Weekday>?       // 当 type = .weekly 时使用
    
    // 便捷初始化方法
    static func days(_ interval: Int) -> WateringSchedule {
        WateringSchedule(type: .days, daysInterval: interval, weeklyDays: nil)
    }
    
    static func weekly(_ days: Set<Weekday>) -> WateringSchedule {
        WateringSchedule(type: .weekly, daysInterval: nil, weeklyDays: days)
    }
    
    // 描述文本
    var description: String {
        switch type {
        case .days:
            let days = daysInterval ?? 1
            return "Every \(days) day\(days > 1 ? "s" : "")"
        case .weekly:
            guard let weeklyDays = weeklyDays, !weeklyDays.isEmpty else {
                return "Not set"
            }
            let count = weeklyDays.count
            let dayNames = weeklyDays.sorted().map { $0.shortName }.joined(separator: ", ")
            return "\(count) time\(count > 1 ? "s" : "") per week (\(dayNames))"
        }
    }
    
    // 简短描述（用于列表显示）
    var shortDescription: String {
        switch type {
        case .days:
            return "\(daysInterval ?? 1)d"
        case .weekly:
            return "\(weeklyDays?.count ?? 0)×/wk"
        }
    }
}

// MARK: - 星期枚举
enum Weekday: Int, Codable, CaseIterable, Comparable {
    case sunday = 0
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    
    var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
    
    var veryShortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
    
    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
