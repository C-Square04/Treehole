import SwiftUI
import SwiftData

struct JournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let entry: JournalEntry

    @State private var showDeleteConfirm = false

    var moodLabel: String {
        appState.preferredLanguage == "zh-Hans" ? entry.moodTag.labelZH : entry.moodTag.labelEN
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

                    // MARK: - Photo Gallery
                    if let photos = entry.photoData, !photos.isEmpty {
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundStyle(TreeholeTheme.skyBlue)
                                Text(L10n.t("Photos", "照片"))
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                                Spacer()
                                Text("\(photos.count)")
                                    .font(.caption)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: TreeholeTheme.spacingSmall) {
                                    ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                                        if let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
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
                modelContext.delete(entry)
                try? modelContext.save()
                dismiss()
            }
            Button(L10n.t("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(L10n.t("This action cannot be undone.", "此操作无法撤销。"))
        }
    }
}
