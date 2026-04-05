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

        // Try CloudKit first, fall back to local-only
        do {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("CloudKit setup failed, falling back to local: \(error)")
            // Fall back to local storage
            let localConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                // Last resort: delete and recreate
                print("Local setup failed, recreating: \(error)")
                let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                if let appSupport = urls.first {
                    let storeURL = appSupport.appendingPathComponent("default.store")
                    try? FileManager.default.removeItem(at: storeURL)
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                    try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
                }
                do {
                    return try ModelContainer(for: schema, configurations: [localConfig])
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
