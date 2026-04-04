import SwiftUI
import SwiftData
import PhotosUI

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var economyVM = EconomyViewModel()
    @State private var showNewEntry = false
    @State private var draftText = ""
    @State private var draftMood: MoodTag = .calm
    @State private var draftPhotoData: [Data] = []
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
                        title: L10n.t("Start Your Journal", "开始写日记"),
                        message: L10n.t("Write your first entry to begin reflecting on your feelings.", "写下你的第一篇日记吧..."),
                        actionLabel: L10n.t("Write Entry", "写日记"),
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
                                    Text(L10n.t("Today's Prompt", "今日提示"))
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
                                MiniStat(label: L10n.t("Total", "总计"), value: "\(entries.count)", icon: "book.fill", color: TreeholeTheme.softPurple)
                                MiniStat(label: L10n.t("This Week", "本周"), value: "\(thisWeekCount)", icon: "calendar", color: TreeholeTheme.skyBlue)
                                MiniStat(label: L10n.t("This Month", "本月"), value: "\(thisMonthCount)", icon: "calendar.badge.clock", color: TreeholeTheme.coral)
                            }
                            .listRowBackground(Color.clear)
                        }

                        // Entries
                        Section(L10n.t("Entries", "日记列表")) {
                            ForEach(entries) { entry in
                                NavigationLink(destination: JournalDetailView(entry: entry)) {
                                    JournalEntryRow(entry: entry)
                                }
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
            .navigationTitle(L10n.t("Journal", "日记"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink {
                        MoodStatsView()
                    } label: {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(TreeholeTheme.softPurple)
                    }
                }
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
                    draftPhotoData: $draftPhotoData,
                    prompt: currentPrompt,
                    onSave: {
                        let entry = JournalEntry(moodTag: draftMood, text: draftText)
                        if !draftPhotoData.isEmpty {
                            entry.photoData = draftPhotoData
                        }
                        modelContext.insert(entry)
                        let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                        if let task = dailyTasks.first(where: { $0.type == .writeJournal && !$0.isCompleted }) {
                            economyVM.completeTask(task, economy: economy)
                        }
                        economyVM.incrementChallenge(type: .journalStreak, economy: economy, challenges: weeklyChallenges)
                        try? modelContext.save()
                        draftText = ""
                        draftMood = .calm
                        draftPhotoData = []
                        showNewEntry = false
                    }
                )
            }
            .onAppear {
                selectRandomPrompt()
                _ = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                try? modelContext.save()
            }
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
        currentPrompt = appState.preferredLanguage == "zh-Hans" ? prompt.zh : prompt.en
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
                HStack(spacing: TreeholeTheme.spacingTight) {
                    Text(entry.formattedDate)
                        .font(.caption)
                        .foregroundStyle(TreeholeTheme.textLight)
                    if entry.photoCount > 0 {
                        Label("\(entry.photoCount)", systemImage: "photo.fill")
                            .font(.caption)
                            .foregroundStyle(TreeholeTheme.skyBlue)
                    }
                }
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
    @Binding var draftPhotoData: [Data]
    let prompt: String
    let onSave: () -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false

    private let maxPhotos = 3

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
                                Text(L10n.t("Prompt", "写作提示"))
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
                            Text(L10n.t("How are you feeling?", "你现在感觉怎么样？"))
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

                        // MARK: - Photo Section
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Text(L10n.t("Photos", "照片"))
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                                Spacer()
                                Text(L10n.t("\(draftPhotoData.count)/\(maxPhotos)", "\(draftPhotoData.count)/\(maxPhotos)"))
                                    .font(.caption)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }

                            // Photo thumbnails
                            if !draftPhotoData.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: TreeholeTheme.spacingSmall) {
                                        ForEach(Array(draftPhotoData.enumerated()), id: \.offset) { index, data in
                                            ZStack(alignment: .topTrailing) {
                                                if let uiImage = UIImage(data: data) {
                                                    Image(uiImage: uiImage)
                                                        .resizable()
                                                        .scaledToFill()
                                                        .frame(width: 80, height: 80)
                                                        .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                                                }
                                                Button {
                                                    draftPhotoData.remove(at: index)
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundStyle(.white)
                                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                                }
                                                .offset(x: 6, y: -6)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Photos picker button
                            if draftPhotoData.count < maxPhotos {
                                PhotosPicker(
                                    selection: $selectedItems,
                                    maxSelectionCount: maxPhotos - draftPhotoData.count,
                                    matching: .images
                                ) {
                                    HStack(spacing: TreeholeTheme.spacingTight) {
                                        if isLoadingPhotos {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "photo.badge.plus")
                                        }
                                        Text(L10n.t("Add Photos", "添加照片"))
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(TreeholeTheme.skyBlue)
                                    .padding(.vertical, TreeholeTheme.spacingTight)
                                    .padding(.horizontal, TreeholeTheme.spacingSmall)
                                    .background(TreeholeTheme.skyBlue.opacity(0.15), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.t("New Entry", "新日记"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Cancel", "取消")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Save", "保存")) { onSave() }
                        .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .tint(TreeholeTheme.coral)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await loadPhotos(from: newItems)
                }
            }
        }
    }

    @MainActor
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

        for item in items {
            guard draftPhotoData.count < maxPhotos else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data),
               let jpegData = uiImage.jpegData(compressionQuality: 0.7) {
                draftPhotoData.append(jpegData)
            }
        }
        selectedItems = []
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
