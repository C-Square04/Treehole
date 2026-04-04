import SwiftUI
import SwiftData

struct CloudPostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @Query private var weeklyChallenges: [WeeklyChallenge]
    @State private var viewModel = CloudPostViewModel()
    @State private var economyVM = EconomyViewModel()
    @State private var previousPostCount: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.cloudyBackground.ignoresSafeArea()

                if viewModel.isLoading && viewModel.remotePosts.isEmpty {
                    ProgressView(L10n.t("Loading clouds...", "加载云朵中..."))
                } else if viewModel.remotePosts.isEmpty {
                    EmptyStateView(
                        icon: "cloud",
                        title: L10n.t("No Clouds Yet", "还没有云朵"),
                        message: L10n.t("Be the first to share a thought!", "成为第一个分享想法的人！"),
                        actionLabel: L10n.t("Write a Cloud", "写一朵云"),
                        action: { viewModel.showCreation = true }
                    )
                } else {
                    ScrollView {
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

                        LazyVStack(spacing: TreeholeTheme.spacingMedium) {
                            ForEach(viewModel.remotePosts) { post in
                                NavigationLink(value: post.id) {
                                    CloudPostCard(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, TreeholeTheme.spacingXL)
                    }
                    .refreshable {
                        await viewModel.fetchPosts()
                    }
                }

                // Error banner
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
            .navigationDestination(for: String.self) { postId in
                if let post = viewModel.remotePosts.first(where: { $0.id == postId }) {
                    CloudPostDetailView(post: post, viewModel: viewModel)
                } else {
                    ContentUnavailableView("Cloud Not Found", systemImage: "cloud.slash")
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { viewModel.showCreation = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(TreeholeTheme.coral)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreation, onDismiss: {
                // Check if a new post was added
                if viewModel.remotePosts.count > previousPostCount {
                    let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                    if let task = dailyTasks.first(where: { $0.type == .post && !$0.isCompleted }) {
                        economyVM.completeTask(task, economy: economy)
                    }
                    economyVM.incrementChallenge(type: .postStreak, economy: economy, challenges: weeklyChallenges)
                    try? modelContext.save()
                }
                previousPostCount = viewModel.remotePosts.count
            }) {
                CloudPostCreationView(viewModel: viewModel)
            }
            .task {
                await viewModel.fetchPosts()
                _ = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                previousPostCount = viewModel.remotePosts.count
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Cloud Post Card

private struct CloudPostCard: View {
    let post: RemoteCloudPost

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
            HStack {
                Text(post.mood.emoji)
                    .font(.title3)
                Text(post.authorAlias)
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
                if post.isOwn {
                    Text(L10n.t("(You)", "(你)"))
                        .font(.caption2)
                        .foregroundStyle(TreeholeTheme.softPurple)
                }
                Spacer()
                Text(post.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(TreeholeTheme.textLight)
            }

            Text(post.text)
                .font(.body)
                .foregroundStyle(TreeholeTheme.textPrimary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            if post.npcReplyText != nil {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption2)
                    Text(L10n.t("NPC replied", "NPC 已回复"))
                        .font(.caption2)
                }
                .foregroundStyle(TreeholeTheme.softPurple)
            }
        }
        .glassCard()
    }
}
