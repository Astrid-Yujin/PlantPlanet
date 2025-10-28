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
    var wateringFrequency: Int
    
    init(id: UUID = UUID(), 
         name: String, 
         species: String, 
         location: String, 
         createdAt: Date = Date(), 
         photoFilenames: [String] = [], 
         notes: String = "", 
         groupIds: [UUID] = [], 
         wateringFrequency: Int = 3) {
        self.id = id
        self.name = name
        self.species = species
        self.location = location
        self.createdAt = createdAt
        self.photoFilenames = photoFilenames
        self.notes = notes
        self.groupIds = groupIds
        self.wateringFrequency = wateringFrequency
    }
}