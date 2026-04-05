import Foundation
import UIKit

enum PhotoStorage {
    // MARK: - Public API

    static func savePhoto(_ imageData: Data) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let fileURL = photosDirectory.appendingPathComponent(filename)
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            return nil
        }
    }

    static func loadPhoto(_ filename: String) -> Data? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    static func loadImage(_ filename: String) -> UIImage? {
        guard let data = loadPhoto(filename) else { return nil }
        return UIImage(data: data)
    }

    static func deletePhoto(_ filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    static func deletePhotos(_ filenames: [String]) {
        filenames.forEach { deletePhoto($0) }
    }

    // MARK: - Storage Directory (iCloud first, local fallback)

    private static var photosDirectory: URL {
        let dir: URL

        // Try iCloud ubiquity container first
        if let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents/journal_photos") {
            dir = iCloudURL
        } else {
            // Fallback to local Documents
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            dir = docs.appendingPathComponent("journal_photos")
        }

        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}
