//
//  CloudPostDetailView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct CloudPostDetailView: View {
    let post: CloudPost
    @ObservedObject var viewModel: CloudPostViewModel
    @State private var showTranslation: Bool = false
    @State private var targetLanguage: CloudPost.Language = .english
    @Environment(\.dismiss) var dismiss

    var displayedText: String {
        if showTranslation, let translation = post.translations[targetLanguage] {
            return translation.text
        }
        return post.text
    }

    var displayedLanguage: String {
        if showTranslation {
            return targetLanguage == .english ? "English" : "Chinese"
        }
        return post.sourceLanguage == .english ? "English" : "Chinese"
    }

    var body: some View {
        ZStack {
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
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    Spacer()
                    Text("Cloud Details")
                        .font(.headline)
                    Spacer()
                    Button(action: { viewModel.deletePost(post.id) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.white)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Author and mood
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(post.authorAlias)
                                        .font(.headline)
                                    Text(post.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(post.moodTag.rawValue)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // Main content
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Language: \(displayedLanguage)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Spacer()
                                if post.sourceLanguage != targetLanguage {
                                    Button(action: {
                                        let targetLang: CloudPost.Language = post.sourceLanguage == .english ? .simplifiedChinese : .english
                                        viewModel.translatePost(post.id, to: targetLang)
                                    }) {
                                        Text("Translate")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }

                            Text(displayedText)
                                .font(.body)
                                .lineSpacing(1.5)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)

                        // NPC Reply
                        if let replyText = post.npcReplyText {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("💙 NPC Response", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                Text(replyText)
                                    .font(.body)
                                    .lineSpacing(1.5)
                                    .padding()
                                    .background(Color.blue.opacity(0.05))
                                    .cornerRadius(8)
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                        }

                        // Gentle interactions
                        VStack(spacing: 8) {
                            Text("Send warmth")
                                .font(.caption)
                                .foregroundColor(.gray)

                            HStack(spacing: 16) {
                                InteractionButton(emoji: "👆", label: "Light Breeze", color: .blue)
                                InteractionButton(emoji: "☁️", label: "Cloud Hug", color: .cyan)
                                InteractionButton(emoji: "⭐", label: "Starlight", color: .yellow)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct InteractionButton: View {
    let emoji: String
    let label: String
    let color: Color

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(color)
            }
            .padding(8)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

#Preview {
    CloudPostDetailView(
        post: CloudPost(
            id: "1",
            authorAlias: "CloudWhisperer",
            moodTag: .sad,
            text: "Today was really tough. I'm struggling with work pressure and feeling overwhelmed.",
            createdAt: Date(),
            visibilityState: .visible,
            sourceLanguage: .english
        ),
        viewModel: CloudPostViewModel()
    )
}
