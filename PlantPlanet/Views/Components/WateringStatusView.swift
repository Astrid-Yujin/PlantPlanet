//
//  WateringStatusView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/30/25.
//


import SwiftUI
import SwiftData

struct WateringStatusView: View {
    let plant: Plant
    var compact: Bool = false
    
    var body: some View {
        if compact {
            compactView
        } else {
            fullView
        }
    }
    
    // MARK: - 紧凑视图（列表用）
    private var compactView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.caption2)
                Text(statusText)
                    .font(.caption)
            }
            .foregroundColor(statusColor)
            
            if let nextDate = plant.nextWateringDate {
                Text(nextDateText(nextDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 完整视图（详情用）
    private var fullView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 最后浇水
            if let lastDate = plant.lastWateringDate {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("Last watered:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatDate(lastDate))
                        .fontWeight(.medium)
                }
            } else {
                HStack {
                    Image(systemName: "drop")
                        .foregroundColor(.gray)
                    Text("Never watered")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // 下次浇水
            if let nextDate = plant.nextWateringDate {
                HStack {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    Text("Next watering:")
                        .foregroundColor(.secondary)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        // 状态文本（"In 2 days" 等）
                        Text(nextDateText(nextDate))
                            .font(.caption)
                            .foregroundColor(statusColor)
                        
                        // 日期（包含星期几，不含年份）
                        Text(formatDate(nextDate))
                            .font(.subheadline)  // ← 缩小字体
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
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
            return "In \(days) days"
        }
    }
    
    private func nextDateText(_ date: Date) -> String {
        let days = plant.daysUntilNextWatering ?? 0
        
        if days < 0 {
            return "\(abs(days)) day\(abs(days) > 1 ? "s" : "") overdue"
        } else if days == 0 {
            return "Water today!"
        } else if days == 1 {
            return "Water tomorrow"
        } else {
            return "In \(days) days"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"  // 星期几, 月份 日期
        return formatter.string(from: date)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // 紧凑视图
        WateringStatusView(
            plant: Plant(
                name: "Test",
                species: "Rose",
                location: "Balcony",
                wateringSchedule: .days(3)
            ),
            compact: true
        )
        
        // 完整视图
        WateringStatusView(
            plant: Plant(
                name: "Test",
                species: "Rose",
                location: "Balcony",
                wateringSchedule: .days(3)
            ),
            compact: false
        )
    }
    .padding()
    .modelContainer(for: Plant.self, inMemory: true)
}
