//
//  PhotoManager.swift
//  PlantPlanet
//
//  Created by Yujin Wang on 10/28/25.
//


import SwiftUI

class PhotoManager {
    static let shared = PhotoManager()
    
    private let photosDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("PlantPhotos", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: photosPath.path) {
            try? FileManager.default.createDirectory(at: photosPath, withIntermediateDirectories: true)
        }
        
        return photosPath
    }()
    
    // MARK: - Public Methods
    
    func savePhoto(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)
        
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            print("Failed to save photo: \(error)")
            return nil
        }
    }
    
    func loadPhoto(_ filename: String) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        guard let imageData = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    func deletePhoto(_ filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func deletePhotos(_ filenames: [String]) {
        filenames.forEach { deletePhoto($0) }
    }
    
    // MARK: - Helper Methods
    
    func getPhotoSize(_ filename: String) -> Int64 {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attributes?[.size] as? Int64 ?? 0
    }
    
    func getTotalPhotoSize() -> Int64 {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: photosDirectory.path) else {
            return 0
        }
        return files.reduce(0) { $0 + getPhotoSize($1) }
    }
}