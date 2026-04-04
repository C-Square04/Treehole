import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.hasCompletedOnboarding {
            MainTabView()
        } else {
            OnboardingFlowView()
        }
    }
}

// MARK: - Main Tab Navigation

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Clouds", systemImage: "cloud.fill", value: 0) {
                CloudPostListView()
            }
            Tab("Pet", systemImage: "cat.fill", value: 1) {
                PetHomeView()
            }
            Tab("Garden", systemImage: "leaf.fill", value: 2) {
                PlantGardenView()
            }
            Tab("Journal", systemImage: "book.fill", value: 3) {
                JournalView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: 4) {
                SettingsView()
            }
        }
        .tint(TreeholeTheme.softPurple)
    }
}

// MARK: - View Stubs (replaced incrementally)

// OnboardingView is defined in Views/Onboarding/OnboardingView.swift

// CloudPostListView is defined in Views/Cloud/

// PetHomeView is defined in Views/Pet/

// PlantGardenView is defined in Views/Plant/

// JournalView is defined in Views/Journal/

// SettingsView is defined in Views/Settings/

// LoginPromptView is defined in Views/Auth/
