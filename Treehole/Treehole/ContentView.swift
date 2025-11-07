//
//  ContentView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    @StateObject private var petViewModel = PetViewModel()
    @StateObject private var journalViewModel = JournalViewModel()
    @StateObject private var plantViewModel = PlantViewModel()
    @StateObject private var cloudPostViewModel = CloudPostViewModel()
    @StateObject private var economyViewModel = EconomyViewModel()

    @State private var selectedTab: Tab = .clouds

    enum Tab {
        case clouds
        case pet
        case plant
        case journal
        case shop
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Clouds Tab
                CloudPostListView(viewModel: cloudPostViewModel, appState: appState)
                    .tag(Tab.clouds)
                    .tabItem {
                        Label("Clouds", systemImage: "cloud.fill")
                    }

                // Pet Tab
                PetHomeView(viewModel: petViewModel, economyViewModel: economyViewModel)
                    .tag(Tab.pet)
                    .tabItem {
                        Label("Pet", systemImage: "heart.fill")
                    }

                // Plant Tab
                PlantGardenView(viewModel: plantViewModel, economyViewModel: economyViewModel)
                    .tag(Tab.plant)
                    .tabItem {
                        Label("Garden", systemImage: "leaf.fill")
                    }

                // Journal Tab
                JournalListView(viewModel: journalViewModel, economyViewModel: economyViewModel)
                    .tag(Tab.journal)
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }

                // Shop Tab
                ShopView(economyViewModel: economyViewModel, petViewModel: petViewModel)
                    .tag(Tab.shop)
                    .tabItem {
                        Label("Shop", systemImage: "bag.fill")
                    }
            }

            // Login sheet overlay for guests
            if appState.isGuest && !appState.isAuthenticated {
                LoginPromptView(appState: appState)
                    .opacity(0.9)
            }
        }
        .environmentObject(appState)
        .environmentObject(petViewModel)
        .environmentObject(journalViewModel)
        .environmentObject(plantViewModel)
        .environmentObject(cloudPostViewModel)
        .environmentObject(economyViewModel)
    }
}

#Preview {
    ContentView()
}
