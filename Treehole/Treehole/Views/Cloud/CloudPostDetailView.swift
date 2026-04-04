import SwiftUI
import SwiftData

struct CloudPostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let post: CloudPost
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            TreeholeTheme.cloudyBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: TreeholeTheme.spacingLarge) {
                    // Header
                    HStack {
                        Text(post.moodTag.emoji)
                            .font(.largeTitle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.authorAlias)
                                .font(.headline)
                                .foregroundStyle(TreeholeTheme.textPrimary)
                            Text(post.createdAt, style: .date)
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                        }
                        Spacer()
                        Text(post.moodTag.labelEN)
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
                                Text("Treehole Spirit")
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
                        GentleInteractionButton(icon: "wind", label: "Breeze")
                        GentleInteractionButton(icon: "heart.fill", label: "Hug")
                        GentleInteractionButton(icon: "sparkles", label: "Starlight")
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this cloud?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(post)
                dismiss()
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
