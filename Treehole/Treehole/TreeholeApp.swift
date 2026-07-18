import SwiftUI
import SwiftData

@main
struct TreeholeApp: App {
    @State private var appState = AppState()
    @State private var lockManager = PrivacyLockManager()
    @Environment(\.scenePhase) private var scenePhase

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
            ChatMessage.self, JournalSummary.self
        ])

        // Move stores aside instead of deleting — the data may be recoverable
        // (e.g. by a future app version with a proper migration).
        func moveStoresAside() {
            let fm = FileManager.default
            if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                if let files = try? fm.contentsOfDirectory(at: appSupport, includingPropertiesForKeys: nil) {
                    for file in files where file.lastPathComponent.contains(".store") {
                        let backup = appSupport.appendingPathComponent("Backup-" + file.lastPathComponent)
                        try? fm.removeItem(at: backup)
                        try? fm.moveItem(at: file, to: backup)
                    }
                }
            }
        }

        func makeContainer(cloudKit: Bool) throws -> ModelContainer {
            let config = cloudKit
                ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
                : ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        }

        // 1. CloudKit container
        do { return try makeContainer(cloudKit: true) }
        catch { print("CloudKit ModelContainer failed: \(error). Retrying...") }

        // 2. Retry once — the failure may be transient (CloudKit hiccup, disk pressure)
        do { return try makeContainer(cloudKit: true) }
        catch { print("CloudKit retry failed: \(error). Trying local-only...") }

        // 3. Same store without CloudKit — preserves data if CloudKit setup was the problem
        do { return try makeContainer(cloudKit: false) }
        catch { print("Local container failed: \(error). Moving stores aside and starting fresh...") }

        // 4. Last resort: the store itself won't open. Move it aside (never delete)
        //    and start with a fresh database.
        moveStoresAside()
        do { return try makeContainer(cloudKit: true) }
        catch {
            do { return try makeContainer(cloudKit: false) }
            catch { fatalError("Could not create ModelContainer: \(error)") }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(lockManager)
                .preferredColorScheme(
                    appState.colorSchemePreference == "dark" ? .dark :
                    appState.colorSchemePreference == "light" ? .light : nil
                )
                .onAppear {
                    appState.requestNotificationPermission()
                    NotificationService.scheduleAllNotifications()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        AnalyticsService.track("app_opened")
                        Task {
                            await NotificationService.checkUnreadInteractionsAndNotify()
                        }
                    } else if newPhase == .background {
                        // Re-lock protected sections whenever the app leaves the
                        // foreground, regardless of which screen is showing.
                        lockManager.lockAll()
                        // Hand the home-screen widget a fresh snapshot.
                        WidgetStateStore.pushSnapshot(
                            context: sharedModelContainer.mainContext,
                            language: appState.preferredLanguage
                        )
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

// NOTE: CloudKit sync is enabled. All @Model properties have inline defaults for compatibility.
