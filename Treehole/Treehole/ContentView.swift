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
            Tab(L10n.t("Clouds", "云朵"), systemImage: "cloud.fill", value: 0) {
                CloudPostListView()
            }
            Tab(L10n.t("Pet", "宠物"), systemImage: "cat.fill", value: 1) {
                PetHomeView()
            }
            Tab(L10n.t("Garden", "花园"), systemImage: "leaf.fill", value: 2) {
                PlantGardenView()
            }
            Tab(L10n.t("Journal", "日记"), systemImage: "book.fill", value: 3) {
                JournalView()
            }
            Tab(L10n.t("Me", "我"), systemImage: "person.fill", value: 4) {
                MeView()
            }
        }
        .tint(TreeholeTheme.softPurple)
    }
}

// MARK: - Me Tab (Shop + Settings combined)

struct MeView: View {
    var body: some View {
        NavigationStack {
            List {
                // Quick links
                Section {
                    NavigationLink {
                        ShopView()
                    } label: {
                        Label(L10n.t("Shop & Tasks", "商店 & 任务"), systemImage: "bag.fill")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label(L10n.t("Settings", "设置"), systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle(L10n.t("Me", "我"))
        }
    }
}
