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
            Economy.self, DailyTask.self, WeeklyChallenge.self,
            ChatMessage.self
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

        // Try CloudKit first
        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("CloudKit ModelContainer failed: \(error). Deleting stores and retrying...")
            deleteAllStores()
            do {
                let config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                print("CloudKit retry failed: \(error). Falling back to local.")
                do {
                    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                    return try ModelContainer(for: schema, configurations: [config])
                } catch {
                    fatalError("Could not create ModelContainer: \(error)")
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

// NOTE: CloudKit sync is enabled. All @Model properties have inline defaults for compatibility.
