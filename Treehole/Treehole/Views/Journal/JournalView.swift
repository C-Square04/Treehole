import SwiftUI
import SwiftData
import PhotosUI

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PrivacyLockManager.self) private var lockManager
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var economyVM = EconomyViewModel()
    @State private var showNewEntry = false
    @State private var draftText = ""
    @State private var draftMood: MoodTag = .calm
    @State private var draftPhotoData: [Data] = []

    var body: some View {
        Group {
            if lockManager.isJournalLockEnabled && !lockManager.isJournalUnlocked {
                NavigationStack {
                    PrivacyLockView(lockType: .journal, title: L10n.t("Journal", "日记"))
                        .navigationTitle(L10n.t("Journal", "日记"))
                }
            } else {
                journalContent
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            lockManager.lock()
        }
    }

    @ViewBuilder
    private var journalContent: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingMedium) {

                        // MARK: - Mood Week Strip (always visible)
                        MoodWeekStrip(entries: entries)
                            .padding(.horizontal, TreeholeTheme.spacingMedium)
                            .padding(.top, TreeholeTheme.spacingSmall)

                        if entries.isEmpty {
                            // Empty state below week strip
                            VStack(spacing: TreeholeTheme.spacingMedium) {
                                Spacer().frame(height: 40)
                                EmptyStateView(
                                    icon: "book.closed",
                                    title: L10n.t("Start Your Journal", "开始写日记"),
                                    message: L10n.t("Write your first entry to begin reflecting on your feelings.", "写下你的第一篇日记吧..."),
                                    actionLabel: L10n.t("Write Entry", "写日记"),
                                    action: { showNewEntry = true }
                                )
                            }
                        } else {
                            // MARK: - Compact Stats Row
                            HStack(spacing: TreeholeTheme.spacingMedium) {
                                MiniStat(
                                    label: L10n.t("Total", "总计"),
                                    value: "\(entries.count)",
                                    icon: "book.fill",
                                    color: TreeholeTheme.softPurple
                                )
                                MiniStat(
                                    label: L10n.t("This Week", "本周"),
                                    value: "\(thisWeekCount)",
                                    icon: "calendar",
                                    color: TreeholeTheme.skyBlue
                                )
                                MiniStat(
                                    label: L10n.t("This Month", "本月"),
                                    value: "\(thisMonthCount)",
                                    icon: "calendar.badge.clock",
                                    color: TreeholeTheme.coral
                                )
                            }
                            .glassCard()
                            .padding(.horizontal, TreeholeTheme.spacingMedium)

                            // MARK: - Entries Section
                            VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                                HStack(spacing: TreeholeTheme.spacingTight) {
                                    Image(systemName: "book.pages")
                                        .foregroundStyle(TreeholeTheme.softPurple)
                                    Text(L10n.t("Entries", "日记列表"))
                                        .font(.headline)
                                        .foregroundStyle(TreeholeTheme.textPrimary)
                                }
                                .padding(.horizontal, TreeholeTheme.spacingMedium)

                                ForEach(entries) { entry in
                                    NavigationLink(destination: JournalDetailView(entry: entry)) {
                                        JournalEntryCard(entry: entry, appState: appState)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, TreeholeTheme.spacingMedium)
                                }
                            }
                            .padding(.bottom, TreeholeTheme.spacingLarge)
                        }
                    }
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
                if lockManager.isJournalLockEnabled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            lockManager.lockAll()
                        } label: {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(TreeholeTheme.softPurple)
                        }
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                JournalEntryEditor(
                    draftText: $draftText,
                    draftMood: $draftMood,
                    draftPhotoData: $draftPhotoData,
                    onSave: {
                        let entry = JournalEntry(moodTag: draftMood, text: draftText)
                        if !draftPhotoData.isEmpty {
                            var filenames: [String] = []
                            for data in draftPhotoData {
                                if let filename = PhotoStorage.savePhoto(data) {
                                    filenames.append(filename)
                                }
                            }
                            entry.photoFilenames = filenames.isEmpty ? nil : filenames
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
}

// MARK: - Mood Week Strip

private struct MoodWeekStrip: View {
    let entries: [JournalEntry]

    private var today: Date { Date() }
    private var calendar: Calendar { Calendar.current }

    /// Returns the Monday of the current week
    private var weekStart: Date {
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1=Sun,2=Mon,...,7=Sat. We want Mon=0
        let daysFromMonday = (weekday + 5) % 7
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today)
    }

    /// 7 days starting from Monday
    private var weekDays: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }

    /// Formatted date header: "Today, 4 April"
    private var headerText: String {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d MMMM"
        return L10n.t("Today, \(dayFormatter.string(from: today))", "今天，\(chineseDateString(today))")
    }

    private func chineseDateString(_ date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)月\(day)日"
    }

    /// Short weekday label (Mon, Tue, ...)
    private func shortWeekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = L10n.t("EEE", "EEE")
        formatter.locale = Locale(identifier: L10n.lang == "zh-Hans" ? "zh_Hans" : "en_US")
        return formatter.string(from: date)
    }

    /// First entry's mood for a given calendar day, if any
    private func mood(for date: Date) -> MoodTag? {
        entries.first { calendar.isDate($0.createdAt, inSameDayAs: date) }?.moodTag
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            Text(headerText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TreeholeTheme.textPrimary)

            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    VStack(spacing: 6) {
                        Text(shortWeekdayLabel(day))
                            .font(.caption2)
                            .foregroundStyle(isToday(day) ? TreeholeTheme.softPurple : TreeholeTheme.textLight)
                            .fontWeight(isToday(day) ? .semibold : .regular)

                        ZStack {
                            if isToday(day) {
                                Circle()
                                    .strokeBorder(TreeholeTheme.softPurple, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }

                            if let moodTag = mood(for: day) {
                                Text(moodTag.emoji)
                                    .font(.title3)
                            } else {
                                Circle()
                                    .fill(TreeholeTheme.textLight.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .frame(width: 36, height: 36)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .glassCard()
    }
}

// MARK: - Journal Entry Card

private struct JournalEntryCard: View {
    let entry: JournalEntry
    let appState: AppState

    private var moodLabel: String {
        appState.preferredLanguage == "zh-Hans" ? entry.moodTag.labelZH : entry.moodTag.labelEN
    }

    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.createdAt, relativeTo: Date())
    }

    private var shortDate: String {
        entry.createdAt.formatted(.dateTime.month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
            // Header row: mood emoji + label + date
            HStack(alignment: .center, spacing: TreeholeTheme.spacingTight) {
                Text(entry.moodTag.emoji)
                    .font(.title2)

                Text(moodLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TreeholeTheme.textPrimary)

                Text("•")
                    .foregroundStyle(TreeholeTheme.textLight)

                Text(shortDate)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)

                Spacer()

                if entry.photoCount > 0 {
                    Label("\(entry.photoCount)", systemImage: "photo.fill")
                        .font(.caption)
                        .foregroundStyle(TreeholeTheme.skyBlue)
                }
            }

            // Text preview
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.body)
                    .foregroundStyle(TreeholeTheme.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

// MARK: - Journal Entry Editor

private struct JournalEntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draftText: String
    @Binding var draftMood: MoodTag
    @Binding var draftPhotoData: [Data]
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
               let uiImage = UIImage(data: data) {
                // Resize if too large
                let maxDimension: CGFloat = 1024
                let resized: UIImage
                if max(uiImage.size.width, uiImage.size.height) > maxDimension {
                    let scale = maxDimension / max(uiImage.size.width, uiImage.size.height)
                    let newSize = CGSize(width: uiImage.size.width * scale, height: uiImage.size.height * scale)
                    let renderer = UIGraphicsImageRenderer(size: newSize)
                    resized = renderer.image { _ in uiImage.draw(in: CGRect(origin: .zero, size: newSize)) }
                } else {
                    resized = uiImage
                }
                if let jpegData = resized.jpegData(compressionQuality: 0.7), jpegData.count <= 2_000_000 {
                    draftPhotoData.append(jpegData)
                }
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
