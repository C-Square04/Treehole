import SwiftUI
import SwiftData

@main
struct TreeholeApp: App {
    @State private var appState = AppState()
    @State private var lockManager = PrivacyLockManager()

    // IMPORTANT: User must enable these in Xcode:
    // 1. Target → Signing & Capabilities → + Capability → "Sign in with Apple"
    // 2. Target → Signing & Capabilities → + Capability → "iCloud" → Check "CloudKit"
    //    → Add container: "iCloud.com.Toki.Treehole"
    // 3. Target → Signing & Capabilities → + Capability → "Push Notifications"
    // 4. Select your Development Team in Signing

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Pet.self, Plant.self, JournalEntry.self,
            Economy.self, DailyTask.self, WeeklyChallenge.self
        ])

        // Helper to delete all SwiftData stores
        func deleteAllStores() {
            let fm = FileManager.default
            if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                // Delete all .store files and related files
                if let files = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
                    for file in files where file.lastPathComponent.contains(".store") {
                        try? fm.removeItem(at: file)
                    }
                }
            }
        }

        // Step 1: Try local-only first (most reliable)
        // CloudKit can be enabled later once schema is stable
        let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [localConfig])
        } catch {
            print("Local ModelContainer failed: \(error). Deleting store and retrying...")
            deleteAllStores()
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                // Absolute last resort: in-memory only (no persistence, but no crash)
                print("Recreate also failed: \(error). Using in-memory store.")
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [memoryConfig])
                } catch {
                    fatalError("Could not create any ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(lockManager)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .onAppear {
                    appState.requestNotificationPermission()
                    NotificationService.scheduleDailyCheckIn()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// NOTE: CloudKit sync is temporarily disabled to ensure stability.
// To re-enable later (when schema is stable):
// 1. Change ModelConfiguration to: cloudKitDatabase: .automatic
// 2. Ensure ALL @Model properties have defaults or are optional
// 3. Test on a fresh install first
