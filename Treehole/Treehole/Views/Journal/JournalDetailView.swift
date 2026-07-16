import SwiftUI
import SwiftData
import MapKit

struct JournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(sort: \JournalSummary.generatedAt, order: .reverse) private var allSummaries: [JournalSummary]
    let entry: JournalEntry
    /// Called after the entry is deleted (from the toolbar or the edit sheet)
    /// so the presenting view can clear its selection — dismiss() alone is a
    /// no-op for a NavigationSplitView detail column on iPad.
    var onDelete: (() -> Void)? = nil

    @State private var showDeleteConfirm = false
    @State private var isGeneratingSummary = false
    @State private var showEditSheet = false

    var moodLabel: String {
        appState.preferredLanguage == "zh-Hans" ? entry.moodTag.labelZH : entry.moodTag.labelEN
    }

    private var existingSummary: JournalSummary? {
        allSummaries.first { $0.kindRaw == "single" && $0.sourceEntryId == entry.id }
    }

    var body: some View {
        if entry.isDeleted {
            // The backing model was deleted out from under this view (e.g. via
            // the edit sheet) — rendering its fields would fault a deleted
            // SwiftData object. Show nothing and pop.
            Color.clear.onAppear { dismiss() }
        } else {
            content
        }
    }

    private var content: some View {
        ZStack {
            TreeholeTheme.warmBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: TreeholeTheme.spacingLarge) {

                    // MARK: - Mood Header
                    VStack(spacing: TreeholeTheme.spacingTight) {
                        Text(entry.moodTag.emoji)
                            .font(.system(size: 64))
                        Text(moodLabel)
                            .font(.title2.bold())
                            .foregroundStyle(TreeholeTheme.textPrimary)
                        Text(entry.formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(TreeholeTheme.textLight)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, TreeholeTheme.spacingMedium)

                    // MARK: - Journal Text
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                        Text(entry.text)
                            .font(.body)
                            .foregroundStyle(TreeholeTheme.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .glassCard()

                    // MARK: - AI Summary Section
                    if appState.allowAIJournalAnalysis {
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(TreeholeTheme.softPurple)
                                Text(L10n.t("AI Summary", "AI 摘要"))
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                                Spacer()
                                if existingSummary == nil {
                                    Button {
                                        generateEntrySummary()
                                    } label: {
                                        if isGeneratingSummary {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Text(L10n.t("Generate", "生成"))
                                                .font(.subheadline)
                                                .foregroundStyle(TreeholeTheme.softPurple)
                                        }
                                    }
                                    .disabled(isGeneratingSummary)
                                }
                            }

                            if isGeneratingSummary {
                                HStack {
                                    ProgressView()
                                    Text(L10n.t("Analyzing…", "分析中…"))
                                        .font(.subheadline)
                                        .foregroundStyle(TreeholeTheme.textSecondary)
                                }
                            } else if let s = existingSummary {
                                Text(renderMarkdown(s.summary))
                                    .font(.subheadline)
                                    .foregroundStyle(TreeholeTheme.textSecondary)
                            } else {
                                Text(L10n.t("Tap Generate to create an AI summary of this entry.", "点击生成，为此篇日记创建 AI 摘要。"))
                                    .font(.caption)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassCard()
                    }

                    // MARK: - Photo Gallery
                    if let filenames = entry.photoFilenames, !filenames.isEmpty {
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundStyle(TreeholeTheme.skyBlue)
                                Text(L10n.t("Photos", "照片"))
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                                Spacer()
                                Text("\(filenames.count)")
                                    .font(.caption)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }

                            let columns = Array(repeating: GridItem(.flexible(), spacing: TreeholeTheme.spacingSmall), count: 3)
                            LazyVGrid(columns: columns, spacing: TreeholeTheme.spacingSmall) {
                                ForEach(filenames, id: \.self) { filename in
                                    if let image = PhotoStorage.loadImage(filename) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                                    }
                                }
                            }
                        }
                        .glassCard()
                    }

                    // MARK: - Voice Note Section
                    if let audioFilename = entry.audioFilename {
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Image(systemName: "waveform.circle.fill")
                                    .foregroundStyle(TreeholeTheme.skyBlue)
                                Text(L10n.t("Voice Note", "语音备注"))
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                                Spacer()
                                Button {
                                    if let fn = entry.audioFilename {
                                        AudioStorage.deleteAudio(filename: fn)
                                    }
                                    entry.audioFilename = nil
                                    entry.audioDurationSeconds = nil
                                    entry.audioTranscript = nil
                                    try? modelContext.save()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundStyle(TreeholeTheme.coral)
                                }
                            }

                            if let audioURL = AudioStorage.loadAudioURL(filename: audioFilename) {
                                AudioPlayerView(
                                    audioURL: audioURL,
                                    totalDuration: entry.audioDurationSeconds ?? 0
                                )
                            } else {
                                Text(L10n.t("Audio file not found.", "音频文件未找到。"))
                                    .font(.caption)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }

                            if let transcript = entry.audioTranscript {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.t("Voice transcript / 语音转录", "语音转录 / Voice transcript"))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(TreeholeTheme.textLight)
                                    Text(transcript)
                                        .font(.subheadline.italic())
                                        .foregroundStyle(TreeholeTheme.textSecondary)
                                }
                                .padding(TreeholeTheme.spacingSmall)
                                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                            }
                        }
                        .glassCard()
                    }

                    // MARK: - Location + Weather + Date Chip
                    // Combined: 📍 Brooklyn · ☀️ 18°C · Apr 5
                    if entry.locationName != nil || entry.weatherEmoji != nil {
                        HStack(spacing: TreeholeTheme.spacingTight) {
                            if let locationName = entry.locationName {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(TreeholeTheme.coral)
                                Text(locationName)
                                    .font(.subheadline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                            }
                            if let emoji = entry.weatherEmoji,
                               let temp = entry.weatherTempC {
                                if entry.locationName != nil {
                                    Text("·")
                                        .foregroundStyle(TreeholeTheme.textLight)
                                }
                                Text("\(emoji) \(Int(temp.rounded()))°C")
                                    .font(.subheadline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                            }
                            Spacer()
                            Text(entry.displayDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                        .padding(.horizontal, TreeholeTheme.spacingSmall)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                        .onTapGesture {
                            if let lat = entry.latitude, let lon = entry.longitude {
                                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                let placemark = MKPlacemark(coordinate: coordinate)
                                let mapItem = MKMapItem(placemark: placemark)
                                mapItem.name = entry.locationName ?? ""
                                mapItem.openInMaps()
                            }
                        }
                    }

                    Spacer(minLength: TreeholeTheme.spacingXL)
                }
                .padding(.horizontal, TreeholeTheme.spacingMedium)
            }
        }
        .navigationTitle(L10n.t("Journal Detail", "日记详情"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(TreeholeTheme.softPurple)
                }
            }
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(TreeholeTheme.coral)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            JournalEntryEditor(
                existingEntry: entry,
                allowAnyDate: appState.isDeveloperMode,
                language: appState.preferredLanguage,
                onSave: { _ in
                    showEditSheet = false
                },
                onDelete: {
                    // Entry deleted inside the editor — this view must also go.
                    showEditSheet = false
                    onDelete?()
                    dismiss()
                }
            )
        }
        .confirmationDialog(
            L10n.t("Delete this entry?", "删除这篇日记？"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(L10n.t("Delete", "删除"), role: .destructive) {
                if let filenames = entry.photoFilenames {
                    PhotoStorage.deletePhotos(filenames)
                }
                if let audioFilename = entry.audioFilename {
                    AudioStorage.deleteAudio(filename: audioFilename)
                }
                modelContext.delete(entry)
                try? modelContext.save()
                onDelete?()
                dismiss()
            }
            Button(L10n.t("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(L10n.t("This action cannot be undone.", "此操作无法撤销。"))
        }
    }

    private func generateEntrySummary() {
        guard appState.allowAIJournalAnalysis else { return }
        guard existingSummary == nil else { return }
        guard !isGeneratingSummary else { return }
        isGeneratingSummary = true
        let language = appState.preferredLanguage
        let entryId = entry.id
        let dateStr = entry.createdAt.formatted(.iso8601.year().month().day())
        let mood = entry.moodTag.rawValue
        let text = entry.text
        let entryDate = entry.createdAt
        Task {
            defer { isGeneratingSummary = false }
            guard let result = try? await SupabaseService.summarizeJournal(
                mode: "single",
                language: language,
                entries: [(date: dateStr, mood: mood, text: text)]
            ) else { return }
            let summary = JournalSummary(
                kind: .single,
                periodStart: entryDate,
                periodEnd: entryDate,
                summary: result,
                language: language,
                sourceEntryId: entryId
            )
            modelContext.insert(summary)
            try? modelContext.save()
        }
    }
}
