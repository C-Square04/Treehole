//
//  CloudPostListView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct CloudPostListView: View {
    @ObservedObject var viewModel: CloudPostViewModel
    @ObservedObject var appState: AppState
    @State private var showCreatePost: Bool = false
    @State private var showDetail: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 0.97)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Floating Clouds")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                if let alias = appState.currentAlias {
                                    Text("Anonymous: \(alias.generatedName)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Button(action: { appState.generateNewAlias() }) {
                                Image(systemName: "arrow.2.squarepath")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)

                        Button(action: { showCreatePost = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Share Your Thoughts")
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.white)

                    // Post List
                    if viewModel.posts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No clouds yet")
                                .font(.headline)
                            Text("Share your thoughts to see them float here")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.posts) { post in
                                    CloudPostCardView(post: post, viewModel: viewModel, appState: appState)
                                        .onTapGesture {
                                            showDetail = post.id
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationDestination(item: $showDetail) { postId in
                if let post = viewModel.posts.first(where: { $0.id == postId }) {
                    CloudPostDetailView(post: post, viewModel: viewModel)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Post Not Found")
                            .font(.headline)
                        Text("This post may have been deleted")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showDetail = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CloudPostCreationView(viewModel: viewModel, appState: appState, isPresented: $showCreatePost)
            }
        }
    }
}

struct CloudPostCardView: View {
    let post: CloudPost
    @ObservedObject var viewModel: CloudPostViewModel
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.authorAlias)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(post.moodTag.rawValue)
                        .font(.headline)
                }
                Spacer()
                Text(post.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(post.text)
                .font(.body)
                .lineLimit(3)
                .foregroundColor(.primary)

            if let replyText = post.npcReplyText {
                VStack(alignment: .leading, spacing: 4) {
                    Label("NPC Reply", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(replyText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    CloudPostListView(viewModel: CloudPostViewModel(), appState: AppState())
}
