//
//  AddWateringLogView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/30/25.
//

import SwiftUI
import SwiftData

struct DateTimePair: Identifiable {
    let id = UUID()
    var date: Date
    var time: Date
    
    var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 8,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: calendar.date(from: dateComponents) ?? date
        ) ?? date
    }
}

struct AddWateringLogView: View {
    @Bindable var plant: Plant
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var dateTimePairs: [DateTimePair] = [
        DateTimePair(date: Date(), time: Date())
    ]
    @State private var notes = ""
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            Form {
                // ✨ 浇水记录（带 Calendar 按钮在标题）
                Section {
                    ForEach($dateTimePairs) { $pair in
                        HStack(spacing: 16) {
                            // 日期显示（只读）
                            HStack(spacing: 8) {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .font(.body)
                                
                                Text(formatDateOnly(pair.date))
                                    .font(.body)
                            }
                            
                            Spacer()
                            
                            // 时间部分（带图标和菜单）
                            HStack(spacing: 8) {
                                DatePicker(
                                    "Time",
                                    selection: $pair.time,
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()
                                
                                
                                // 快捷菜单
                                Menu {
                                    Button {
                                        setTime(hour: 8, minute: 0, for: $pair)
                                    } label: {
                                        Label("Morning (8:00 AM)", systemImage: "sunrise.fill")
                                    }
                                    
                                    Button {
                                        setTime(hour: 12, minute: 0, for: $pair)
                                    } label: {
                                        Label("Noon (12:00 PM)", systemImage: "sun.max.fill")
                                    }
                                    
                                    Button {
                                        setTime(hour: 18, minute: 0, for: $pair)
                                    } label: {
                                        Label("Evening (6:00 PM)", systemImage: "sunset.fill")
                                    }
                                    
                                    Button {
                                        setTime(hour: 21, minute: 0, for: $pair)
                                    } label: {
                                        Label("Night (9:00 PM)", systemImage: "moon.fill")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .foregroundColor(.blue)
                                        .imageScale(.large)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onDelete(perform: deletePair)
                } header: {
                    // 自定义标题（带 Calendar 按钮）
                    HStack {
                        Text("Watering Records")
                        
                        Spacer()
                        
                        // ✨ Calendar 按钮
                        Button {
                            showingDatePicker = true
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(.blue)
                                .imageScale(.large)
                        }
                    }
                }
                
                // ✨ 常用时间
                if !commonTimes.isEmpty {
                    Section(header: Text("Common Times")) {
                        ForEach(Array(commonTimes.enumerated()), id: \.offset) { index, time in
                            Button {
                                applyTimeToAll(hour: time.hour, minute: time.minute)
                            } label: {
                                HStack(spacing: 12) {
                                    // 图标
                                    ZStack {
                                        Circle()
                                            .fill(Color.purple.opacity(0.1))
                                            .frame(width: 36, height: 36)
                                        
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.purple)
                                            .font(.body)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatTimeDescription(hour: time.hour, minute: time.minute))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        Text(formatTime(hour: time.hour, minute: time.minute))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                // 快速时间选择
                Section(header: Text("Quick Time Presets")) {
                    
                    HStack(spacing: 8) {
                        Button {
                            applyTimeToAll(hour: 8, minute: 0)
                        } label: {
                            quickTimeCard(
                                title: "Morning",
                                time: "8:00 AM",
                                icon: "sunrise.fill",
                                gradient: [Color.orange.opacity(0.7), Color.orange]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            applyTimeToAll(hour: 12, minute: 0)
                        } label: {
                            quickTimeCard(
                                title: "Noon",
                                time: "12:00 PM",
                                icon: "sun.max.fill",
                                gradient: [Color.yellow.opacity(0.7), Color.yellow]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            applyTimeToAll(hour: 18, minute: 0)
                        } label: {
                            quickTimeCard(
                                title: "Evening",
                                time: "6:00 PM",
                                icon: "sunset.fill",
                                gradient: [Color.purple.opacity(0.7), Color.purple]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            applyTimeToAll(hour: 21, minute: 0)
                        } label: {
                            quickTimeCard(
                                title: "Night",
                                time: "9:00 PM",
                                icon: "moon.fill",
                                gradient: [Color.indigo.opacity(0.7), Color.indigo]
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // 备注
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Watering Records")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLogs()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                MultiDatePickerView(
                    initialSelectedDates: Set(dateTimePairs.map { $0.date })
                ) { selectedDates in
                    handleCalendarSelection(selectedDates)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var commonTimes: [(hour: Int, minute: Int)] {
        let recentLogs = plant.wateringLogs
            .sorted(by: { $0.date > $1.date })
            .prefix(10)
        
        let calendar = Calendar.current
        let times = recentLogs.map { log -> (hour: Int, minute: Int) in
            let components = calendar.dateComponents([.hour, .minute], from: log.date)
            return (hour: components.hour ?? 0, minute: components.minute ?? 0)
        }
        
        var timeFrequency: [String: (time: (hour: Int, minute: Int), count: Int)] = [:]
        
        for time in times {
            let key = "\(time.hour):\(time.minute)"
            if let existing = timeFrequency[key] {
                timeFrequency[key] = (time: existing.time, count: existing.count + 1)
            } else {
                timeFrequency[key] = (time: time, count: 1)
            }
        }
        
        return timeFrequency.values
            .filter { $0.count >= 2 }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0.time }
    }
    
    // MARK: - Custom Card Views
    
    // 快速时间卡片（渐变样式）
    private func quickTimeCard(
        title: String,
        time: String,
        icon: String,
        gradient: [Color],
    ) -> some View {
        VStack(spacing: 8) {
             Image(systemName: icon)
                 .font(.title2)
                 .foregroundColor(.white)
             
             Text(title)
                 .font(.subheadline)
                 .fontWeight(.semibold)
                 .foregroundColor(.white)
             
             Text(time)
                 .font(.caption2)
                 .foregroundColor(.white.opacity(0.9))
         }
         .frame(maxWidth: .infinity)
         .frame(height: 100)
         .background(
             LinearGradient(
                 colors: gradient,
                 startPoint: .topLeading,
                 endPoint: .bottomTrailing
             )
         )
         .cornerRadius(12)
         .shadow(color: gradient[1].opacity(0.3), radius: 4, y: 2)
    }
    
    // MARK: - Helper Methods
    
    // 为单个记录设置时间
    private func setTime(hour: Int, minute: Int, for pair: Binding<DateTimePair>) {
        let calendar = Calendar.current
        if let newTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: pair.wrappedValue.time) {
            pair.wrappedValue.time = newTime
        }
    }
    
    // 应用时间到所有记录（添加调试信息）
    private func applyTimeToAll(hour: Int, minute: Int) {
        let calendar = Calendar.current
        for index in dateTimePairs.indices {
            if let newTime = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dateTimePairs[index].time) {
                dateTimePairs[index].time = newTime
            }
        }
    }
    
    // 格式化日期（只显示日期，不显示时间）
    private func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    // 处理日历选择
    private func handleCalendarSelection(_ selectedDates: Set<Date>) {
        _ = Calendar.current
        
        // 如果没有选择日期，至少保留一个今天的日期
        guard !selectedDates.isEmpty else {
            if dateTimePairs.isEmpty {
                dateTimePairs = [DateTimePair(date: Date(), time: Date())]
            }
            return
        }
        
        let defaultTime = dateTimePairs.first?.time ?? Date()
        
        // 清空现有记录
        dateTimePairs.removeAll()
        
        // 为每个选中的日期创建记录
        for date in selectedDates.sorted() {
            dateTimePairs.append(DateTimePair(date: date, time: defaultTime))
        }
    }
    
    // 删除日期时间对
    private func deletePair(at offsets: IndexSet) {
        if dateTimePairs.count > 1 {
            dateTimePairs.remove(atOffsets: offsets)
        }
    }
    
    private func formatTime(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        let calendar = Calendar.current
        if let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) {
            return formatter.string(from: date)
        }
        
        return "\(hour):\(String(format: "%02d", minute))"
    }
    
    private func formatTimeDescription(hour: Int, minute: Int) -> String {
        switch hour {
        case 5..<8:
            return "Early Morning"
        case 8..<12:
            return "Morning"
        case 12:
            return "Noon"
        case 13..<17:
            return "Afternoon"
        case 17..<20:
            return "Evening"
        case 20..<24, 0..<5:
            return "Night"
        default:
            return "Custom Time"
        }
    }
    
    // 批量保存
    private func saveLogs() {
        for pair in dateTimePairs {
            let finalDate = pair.combinedDateTime
            let log = WateringLog(
                date: finalDate,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            plant.wateringLogs.append(log)
        }
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    AddWateringLogView(plant: Plant(
        name: "Test Plant",
        species: "Rose",
        location: "Balcony",
        wateringSchedule: .days(3)
    ))
    .modelContainer(for: Plant.self, inMemory: true)
}
