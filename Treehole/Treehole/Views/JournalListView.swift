//
//  JournalListView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct JournalListView: View {
    @ObservedObject var viewModel: JournalViewModel
    @ObservedObject var economyViewModel: EconomyViewModel
    @State private var showWriteSheet: Bool = false

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
                    // Header with stats
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("My Journal")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Reflect and grow")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Button(action: { showWriteSheet = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }

                        // Quick stats
                        HStack(spacing: 12) {
                            StatCard(label: "Total", value: "\(viewModel.totalEntries)", icon: "📚")
                            StatCard(label: "This Week", value: "\(viewModel.thisWeekEntries)", icon: "📖")
                            StatCard(label: "This Month", value: "\(viewModel.thisMonthEntries)", icon: "📕")
                        }
                    }
                    .padding()
                    .background(Color.white)

                    // Entries List
                    if viewModel.entries.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Start reflecting")
                                .font(.headline)
                            Text("Write your first journal entry to begin your wellness journey")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            Button(action: { showWriteSheet = true }) {
                                Text("Write Now")
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach($viewModel.entries) { $entry in
                                    JournalEntryCardView(
                                        entry: $entry,
                                        economyViewModel: economyViewModel,
                                        viewModel: viewModel
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .sheet(isPresented: $showWriteSheet) {
                JournalWriteView(viewModel: viewModel, isPresented: $showWriteSheet)
            }
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Text(icon)
                .font(.title2)
            Text(value)
                .font(.headline)
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

struct JournalEntryCardView: View {
    @Binding var entry: JournalEntry
    @ObservedObject var economyViewModel: EconomyViewModel
    @ObservedObject var viewModel: JournalViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(entry.mood.rawValue)
                            .font(.title3)
                        Text(entry.formattedDate)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
                if !entry.rewardGranted {
                    Button(action: {
                        viewModel.grantReward(to: &entry, economy: &economyViewModel.economy)
                        economyViewModel.saveEconomy()
                    }) {
                        Label("Reward", systemImage: "gift.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                } else {
                    Label("Claimed", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }

            Text(entry.text)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.primary)

            if !entry.rewardGranted {
                HStack(spacing: 8) {
                    Image(systemName: "carrot.fill")
                        .foregroundColor(.orange)
                    Text("+\(entry.foodReward)")
                        .font(.caption)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("+\(entry.decorTokenReward)")
                        .font(.caption)
                }
                .padding(.top, 4)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct JournalWriteView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Binding var isPresented: Bool
    @State private var text: String = ""
    @State private var selectedMood: CloudPost.MoodTag = .calm

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

                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Write Journal Entry")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)

                    ScrollView {
                        VStack(spacing: 16) {
                            // Today's prompt
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Today's Prompt", systemImage: "lightbulb.fill")
                                    .font(.headline)
                                Text(viewModel.currentPrompt.text)
                                    .font(.body)
                                    .italic()
                                    .foregroundColor(.gray)
                                Button(action: { viewModel.selectRandomPrompt() }) {
                                    Text("New prompt")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            // Mood selector
                            VStack(alignment: .leading, spacing: 8) {
                                Label("How are you feeling?", systemImage: "heart.fill")
                                    .font(.headline)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(CloudPost.MoodTag.allCases, id: \.self) { mood in
                                            MoodSelectorButton(
                                                mood: mood,
                                                isSelected: selectedMood == mood,
                                                action: { selectedMood = mood }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            // Text editor
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Your entry", systemImage: "pencil")
                                    .font(.headline)
                                TextEditor(text: $text)
                                    .frame(minHeight: 200)
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            Spacer()
                        }
                        .padding()
                    }

                    // Save button
                    Button(action: {
                        _ = viewModel.createEntry(mood: selectedMood, text: text)
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Entry")
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding()
                }
            }
        }
    }
}

#Preview {
    JournalListView(viewModel: JournalViewModel(), economyViewModel: EconomyViewModel())
}
