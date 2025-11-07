//
//  ShopView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var economyViewModel: EconomyViewModel
    @ObservedObject var petViewModel: PetViewModel
    @State private var selectedTab: ShopTab = .food

    enum ShopTab {
        case food
        case decorations
        case tasks
        case rewards
    }

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

                VStack(spacing: 0) {
                    // Header with currency
                    VStack(spacing: 12) {
                        HStack {
                            Text("Shop")
                                .font(.title2)
                                .fontWeight(.bold)
                            Spacer()
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "carrot.fill")
                                        .foregroundColor(.orange)
                                    Text("\(economyViewModel.economy.food)")
                                        .font(.headline)
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("\(economyViewModel.economy.decorationToken)")
                                        .font(.headline)
                                }
                            }
                        }

                        // Tab selector
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ShopTabButton(
                                    title: "Food",
                                    icon: "🍔",
                                    isSelected: selectedTab == .food,
                                    action: { selectedTab = .food }
                                )
                                ShopTabButton(
                                    title: "Decor",
                                    icon: "🏠",
                                    isSelected: selectedTab == .decorations,
                                    action: { selectedTab = .decorations }
                                )
                                ShopTabButton(
                                    title: "Tasks",
                                    icon: "✓",
                                    isSelected: selectedTab == .tasks,
                                    action: { selectedTab = .tasks }
                                )
                                ShopTabButton(
                                    title: "Rewards",
                                    icon: "⭐",
                                    isSelected: selectedTab == .rewards,
                                    action: { selectedTab = .rewards }
                                )
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)

                    // Content
                    Group {
                        switch selectedTab {
                        case .food:
                            FoodShopView(economyViewModel: economyViewModel)
                        case .decorations:
                            DecorationsShopView(economyViewModel: economyViewModel, petViewModel: petViewModel)
                        case .tasks:
                            TasksShopView(economyViewModel: economyViewModel)
                        case .rewards:
                            RewardsListView(economyViewModel: economyViewModel)
                        }
                    }
                }
            }
        }
    }
}

struct ShopTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(icon)
                    .font(.headline)
                Text(title)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(UIColor.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(6)
        }
    }
}

struct FoodShopView: View {
    @ObservedObject var economyViewModel: EconomyViewModel

    let foodItems = [
        (name: "Small Snack", amount: 10, price: 10),
        (name: "Regular Meal", amount: 30, price: 25),
        (name: "Feast", amount: 100, price: 75),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(foodItems, id: \.name) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.headline)
                            Text("+ \(item.amount) food")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            economyViewModel.addFood(item.amount)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "carrot.fill")
                                Text("\(item.price)")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct DecorationsShopView: View {
    @ObservedObject var economyViewModel: EconomyViewModel
    @ObservedObject var petViewModel: PetViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(petViewModel.decorations) { decoration in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(decoration.name)
                                .font(.headline)
                            Text(decoration.description)
                                .font(.caption)
                                .foregroundColor(.gray)
                            HStack(spacing: 4) {
                                Text(decoration.category.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(decoration.rarity.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                            }
                        }
                        Spacer()
                        Button(action: {
                            if petViewModel.purchaseDecoration(decoration.id, with: &economyViewModel.economy) {
                                economyViewModel.saveEconomy()
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("\(decoration.price)")
                            }
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.yellow)
                            .cornerRadius(6)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
}

struct TasksShopView: View {
    @ObservedObject var economyViewModel: EconomyViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Daily Tasks & Weekly Challenges")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(economyViewModel.pendingTasks) { task in
                        TaskItemView(task: task, economyViewModel: economyViewModel)
                    }
                }
                .padding()

                Text("Weekly Challenges")
                    .font(.headline)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(economyViewModel.weeklyChallenges) { challenge in
                        WeeklyChallengeItemView(challenge: challenge, economyViewModel: economyViewModel)
                    }
                }
                .padding()
            }
        }
    }
}

struct TaskItemView: View {
    let task: DailyTask
    @ObservedObject var economyViewModel: EconomyViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(spacing: 8) {
                    if task.reward.food > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "carrot.fill")
                            Text("+\(task.reward.food)")
                        }
                        .font(.caption2)
                        .foregroundColor(.orange)
                    }
                    if task.reward.decorationToken > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                            Text("+\(task.reward.decorationToken)")
                        }
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    }
                }
            }
            Spacer()
            if task.completed {
                Label("Done", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Button(action: {
                    economyViewModel.completeDailyTask(task.id)
                }) {
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct WeeklyChallengeItemView: View {
    let challenge: WeeklyChallenge
    @ObservedObject var economyViewModel: EconomyViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(challenge.title)
                .font(.headline)
            Text(challenge.description)
                .font(.caption)
                .foregroundColor(.gray)

            ProgressView(value: challenge.progress)
                .tint(.blue)

            HStack {
                Text("\(challenge.currentCount)/\(challenge.targetCount)")
                    .font(.caption2)
                Spacer()
                if challenge.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

#Preview {
    ShopView(economyViewModel: EconomyViewModel(), petViewModel: PetViewModel())
}
