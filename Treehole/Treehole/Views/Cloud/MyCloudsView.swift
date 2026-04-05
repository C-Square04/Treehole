import SwiftUI

struct MyCloudsView: View {
    @Environment(AppState.self) private var appState
    @Environment(PrivacyLockManager.self) private var lockManager

    @State private var myPosts: [RemoteCloudPost] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var totalReactions: Int = 0
    @State private var reactionMap: [String: ReactionCounts] = [:]
    @State private var postToDelete: RemoteCloudPost?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        Group {
            if lockManager.isCloudLockEnabled && !lockManager.isCloudUnlocked {
                PrivacyLockView(lockType: .cloud, title: L10n.t("My Clouds", "我的云朵"))
            } else {
                mainContent
            }
        }
        .navigationTitle(L10n.t("My Clouds", "我的云朵"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if lockManager.isCloudLockEnabled {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        lockManager.lockAll()
                    } label: {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(TreeholeTheme.softPurple)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            lockManager.lock()
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
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

            if isLoading && myPosts.isEmpty {
                ProgressView()
            } else if myPosts.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: TreeholeTheme.spacingMedium) {
                        statsHeader
                        postsSection
                        Spacer(minLength: TreeholeTheme.spacingXL)
                    }
                    .padding(.top, TreeholeTheme.spacingSmall)
                }
                .refreshable {
                    await loadMyPosts()
                }
            }

            // Error banner
            if let error = errorMessage {
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
        .task {
            await loadMyPosts()
        }
        .confirmationDialog(
            L10n.t("Delete this cloud?", "删除这朵云？"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L10n.t("Delete", "删除"), role: .destructive) {
                if let post = postToDelete {
                    Task { await deletePost(post) }
                }
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: TreeholeTheme.spacingMedium) {
            VStack(spacing: 4) {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(TreeholeTheme.skyBlue)
                Text("\(myPosts.count)")
                    .font(.title3.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(L10n.t("Total Clouds", "云朵总数"))
                    .font(.caption2)
                    .foregroundStyle(TreeholeTheme.textLight)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("🌬️")
                    .font(.title3)
                Text("\(totalReactions)")
                    .font(.title3.bold())
                    .foregroundStyle(TreeholeTheme.textPrimary)
                Text(L10n.t("Reactions", "互动总数"))
                    .font(.caption2)
                    .foregroundStyle(TreeholeTheme.textLight)
            }
            .frame(maxWidth: .infinity)
        }
        .glassCard()
        .padding(.horizontal)
    }

    // MARK: - Posts Section

    private var postsSection: some View {
        LazyVStack(spacing: TreeholeTheme.spacingSmall) {
            ForEach(myPosts) { post in
                NavigationLink(destination: cloudDetail(for: post)) {
                    MyCloudCard(
                        post: post,
                        reactionCounts: reactionMap[post.id]
                    )
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        postToDelete = post
                        showDeleteConfirmation = true
                    } label: {
                        Label(L10n.t("Delete", "删除"), systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func cloudDetail(for post: RemoteCloudPost) -> some View {
        // Reuse the grabbed-cloud detail as a pushed view; hide "Grab Another" for own clouds
        GrabbedCloudView(post: .constant(post), appState: appState, showGrabAnother: false)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            Text("☁️")
                .font(.system(size: 56))
            Text(L10n.t("No clouds yet", "还没有云朵"))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)
            Text(L10n.t("Send your first cloud to see it here.", "放飞你的第一朵云，就会出现在这里。"))
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .refreshable {
            await loadMyPosts()
        }
    }

    // MARK: - Data Loading

    private func loadMyPosts() async {
        isLoading = true
        errorMessage = nil
        do {
            myPosts = try await SupabaseService.fetchMyPosts()
            await loadAllReactions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func loadAllReactions() async {
        await withTaskGroup(of: (String, ReactionCounts?).self) { group in
            for post in myPosts {
                group.addTask {
                    let counts = try? await SupabaseService.fetchReactionCounts(postId: post.id)
                    return (post.id, counts)
                }
            }
            for await (id, counts) in group {
                if let counts = counts {
                    reactionMap[id] = counts
                }
            }
        }
        totalReactions = reactionMap.values.reduce(0) { $0 + $1.totalCount }
    }

    private func deletePost(_ post: RemoteCloudPost) async {
        do {
            try await SupabaseService.deletePost(id: post.id)
            myPosts.removeAll { $0.id == post.id }
            reactionMap.removeValue(forKey: post.id)
            totalReactions = reactionMap.values.reduce(0) { $0 + $1.totalCount }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - My Cloud Card

private struct MyCloudCard: View {
    let post: RemoteCloudPost
    let reactionCounts: ReactionCounts?

    var body: some View {
        HStack(alignment: .top, spacing: TreeholeTheme.spacingSmall) {
            Text(post.mood.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(post.authorAlias)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TreeholeTheme.textPrimary)

                Text(post.text)
                    .font(.subheadline)
                    .foregroundStyle(TreeholeTheme.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(post.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.textLight)

                    if let counts = reactionCounts, counts.totalCount > 0 {
                        reactionRow(counts)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(TreeholeTheme.textLight)
        }
        .padding(TreeholeTheme.spacingSmall)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
    }

    @ViewBuilder
    private func reactionRow(_ counts: ReactionCounts) -> some View {
        HStack(spacing: 4) {
            if counts.breezeCount > 0 {
                Text("🌬️\(counts.breezeCount)").font(.caption2).foregroundStyle(TreeholeTheme.textLight)
            }
            if counts.hugCount > 0 {
                Text("🤗\(counts.hugCount)").font(.caption2).foregroundStyle(TreeholeTheme.textLight)
            }
            if counts.starlightCount > 0 {
                Text("✨\(counts.starlightCount)").font(.caption2).foregroundStyle(TreeholeTheme.textLight)
            }
        }
    }
}
