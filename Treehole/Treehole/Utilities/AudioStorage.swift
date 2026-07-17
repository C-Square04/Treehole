import Foundation

enum AudioStorage {
    // MARK: - Public API

    nonisolated static func saveAudio(_ data: Data) -> String? {
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

    nonisolated static func loadAudioURL(filename: String) -> URL? {
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

    nonisolated static func deleteAudio(filename: String) {
        let localURL = localAudioDirectory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: localURL)
        if let iCloudDir = iCloudAudioDirectory {
            let iCloudURL = iCloudDir.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: iCloudURL)
        }
    }

    // MARK: - Storage Directories (cached — iCloud resolution does disk I/O)

    // Same caching pattern as PhotoStorage: url(forUbiquityContainerIdentifier:)
    // can perform disk I/O and take locks, and loadAudioURL is called from
    // view bodies — resolving on every render is wasteful. The iCloud cache
    // is keyed on ubiquityIdentityToken so iCloud sign-in/out mid-session
    // still switches directories exactly like the previous per-call resolution.
    nonisolated private static let directoryLock = NSLock()
    nonisolated(unsafe) private static var cachedLocalDirectory: URL?
    nonisolated(unsafe) private static var iCloudResolved = false
    nonisolated(unsafe) private static var cachedICloudDirectory: URL?
    nonisolated(unsafe) private static var cachedToken: (any NSCoding & NSCopying & NSObjectProtocol)?

    nonisolated static var localAudioDirectory: URL {
        directoryLock.lock()
        defer { directoryLock.unlock() }
        if let cached = cachedLocalDirectory { return cached }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("journal_audio")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        cachedLocalDirectory = dir
        return dir
    }

    private nonisolated static var iCloudAudioDirectory: URL? {
        directoryLock.lock()
        defer { directoryLock.unlock() }
        let token = FileManager.default.ubiquityIdentityToken
        if iCloudResolved, tokensMatch(token, cachedToken) { return cachedICloudDirectory }
        let dir = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents/journal_audio")
        if let dir, !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        cachedICloudDirectory = dir
        cachedToken = token
        iCloudResolved = true
        return dir
    }

    private nonisolated static func tokensMatch(
        _ a: (any NSCoding & NSCopying & NSObjectProtocol)?,
        _ b: (any NSCoding & NSCopying & NSObjectProtocol)?
    ) -> Bool {
        switch (a, b) {
        case (nil, nil): return true
        case let (a?, b?): return a.isEqual(b)
        default: return false
        }
    }
}
