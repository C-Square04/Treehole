//
//  TasksPanelView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-07.
//

import SwiftUI

struct TasksPanelView: View {
    @ObservedObject var economyViewModel: EconomyViewModel
    @State private var selectedTab: TaskTab = .daily

    enum TaskTab {
        case daily
        case weekly
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
                    // Header with Stats
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tasks & Challenges")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Complete tasks to earn rewards")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }

                        // Quick Stats
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text("\(economyViewModel.completedTasksToday)")
                                    .font(.headline)
                                Text("Completed")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)

                            VStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("\(economyViewModel.pendingTasks.count)")
                                    .font(.headline)
                                Text("Pending")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)

                            VStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("\(economyViewModel.totalStarsEarned)")
                                    .font(.headline)
                                Text("Stars")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.white)

                    // Tab Selector
                    HStack(spacing: 0) {
                        TabSelectorButton(
                            title: "Daily Tasks",
                            icon: "calendar",
                            isSelected: selectedTab == .daily,
                            action: { selectedTab = .daily }
                        )
                        TabSelectorButton(
                            title: "Weekly Challenges",
                            icon: "flag.fill",
                            isSelected: selectedTab == .weekly,
                            action: { selectedTab = .weekly }
                        )
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)

                    // Content
                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedTab == .daily {
                                if economyViewModel.dailyTasks.isEmpty {
                                    EmptyStateView(
                                        icon: "checkmark.circle",
                                        title: "No Tasks Available",
                                        message: "Come back tomorrow for new tasks!"
                                    )
                                } else {
                                    ForEach(economyViewModel.dailyTasks) { task in
                                        TaskCardView(
                                            task: task,
                                            onComplete: {
                                                economyViewModel.completeDailyTask(task.id)
                                            }
                                        )
                                    }
                                }
                            } else {
                                if economyViewModel.weeklyChallenges.isEmpty {
                                    EmptyStateView(
                                        icon: "flag.circle",
                                        title: "No Challenges Available",
                                        message: "Check back next week!"
                                    )
                                } else {
                                    ForEach(economyViewModel.weeklyChallenges) { challenge in
                                        ChallengCard(
                                            challenge: challenge,
                                            onProgress: {
                                                economyViewModel.incrementChallengeProgress(challenge.id)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct TabSelectorButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue : Color.white)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(8)
        }
    }
}

struct TaskCardView: View {
    let task: DailyTask
    let onComplete: () -> Void
    @State private var isAnimating = false

    var rewardLabel: String {
        var rewards = [String]()
        if task.reward.food > 0 {
            rewards.append("\(task.reward.food) Food")
        }
        if task.reward.decorationToken > 0 {
            rewards.append("\(task.reward.decorationToken) ⭐")
        }
        return rewards.joined(separator: " + ")
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(task.title, systemImage: "square.and.pencil")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
                if task.completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            isAnimating = true
                            onComplete()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isAnimating = false
                            }
                        }
                    }) {
                        Image(systemName: "circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !rewardLabel.isEmpty {
                HStack {
                    Label(rewardLabel, systemImage: "gift.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                    if let completedAt = task.completedAt {
                        Text(completedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(task.completed ? Color.green.opacity(0.1) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(task.completed ? Color.green : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isAnimating ? 0.95 : 1.0)
    }
}

struct ChallengCard: View {
    let challenge: WeeklyChallenge
    let onProgress: () -> Void
    @State private var showProgressAnimation = false

    var progressPercentage: Double {
        guard challenge.targetCount > 0 else { return 0 }
        return Double(challenge.currentCount) / Double(challenge.targetCount)
    }

    var rewardLabel: String {
        var rewards = [String]()
        if challenge.reward.food > 0 {
            rewards.append("\(challenge.reward.food) Food")
        }
        if challenge.reward.decorationToken > 0 {
            rewards.append("\(challenge.reward.decorationToken) ⭐")
        }
        return rewards.joined(separator: " + ")
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Label(challenge.title, systemImage: "flag.circle.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(challenge.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                Spacer()
                if challenge.isCompleted {
                    Image(systemName: "star.circle.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            showProgressAnimation = true
                            onProgress()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showProgressAnimation = false
                            }
                        }
                    }) {
                        Text("+1")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                }
            }

            // Progress Bar
            VStack(spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(challenge.currentCount)/\(challenge.targetCount)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue,
                                        Color.blue.opacity(0.7)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage)
                    }
                }
                .frame(height: 8)
            }

            if !rewardLabel.isEmpty {
                HStack {
                    Label(rewardLabel, systemImage: "gift.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
        .padding()
        .background(challenge.isCompleted ? Color.yellow.opacity(0.1) : Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(challenge.isCompleted ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    TasksPanelView(economyViewModel: EconomyViewModel())
}
