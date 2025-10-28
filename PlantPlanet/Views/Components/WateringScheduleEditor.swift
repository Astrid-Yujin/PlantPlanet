//
//  WateringScheduleEditor.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI

struct WateringScheduleEditor: View {
    @Binding var schedule: WateringSchedule
    
    var body: some View {
        VStack(spacing: 16) {
            // 类型选择
            Picker("Watering Type", selection: $schedule.type) {
                Text("Per days").tag(WateringFrequencyType.days)
                Text("Weekly ").tag(WateringFrequencyType.weekly)
            }
            .pickerStyle(.segmented)
            .onChange(of: schedule.type) { oldValue, newValue in
                // 切换类型时初始化默认值
                switch newValue {
                case .days:
                    if schedule.daysInterval == nil {
                        schedule.daysInterval = 3
                    }
                    schedule.weeklyDays = nil
                case .weekly:
                    if schedule.weeklyDays == nil {
                        schedule.weeklyDays = [.monday]
                    }
                    schedule.daysInterval = nil
                }
            }
            
            // 根据类型显示不同的编辑器
            switch schedule.type {
            case .days:
                daysEditor
            case .weekly:
                weeklyEditor
            }
        }
    }
    
    // MARK: - 每N天编辑器
    private var daysEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Stepper(value: Binding(
                get: { schedule.daysInterval ?? 3 },
                set: { schedule.daysInterval = $0 }
            ), in: 1...30) {
                let days = schedule.daysInterval ?? 3
                Text("Every \(days) day\(days > 1 ? "s" : "")")
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 每周N次编辑器
    private var weeklyEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 显示选择的天数
            HStack {
                Text("Selected:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                let count = schedule.weeklyDays?.count ?? 0
                Text("\(count) day\(count != 1 ? "s" : "") per week")
                    .font(.headline)
                    .foregroundColor(count > 0 ? .blue : .red)
            }
            
            Divider()
            
            // 星期选择器
            VStack(spacing: 8) {
                ForEach(Weekday.allCases, id: \.self) { day in
                    weekdayRow(day)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 星期行
    private func weekdayRow(_ day: Weekday) -> some View {
        Button {
            toggleWeekday(day)
        } label: {
            HStack {
                Image(systemName: isSelected(day) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected(day) ? .blue : .gray)
                    .font(.title3)
                
                Text(day.name)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(day.shortName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected(day) ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    private func isSelected(_ day: Weekday) -> Bool {
        schedule.weeklyDays?.contains(day) ?? false
    }
    
    private func toggleWeekday(_ day: Weekday) {
        if schedule.weeklyDays == nil {
            schedule.weeklyDays = []
        }
        
        if schedule.weeklyDays!.contains(day) {
            schedule.weeklyDays!.remove(day)
        } else {
            schedule.weeklyDays!.insert(day)
        }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var schedule = WateringSchedule.days(3)
    
    return NavigationView {
        Form {
            Section(header: Text("Watering Schedule")) {
                WateringScheduleEditor(schedule: $schedule)
            }
        }
        .navigationTitle("Test")
    }
}
