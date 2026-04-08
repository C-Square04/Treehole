import Foundation

enum AudioStorage {
    // MARK: - Public API

    static func saveAudio(_ data: Data) -> String? {
        let filename = UUID().uuidString + ".m4a"
        // Write to local first
        let localURL = localAudioDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: localURL)
        } catch {
            return nil
        }
        // Copy to iCloud ubiquity container if available
        if let iCloudDir = iCloudAudioDirectory {
            let iCloudURL = iCloudDir.appendingPathComponent(filename)
            try? FileManager.default.copyItem(at: localURL, to: iCloudURL)
        }
        return filename
    }

    static func loadAudioURL(filename: String) -> URL? {
        // Prefer local file
        let localURL = localAudioDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: localURL.path) {
            return localURL
        }
        // iCloud fallback
        if let iCloudDir = iCloudAudioDirectory {
            let iCloudURL = iCloudDir.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: iCloudURL.path) {
                return iCloudURL
            }
        }
        return nil
    }

    static func deleteAudio(filename: String) {
        let localURL = localAudioDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: localURL)
        if let iCloudDir = iCloudAudioDirectory {
            let iCloudURL = iCloudDir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: iCloudURL)
        }
    }

    // MARK: - Storage Directories

    static var localAudioDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("journal_audio")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private static var iCloudAudioDirectory: URL? {
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents/journal_audio") else {
            return nil
        }
        if !FileManager.default.fileExists(atPath: iCloudURL.path) {
            try? FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true)
        }
        return iCloudURL
    }
}
