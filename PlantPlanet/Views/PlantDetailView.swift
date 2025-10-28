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
    @State private var showingEditSheet = false
    @State private var selectedPhotoIndex: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                photosCarousel
                basicInfoSection
                notesSection
            }
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
