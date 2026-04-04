import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @State private var showNewEntry = false
    @State private var draftText = ""
    @State private var draftMood: MoodTag = .calm
    @State private var currentPrompt: String = ""

    private static let prompts: [(en: String, zh: String)] = [
        ("What was your proudest moment today?", "今天最自豪的时刻是什么？"),
        ("What are you grateful for right now?", "你现在最感恩的是什么？"),
        ("Describe how you're feeling in three words.", "用三个词描述你现在的感受。"),
        ("What challenged you today, and how did you handle it?", "今天有什么挑战？你是怎么应对的？"),
        ("Write about something that made you smile.", "写一件让你微笑的事。"),
        ("What would you tell your future self?", "你想对未来的自己说什么？"),
        ("What's one thing you'd like to let go of?", "有什么事你想放下？"),
        ("Describe your ideal peaceful moment.", "描述你理想中的平静时刻。"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground.ignoresSafeArea()

                if entries.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "Start Your Journal",
                        message: "Write your first entry to begin reflecting on your feelings.",
                        actionLabel: "Write Entry",
                        action: { showNewEntry = true }
                    )
                } else {
                    List {
                        // Prompt card
                        Section {
                            VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(TreeholeTheme.warmGold)
                                    Text("Today's Prompt")
                                        .font(.headline)
                                        .foregroundStyle(TreeholeTheme.textPrimary)
                                }
                                Text(currentPrompt)
                                    .font(.subheadline)
                                    .foregroundStyle(TreeholeTheme.textSecondary)
                                    .italic()
                            }
                            .listRowBackground(TreeholeTheme.warmGold.opacity(0.1))
                        }

                        // Stats
                        Section {
                            HStack(spacing: TreeholeTheme.spacingMedium) {
                                MiniStat(label: "Total", value: "\(entries.count)", icon: "book.fill", color: TreeholeTheme.softPurple)
                                MiniStat(label: "This Week", value: "\(thisWeekCount)", icon: "calendar", color: TreeholeTheme.skyBlue)
                                MiniStat(label: "This Month", value: "\(thisMonthCount)", icon: "calendar.badge.clock", color: TreeholeTheme.coral)
                            }
                            .listRowBackground(Color.clear)
                        }

                        // Entries
                        Section("Entries") {
                            ForEach(entries) { entry in
                                JournalEntryRow(entry: entry)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    modelContext.delete(entries[index])
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewEntry = true } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(TreeholeTheme.coral)
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                JournalEntryEditor(
                    draftText: $draftText,
                    draftMood: $draftMood,
                    prompt: currentPrompt,
                    onSave: {
                        let entry = JournalEntry(moodTag: draftMood, text: draftText)
                        modelContext.insert(entry)
                        draftText = ""
                        draftMood = .calm
                        showNewEntry = false
                    }
                )
            }
            .onAppear { selectRandomPrompt() }
        }
    }

    private var thisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.createdAt > weekAgo }.count
    }

    private var thisMonthCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.createdAt > monthAgo }.count
    }

    private func selectRandomPrompt() {
        let prompt = Self.prompts.randomElement() ?? Self.prompts[0]
        currentPrompt = prompt.en // TODO: use appState.preferredLanguage
    }
}

// MARK: - Journal Entry Row

private struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Text(entry.moodTag.emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                    .lineLimit(2)
                Text(entry.formattedDate)
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
            }
            Spacer()
        }
    }
}

// MARK: - Journal Entry Editor

private struct JournalEntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draftText: String
    @Binding var draftMood: MoodTag
    let prompt: String
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingLarge) {
                        // Prompt
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(TreeholeTheme.warmGold)
                                Text("Prompt")
                                    .font(.headline)
                            }
                            Text(prompt)
                                .font(.subheadline)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                                .italic()
                        }
                        .accentCard(TreeholeTheme.warmGold)

                        // Mood picker
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            Text("How are you feeling?")
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            MoodPicker(selectedMood: $draftMood)
                        }

                        // Text editor
                        TextEditor(text: $draftText)
                            .frame(minHeight: 200)
                            .padding(TreeholeTheme.spacingSmall)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                            .scrollContentBackground(.hidden)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave() }
                        .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .tint(TreeholeTheme.coral)
                }
            }
        }
    }
}

// MARK: - Mini Stat

private struct MiniStat: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TreeholeTheme.textLight)
        }
        .frame(maxWidth: .infinity)
    }
}
