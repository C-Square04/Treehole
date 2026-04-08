import SwiftUI
import SwiftData
import PhotosUI
import AVFoundation
import Speech
import CoreLocation

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PrivacyLockManager.self) private var lockManager
    @Query(sort: \JournalEntry.createdAt, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \JournalSummary.generatedAt, order: .reverse) private var allSummaries: [JournalSummary]
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var economyVM = EconomyViewModel()
    @State private var showNewEntry = false
    @State private var isGeneratingInsights = false
    @State private var isGeneratingWeekly = false
    @State private var searchText = ""
    @State private var editingEntry: JournalEntry? = nil

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

                        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                            // MARK: - Mood Week Strip (always visible)
                            MoodWeekStrip(entries: entries)
                                .padding(.horizontal, TreeholeTheme.spacingMedium)
                                .padding(.top, TreeholeTheme.spacingSmall)

                            // MARK: - AI Insights Card (only if opted in)
                            if appState.allowAIJournalAnalysis {
                                AIInsightsCard(
                                    entries: entries,
                                    allSummaries: allSummaries,
                                    isGenerating: $isGeneratingInsights,
                                    language: appState.preferredLanguage
                                )
                                .padding(.horizontal, TreeholeTheme.spacingMedium)

                                // MARK: - Weekly Summary Card
                                if let weeklySummary = latestWeeklySummary {
                                    AIWeeklySummaryCard(summary: weeklySummary)
                                        .padding(.horizontal, TreeholeTheme.spacingMedium)
                                }
                            }
                        }

                        if entries.isEmpty && searchText.trimmingCharacters(in: .whitespaces).isEmpty {
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
                            let filtered = filteredEntries

                            // MARK: - Search results header
                            if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                HStack {
                                    Text(L10n.t("\(filtered.count) results", "\(filtered.count) 条结果"))
                                        .font(.subheadline)
                                        .foregroundStyle(TreeholeTheme.textSecondary)
                                    Spacer()
                                }
                                .padding(.horizontal, TreeholeTheme.spacingMedium)
                                .padding(.top, TreeholeTheme.spacingSmall)
                            }

                            if filtered.isEmpty && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                VStack(spacing: TreeholeTheme.spacingSmall) {
                                    Spacer().frame(height: 60)
                                    Text(L10n.t("No matches", "没有匹配结果"))
                                        .font(.headline)
                                        .foregroundStyle(TreeholeTheme.textSecondary)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    // MARK: - Compact Stats Row (only shown outside search)
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
                                }

                                // MARK: - Entries Section
                                VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                                    if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                                        HStack(spacing: TreeholeTheme.spacingTight) {
                                            Image(systemName: "book.pages")
                                                .foregroundStyle(TreeholeTheme.softPurple)
                                            Text(L10n.t("Entries", "日记列表"))
                                                .font(.headline)
                                                .foregroundStyle(TreeholeTheme.textPrimary)
                                        }
                                        .padding(.horizontal, TreeholeTheme.spacingMedium)
                                    }

                                    ForEach(filtered) { entry in
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
            }
            .navigationTitle(L10n.t("Journal", "日记"))
            .searchable(
                text: $searchText,
                prompt: L10n.t("Search entries", "搜索日记")
            )
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
                    existingEntry: nil,
                    allowAnyDate: appState.isDeveloperMode,
                    language: appState.preferredLanguage,
                    onSave: { draft in
                        saveNewEntry(draft: draft)
                        showNewEntry = false
                    }
                )
            }
            .sheet(item: $editingEntry) { entry in
                JournalEntryEditor(
                    existingEntry: entry,
                    allowAnyDate: appState.isDeveloperMode,
                    language: appState.preferredLanguage,
                    onSave: { _ in
                        editingEntry = nil
                    }
                )
            }
            .onAppear {
                _ = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                try? modelContext.save()
                maybeGenerateWeeklySummary()
            }
        }
    }

    // MARK: - Search Filter

    private var filteredEntries: [JournalEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        let sorted = entries.sorted { $0.displayDate > $1.displayDate }
        guard !trimmed.isEmpty else { return sorted }
        let lowered = trimmed.lowercased()
        return sorted.filter { entry in
            entry.text.lowercased().contains(lowered) ||
            (entry.title?.lowercased().contains(lowered) ?? false) ||
            (entry.audioTranscript?.lowercased().contains(lowered) ?? false) ||
            (entry.locationName?.lowercased().contains(lowered) ?? false)
        }
    }

    // MARK: - Save New Entry

    private func saveNewEntry(draft: EntryDraft) {
        let entry = JournalEntry(moodTag: draft.mood, text: draft.text)
        entry.title = draft.title.isEmpty ? nil : draft.title
        // createdAt = now (immutable from creation)
        entry.createdAt = Date()
        // entryDate is user-chosen date (nil = same as createdAt)
        if let ed = draft.entryDate {
            let cal = Calendar.current
            if !cal.isDateInToday(ed) {
                entry.entryDate = ed
            }
        }
        if !draft.photoData.isEmpty {
            var filenames: [String] = []
            for data in draft.photoData {
                if let filename = PhotoStorage.savePhoto(data) {
                    filenames.append(filename)
                }
            }
            entry.photoFilenames = filenames.isEmpty ? nil : filenames
        }
        entry.audioFilename = draft.audioFilename
        entry.audioDurationSeconds = draft.audioDuration
        entry.audioTranscript = draft.audioTranscript
        entry.latitude = draft.latitude
        entry.longitude = draft.longitude
        entry.locationName = draft.locationName
        entry.weatherTempC = draft.weatherTempC
        entry.weatherCode = draft.weatherCode
        entry.weatherEmoji = draft.weatherEmoji
        entry.weatherDescription = draft.weatherDescription
        modelContext.insert(entry)
        let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
        if let task = dailyTasks.first(where: { $0.type == .writeJournal && !$0.isCompleted }) {
            economyVM.completeTask(task, economy: economy)
        }
        economyVM.incrementChallenge(type: .journalStreak, economy: economy, challenges: weeklyChallenges)
        try? modelContext.save()
        AnalyticsService.track("journal_written")
    }

    // MARK: - Stats

    private var thisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.displayDate > weekAgo }.count
    }

    private var thisMonthCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.displayDate > monthAgo }.count
    }

    private var currentWeekStart: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
    }

    private var latestWeeklySummary: JournalSummary? {
        allSummaries.first { $0.kindRaw == "weekly" }
    }

    private var thisWeekEntries: [JournalEntry] {
        entries.filter { $0.displayDate >= currentWeekStart }
    }

    private func maybeGenerateWeeklySummary() {
        guard appState.allowAIJournalAnalysis else { return }
        let weekStart = currentWeekStart
        let alreadyExists = allSummaries.contains {
            $0.kindRaw == "weekly" &&
            Calendar.current.isDate($0.periodStart, inSameDayAs: weekStart)
        }
        guard !alreadyExists else { return }
        let weekEntries = thisWeekEntries
        guard weekEntries.count >= 3 else { return }
        guard !isGeneratingWeekly else { return }
        isGeneratingWeekly = true
        let language = appState.preferredLanguage
        let entryPayloads = weekEntries.map { entry -> (date: String, mood: String, text: String) in
            let dateStr = entry.displayDate.formatted(.iso8601.year().month().day())
            return (date: dateStr, mood: entry.moodTag.rawValue, text: entry.text)
        }
        Task {
            defer { isGeneratingWeekly = false }
            guard let text = try? await SupabaseService.summarizeJournal(
                mode: "weekly",
                language: language,
                entries: entryPayloads
            ) else { return }
            let weekEnd = Date()
            let summary = JournalSummary(
                kind: .weekly,
                periodStart: weekStart,
                periodEnd: weekEnd,
                summary: text,
                language: language
            )
            modelContext.insert(summary)
            try? modelContext.save()
        }
    }
}

