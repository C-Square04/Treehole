import SwiftUI
import SwiftData

// MARK: - Cloud Post List View (Drift Bottle)

struct CloudPostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(PrivacyLockManager.self) private var lockManager
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var viewModel = CloudPostViewModel()
    @State private var economyVM = EconomyViewModel()
    @State private var didCreatePost = false
    @State private var showMyClouds: Bool = false

    // Drift bottle state
    @State private var grabbedPost: RemoteCloudPost? = nil
    @State private var showGrabbedCloud: Bool = false
    @State private var isGrabbing: Bool = false
    @State private var grabError: String? = nil

    // Floating animation offsets for decorative clouds
    @State private var floatOffsets: [CGFloat] = Array(repeating: 0, count: 6)

    private let cloudPositions: [(x: CGFloat, y: CGFloat, size: CGFloat)] = [
        (-120, -30, 44),
        (90, -60, 34),
        (-60, 40, 52),
        (130, 20, 38),
        (-140, 100, 30),
        (70, 90, 48)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Sky gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.88, blue: 0.98),
                        TreeholeTheme.warmPeach.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Decorative floating clouds
                GeometryReader { geo in
                    let cx = geo.size.width / 2
                    let cy = geo.size.height * 0.25
                    ForEach(0..<6) { i in
                        Image(systemName: "cloud.fill")
                            .font(.system(size: cloudPositions[i].size))
                            .foregroundStyle(.white.opacity(0.4))
                            .position(
                                x: cx + cloudPositions[i].x,
                                y: cy + cloudPositions[i].y + floatOffsets[i]
                            )
                            .animation(
                                .easeInOut(duration: 3.0 + Double(i) * 0.4)
                                    .repeatForever(autoreverses: true),
                                value: floatOffsets[i]
                            )
                    }
                }
                .allowsHitTesting(false)

                // Main content
                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingLarge) {

                        // Alias badge
                        HStack {
                            Image(systemName: "theatermasks")
                                .foregroundStyle(TreeholeTheme.softPurple)
                            Text(appState.currentAlias)
                                .font(.caption)
                                .foregroundStyle(TreeholeTheme.textSecondary)
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, TreeholeTheme.spacingTight)

                        Spacer(minLength: 80)

                        // Primary: Grab a Cloud button
                        Button {
                            Task { await grabCloud() }
                        } label: {
                            HStack(spacing: TreeholeTheme.spacingSmall) {
                                Text("🫧")
                                    .font(.title2)
                                Text(L10n.t("Grab a Cloud", "抓一朵云"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                if isGrabbing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(TreeholeTheme.textPrimary)
                                }
                            }
                            .foregroundStyle(TreeholeTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TreeholeTheme.spacingMedium)
                        }
                        .disabled(isGrabbing)
                        .glassCard()
                        .padding(.horizontal)

                        // Secondary: Send a Cloud button
                        Button {
                            viewModel.showCreation = true
                        } label: {
                            HStack(spacing: TreeholeTheme.spacingSmall) {
                                Text("✉️")
                                    .font(.title2)
                                Text(L10n.t("Send a Cloud", "放飞一朵云"))
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(TreeholeTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TreeholeTheme.spacingSmall)
                        }
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
                        .padding(.horizontal)

                        // Error display
                        if let error = grabError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.white)
                                .padding(.horizontal, TreeholeTheme.spacingSmall)
                                .padding(.vertical, 6)
                                .background(.red.opacity(0.8), in: Capsule())
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Bottom padding
                        Spacer(minLength: TreeholeTheme.spacingXL)
                    }
                }
                .refreshable {
                    await viewModel.fetchPosts()
                }

                // viewModel error banner
                if let error = viewModel.errorMessage {
                    VStack {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, TreeholeTheme.spacingSmall)
                            .padding(.vertical, 6)
                            .background(.red.opacity(0.8), in: Capsule())
                        Spacer()
                    }
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .navigationTitle(L10n.t("Clouds", "云朵"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { viewModel.showCreation = true } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(TreeholeTheme.coral)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showMyClouds = true
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
                                .foregroundStyle(TreeholeTheme.softPurple)
                            if lockManager.isCloudLockEnabled {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8))
                                    .foregroundStyle(TreeholeTheme.softPurple)
                                    .offset(x: 2, y: 2)
                            }
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showMyClouds) {
                MyCloudsView()
            }
            .sheet(isPresented: $showGrabbedCloud, onDismiss: {
                grabbedPost = nil
            }) {
                if let post = grabbedPost {
                    GrabbedCloudView(post: post, appState: appState) {
                        Task { await grabCloud() }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreation, onDismiss: {
                if viewModel.didCreatePost {
                    viewModel.didCreatePost = false
                    let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                    if let task = dailyTasks.first(where: { $0.type == .post && !$0.isCompleted }) {
                        economyVM.completeTask(task, economy: economy)
                    }
                    economyVM.incrementChallenge(type: .postStreak, economy: economy, challenges: weeklyChallenges)
                    try? modelContext.save()
                    // My Clouds is now a separate page
                }
            }) {
                CloudPostCreationView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchPosts()
                _ = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                try? modelContext.save()
                // Start floating animations
                for i in 0..<6 {
                    floatOffsets[i] = (i % 2 == 0) ? 8 : -8
                }
            }
        }
    }

    // MARK: - Actions

    private func grabCloud() async {
        isGrabbing = true
        grabError = nil
        do {
            if let post = try await SupabaseService.fetchRandomPost() {
                grabbedPost = post
                showGrabbedCloud = true
            } else {
                grabError = L10n.t("No clouds out there right now. Try again soon!", "目前没有云朵，稍后再试！")
            }
        } catch {
            grabError = error.localizedDescription
        }
        isGrabbing = false
    }

}

