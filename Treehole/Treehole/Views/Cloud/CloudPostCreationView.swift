import SwiftUI
import SwiftData

struct CloudPostCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @Bindable var viewModel: CloudPostViewModel

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
                            MoodPicker(selectedMood: $viewModel.draftMood)
                        }

                        // Text editor
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            Text(L10n.t("Share your thoughts...", "分享你的想法..."))
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)

                            TextEditor(text: $viewModel.draftText)
                                .frame(minHeight: 150)
                                .padding(TreeholeTheme.spacingSmall)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                                .scrollContentBackground(.hidden)

                            HStack {
                                Spacer()
                                Text("\(viewModel.characterCount)/500")
                                    .font(.caption)
                                    .foregroundStyle(
                                        viewModel.characterCount > 500
                                            ? .red
                                            : TreeholeTheme.textLight
                                    )
                            }
                        }

                        // Anonymous reminder
                        HStack(spacing: TreeholeTheme.spacingTight) {
                            Image(systemName: "theatermasks")
                                .foregroundStyle(TreeholeTheme.softPurple)
                            Text("\(L10n.t("Posting as", "发布身份")) \(appState.currentAlias)")
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                        .glassCard()
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.t("New Cloud", "新云朵"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("Cancel", "取消")) {
                        viewModel.resetDraft()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("Post", "发布")) {
                        Task {
                            await viewModel.createPost(
                                authorAlias: appState.currentAlias,
                                language: appState.preferredLanguage
                            )
                        }
                    }
                    .disabled(!viewModel.isValid)
                    .tint(TreeholeTheme.coral)
                }
            }
        }
    }
}
