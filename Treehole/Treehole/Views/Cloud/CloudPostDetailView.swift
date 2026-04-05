import SwiftUI

struct CloudPostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let post: RemoteCloudPost
    var viewModel: CloudPostViewModel
    @State private var showDeleteConfirmation = false

    // Comments
    @State private var comments: [RemoteComment] = []
    @State private var commentText: String = ""
    @State private var isLoadingComments: Bool = false
    @State private var isPostingComment: Bool = false
    @State private var commentError: String? = nil

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
                        .frame(maxWidth: .infinity, alignment: .leading)
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

                    // Comments section
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingSmall) {
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(TreeholeTheme.textLight.opacity(0.4))
                            Text(
                                comments.isEmpty
                                    ? L10n.t("Comments", "评论")
                                    : L10n.t("Comments (\(comments.count))", "评论 (\(comments.count))")
                            )
                            .font(.caption)
                            .foregroundStyle(TreeholeTheme.textLight)
                            .fixedSize()
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(TreeholeTheme.textLight.opacity(0.4))
                        }

                        if isLoadingComments {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.vertical, TreeholeTheme.spacingSmall)
                        } else if comments.isEmpty {
                            Text(L10n.t("Be the first to leave a message 🌿", "第一个留言吧 🌿"))
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textLight)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, TreeholeTheme.spacingSmall)
                        } else {
                            ForEach(comments) { comment in
                                DetailCommentBubble(comment: comment)
                            }
                        }

                        if let error = commentError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        // Comment input
                        HStack(spacing: TreeholeTheme.spacingSmall) {
                            TextField(
                                L10n.t("Leave a kind word...", "留下暖心的话..."),
                                text: $commentText,
                                axis: .vertical
                            )
                            .font(.subheadline)
                            .lineLimit(1...4)
                            .submitLabel(.send)
                            .onSubmit { Task { await postComment() } }

                            Button {
                                Task { await postComment() }
                            } label: {
                                if isPostingComment {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .foregroundStyle(TreeholeTheme.softPurple)
                                }
                            }
                            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPostingComment)
                        }
                        .padding(TreeholeTheme.spacingSmall)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                    }
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
        .task {
            await loadComments()
        }
    }

    // MARK: - Actions

    private func loadComments() async {
        isLoadingComments = true
        do {
            comments = try await SupabaseService.fetchComments(postId: post.id)
        } catch {
            // Silently fail — comments are supplementary
        }
        isLoadingComments = false
    }

    private func postComment() async {
        let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        isPostingComment = true
        commentError = nil
        do {
            let newComment = try await SupabaseService.addComment(
                postId: post.id,
                authorAlias: appState.currentAlias,
                text: text
            )
            comments.append(newComment)
            commentText = ""
        } catch {
            commentError = error.localizedDescription
        }
        isPostingComment = false
    }
}

// MARK: - Detail Comment Bubble

private struct DetailCommentBubble: View {
    let comment: RemoteComment

    var body: some View {
        HStack(alignment: .top, spacing: TreeholeTheme.spacingSmall) {
            Text("💬")
                .font(.caption)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(comment.authorAlias)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(TreeholeTheme.textSecondary)
                    if comment.isOwn {
                        Text(L10n.t("(You)", "(你)"))
                            .font(.caption2)
                            .foregroundStyle(TreeholeTheme.softPurple)
                    }
                    Spacer()
                    Text(comment.date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.textLight)
                }
                Text(comment.text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
            }
        }
        .padding(TreeholeTheme.spacingSmall)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
    }
}

// MARK: - Gentle Interaction Button

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
