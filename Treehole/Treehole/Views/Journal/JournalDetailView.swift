import SwiftUI
import SwiftData

struct JournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Query(sort: \JournalSummary.generatedAt, order: .reverse) private var allSummaries: [JournalSummary]
    let entry: JournalEntry

    @State private var showDeleteConfirm = false
    @State private var isGeneratingSummary = false

    var moodLabel: String {
        appState.preferredLanguage == "zh-Hans" ? entry.moodTag.labelZH : entry.moodTag.labelEN
    }

    private var existingSummary: JournalSummary? {
        allSummaries.first { $0.kindRaw == "single" && $0.sourceEntryId == entry.id }
    }

    var body: some View {
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

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: TreeholeTheme.spacingSmall) {
                                    ForEach(filenames, id: \.self) { filename in
                                        if let image = PhotoStorage.loadImage(filename) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                                .padding(.vertical, 4)
                            }
                        }
                        .glassCard()
                    }

                    Spacer(minLength: TreeholeTheme.spacingXL)
                }
                .padding(.horizontal, TreeholeTheme.spacingMedium)
            }
        }
        .navigationTitle(L10n.t("Journal Detail", "日记详情"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(TreeholeTheme.coral)
                }
            }
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
                modelContext.delete(entry)
                try? modelContext.save()
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
