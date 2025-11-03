//
//  WateringLog.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/29/25.
//


import Foundation
import SwiftData

@Model
final class WateringLog {
    var id: UUID
    var date: Date
    var notes: String
    
    // 关系：属于哪个植物
    var plant: Plant?
    
    init(id: UUID = UUID(), date: Date = Date(), notes: String = "") {
        self.id = id
        self.date = date
        self.notes = notes
    }
}