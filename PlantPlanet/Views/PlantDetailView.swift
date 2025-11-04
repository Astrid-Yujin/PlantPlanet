//
//  PlantDetailView.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Bindable var plant: Plant
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditSheet = false
    @State private var showingWateringHistory = false
    @State private var showingAddWateringLog = false
    @State private var selectedPhotoIndex: Int = 0
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 主内容区域
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    photosCarousel
                    wateringStatusSection
                    basicInfoSection
                    notesSection
                    wateringHistorySection
                }
                .padding(.bottom, 100)
            }
            floatingWaterButton

        }
        .navigationTitle(plant.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPlantView(plant: plant)
        }
        .sheet(isPresented: $showingAddWateringLog) {
            AddWateringLogView(plant: plant)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var photosCarousel: some View {
        if !plant.photoFilenames.isEmpty {
            TabView(selection: $selectedPhotoIndex) {
                ForEach(Array(plant.photoFilenames.enumerated()), id: \.offset) { index, filename in
                    if let image = PhotoManager.shared.loadPhoto(filename) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 300)
            .background(Color.gray.opacity(0.1))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No photos yet")
                            .foregroundColor(.secondary)
                    }
                )
                .padding()
        }
    }
    
    private var floatingWaterButton: some View {
        VStack(spacing: 0) {
            // 渐变遮罩，让按钮看起来更自然
            LinearGradient(
                colors: [Color.clear, Color(.systemBackground).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 30)
            
            VStack(spacing: 12) {
                Button {
                    addWateringLog()
                } label: {
                    HStack(spacing: 12) {
                        Spacer()
                        
                        Image(systemName: wateredToday ? "checkmark.circle.fill" : "drop.fill")
                            .font(.title3)
                        
                        Text(wateredToday ? "Already Watered Today" : "Water Now")
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(buttonBackground)
                    .foregroundColor(buttonForeground)
                    .cornerRadius(16)
                    .shadow(color: wateredToday ? Color.clear : Color.black.opacity(0.15), radius: 10, y: 5)
                }
                .disabled(wateredToday)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: wateredToday)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(Color(.systemBackground))
        }
    }
    
    private var wateringStatusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watering Status")
                .font(.headline)
                .padding(.horizontal)
            
            WateringStatusView(plant: plant, compact: false)
                .padding(.horizontal)
        }
    }
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            InfoRow(label: "Name", value: plant.name)
            InfoRow(label: "Species", value: plant.species)
            InfoRow(label: "Location", value: plant.location)
            InfoRow(label: "Watering", value: plant.wateringSchedule.description)
            InfoRow(label: "Created", value: plant.createdAt.formatted(date: .abbreviated, time: .omitted))
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    @ViewBuilder
    private var notesSection: some View {
        if !plant.notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                    .padding(.horizontal)
                Text(plant.notes)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
        }
    }
    
    private var wateringHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Watering History")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddWateringLog = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if plant.wateringLogs.isEmpty {
                Text("No watering records yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                ForEach(plant.wateringLogs.sorted(by: { $0.date > $1.date }).prefix(5)) { log in
                    WateringLogRow(log: log)
                }
                .padding(.horizontal)
                
                if plant.wateringLogs.count > 5 {
                    Button("View All (\(plant.wateringLogs.count))") {
                        showingWateringHistory = true
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    // 检查今天是否已经浇水
    private var wateredToday: Bool {
        guard let lastDate = plant.lastWateringDate else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(lastDate)
    }
    
    // 按钮背景色
    private var buttonBackground: Color {
        if wateredToday {
            return Color(.systemGray5)
        } else if plant.needsWatering {
            return Color.blue
        } else {
            return Color.green
        }
    }
    
    // 按钮前景色
    private var buttonForeground: Color {
        wateredToday ? Color.secondary : Color.white
    }
    
    // 下次浇水文本
    private var nextWateringText: String {
        guard let nextDate = plant.nextWateringDate else {
            return "Not scheduled"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextDate)
    }
    
    // MARK: - Actions
    
    private func addWateringLog() {
        let log = WateringLog(date: Date(), notes: "")
        plant.wateringLogs.append(log)
    }
}

// MARK: - 浇水记录行
struct WateringLogRow: View {
    let log: WateringLog
    
    var body: some View {
        HStack {
            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDate(log.date))
                    .font(.subheadline)
                
                if !log.notes.isEmpty {
                    Text(log.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(relativeTime(log.date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) week\(weeks > 1 ? "s" : "") ago"
        } else {
            let months = days / 30
            return "\(months) month\(months > 1 ? "s" : "") ago"
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationView {
        PlantDetailView(plant: Plant(
            name: "Test Plant",
            species: "Rose",
            location: "Balcony",
            wateringSchedule: .days(3)
        ))
    }
    .modelContainer(for: Plant.self, inMemory: true)
}
