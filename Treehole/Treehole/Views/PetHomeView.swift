//
//  PetHomeView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct PetHomeView: View {
    @ObservedObject var viewModel: PetViewModel
    @ObservedObject var economyViewModel: EconomyViewModel
    @State private var showDecorationShop: Bool = false
    @State private var showLevelUp: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background based on theme
                backgroundForTheme(viewModel.petState.homeTheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with economy info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.petState.name)
                                .font(.headline)
                            HStack(spacing: 12) {
                                Label("\(economyViewModel.economy.food)", systemImage: "carrot.fill")
                                    .font(.caption)
                                Label("\(economyViewModel.economy.decorationToken)", systemImage: "star.fill")
                                    .font(.caption)
                            }
                        }
                        Spacer()
                        Button(action: { showDecorationShop = true }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))

                    // Pet Display Area
                    VStack(spacing: 20) {
                        // Pet Visual
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 200, height: 200)

                            VStack(spacing: 10) {
                                // Pet emoji representation
                                Text("🐱")
                                    .font(.system(size: 80))
                                    .scaleEffect(viewModel.showFeedingAnimation ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: viewModel.showFeedingAnimation)

                                Text(viewModel.petState.mood.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        // Status Bars
                        VStack(spacing: 12) {
                            StatusBar(label: "Hunger", value: viewModel.petState.hungerLevel, maxValue: 100, color: .orange)
                            StatusBar(label: "Energy", value: viewModel.petState.energy, maxValue: 100, color: .yellow)
                            StatusBar(label: "Level", value: viewModel.petState.level, maxValue: 10, color: .blue)
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)

                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .padding()

                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: "🍔", label: "Feed", color: .green) {
                            viewModel.feed()
                            _ = economyViewModel.spendFood(5)
                        }
                        ActionButton(icon: "👋", label: "Pet", color: .blue) {
                            viewModel.pet()
                        }
                        ActionButton(icon: "😴", label: "Rest", color: .purple) {
                            viewModel.rest()
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.95))
                }
            }
            .sheet(isPresented: $showDecorationShop) {
                PetDecorationsView(viewModel: viewModel, economyViewModel: economyViewModel)
            }
        }
    }

    private func backgroundForTheme(_ theme: PetState.HomeTheme) -> some View {
        Group {
            switch theme {
            case .daylight:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.7, green: 0.9, blue: 1.0),
                        Color(red: 0.95, green: 0.97, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .night:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.2, green: 0.2, blue: 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .sunset:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.7, blue: 0.5),
                        Color(red: 1.0, green: 0.9, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .garden:
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.6, green: 0.9, blue: 0.6),
                        Color(red: 0.9, green: 0.95, blue: 0.85)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
}

struct StatusBar: View {
    let label: String
    let value: Int
    let maxValue: Int
    let color: Color

    var progress: Double {
        Double(value) / Double(maxValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(value)/\(maxValue)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct PetDecorationsView: View {
    @ObservedObject var viewModel: PetViewModel
    @ObservedObject var economyViewModel: EconomyViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 0.97)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack {
                    HStack {
                        Text("Home Decorations")
                            .font(.headline)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)

                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.decorations) { decoration in
                                DecorationItemView(
                                    decoration: decoration,
                                    isOwned: viewModel.petState.decorations.contains(decoration.id),
                                    action: {
                                        if viewModel.purchaseDecoration(decoration.id, with: &economyViewModel.economy) {
                                            economyViewModel.saveEconomy()
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    private func saveEconomy() {
        if let encoded = try? JSONEncoder().encode(economyViewModel.economy) {
            UserDefaults.standard.set(encoded, forKey: "economy")
        }
    }
}

struct DecorationItemView: View {
    let decoration: HomeDecoration
    let isOwned: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(decoration.name)
                    .font(.headline)
                Text(decoration.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(spacing: 8) {
                    Text(decoration.category.rawValue.capitalized)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    Text(decoration.rarity.rawValue.capitalized)
                        .font(.caption2)
                        .padding(4)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            Spacer()
            if isOwned {
                Text("Owned")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Button(action: action) {
                    Text("\(decoration.price)")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    PetHomeView(viewModel: PetViewModel(), economyViewModel: EconomyViewModel())
}
