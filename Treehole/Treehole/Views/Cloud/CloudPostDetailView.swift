import SwiftUI

struct CloudPostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let post: RemoteCloudPost
    var viewModel: CloudPostViewModel
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            TreeholeTheme.cloudyBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: TreeholeTheme.spacingLarge) {
                    // Header
                    HStack {
                        Text(post.mood.emoji)
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.authorAlias)
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            Text(post.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                        if post.isOwn {
                            Text(L10n.t("(You)", "(你)"))
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.softPurple)
                        }
                        Spacer()
                        Text(appState.preferredLanguage == "zh-Hans" ? post.mood.labelZH : post.mood.labelEN)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(TreeholeTheme.softPurple.opacity(0.2), in: Capsule())
                            .foregroundStyle(TreeholeTheme.softPurple)
                    }
                    .glassCard()

                    // Post content
                    Text(post.text)
                        .font(.body)
                        .foregroundStyle(TreeholeTheme.textPrimary)
                        .glassCard()

                    // NPC Reply
                    if let npcReply = post.npcReplyText {
                        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
                            HStack {
                                Image(systemName: "bubble.left.fill")
                                    .foregroundStyle(TreeholeTheme.warmGold)
                                Text(L10n.t("Treehole Spirit", "树洞精灵"))
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                            }
                            Text(npcReply)
                                .font(.body)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                        }
                        .accentCard(TreeholeTheme.warmGold)
                    }

                    // Gentle interactions
                    HStack(spacing: TreeholeTheme.spacingMedium) {
                        GentleInteractionButton(icon: "wind", label: L10n.t("Breeze", "微风"))
                        GentleInteractionButton(icon: "heart.fill", label: L10n.t("Hug", "拥抱"))
                        GentleInteractionButton(icon: "sparkles", label: L10n.t("Starlight", "星光"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if post.isOwn {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog(L10n.t("Delete this cloud?", "删除这朵云？"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button(L10n.t("Delete", "删除"), role: .destructive) {
                Task {
                    await viewModel.deletePost(id: post.id)
                    dismiss()
                }
            }
        }
    }
}

private struct GentleInteractionButton: View {
    let icon: String
    let label: String
    @State private var tapped = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                tapped = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                tapped = false
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .scaleEffect(tapped ? 1.3 : 1.0)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(TreeholeTheme.softPurple)
            .frame(maxWidth: .infinity)
            .padding(.vertical, TreeholeTheme.spacingSmall)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
        }
        .buttonStyle(.plain)
    }
}
