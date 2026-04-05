import Foundation
import UIKit

enum PhotoStorage {
    // MARK: - Public API

    /// Save photo data to the journal_photos directory.
    /// Returns the filename (UUID-based) on success, or nil on failure.
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

    /// Load raw photo data from a filename.
    static func loadPhoto(_ filename: String) -> Data? {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    /// Load a UIImage from a filename.
    static func loadImage(_ filename: String) -> UIImage? {
        guard let data = loadPhoto(filename) else { return nil }
        return UIImage(data: data)
    }

    /// Delete a single photo file.
    static func deletePhoto(_ filename: String) {
        let fileURL = photosDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Delete multiple photo files.
    static func deletePhotos(_ filenames: [String]) {
        for filename in filenames {
            deletePhoto(filename)
        }
    }

    // MARK: - Private

    /// The journal_photos directory inside the app's Documents folder.
    /// Created on first access if it does not yet exist.
    private static var photosDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("journal_photos")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}