// MARK: - EntryDraft (shared between create and edit)

struct EntryDraft {
    var text: String = ""
    var title: String = ""
    var mood: MoodTag = .calm
    var photoData: [Data] = []
    var audioFilename: String? = nil
    var audioDuration: Double? = nil
    var audioTranscript: String? = nil
    var latitude: Double? = nil
    var longitude: Double? = nil
    var locationName: String? = nil
    var weatherTempC: Double? = nil
    var weatherCode: Int? = nil
    var weatherEmoji: String? = nil
    var weatherDescription: String? = nil
    var entryDate: Date? = nil
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
        entries.first { calendar.isDate($0.displayDate, inSameDayAs: date) }?.moodTag
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

    private var shortDate: String {
        entry.displayDate.formatted(.dateTime.month(.abbreviated).day())
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

            // Title (if any)
            if let title = entry.title, !title.isEmpty {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)
                    .lineLimit(1)
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

struct JournalEntryEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let existingEntry: JournalEntry?
    let allowAnyDate: Bool
    let language: String
    let onSave: (EntryDraft) -> Void

    // Draft state
    @State private var draftText: String = ""
    @State private var draftTitle: String = ""
    @State private var draftMood: MoodTag = .calm
    @State private var draftPhotoData: [Data] = []
    @State private var existingPhotoFilenames: [String] = []
    @State private var removedPhotoFilenames: [String] = []
    @State private var draftAudioFilename: String? = nil
    @State private var existingAudioFilename: String? = nil
    @State private var draftAudioDuration: Double? = nil
    @State private var draftAudioTranscript: String? = nil
    @State private var draftLatitude: Double? = nil
    @State private var draftLongitude: Double? = nil
    @State private var draftLocationName: String? = nil
    @State private var draftWeatherTempC: Double? = nil
    @State private var draftWeatherCode: Int? = nil
    @State private var draftWeatherEmoji: String? = nil
    @State private var draftWeatherDescription: String? = nil
    @State private var draftEntryDate: Date? = nil

    // Toolbar / recording state
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var audioRecorder = AudioRecorder()
    @State private var locationService = LocationService()
    @State private var isLoadingLocation = false
    @State private var permissionDeniedMessage: String? = nil
    @State private var showDatePicker = false
    @State private var showDeleteConfirm = false
    @State private var showLocationRemoveAlert = false

    private let maxPhotos = 10
    private var isEditMode: Bool { existingEntry != nil }

    private var dateRange: ClosedRange<Date> {
        let now = Date()
        if allowAnyDate {
            let cal = Calendar.current
            let lower = cal.date(byAdding: .year, value: -1, to: now) ?? now
            let upper = cal.date(byAdding: .year, value: 1, to: now) ?? now
            return lower...upper
        }
        let cal = Calendar.current
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: cal.startOfDay(for: now)) ?? now
        return threeDaysAgo...now
    }

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.warmBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingMedium) {

                        // Mood picker — always at top
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            Text(L10n.t("How are you feeling?", "你现在感觉怎么样？"))
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            MoodPicker(selectedMood: $draftMood)
                        }
                        .padding(.horizontal, TreeholeTheme.spacingSmall)

                        // Title field
                        TextField(
                            L10n.t("Title (optional)", "标题（可选）"),
                            text: $draftTitle
                        )
                        .font(.title3.bold())
                        .padding(.horizontal, TreeholeTheme.spacingSmall)

                        // Body TextEditor
                        TextEditor(text: $draftText)
                            .frame(minHeight: 200)
                            .padding(TreeholeTheme.spacingSmall)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, TreeholeTheme.spacingSmall)

                        // Photo grid (only if photos exist)
                        if !existingPhotoFilenames.isEmpty || !draftPhotoData.isEmpty {
                            photoGridSection
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                        }

                        // Audio chip (only if audio recorded — recording bar is in the bottom inset)
                        if !audioRecorder.isRecording,
                           let fn = draftAudioFilename ?? existingAudioFilename,
                           let dur = draftAudioDuration {
                            audioChip(filename: fn, duration: dur)
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                        }

                        // Location + weather chip
                        if draftLocationName != nil || draftWeatherEmoji != nil {
                            locationWeatherChip
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                        }

                        // Event date chip (only if entryDate set AND not today)
                        if let ed = draftEntryDate,
                           !Calendar.current.isDateInToday(ed) {
                            eventDateChip(date: ed)
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                        }

                        // Permission denied message
                        if let msg = permissionDeniedMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.coral)
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                        }

                        // Big bottom padding so content clears the floating toolbar
                        Spacer().frame(height: 80)
                    }
                    .padding(.vertical, TreeholeTheme.spacingMedium)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Floating bottom toolbar — SwiftUI auto-shifts it above the keyboard
                Group {
                    if audioRecorder.isRecording {
                        recordingBar
                    } else {
                        floatingToolbar
                    }
                }
                .padding(.horizontal, TreeholeTheme.spacingMedium)
                .padding(.bottom, TreeholeTheme.spacingSmall)
            }
            .navigationTitle(isEditMode
                             ? L10n.t("Edit Entry", "编辑日记")
                             : L10n.t("New Entry", "新日记"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Cancel", "取消")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Save", "保存")) { handleSave() }
                        .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .tint(TreeholeTheme.coral)
                }
            }
            .onChange(of: selectedItems) { _, newItems in
                Task { await loadPhotos(from: newItems) }
            }
            .sheet(isPresented: $showDatePicker) {
                eventDatePickerSheet
            }
            .confirmationDialog(
                L10n.t("Delete this entry?", "删除这篇日记？"),
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button(L10n.t("Delete", "删除"), role: .destructive) {
                    deleteEntry()
                }
                Button(L10n.t("Cancel", "取消"), role: .cancel) {}
            } message: {
                Text(L10n.t("This action cannot be undone.", "此操作无法撤销。"))
            }
            .onAppear { populateFromExisting() }
        }
    }

    // MARK: - Photo Grid

    @ViewBuilder
    private var photoGridSection: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
            HStack {
                Text(L10n.t("Photos", "照片"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Spacer()
                let total = existingPhotoFilenames.count + draftPhotoData.count
                Text(L10n.t("\(total)/\(maxPhotos)", "\(total)/\(maxPhotos)"))
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: TreeholeTheme.spacingSmall), count: 2)
            LazyVGrid(columns: columns, spacing: TreeholeTheme.spacingSmall) {
                // Existing photos
                ForEach(existingPhotoFilenames, id: \.self) { filename in
                    ZStack(alignment: .topTrailing) {
                        if let image = PhotoStorage.loadImage(filename) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                        }
                        Button {
                            if let idx = existingPhotoFilenames.firstIndex(of: filename) {
                                removedPhotoFilenames.append(filename)
                                existingPhotoFilenames.remove(at: idx)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
                // New photos
                ForEach(Array(draftPhotoData.enumerated()), id: \.offset) { index, data in
                    ZStack(alignment: .topTrailing) {
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                        }
                        Button {
                            draftPhotoData.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
        }
    }

    // MARK: - Recording Bar

    @ViewBuilder
    private var recordingBar: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .symbolEffect(.pulse, isActive: true)

            Image(systemName: "waveform")
                .foregroundStyle(TreeholeTheme.coral)
                .symbolEffect(.variableColor.iterative, isActive: true)

            Text(formatElapsed(audioRecorder.elapsed))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(TreeholeTheme.textPrimary)

            Spacer()

            Button {
                finishRecording()
            } label: {
                Label(L10n.t("Stop", "停止"), systemImage: "stop.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, TreeholeTheme.spacingSmall)
                    .padding(.vertical, 6)
                    .background(TreeholeTheme.coral, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
            }

            Button {
                audioRecorder.cancelRecording()
            } label: {
                Image(systemName: "xmark.circle")
                    .foregroundStyle(TreeholeTheme.textSecondary)
            }
        }
        .padding(TreeholeTheme.spacingSmall)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
    }

    // MARK: - Audio Chip

    @ViewBuilder
    private func audioChip(filename: String, duration: Double) -> some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            Image(systemName: "waveform.circle.fill")
                .font(.title3)
                .foregroundStyle(TreeholeTheme.skyBlue)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("Voice Note", "语音备注"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(formatElapsed(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(TreeholeTheme.textLight)
            }
            Spacer()
            Button {
                if draftAudioFilename != nil {
                    AudioStorage.deleteAudio(filename: filename)
                    draftAudioFilename = nil
                } else {
                    existingAudioFilename = nil
                }
                draftAudioDuration = nil
                draftAudioTranscript = nil
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(TreeholeTheme.coral)
            }
        }
        .padding(TreeholeTheme.spacingSmall)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
    }

    // MARK: - Location + Weather Chip

    @ViewBuilder
    private var locationWeatherChip: some View {
        let chipText: String = {
            var parts: [String] = []
            if let name = draftLocationName { parts.append("📍 \(name)") }
            if let emoji = draftWeatherEmoji, let temp = draftWeatherTempC {
                parts.append("\(emoji) \(Int(temp.rounded()))°C")
            }
            return parts.joined(separator: " · ")
        }()

        HStack {
            Text(chipText)
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textPrimary)
            Spacer()
            Button {
                showLocationRemoveAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(TreeholeTheme.textLight)
            }
        }
        .padding(.horizontal, TreeholeTheme.spacingSmall)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .confirmationDialog(
            L10n.t("Remove location?", "移除位置？"),
            isPresented: $showLocationRemoveAlert,
            titleVisibility: .visible
        ) {
            Button(L10n.t("Remove", "移除"), role: .destructive) {
                draftLocationName = nil
                draftLatitude = nil
                draftLongitude = nil
                draftWeatherTempC = nil
                draftWeatherCode = nil
                draftWeatherEmoji = nil
                draftWeatherDescription = nil
            }
            Button(L10n.t("Cancel", "取消"), role: .cancel) {}
        }
    }

    // MARK: - Event Date Chip

    @ViewBuilder
    private func eventDateChip(date: Date) -> some View {
        HStack {
            Text("📅 \(date.formatted(.dateTime.month(.abbreviated).day()))")
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textPrimary)
            Spacer()
            Button {
                draftEntryDate = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(TreeholeTheme.textLight)
            }
        }
        .padding(.horizontal, TreeholeTheme.spacingSmall)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Event Date Picker Sheet

    private var eventDatePickerSheet: some View {
        NavigationStack {
            VStack(spacing: TreeholeTheme.spacingLarge) {
                DatePicker(
                    L10n.t("Event Date", "事件日期"),
                    selection: Binding(
                        get: { draftEntryDate ?? Date() },
                        set: { draftEntryDate = $0 }
                    ),
                    in: dateRange,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                if allowAnyDate {
                    Text(L10n.t("Developer mode: any date allowed", "开发者模式：可选任意日期"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.warmGold)
                } else {
                    Text(L10n.t("You can backdate up to 3 days", "可以补写最近 3 天的日记"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.textLight)
                }

                Spacer()
            }
            .navigationTitle(L10n.t("When did this happen?", "事件发生时间"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Done", "完成")) { showDatePicker = false }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Clear", "清除")) {
                        draftEntryDate = nil
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Floating Toolbar

    @ViewBuilder
    private var floatingToolbar: some View {
        HStack(spacing: 0) {
            // Camera (placeholder — opens photo picker)
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxPhotos - existingPhotoFilenames.count - draftPhotoData.count,
                matching: .images
            ) {
                toolbarIcon(
                    systemName: "camera",
                    active: false
                )
            }
            .disabled(existingPhotoFilenames.count + draftPhotoData.count >= maxPhotos)

            // Photos picker
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxPhotos - existingPhotoFilenames.count - draftPhotoData.count,
                matching: .images
            ) {
                toolbarIcon(
                    systemName: "photo.on.rectangle",
                    active: !draftPhotoData.isEmpty || !existingPhotoFilenames.isEmpty
                )
            }
            .disabled(existingPhotoFilenames.count + draftPhotoData.count >= maxPhotos)

            // Mic
            Button {
                Task {
                    if audioRecorder.isRecording {
                        finishRecording()
                    } else {
                        await startRecordingWithPermissionCheck()
                    }
                }
            } label: {
                toolbarIcon(
                    systemName: (draftAudioFilename != nil || existingAudioFilename != nil) ? "mic.fill" : "mic",
                    active: draftAudioFilename != nil || existingAudioFilename != nil
                )
            }

            // Location
            Button {
                Task {
                    if draftLocationName != nil {
                        showLocationRemoveAlert = true
                    } else {
                        await fetchLocationAndWeather()
                    }
                }
            } label: {
                if isLoadingLocation {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(maxWidth: .infinity)
                } else {
                    toolbarIcon(
                        systemName: draftLocationName != nil ? "mappin.circle.fill" : "mappin",
                        active: draftLocationName != nil
                    )
                }
            }

            // Calendar / event date
            Button {
                showDatePicker = true
            } label: {
                let hasDate = draftEntryDate != nil && !Calendar.current.isDateInToday(draftEntryDate!)
                toolbarIcon(systemName: "calendar", active: hasDate)
            }

            // Ellipsis / more menu
            Menu {
                Button {
                    // "Find in entry" — placeholder, no-op
                } label: {
                    Label(L10n.t("Find in Entry", "在日记中查找"), systemImage: "magnifyingglass")
                }
                if isEditMode {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label(L10n.t("Delete Entry", "删除日记"), systemImage: "trash")
                    }
                }
            } label: {
                toolbarIcon(systemName: "ellipsis", active: false)
            }
        }
        .padding(.horizontal, TreeholeTheme.spacingSmall)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .frame(maxWidth: 360)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func toolbarIcon(systemName: String, active: Bool) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 18))
            .foregroundStyle(active ? TreeholeTheme.softPurple : TreeholeTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                active
                    ? TreeholeTheme.softPurple.opacity(0.12)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 8)
            )
    }

    // MARK: - Save / Edit Logic

    private func handleSave() {
        if let existing = existingEntry {
            // Edit mode: update in place
            existing.text = draftText
            existing.title = draftTitle.isEmpty ? nil : draftTitle
            existing.moodTagRaw = draftMood.rawValue
            existing.entryDate = draftEntryDate

            // Photos: remove deleted ones, add new ones
            for fn in removedPhotoFilenames {
                PhotoStorage.deletePhotos([fn])
            }
            var allFilenames = existingPhotoFilenames
            for data in draftPhotoData {
                if let fn = PhotoStorage.savePhoto(data) {
                    allFilenames.append(fn)
                }
            }
            existing.photoFilenames = allFilenames.isEmpty ? nil : allFilenames

            // Audio: handle removal or new
            if existingAudioFilename == nil && draftAudioFilename == nil {
                // both cleared
                if let old = existing.audioFilename {
                    AudioStorage.deleteAudio(filename: old)
                }
                existing.audioFilename = nil
                existing.audioDurationSeconds = nil
                existing.audioTranscript = nil
            } else if let newFn = draftAudioFilename {
                // replaced with new recording
                if let old = existing.audioFilename, old != newFn {
                    AudioStorage.deleteAudio(filename: old)
                }
                existing.audioFilename = newFn
                existing.audioDurationSeconds = draftAudioDuration
                existing.audioTranscript = draftAudioTranscript
            }
            // else existingAudioFilename still set = keep existing, no change

            existing.latitude = draftLatitude
            existing.longitude = draftLongitude
            existing.locationName = draftLocationName
            existing.weatherTempC = draftWeatherTempC
            existing.weatherCode = draftWeatherCode
            existing.weatherEmoji = draftWeatherEmoji
            existing.weatherDescription = draftWeatherDescription

            try? modelContext.save()
            onSave(EntryDraft())
            dismiss()
        } else {
            // Create mode
            var draft = EntryDraft()
            draft.text = draftText
            draft.title = draftTitle
            draft.mood = draftMood
            draft.photoData = draftPhotoData
            draft.audioFilename = draftAudioFilename
            draft.audioDuration = draftAudioDuration
            draft.audioTranscript = draftAudioTranscript
            draft.latitude = draftLatitude
            draft.longitude = draftLongitude
            draft.locationName = draftLocationName
            draft.weatherTempC = draftWeatherTempC
            draft.weatherCode = draftWeatherCode
            draft.weatherEmoji = draftWeatherEmoji
            draft.weatherDescription = draftWeatherDescription
            draft.entryDate = draftEntryDate
            onSave(draft)
            dismiss()
        }
    }

    private func deleteEntry() {
        guard let existing = existingEntry else { return }
        if let filenames = existing.photoFilenames {
            PhotoStorage.deletePhotos(filenames)
        }
        if let audioFilename = existing.audioFilename {
            AudioStorage.deleteAudio(filename: audioFilename)
        }
        modelContext.delete(existing)
        try? modelContext.save()
        dismiss()
    }

    // MARK: - Populate from Existing

    private func populateFromExisting() {
        guard let entry = existingEntry else { return }
        draftText = entry.text
        draftTitle = entry.title ?? ""
        draftMood = entry.moodTag
        draftEntryDate = entry.entryDate
        existingPhotoFilenames = entry.photoFilenames ?? []
        existingAudioFilename = entry.audioFilename
        draftAudioDuration = entry.audioDurationSeconds
        draftAudioTranscript = entry.audioTranscript
        draftLatitude = entry.latitude
        draftLongitude = entry.longitude
        draftLocationName = entry.locationName
        draftWeatherTempC = entry.weatherTempC
        draftWeatherCode = entry.weatherCode
        draftWeatherEmoji = entry.weatherEmoji
        draftWeatherDescription = entry.weatherDescription
    }

    // MARK: - Recording Helpers

    private func startRecordingWithPermissionCheck() async {
        let granted = await audioRecorder.requestPermission()
        guard granted else {
            permissionDeniedMessage = L10n.t(
                "Microphone access denied. Enable it in Settings.",
                "麦克风权限被拒绝，请在设置中开启。"
            )
            return
        }
        permissionDeniedMessage = nil
        do {
            try audioRecorder.startRecording()
        } catch {
            permissionDeniedMessage = L10n.t("Unable to start recording.", "无法开始录音。")
        }
    }

    private func finishRecording() {
        guard let result = audioRecorder.stopRecording() else { return }
        if let filename = AudioStorage.saveAudio(result.data) {
            draftAudioFilename = filename
            draftAudioDuration = result.duration
            Task.detached(priority: .background) {
                let transcript = await transcribeAudio(data: result.data)
                await MainActor.run {
                    draftAudioTranscript = transcript
                }
            }
        }
    }

    private func transcribeAudio(data: Data) async -> String? {
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".m4a")
        do {
            try data.write(to: tmpURL)
        } catch {
            return nil
        }
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        let zhResult = await runSpeechRecognition(url: tmpURL, locale: Locale(identifier: "zh-CN"))
        let enResult = await runSpeechRecognition(url: tmpURL, locale: Locale(identifier: "en-US"))

        let best: String?
        switch (zhResult, enResult) {
        case (let zh?, let en?) where zh.count >= en.count:
            best = zh
        case (_, let en?):
            best = en
        case (let zh?, _):
            best = zh
        default:
            best = nil
        }
        return (best?.isEmpty == false) ? best : nil
    }

    private func runSpeechRecognition(url: URL, locale: Locale) async -> String? {
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else { return nil }
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else { return nil }
        return await withCheckedContinuation { continuation in
            let request = SFSpeechURLRecognitionRequest(url: url)
            request.shouldReportPartialResults = false
            recognizer.recognitionTask(with: request) { result, error in
                if let result = result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                } else if error != nil {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Location + Weather Helper

    private func fetchLocationAndWeather() async {
        isLoadingLocation = true
        defer { isLoadingLocation = false }
        let result = await locationService.fetchCurrentLocation()
        guard let loc = result else { return }
        draftLatitude = loc.latitude
        draftLongitude = loc.longitude
        draftLocationName = loc.name

        // Fetch weather in parallel (non-blocking)
        let lang = language
        async let weatherFetch = WeatherService.fetchWeather(lat: loc.latitude, lng: loc.longitude, language: lang)
        let weatherInfo = await weatherFetch
        if let w = weatherInfo {
            draftWeatherTempC = w.tempC
            draftWeatherCode = w.code
            draftWeatherEmoji = w.emoji
            draftWeatherDescription = w.description
        }
    }

    // MARK: - Format Helpers

    private func formatElapsed(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    @MainActor
    private func loadPhotos(from items: [PhotosPickerItem]) async {
        isLoadingPhotos = true
        defer { isLoadingPhotos = false }

        let currentCount = existingPhotoFilenames.count + draftPhotoData.count
        for item in items {
            guard currentCount + draftPhotoData.count < maxPhotos else { break }
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
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

// MARK: - AI Insights Card

private struct AIInsightsCard: View {
    let entries: [JournalEntry]
    let allSummaries: [JournalSummary]
    @Binding var isGenerating: Bool
    let language: String
    @Environment(\.modelContext) private var modelContext
    @AppStorage("ai_insights_card_expanded") private var isExpanded: Bool = false

    private var latestInsights: JournalSummary? {
        allSummaries.first { $0.kindRaw == "insights" }
    }

    private var last14DayEntries: [JournalEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return entries.filter { $0.displayDate >= cutoff }
    }

    private var collapsedSubtitle: String {
        if let insights = latestInsights {
            return L10n.t(
                "Updated \(insights.generatedAt.formatted(.relative(presentation: .named)))",
                "更新于 \(insights.generatedAt.formatted(date: .abbreviated, time: .omitted))"
            )
        } else if last14DayEntries.isEmpty {
            return L10n.t("Write a few entries first", "先写几条日记")
        } else {
            return L10n.t("Tap to view", "点击查看")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(TreeholeTheme.softPurple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t("AI Insights", "AI 洞察"))
                            .font(.headline)
                            .foregroundStyle(TreeholeTheme.textPrimary)
                        if !isExpanded {
                            Text(collapsedSubtitle)
                                .font(.caption2)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                    }
                    Spacer()
                    if isExpanded {
                        Button {
                            generateInsights()
                        } label: {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundStyle(TreeholeTheme.softPurple)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isGenerating)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TreeholeTheme.textLight)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                if isGenerating {
                    HStack {
                        ProgressView()
                        Text(L10n.t("Generating insights…", "正在生成洞察…"))
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textSecondary)
                    }
                } else if let insights = latestInsights {
                    Text(renderMarkdown(insights.summary))
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textSecondary)
                    Text(L10n.t("Generated \(insights.generatedAt.formatted(.relative(presentation: .named)))", "生成于 \(insights.generatedAt.formatted(date: .abbreviated, time: .omitted))"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.textLight)
                } else if last14DayEntries.isEmpty {
                    Text(L10n.t("Write a few entries to see your insights", "写几条日记后即可查看洞察"))
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textLight)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(L10n.t("Tap refresh to generate your insights", "点击刷新以生成你的洞察"))
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textLight)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func generateInsights() {
        let recentEntries = last14DayEntries
        guard !recentEntries.isEmpty else { return }
        guard !isGenerating else { return }
        isGenerating = true
        let lang = language
        let payloads = recentEntries.map { entry -> (date: String, mood: String, text: String) in
            let dateStr = entry.displayDate.formatted(.iso8601.year().month().day())
            return (date: dateStr, mood: entry.moodTag.rawValue, text: entry.text)
        }
        let windowStart = recentEntries.last?.displayDate ?? Date()
        Task {
            defer { isGenerating = false }
            guard let text = try? await SupabaseService.summarizeJournal(
                mode: "insights",
                language: lang,
                entries: payloads
            ) else { return }
            let summary = JournalSummary(
                kind: .insights,
                periodStart: windowStart,
                periodEnd: Date(),
                summary: text,
                language: lang
            )
            modelContext.insert(summary)
            try? modelContext.save()
        }
    }
}

// MARK: - AI Weekly Summary Card

private struct AIWeeklySummaryCard: View {
    let summary: JournalSummary

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            HStack {
                Image(systemName: "calendar.badge.checkmark")
                    .foregroundStyle(TreeholeTheme.skyBlue)
                Text(L10n.t("Weekly Summary", "本周摘要"))
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Spacer()
            }
            Text(renderMarkdown(summary.summary))
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textSecondary)
            Text(L10n.t("Week of \(summary.periodStart.formatted(date: .abbreviated, time: .omitted))", "\(summary.periodStart.formatted(date: .abbreviated, time: .omitted)) 这周"))
                .font(.caption2)
                .foregroundStyle(TreeholeTheme.textLight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

// MARK: - Markdown helper

/// Render AI-generated markdown text (e.g. **bold**, *italic*, lists) into an AttributedString.
/// Falls back to plain text if parsing fails.
func renderMarkdown(_ raw: String) -> AttributedString {
    let options = AttributedString.MarkdownParsingOptions(
        interpretedSyntax: .inlineOnlyPreservingWhitespace
    )
    if let attributed = try? AttributedString(markdown: raw, options: options) {
        return attributed
    }
    return AttributedString(raw)
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
