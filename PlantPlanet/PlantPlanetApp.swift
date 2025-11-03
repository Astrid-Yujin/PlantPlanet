//
//  PlantPlanetApp.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 9/29/25.
//

import SwiftUI
import SwiftData

@main
struct PlantApp: App {
    var body: some Scene {
        WindowGroup {
            PlantListView()
        }
        .modelContainer(for: [Plant.self, WateringLog.self])
    }
}
