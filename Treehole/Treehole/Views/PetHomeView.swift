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
                    VStack(spacing: 12) {
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
                                    .foregroundColor(TreeholeTheme.softPurple)
                            }
                        }

                        // Login Streak Bonus
                        HStack(spacing: 12) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Login Streak: \(economyViewModel.loginStreak) days")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                Text("Earn up to \(min(economyViewModel.loginStreak * 2, 25)) bonus stars daily")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(TreeholeTheme.warmGold.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(TreeholeTheme.glassLight)

                    // Pet Display Area
                    VStack(spacing: 20) {
                        // Pet Visual - Interactive 3D Cat
                        VStack(spacing: 12) {
                            InteractivePetView(
                                mood: viewModel.petState.mood,
                                showFeedingAnimation: viewModel.showFeedingAnimation
                            )
                            .frame(height: 280)

                            Text(viewModel.petState.mood.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(TreeholeTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(TreeholeTheme.glassLight)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)

                        // Status Bars
                        VStack(spacing: 12) {
                            StatusBar(label: "Hunger", value: viewModel.petState.hungerLevel, maxValue: 100, color: TreeholeTheme.coral)
                            StatusBar(label: "Energy", value: viewModel.petState.energy, maxValue: 100, color: TreeholeTheme.warmGold)
                            StatusBar(label: "Level", value: viewModel.petState.level, maxValue: 10, color: TreeholeTheme.softPurple)
                        }
                        .padding()
                        .background(TreeholeTheme.glassLight)
                        .cornerRadius(TreeholeTheme.cornerMedium)

                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .padding()

                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: "🍔", label: "Feed", color: TreeholeTheme.mintCream.opacity(0.8)) {
                            viewModel.feed()
                            _ = economyViewModel.spendFood(5)
                        }
                        ActionButton(icon: "👋", label: "Pet", color: TreeholeTheme.skyBlue.opacity(0.8)) {
                            viewModel.petWithReward(economyViewModel: economyViewModel)
                        }
                        ActionButton(icon: "😴", label: "Rest", color: TreeholeTheme.gentleLavender.opacity(0.8)) {
                            viewModel.rest()
                        }
                    }
                    .padding()
                    .background(TreeholeTheme.glassLight)
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
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 8) {
                Text(icon)
                    .font(.system(size: 32))
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(TreeholeTheme.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .cornerRadius(TreeholeTheme.cornerMedium)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
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
