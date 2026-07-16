import SwiftUI

struct CloudPostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    let post: RemoteCloudPost
    var viewModel: CloudPostViewModel
    @State private var showDeleteConfirmation = false

    // UGC moderation (App Review guideline 1.2)
    @State private var showReportDialog = false
    @State private var moderationConfirmation: String? = nil

    // Comments
    @State private var comments: [RemoteComment] = []
    @State private var commentText: String = ""
    @State private var isLoadingComments: Bool = false
    @State private var isPostingComment: Bool = false
    @State private var commentError: String? = nil

    // Reactions
    @State private var reactionCounts: ReactionCounts? = nil
    @State private var myReactions: Set<String> = []

    // Visual effects
    @State private var showBreezeEffect = false
    @State private var showHugEffect = false
    @State private var showStarlightEffect = false

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

                    // Reaction bar
                    ReactionBar(
                        postId: post.id,
                        reactionCounts: reactionCounts,
                        myReactions: $myReactions,
                        showBreezeEffect: $showBreezeEffect,
                        showHugEffect: $showHugEffect,
                        showStarlightEffect: $showStarlightEffect,
                        onCountsUpdated: { updated in
                            reactionCounts = updated
                        }
                    )

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
                            .accessibilityLabel(L10n.t("Send comment", "发送评论"))
                        }
                        .padding(TreeholeTheme.spacingSmall)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                    }
                }
                .padding()
            }

            // Reaction visual effects overlay
            ReactionEffectsOverlay(
                showBreezeEffect: showBreezeEffect,
                showHugEffect: showHugEffect,
                showStarlightEffect: showStarlightEffect
            )

            // Moderation confirmation banner (auto-dismisses the view shortly after)
            if let confirmation = moderationConfirmation {
                VStack {
                    Text(confirmation)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, TreeholeTheme.spacingSmall)
                        .padding(.vertical, 6)
                        .background(TreeholeTheme.softPurple.opacity(0.9), in: Capsule())
                    Spacer()
                }
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TreeholeTheme.textLight)
                }
                .accessibilityLabel(L10n.t("Close", "关闭"))
            }
            if post.isOwn {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel(L10n.t("Delete cloud", "删除云朵"))
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showReportDialog = true
                        } label: {
                            Label(L10n.t("Report Cloud", "举报云朵"), systemImage: "flag")
                        }
                        Button(role: .destructive) {
                            blockAuthor()
                        } label: {
                            Label(L10n.t("Hide Clouds from This Author", "隐藏此作者的云朵"), systemImage: "hand.raised")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(TreeholeTheme.textLight)
                    }
                    .accessibilityLabel(L10n.t("More options", "更多选项"))
                    .accessibilityHint(L10n.t("Report this cloud or hide its author", "举报这朵云或隐藏其作者"))
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
        .confirmationDialog(
            L10n.t("Why are you reporting this cloud?", "你为什么要举报这朵云？"),
            isPresented: $showReportDialog,
            titleVisibility: .visible
        ) {
            ForEach(CloudReportReason.allCases, id: \.rawValue) { reason in
                Button(reason.label) {
                    reportPost(reason: reason)
                }
            }
        }
        .task {
            await loadComments()
            await loadReactions()
        }
    }

    // MARK: - Moderation

    private func reportPost(reason: CloudReportReason) {
        // Best-effort server report; local hide never waits on the network
        Task { await SupabaseService.reportPost(id: post.id, reason: reason.rawValue) }
        HiddenPostsStore.shared.hidePost(id: post.id)
        viewModel.remotePosts.removeAll { $0.id == post.id }
        confirmAndDismiss(L10n.t("Thanks — this cloud is hidden for you.", "谢谢 — 这朵云已为你隐藏。"))
        AnalyticsService.track("cloud_reported", properties: ["reason": reason.rawValue])
    }

    private func blockAuthor() {
        HiddenPostsStore.shared.blockAuthor(deviceId: post.deviceId)
        viewModel.remotePosts = HiddenPostsStore.shared.filter(viewModel.remotePosts)
        confirmAndDismiss(L10n.t("Clouds from this author are now hidden for you.", "已为你隐藏此作者的云朵。"))
        AnalyticsService.track("cloud_author_blocked")
    }

    private func confirmAndDismiss(_ message: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            moderationConfirmation = message
        }
        // Brief beat so the confirmation is readable before the view goes away
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            dismiss()
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

    private func loadReactions() async {
        async let countsTask = SupabaseService.fetchReactionCounts(postId: post.id)
        async let myReactionsTask = SupabaseService.fetchMyReactions(postId: post.id)
        reactionCounts = try? await countsTask
        myReactions = (try? await myReactionsTask) ?? []
    }

    private func postComment() async {
        // Keyboard Send bypasses the button's .disabled — guard against a duplicate in-flight submit
        guard !isPostingComment else { return }
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
            AnalyticsService.track("cloud_commented")
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

// MARK: - Reaction Bar

struct ReactionBar: View {
    let postId: String
    let reactionCounts: ReactionCounts?
    @Binding var myReactions: Set<String>
    @Binding var showBreezeEffect: Bool
    @Binding var showHugEffect: Bool
    @Binding var showStarlightEffect: Bool
    let onCountsUpdated: (ReactionCounts) -> Void

    // Local optimistic counts
    @State private var localBreeze: Int = 0
    @State private var localHug: Int = 0
    @State private var localStarlight: Int = 0

    // Reaction types with a network request in flight — taps are ignored until it settles,
    // otherwise a double-tap races an add against a remove and desyncs from the server
    @State private var inFlightReactions: Set<String> = []

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            ReactionButton(
                emoji: "🌬️",
                label: L10n.t("Breeze", "微风"),
                count: localBreeze,
                isActive: myReactions.contains("breeze"),
                activeColor: TreeholeTheme.skyBlue
            ) {
                Task { await toggleReaction("breeze") }
            }

            Divider()
                .frame(height: 28)
                .opacity(0.4)

            ReactionButton(
                emoji: "🤗",
                label: L10n.t("Hug", "拥抱"),
                count: localHug,
                isActive: myReactions.contains("hug"),
                activeColor: TreeholeTheme.coral
            ) {
                Task { await toggleReaction("hug") }
            }

            Divider()
                .frame(height: 28)
                .opacity(0.4)

            ReactionButton(
                emoji: "✨",
                label: L10n.t("Starlight", "星光"),
                count: localStarlight,
                isActive: myReactions.contains("starlight"),
                activeColor: TreeholeTheme.warmGold
            ) {
                Task { await toggleReaction("starlight") }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TreeholeTheme.spacingSmall)
        .padding(.horizontal, TreeholeTheme.spacingMedium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
        .onAppear {
            if let counts = reactionCounts {
                syncCounts(counts)
            }
        }
        .onChange(of: reactionCounts?.totalCount) { _, _ in
            if let counts = reactionCounts {
                syncCounts(counts)
            }
        }
    }

    private func syncCounts(_ counts: ReactionCounts) {
        localBreeze = counts.breezeCount
        localHug = counts.hugCount
        localStarlight = counts.starlightCount
    }

    private func toggleReaction(_ type: String) async {
        guard !inFlightReactions.contains(type) else { return }
        inFlightReactions.insert(type)
        defer { inFlightReactions.remove(type) }

        let isCurrentlyReacted = myReactions.contains(type)

        // Optimistic update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if isCurrentlyReacted {
                myReactions.remove(type)
                adjustCount(type: type, delta: -1)
            } else {
                myReactions.insert(type)
                adjustCount(type: type, delta: 1)
                triggerEffect(type: type)
            }
        }

        // Persist
        do {
            if isCurrentlyReacted {
                try await SupabaseService.removeReaction(postId: postId, type: type)
            } else {
                try await SupabaseService.addReaction(postId: postId, type: type)
                AnalyticsService.track("cloud_reacted", properties: ["type": type])
            }
            // Refresh counts from server
            let updated = try await SupabaseService.fetchReactionCounts(postId: postId)
            onCountsUpdated(updated)
            syncCounts(updated)
        } catch {
            // Revert optimistic update on failure
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if isCurrentlyReacted {
                    myReactions.insert(type)
                    adjustCount(type: type, delta: 1)
                } else {
                    myReactions.remove(type)
                    adjustCount(type: type, delta: -1)
                }
            }
        }
    }

    private func adjustCount(type: String, delta: Int) {
        switch type {
        case "breeze": localBreeze = max(0, localBreeze + delta)
        case "hug": localHug = max(0, localHug + delta)
        case "starlight": localStarlight = max(0, localStarlight + delta)
        default: break
        }
    }

    private func triggerEffect(type: String) {
        switch type {
        case "breeze":
            showBreezeEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showBreezeEffect = false
            }
        case "hug":
            showHugEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showHugEffect = false
            }
        case "starlight":
            showStarlightEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                showStarlightEffect = false
            }
        default: break
        }
    }
}

