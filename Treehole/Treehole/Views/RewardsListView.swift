//
//  RewardsListView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-07.
//

import SwiftUI

struct RewardsListView: View {
    @ObservedObject var economyViewModel: EconomyViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Daily Login Bonus
                RewardCardView(
                    icon: "🎁",
                    title: "Daily Login Bonus",
                    description: "Earn 5 stars base + 2 stars per day streak",
                    earnedToday: economyViewModel.loginStreak > 0,
                    bonus: "Current: +\(min(economyViewModel.loginStreak * 2 + 5, 30)) stars",
                    iconColor: .orange
                )

                // Daily Tasks
                RewardCardView(
                    icon: "✓",
                    title: "Daily Tasks",
                    description: "Complete daily activities to earn stars",
                    earnedToday: economyViewModel.completedTasksToday > 0,
                    bonus: "Up to 57 stars per day",
                    iconColor: .green
                )

                // Weekly Challenges
                RewardCardView(
                    icon: "🏆",
                    title: "Weekly Challenges",
                    description: "Complete weekly challenges for bonus rewards",
                    earnedToday: false,
                    bonus: "30-80 stars per challenge",
                    iconColor: .blue
                )

                // Pet Interaction
                RewardCardView(
                    icon: "👋",
                    title: "Pet Interactions",
                    description: "Pet your companion and build your bond",
                    earnedToday: false,
                    bonus: "2 stars per pet",
                    iconColor: .purple
                )

                // Social Support
                RewardCardView(
                    icon: "💬",
                    title: "Post Support",
                    description: "Get support (likes/comments) on cloud posts",
                    earnedToday: false,
                    bonus: "Up to 50 stars per post",
                    iconColor: .pink
                )

                // Milestones
                RewardCardView(
                    icon: "⭐",
                    title: "Milestones & Achievements",
                    description: "Reach special milestones to unlock bonuses",
                    earnedToday: false,
                    bonus: "20-100 stars per milestone",
                    iconColor: .yellow
                )

                // Collections
                RewardCardView(
                    icon: "🎨",
                    title: "Collection Bonuses",
                    description: "Collect complete sets of items for rewards",
                    earnedToday: false,
                    bonus: "40-60 stars per set",
                    iconColor: .cyan
                )

                // Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Stats")
                        .font(.headline)
                        .fontWeight(.bold)

                    HStack(spacing: 16) {
                        StatItem(
                            icon: "🔥",
                            label: "Login Streak",
                            value: "\(economyViewModel.loginStreak) days"
                        )
                        StatItem(
                            icon: "⭐",
                            label: "Total Stars",
                            value: "\(economyViewModel.economy.decorationToken)"
                        )
                    }

                    let stats = economyViewModel.statsThisWeek
                    HStack(spacing: 16) {
                        StatItem(
                            icon: "☁️",
                            label: "Posts",
                            value: "\(stats.posts)"
                        )
                        StatItem(
                            icon: "🌱",
                            label: "Plants",
                            value: "\(stats.plants)"
                        )
                        StatItem(
                            icon: "📔",
                            label: "Journals",
                            value: "\(stats.journals)"
                        )
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)

                // Tips
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tips to Earn More Stars")
                        .font(.headline)
                        .fontWeight(.bold)

                    VStack(alignment: .leading, spacing: 6) {
                        TipItem(text: "Log in every day to build your streak bonus")
                        TipItem(text: "Complete all daily tasks for maximum rewards")
                        TipItem(text: "Work towards weekly challenges for big bonuses")
                        TipItem(text: "Interact with your pet daily for extra stars")
                        TipItem(text: "Share posts and get community support")
                        TipItem(text: "Unlock achievements by reaching milestones")
                    }
                }
                .padding()
                .background(TreeholeTheme.gentleLavender.opacity(0.3))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 0.97)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct RewardCardView: View {
    let icon: String
    let title: String
    let description: String
    let earnedToday: Bool
    let bonus: String
    let iconColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(icon)
                            .font(.title2)
                        Text(title)
                            .font(.headline)
                            .fontWeight(.bold)
                        if earnedToday {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(bonus)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(iconColor)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct TipItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(TreeholeTheme.softPurple)
                .frame(width: 4, height: 4)
            Text(text)
                .font(.caption)
                .lineLimit(2)
        }
    }
}

#Preview {
    RewardsListView(economyViewModel: EconomyViewModel())
}
