//
//  PlantExtensions.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 11/03/25.
//

import Foundation
import SwiftUI

// MARK: - Watering Group

/// 浇水分组类型
enum WateringGroup: Int, CaseIterable {
    case overdue      // 需要浇水（已过期）
    case today        // 今天
    case tomorrow     // 明天
    case thisWeek     // 本周内（2-7天）
    case nextWeek     // 下周（8-14天）
    case later        // 更晚（15天以上）
    
    var title: String {
        switch self {
        case .overdue: return "Needs Water"
        case .today: return "Today"
        case .tomorrow: return "Tomorrow"
        case .thisWeek: return "This Week"
        case .nextWeek: return "Next Week"
        case .later: return "Later"
        }
    }
    
    var icon: String {
        switch self {
        case .overdue: return "drop.fill"
        case .today: return "calendar.circle.fill"
        case .tomorrow: return "sun.max.fill"
        case .thisWeek: return "calendar"
        case .nextWeek: return "calendar.badge.clock"
        case .later: return "clock"
        }
    }
    
    var color: Color {
        switch self {
        case .overdue: return .red
        case .today: return .blue
        case .tomorrow: return .orange
        case .thisWeek: return .green
        case .nextWeek: return .purple
        case .later: return .gray
        }
    }
    
    // 用于排序（数值越小越紧急）
    var sortOrder: Int {
        return self.rawValue
    }
}

// MARK: - Plant Extensions

extension Plant {
    /// 判断属于哪个分组
    var wateringGroup: WateringGroup {
        guard let days = daysUntilNextWatering else {
            return .overdue
        }
        
        // 根据天数判断分组
        switch days {
        case ..<0:
            // 负数表示已过期
            return .overdue
        case 0:
            // 今天
            return .today
        case 1:
            // 明天
            return .tomorrow
        case 2...7:
            // 本周内（2-7天）
            return .thisWeek
        case 8...14:
            // 下周（8-14天）
            return .nextWeek
        default:
            // 更晚（15天以上）
            return .later
        }
    }
}
