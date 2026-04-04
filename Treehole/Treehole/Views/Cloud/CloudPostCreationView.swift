import SwiftUI
import SwiftData

struct CloudPostCreationView: View {
    @Environment(\.modelContext) private var modelContext
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
                            Text("How are you feeling?")
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            MoodPicker(selectedMood: $viewModel.draftMood)
                        }

                        // Text editor
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            Text("Share your thoughts...")
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
                            Text("Posting as \(appState.currentAlias)")
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                        .glassCard()
                    }
                    .padding()
                }
            }
            .navigationTitle("New Cloud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetDraft()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        viewModel.createPost(
                            context: modelContext,
                            authorAlias: appState.currentAlias,
                            language: appState.preferredLanguage
                        )
                    }
                    .disabled(!viewModel.isValid)
                    .tint(TreeholeTheme.coral)
                }
            }
        }
    }
}
