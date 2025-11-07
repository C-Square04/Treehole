//
//  LoginPromptView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct LoginPromptView: View {
    @ObservedObject var appState: AppState
    @State private var showLoginOptions: Bool = false
    @State private var selectedAuthMethod: AuthMethod?

    enum AuthMethod {
        case apple
        case email
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    // Icon
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)

                    VStack(spacing: 8) {
                        Text("Welcome to Treehole")
                            .font(.headline)
                        Text("Sign in to save your posts, pets, and progress")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 12) {
                        if !showLoginOptions {
                            // Quick options
                            Button(action: {
                                appState.loginWithAppleID(userId: UUID().uuidString, email: "user@example.com")
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "apple.logo")
                                    Text("Sign in with Apple")
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }

                            Button(action: {
                                appState.loginWithEmail(email: "user@example.com", password: "")
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "envelope.fill")
                                    Text("Sign in with Email")
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }

                            Button(action: {
                                // Continue as guest - dismiss this view
                                // The guest login is already set by default in AppState
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "figure.walk")
                                    Text("Continue as Guest")
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(8)
                            }
                        }
                    }

                    VStack(spacing: 8) {
                        Text("Guest Benefits")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Browse clouds")
                                    .font(.caption)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("See NPC replies")
                                    .font(.caption)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Cannot post clouds")
                                    .font(.caption)
                            }
                            HStack(spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Cannot save progress")
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .padding()

                Spacer()
            }
        }
    }
}

#Preview {
    LoginPromptView(appState: AppState())
}