// MARK: - Own Cloud Card (compact)

private struct OwnCloudCard: View {
    let post: RemoteCloudPost
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    @State private var reactionCounts: ReactionCounts? = nil

    var body: some View {
        HStack(alignment: .top, spacing: TreeholeTheme.spacingSmall) {
            Text(post.mood.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(post.text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textPrimary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(post.date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.textLight)

                    if post.npcReplyText != nil {
                        HStack(spacing: 2) {
                            Image(systemName: "bubble.left.fill")
                                .font(.caption2)
                            Text(L10n.t("Spirit replied", "精灵已回复"))
                                .font(.caption2)
                        }
                        .foregroundStyle(TreeholeTheme.softPurple)
                    }
                }

                // Reaction counts row
                if let counts = reactionCounts, counts.totalCount > 0 {
                    HStack(spacing: TreeholeTheme.spacingTight) {
                        if counts.breezeCount > 0 {
                            HStack(spacing: 2) {
                                Text("🌬️").font(.caption2)
                                Text("\(counts.breezeCount)").font(.caption2)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }
                        }
                        if counts.hugCount > 0 {
                            HStack(spacing: 2) {
                                Text("🤗").font(.caption2)
                                Text("\(counts.hugCount)").font(.caption2)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }
                        }
                        if counts.starlightCount > 0 {
                            HStack(spacing: 2) {
                                Text("✨").font(.caption2)
                                Text("\(counts.starlightCount)").font(.caption2)
                                    .foregroundStyle(TreeholeTheme.textLight)
                            }
                        }
                    }
                }
            }

            Spacer()

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
            }
            .buttonStyle(.plain)
        }
        .padding(TreeholeTheme.spacingSmall)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
        .confirmationDialog(L10n.t("Delete this cloud?", "删除这朵云？"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button(L10n.t("Delete", "删除"), role: .destructive) {
                onDelete()
            }
        }
        .task {
            reactionCounts = try? await SupabaseService.fetchReactionCounts(postId: post.id)
        }
    }
}

// MARK: - Grabbed Cloud View (drift bottle sheet)

struct GrabbedCloudView: View {
    @Environment(\.dismiss) private var dismiss
    let post: RemoteCloudPost
    let appState: AppState
    let onGrabAnother: () -> Void

    @State private var comments: [RemoteComment] = []
    @State private var commentText: String = ""
    @State private var isLoadingComments: Bool = false
    @State private var isPostingComment: Bool = false
    @State private var commentError: String? = nil
    @State private var isGrabbingAnother: Bool = false

    // Reactions
    @State private var reactionCounts: ReactionCounts? = nil
    @State private var myReactions: Set<String> = []

    // Visual effects
    @State private var showBreezeEffect = false
    @State private var showHugEffect = false
    @State private var showStarlightEffect = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.88, blue: 0.98),
                        TreeholeTheme.warmPeach.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: TreeholeTheme.spacingLarge) {

                        // Post header: mood + alias
                        HStack(spacing: TreeholeTheme.spacingSmall) {
                            Text(post.mood.emoji)
                                .font(.largeTitle)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.authorAlias)
                                    .font(.headline)
                                    .foregroundStyle(TreeholeTheme.textPrimary)
                                Text(post.date, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(TreeholeTheme.textLight)
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

                        // Post text
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
                                    CommentBubble(comment: comment)
                                }
                            }

                            // Comment error
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

                        // Grab Another button
                        Button {
                            isGrabbingAnother = true
                            dismiss()
                            onGrabAnother()
                        } label: {
                            HStack(spacing: TreeholeTheme.spacingSmall) {
                                Text("🫧")
                                    .font(.title2)
                                Text(L10n.t("Grab Another Cloud", "再抓一朵云"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                if isGrabbingAnother {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(TreeholeTheme.textPrimary)
                                }
                            }
                            .foregroundStyle(TreeholeTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, TreeholeTheme.spacingMedium)
                        }
                        .glassCard()

                        Spacer(minLength: TreeholeTheme.spacingXL)
                    }
                    .padding()
                }

                // Reaction visual effects overlay
                ReactionEffectsOverlay(
                    showBreezeEffect: showBreezeEffect,
                    showHugEffect: showHugEffect,
                    showStarlightEffect: showStarlightEffect
                )
            }
            .navigationTitle(L10n.t("A Cloud from...", "一朵来自...的云"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(TreeholeTheme.textLight)
                    }
                }
            }
            .task {
                await loadComments()
                await loadReactions()
            }
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

// MARK: - Comment Bubble

private struct CommentBubble: View {
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