// MARK: - Reaction Button

private struct ReactionButton: View {
    let emoji: String
    let label: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                pressed = false
            }
            action()
        }) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.callout)
                    .scaleEffect(pressed ? 1.35 : 1.0)
                Text(count > 0 ? "\(count)" : label)
                    .font(.caption)
                    .foregroundStyle(isActive ? activeColor : TreeholeTheme.textSecondary)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .padding(.horizontal, TreeholeTheme.spacingTight)
            .padding(.vertical, 6)
            .background(
                isActive
                    ? activeColor.opacity(0.18)
                    : Color.clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: pressed)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .accessibilityLabel(count > 0 ? "\(label), \(count)" : label)
        .accessibilityHint(L10n.t("Sends this reaction to the cloud", "向这朵云发送此互动"))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Reaction Effects Overlay

struct ReactionEffectsOverlay: View {
    let showBreezeEffect: Bool
    let showHugEffect: Bool
    let showStarlightEffect: Bool

    var body: some View {
        ZStack {
            // Breeze: animated wind lines
            if showBreezeEffect {
                BreezeEffect()
                    .transition(.opacity)
            }

            // Hug: heart pop
            if showHugEffect {
                Image(systemName: "heart.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(TreeholeTheme.coral)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                            removal: .scale(scale: 1.6).combined(with: .opacity)
                        )
                    )
            }

            // Starlight: scattered stars
            if showStarlightEffect {
                StarlightEffect()
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.35), value: showBreezeEffect)
        .animation(.spring(response: 0.4, dampingFraction: 0.55), value: showHugEffect)
        .animation(.easeInOut(duration: 0.35), value: showStarlightEffect)
    }
}

