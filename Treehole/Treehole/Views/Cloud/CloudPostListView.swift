import SwiftUI
import SwiftData

struct CloudPostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \CloudPost.createdAt, order: .reverse) private var posts: [CloudPost]
    @Query private var economies: [Economy]
    @Query private var dailyTasks: [DailyTask]
    @State private var viewModel = CloudPostViewModel()
    @State private var economyVM = EconomyViewModel()
    @State private var previousPostCount: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.cloudyBackground.ignoresSafeArea()

                if posts.isEmpty {
                    EmptyStateView(
                        icon: "cloud",
                        title: L10n.t("No Clouds Yet", "还没有云朵"),
                        message: L10n.t("Share your first thought — it floats away anonymously.", "分享你的第一个想法吧..."),
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
                        }
                        .padding(.horizontal)
                        .padding(.top, TreeholeTheme.spacingTight)

                        LazyVStack(spacing: TreeholeTheme.spacingMedium) {
                            ForEach(posts) { post in
                                NavigationLink(value: post.id) {
                                    CloudPostCard(post: post, lang: appState.preferredLanguage)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, TreeholeTheme.spacingXL)
                    }
                }
            }
            .navigationTitle(L10n.t("Clouds", "云朵"))
            .navigationDestination(for: String.self) { postId in
                if let post = posts.first(where: { $0.id == postId }) {
                    CloudPostDetailView(post: post)
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
                if posts.count > previousPostCount {
                    let economy = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                    if let task = dailyTasks.first(where: { $0.type == .post && !$0.isCompleted }) {
                        economyVM.completeTask(task, economy: economy)
                    }
                    try? modelContext.save()
                }
                previousPostCount = posts.count
            }) {
                CloudPostCreationView(viewModel: viewModel)
            }
            .onAppear {
                _ = economyVM.ensureEconomyExists(context: modelContext, economies: economies)
                previousPostCount = posts.count
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Cloud Post Card

private struct CloudPostCard: View {
    let post: CloudPost
    let lang: String

    var body: some View {
        VStack(alignment: .leading, spacing: TreeholeTheme.spacingTight) {
            HStack {
                Text(post.moodTag.emoji)
                    .font(.title3)
                Text(post.authorAlias)
                    .font(.caption)
                    .foregroundStyle(TreeholeTheme.textLight)
                Spacer()
                Text(post.createdAt, style: .relative)
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
