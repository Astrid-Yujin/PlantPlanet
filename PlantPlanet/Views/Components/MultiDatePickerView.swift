//
//  MultiDatePickerView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/30/25.
//

import SwiftUI

struct MultiDatePickerView: View {
    let initialSelectedDates: Set<Date>  // 添加初始日期参数
    let onComplete: (Set<Date>) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedDates: Set<Date> = []
    @State private var displayedMonth = Date()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 月份导航
                monthNavigationBar
                
                // 星期标题
                weekdayHeader
                
                // 日历网格
                ScrollView {
                    calendarGrid
                        .padding()
                }
                
                // 底部信息
                selectedDatesInfo
            }
            .navigationTitle("Select Dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onComplete(selectedDates)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedDates.isEmpty)
                }
            }
            .onAppear {
                // 初始化选中的日期
                selectedDates = initialSelectedDates
                
                // 如果有选中的日期，跳转到第一个日期所在的月份
                if let firstDate = initialSelectedDates.sorted().first {
                    displayedMonth = firstDate
                }
            }
        }
    }
    
    // MARK: - Month Navigation Bar
    
    private var monthNavigationBar: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(monthYearString)
                .font(.headline)
            
            Spacer()
            
            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Weekday Header
    
    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        let days = daysInMonth
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    DayCell(
                        date: date,
                        isSelected: isDateSelected(date),
                        isToday: Calendar.current.isDateInToday(date),
                        isFutureDate: date > Date()
                    ) {
                        toggleDate(date)
                    }
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
    }
    
    // MARK: - Selected Dates Info
    
    private var selectedDatesInfo: some View {
        VStack(spacing: 12) {
            if !selectedDates.isEmpty {
                Divider()
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("\(selectedDates.count) date\(selectedDates.count > 1 ? "s" : "") selected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Clear All") {
                        selectedDates.removeAll()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Helper Properties
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        return formatter.veryShortWeekdaySymbols
    }
    
    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: displayedMonth)!
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let daysCount = calendar.dateComponents([.day], from: interval.start, to: interval.end).day!
        
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        for day in 0..<daysCount {
            if let date = calendar.date(byAdding: .day, value: day, to: interval.start) {
                days.append(date)
            }
        }
        
        return days
    }
    
    // MARK: - Helper Methods
    
    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private func isDateSelected(_ date: Date) -> Bool {
        selectedDates.contains { calendar.isDate($0, inSameDayAs: date) }
    }
    
    private func toggleDate(_ date: Date) {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        
        if let existingDate = selectedDates.first(where: { calendar.isDate($0, inSameDayAs: date) }) {
            selectedDates.remove(existingDate)
        } else {
            selectedDates.insert(normalizedDate)
        }
    }
    
    private var calendar: Calendar {
        Calendar.current
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isFutureDate: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.body)
                .fontWeight(isToday ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(backgroundColor)
                .foregroundColor(foregroundColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .disabled(isFutureDate)
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else if isFutureDate {
            return Color.gray.opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }
    
    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isFutureDate {
            return .gray.opacity(0.3)
        } else {
            return .primary
        }
    }
}

// MARK: - Preview Helper
struct MultiDatePickerPreview: View {
    @State private var showingPicker = false
    @State private var selectedDates: Set<Date> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Multi-Date Picker Demo")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text("Selected: \(selectedDates.count) date\(selectedDates.count != 1 ? "s" : "")")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if !selectedDates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Dates:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ForEach(Array(selectedDates.sorted()), id: \.self) { date in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                Text(formatDate(date))
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                Button {
                    showingPicker = true
                } label: {
                    Label("Select Dates", systemImage: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                if !selectedDates.isEmpty {
                    Button {
                        selectedDates.removeAll()
                    } label: {
                        Text("Clear All")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
            .navigationTitle("Preview")
            .sheet(isPresented: $showingPicker) {
                // ✨ 传递当前选中的日期
                MultiDatePickerView(initialSelectedDates: selectedDates) { dates in
                    selectedDates = dates
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Previews
#Preview("Interactive Demo") {
    MultiDatePickerPreview()
}

#Preview("Direct View") {
    MultiDatePickerView(initialSelectedDates: [Date()]) { selectedDates in
        print("✅ Selected \(selectedDates.count) dates:")
        for date in selectedDates.sorted() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            print("  - \(formatter.string(from: date))")
        }
    }
}
