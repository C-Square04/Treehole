import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingFlowView()
            }
        }
        .onAppear {
            #if DEBUG
            UITestSupport.applyLaunchOverridesIfNeeded(context: modelContext)
            #endif
        }
    }
}

// MARK: - Main Tab Navigation

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CloudPostListView()
                .tabItem { Label(L10n.t("Clouds", "云朵"), systemImage: "cloud.fill") }
                .tag(0)
            PetHomeView()
                .tabItem { Label(L10n.t("Pet", "宠物"), systemImage: "cat.fill") }
                .tag(1)
            PlantGardenView()
                .tabItem { Label(L10n.t("Garden", "花园"), systemImage: "leaf.fill") }
                .tag(2)
            JournalView()
                .tabItem { Label(L10n.t("Journal", "日记"), systemImage: "book.fill") }
                .tag(3)
            MeView()
                .tabItem { Label(L10n.t("Me", "我"), systemImage: "person.fill") }
                .tag(4)
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
