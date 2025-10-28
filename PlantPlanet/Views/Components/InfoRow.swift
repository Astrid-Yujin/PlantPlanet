//
//  InfoRow.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        InfoRow(label: "Name", value: "Rose")
        InfoRow(label: "Location", value: "Balcony")
    }
    .padding()
}