// MARK: - Breeze Effect

private struct BreezeEffect: View {
    @State private var progress: CGFloat = 0

    private let lines: [(yOffset: CGFloat, length: CGFloat, delay: Double)] = [
        (-60, 80, 0.0),
        (-20, 120, 0.08),
        (20, 90, 0.15),
        (60, 70, 0.05)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<lines.count, id: \.self) { i in
                let line = lines[i]
                Path { path in
                    let y = geo.size.height / 2 + line.yOffset
                    let startX = geo.size.width * 0.2
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: startX + line.length * progress, y: y))
                }
                .stroke(
                    TreeholeTheme.skyBlue.opacity(0.8 * (1 - progress)),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Starlight Effect

private struct StarlightEffect: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.9

    private let stars: [(angle: Double, radius: CGFloat, size: CGFloat)] = [
        (0, 60, 8),
        (60, 80, 6),
        (120, 55, 10),
        (180, 70, 7),
        (240, 65, 9),
        (300, 75, 6)
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ForEach(0..<stars.count, id: \.self) { i in
                let star = stars[i]
                let rad = star.angle * .pi / 180
                let x = cx + cos(rad) * star.radius * scale
                let y = cy + sin(rad) * star.radius * scale
                Circle()
                    .fill(TreeholeTheme.warmGold)
                    .frame(width: star.size * scale, height: star.size * scale)
                    .position(x: x, y: y)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.5)) {
                opacity = 0
            }
        }
    }
}
