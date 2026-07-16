import Foundation

enum PhotoStorage {
    // MARK: - Public API

    static func savePhoto(_ imageData: Data) -> String? {
        let filename = UUID().uuidString + ".jpg"
        let dir = photosDirectory
        // Saves are rare — re-check cheaply so a directory that vanished
        // after resolution can never fail the write.
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let fileURL = dir.appendingPathComponent(filename)
        do {
            try imageData.write(to: fileURL)
            return filename
        } catch {
            return nil
        }
    }

    /// Display paths load via PhotoThumbnailLoader — never synchronously.
    nonisolated static func photoURL(_ filename: String) -> URL {
        photosDirectory.appendingPathComponent(filename)
    }

    static func deletePhoto(_ filename: String) {
        try? FileManager.default.removeItem(at: photoURL(filename))
    }

    static func deletePhotos(_ filenames: [String]) {
        filenames.forEach { deletePhoto($0) }
    }

    // MARK: - Storage Directory (iCloud first, local fallback)

    // url(forUbiquityContainerIdentifier:) can perform disk I/O and take
    // locks, so the directory is resolved once and reused. The cache is keyed
    // on ubiquityIdentityToken (cheap to read) so iCloud sign-in/out
    // mid-session still switches directories exactly like the previous
    // per-call resolution.
    nonisolated(unsafe) private static let directoryLock = NSLock()
    nonisolated(unsafe) private static var cachedDirectory: URL?
    nonisolated(unsafe) private static var cachedToken: (any NSCoding & NSCopying & NSObjectProtocol)?

    nonisolated static var photosDirectory: URL {
        directoryLock.lock()
        defer { directoryLock.unlock() }
        let token = FileManager.default.ubiquityIdentityToken
        if let cached = cachedDirectory, tokensMatch(token, cachedToken) {
            return cached
        }
        let dir = resolveDirectory()
        cachedDirectory = dir
        cachedToken = token
        return dir
    }

    nonisolated private static func tokensMatch(
        _ a: (any NSCoding & NSCopying & NSObjectProtocol)?,
        _ b: (any NSCoding & NSCopying & NSObjectProtocol)?
    ) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (a?, b?): return a.isEqual(b)
        default: return false
        }
    }

    nonisolated private static func resolveDirectory() -> URL {
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
