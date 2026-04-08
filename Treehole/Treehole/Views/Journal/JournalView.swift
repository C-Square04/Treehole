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
    @State private var draftText = ""
    @State private var draftMood: MoodTag = .calm
    @State private var draftPhotoData: [Data] = []
    @State private var draftDate: Date = Date()
    @State private var draftAudioFilename: String? = nil
    @State private var draftAudioDuration: Double? = nil
    @State private var draftAudioTranscript: String? = nil
    @State private var draftLatitude: Double? = nil
    @State private var draftLongitude: Double? = nil
    @State private var draftLocationName: String? = nil
    @State private var isGeneratingInsights = false
    @State private var isGeneratingWeekly = false

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
                    draftDate: $draftDate,
                    draftAudioFilename: $draftAudioFilename,
                    draftAudioDuration: $draftAudioDuration,
                    draftAudioTranscript: $draftAudioTranscript,
                    draftLatitude: $draftLatitude,
                    draftLongitude: $draftLongitude,
                    draftLocationName: $draftLocationName,
                    allowAnyDate: appState.isDeveloperMode,
                    onSave: {
                        let entry = JournalEntry(moodTag: draftMood, text: draftText)
                        // Backdating: keep current time-of-day on the chosen day so sort still feels natural.
                        let cal = Calendar.current
                        let timeComps = cal.dateComponents([.hour, .minute, .second], from: Date())
                        var dayComps = cal.dateComponents([.year, .month, .day], from: draftDate)
                        dayComps.hour = timeComps.hour
                        dayComps.minute = timeComps.minute
                        dayComps.second = timeComps.second
                        entry.createdAt = cal.date(from: dayComps) ?? draftDate
                        if !draftPhotoData.isEmpty {
                            var filenames: [String] = []
                            for data in draftPhotoData {
                                if let filename = PhotoStorage.savePhoto(data) {
                                    filenames.append(filename)
                                }
                            }
                            entry.photoFilenames = filenames.isEmpty ? nil : filenames
                        }
                        entry.audioFilename = draftAudioFilename
                        entry.audioDurationSeconds = draftAudioDuration
                        entry.audioTranscript = draftAudioTranscript
                        entry.latitude = draftLatitude
                        entry.longitude = draftLongitude
                        entry.locationName = draftLocationName
                        modelContext.insert(entry)
                        let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                        if let task = dailyTasks.first(where: { $0.type == .writeJournal && !$0.isCompleted }) {
                            economyVM.completeTask(task, economy: economy)
                        }
                        economyVM.incrementChallenge(type: .journalStreak, economy: economy, challenges: weeklyChallenges)
                        try? modelContext.save()
                        AnalyticsService.track("journal_written")
                        draftText = ""
                        draftMood = .calm
                        draftPhotoData = []
                        draftDate = Date()
                        draftAudioFilename = nil
                        draftAudioDuration = nil
                        draftAudioTranscript = nil
                        draftLatitude = nil
                        draftLongitude = nil
                        draftLocationName = nil
                        showNewEntry = false
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

    private var thisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return entries.filter { $0.createdAt > weekAgo }.count
    }

    private var thisMonthCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return entries.filter { $0.createdAt > monthAgo }.count
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
        entries.filter { $0.createdAt >= currentWeekStart }
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
            let dateStr = entry.createdAt.formatted(.iso8601.year().month().day())
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
    @Binding var draftDate: Date
    @Binding var draftAudioFilename: String?
    @Binding var draftAudioDuration: Double?
    @Binding var draftAudioTranscript: String?
    @Binding var draftLatitude: Double?
    @Binding var draftLongitude: Double?
    @Binding var draftLocationName: String?
    let allowAnyDate: Bool
    let onSave: () -> Void

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingPhotos = false
    @State private var audioRecorder = AudioRecorder()
    @State private var locationService = LocationService()
    @State private var isLoadingLocation = false
    @State private var permissionDeniedMessage: String? = nil

    private let maxPhotos = 10

    private var dateRange: ClosedRange<Date> {
        let now = Date()
        if allowAnyDate {
            // Allow up to 1 year in past to 1 year in future for developer mode.
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
                    VStack(spacing: TreeholeTheme.spacingLarge) {
                        // Date picker — backdate up to 3 days; developer mode allows any date
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            Text(L10n.t("Date", "日期"))
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            DatePicker(
                                "",
                                selection: $draftDate,
                                in: dateRange,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            if allowAnyDate {
                                Text(L10n.t("Developer mode: any date allowed", "开发者模式：可选任意日期"))
                                    .font(.caption2)
                                    .foregroundStyle(TreeholeTheme.warmGold)
                            } else {
                                Text(L10n.t("You can backdate up to 3 days", "可以补写最近 3 天的日记"))
                                    .font(.caption2)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }
                        }

                        // Mood picker
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            Text(L10n.t("How are you feeling?", "你现在感觉怎么样？"))
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            MoodPicker(selectedMood: $draftMood)
                        }

                        // MARK: - Voice Note Section
                        voiceNoteSection

                        // MARK: - Location Section
                        locationSection

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

    // MARK: - Voice Note Section

    @ViewBuilder
    private var voiceNoteSection: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
            Text(L10n.t("Voice Note", "语音备注"))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)

            if let message = permissionDeniedMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.coral)
            } else if audioRecorder.isRecording {
                // Recording state
                VStack(spacing: TreeholeTheme.spacingTight) {
                    HStack(spacing: TreeholeTheme.spacingSmall) {
                        Image(systemName: "waveform")
                            .foregroundStyle(TreeholeTheme.coral)
                            .symbolEffect(.variableColor.iterative, isActive: true)
                        Text(formatElapsed(audioRecorder.elapsed))
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(TreeholeTheme.textPrimary)
                        Text(L10n.t("/ 5:00 max", "/ 最长 5:00"))
                            .font(.caption)
                            .foregroundStyle(TreeholeTheme.textLight)
                        Spacer()
                    }
                    // Simple level bar
                    ProgressView(value: Double(audioRecorder.currentLevel))
                        .progressViewStyle(.linear)
                        .tint(TreeholeTheme.coral)
                    HStack(spacing: TreeholeTheme.spacingSmall) {
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
                            Label(L10n.t("Cancel", "取消"), systemImage: "xmark.circle")
                                .font(.subheadline)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                    }
                }
            } else if let filename = draftAudioFilename, let duration = draftAudioDuration {
                // Recorded state
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
                        AudioStorage.deleteAudio(filename: filename)
                        draftAudioFilename = nil
                        draftAudioDuration = nil
                        draftAudioTranscript = nil
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(TreeholeTheme.coral)
                    }
                }
                .padding(TreeholeTheme.spacingSmall)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
            } else {
                // Idle state
                Button {
                    Task { await startRecordingWithPermissionCheck() }
                } label: {
                    HStack(spacing: TreeholeTheme.spacingTight) {
                        Image(systemName: "mic.fill")
                        Text(L10n.t("Record Voice Note", "录制语音备注"))
                            .font(.subheadline)
                    }
                    .foregroundStyle(TreeholeTheme.coral)
                    .padding(.vertical, TreeholeTheme.spacingTight)
                    .padding(.horizontal, TreeholeTheme.spacingSmall)
                    .background(TreeholeTheme.coral.opacity(0.15), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                }
            }
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Location Section

    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
            Text(L10n.t("Location", "位置"))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)

            if isLoadingLocation {
                HStack(spacing: TreeholeTheme.spacingTight) {
                    ProgressView().scaleEffect(0.8)
                    Text(L10n.t("Finding location…", "正在获取位置…"))
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textSecondary)
                }
            } else if let name = draftLocationName {
                HStack(spacing: TreeholeTheme.spacingTight) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(TreeholeTheme.coral)
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.textPrimary)
                    Spacer()
                    Button {
                        draftLocationName = nil
                        draftLatitude = nil
                        draftLongitude = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(TreeholeTheme.textLight)
                    }
                }
                .padding(.horizontal, TreeholeTheme.spacingSmall)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            } else {
                Button {
                    Task { await fetchLocation() }
                } label: {
                    HStack(spacing: TreeholeTheme.spacingTight) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(L10n.t("Add Location", "添加位置"))
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
            // Run transcription in background
            Task.detached(priority: .background) {
                let transcript = await transcribeAudio(data: result.data)
                await MainActor.run {
                    draftAudioTranscript = transcript
                }
            }
        }
    }

    private func transcribeAudio(data: Data) async -> String? {
        // Write to a temp file for SFSpeechURLRecognitionRequest
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString + ".m4a")
        do {
            try data.write(to: tmpURL)
        } catch {
            return nil
        }
        defer { try? FileManager.default.removeItem(at: tmpURL) }

        // Try zh-CN and en-US; pick the longer result
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

    // MARK: - Location Helper

    private func fetchLocation() async {
        isLoadingLocation = true
        defer { isLoadingLocation = false }
        let result = await locationService.fetchCurrentLocation()
        draftLatitude = result?.latitude
        draftLongitude = result?.longitude
        draftLocationName = result?.name
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

// MARK: - AI Insights Card

private struct AIInsightsCard: View {
    let entries: [JournalEntry]
    let allSummaries: [JournalSummary]
    @Binding var isGenerating: Bool
    let language: String
    @Environment(\.modelContext) private var modelContext

    private var latestInsights: JournalSummary? {
        allSummaries.first { $0.kindRaw == "insights" }
    }

    private var last14DayEntries: [JournalEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return entries.filter { $0.createdAt >= cutoff }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(TreeholeTheme.softPurple)
                Text(L10n.t("AI Insights", "AI 洞察"))
                    .font(.headline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Spacer()
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
                .disabled(isGenerating)
            }

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
            let dateStr = entry.createdAt.formatted(.iso8601.year().month().day())
            return (date: dateStr, mood: entry.moodTag.rawValue, text: entry.text)
        }
        let windowStart = recentEntries.last?.createdAt ?? Date()
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

// MARK: - Mini Stat

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
