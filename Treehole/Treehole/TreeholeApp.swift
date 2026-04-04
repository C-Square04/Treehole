import SwiftUI
import SwiftData

@main
struct TreeholeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .onAppear {
                    appState.requestNotificationPermission()
                }
        }
        .modelContainer(for: [CloudPost.self, Pet.self, Plant.self, JournalEntry.self, Economy.self, DailyTask.self])
    }
}
