//
//  PlantPlanetApp.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 9/29/25.
//

import SwiftUI
import CoreData

@main
struct PlantPlanetApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
