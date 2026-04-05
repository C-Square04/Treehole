import SwiftUI
import SwiftData

@main
struct TreeholeApp: App {
    @State private var appState = AppState()
    @State private var lockManager = PrivacyLockManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CloudPost.self, Pet.self, Plant.self,
            JournalEntry.self, Economy.self, DailyTask.self,
            WeeklyChallenge.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Schema migration failed — delete old store and retry
            print("SwiftData migration failed: \(error). Recreating store...")
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                // Also remove WAL and SHM files
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            }
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer after reset: \(error)")
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
