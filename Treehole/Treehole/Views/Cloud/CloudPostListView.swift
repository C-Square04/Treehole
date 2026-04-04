import SwiftUI
import SwiftData

struct CloudPostListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \CloudPost.createdAt, order: .reverse) private var posts: [CloudPost]
    @State private var viewModel = CloudPostViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                TreeholeTheme.cloudyBackground.ignoresSafeArea()

                if posts.isEmpty {
                    EmptyStateView(
                        icon: "cloud",
                        title: "No Clouds Yet",
                        message: "Share your first thought — it floats away anonymously.",
                        actionLabel: "Write a Cloud",
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
                                    CloudPostCard(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, TreeholeTheme.spacingXL)
                    }
                }
            }
            .navigationTitle("Clouds")
            .navigationDestination(for: String.self) { postId in
                if let post = posts.first(where: { $0.id == postId }) {
                    CloudPostDetailView(post: post)
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
            .sheet(isPresented: $viewModel.showCreation) {
                CloudPostCreationView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Cloud Post Card

private struct CloudPostCard: View {
    let post: CloudPost

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
                    Text("NPC replied")
                        .font(.caption2)
                }
                .foregroundStyle(TreeholeTheme.softPurple)
            }
        }
        .glassCard()
    }
}
