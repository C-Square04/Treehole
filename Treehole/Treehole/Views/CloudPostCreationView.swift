//
//  CloudPostCreationView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct CloudPostCreationView: View {
    @ObservedObject var viewModel: CloudPostViewModel
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool

    @State private var text: String = ""
    @State private var selectedMood: CloudPost.MoodTag = .calm
    @State private var characterCount: Int = 0
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var characterCountColor: Color {
        if characterCount > 500 {
            return .red
        } else if characterCount > 400 {
            return .orange
        }
        return .green
    }

    var body: some View {
        NavigationStack {
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

                VStack(spacing: 16) {
                    // Header
                    HStack {
                        Text("Share Your Thoughts")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)

                    ScrollView {
                        VStack(spacing: 16) {
                            // Mood Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Label("How are you feeling?", systemImage: "heart.fill")
                                    .font(.headline)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(CloudPost.MoodTag.allCases, id: \.self) { mood in
                                            MoodSelectorButton(
                                                mood: mood,
                                                isSelected: selectedMood == mood,
                                                action: { selectedMood = mood }
                                            )
                                        }
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            // Text Editor
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Your thoughts (max 500 characters)", systemImage: "text.alignleft")
                                    .font(.headline)

                                TextEditor(text: $text)
                                    .frame(minHeight: 150)
                                    .padding(8)
                                    .background(Color(UIColor.systemGray6))
                                    .cornerRadius(8)
                                    .onChange(of: text) {
                                        if text.count > 500 {
                                            text = String(text.prefix(500))
                                        }
                                        characterCount = text.count
                                    }

                                HStack {
                                    Spacer()
                                    Text("\(characterCount)/500")
                                        .font(.caption)
                                        .foregroundColor(characterCountColor)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)

                            // Note for guests
                            if appState.isGuest {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Sign in to save your posts")
                                        .font(.caption)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                            }

                            Spacer()
                        }
                        .padding()
                    }

                    // Post Button
                    Button(action: submitPost) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                            Text("Post")
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding()
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func submitPost() {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)

        let (isApproved, reason) = viewModel.moderatePost(trimmedText)
        if !isApproved {
            errorMessage = reason ?? "Content moderation failed"
            showError = true
            return
        }

        let authorAlias = appState.currentAlias?.generatedName ?? "Anonymous"
        viewModel.createPost(
            text: trimmedText,
            mood: selectedMood,
            authorAlias: authorAlias,
            language: appState.currentUser?.themePrefs.preferredLanguage == .english ? .english : .simplifiedChinese,
            visibilityState: .onlyMe
        )

        text = ""
        characterCount = 0
        isPresented = false
    }
}

struct MoodSelectorButton: View {
    let mood: CloudPost.MoodTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.rawValue)
                    .font(.title2)
                Text(mood.description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(minWidth: 70)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(UIColor.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    CloudPostCreationView(
        viewModel: CloudPostViewModel(),
        appState: AppState(),
        isPresented: .constant(true)
    )
}
