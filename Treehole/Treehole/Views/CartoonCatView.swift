//
//  CartoonCatView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-07.
//

import SwiftUI

struct CartoonCatView: View {
    let mood: PetState.PetMood
    let showFeedingAnimation: Bool
    @State private var isBlinking = false
    @State private var tailPosition: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var breatheScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.98, green: 0.95, blue: 0.92),
                            Color(red: 0.95, green: 0.92, blue: 0.88)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 240, height: 240)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)

            VStack(spacing: 0) {
                // Head
                ZStack {
                    // Head base
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.96, green: 0.87, blue: 0.78),
                                    Color(red: 0.91, green: 0.82, blue: 0.73)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)

                    VStack(spacing: 12) {
                        // Ears
                        HStack(spacing: 50) {
                            CatEar()
                            CatEar()
                        }

                        // Eyes
                        HStack(spacing: 24) {
                            CatEye(
                                mood: mood,
                                isBlinking: isBlinking
                            )
                            CatEye(
                                mood: mood,
                                isBlinking: isBlinking
                            )
                        }
                        .padding(.top, 8)

                        // Nose
                        Ellipse()
                            .fill(Color(red: 0.9, green: 0.7, blue: 0.7))
                            .frame(width: 8, height: 6)

                        // Mouth
                        CatMouth(mood: mood)
                            .frame(height: 20)
                    }
                    .frame(width: 90)
                }

                // Body
                ZStack {
                    // Body base
                    RoundedRectangle(cornerRadius: 35)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.96, green: 0.87, blue: 0.78),
                                    Color(red: 0.91, green: 0.82, blue: 0.73)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 90)

                    // Belly
                    Ellipse()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 60, height: 65)

                    // Paws indicators
                    HStack(spacing: 35) {
                        Circle()
                            .fill(Color(red: 0.85, green: 0.75, blue: 0.68))
                            .frame(width: 12, height: 12)

                        Circle()
                            .fill(Color(red: 0.85, green: 0.75, blue: 0.68))
                            .frame(width: 12, height: 12)
                    }
                    .offset(y: 35)
                }
                .offset(y: bounceOffset)

                Spacer()
            }
            .frame(height: 240)

            // Tail
            TailView(position: tailPosition)
                .offset(x: 95, y: -20)
        }
        .scaleEffect(showFeedingAnimation ? 1.1 : breatheScale)
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Blinking animation
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                isBlinking = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isBlinking = false
                }
            }
        }

        // Tail wagging
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            tailPosition = 15
        }

        // Bounce when happy/excited
        if mood == .happy || mood == .excited {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounceOffset = -8
            }
        }

        // Breathing animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            breatheScale = 1.02
        }
    }
}

// MARK: - Cat Components

struct CatEar: View {
    var body: some View {
        ZStack {
            // Outer ear
            Triangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.96, green: 0.87, blue: 0.78),
                            Color(red: 0.91, green: 0.82, blue: 0.73)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: 28)

            // Inner ear
            Triangle()
                .fill(Color(red: 0.95, green: 0.75, blue: 0.75))
                .frame(width: 10, height: 16)
        }
    }
}

struct CatEye: View {
    let mood: PetState.PetMood
    let isBlinking: Bool

    var eyeHeight: CGFloat {
        if isBlinking {
            return 1
        }

        switch mood {
        case .happy, .excited:
            return 16
        case .sad:
            return 14
        case .tired:
            return 6
        case .neutral:
            return 14
        }
    }

    var pupilOffset: CGFloat {
        switch mood {
        case .happy, .excited:
            return 3
        case .sad:
            return -2
        default:
            return 0
        }
    }

    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white)
                .frame(width: 16, height: eyeHeight)

            if !isBlinking {
                // Pupil
                Circle()
                    .fill(Color.black)
                    .frame(width: 8)
                    .offset(y: pupilOffset)

                // Shine
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 3)
                    .offset(x: -2, y: -3)
            }
        }
    }
}

struct CatMouth: View {
    let mood: PetState.PetMood

    var body: some View {
        Group {
            switch mood {
            case .happy, .excited:
                // Big smile
                VStack(spacing: 2) {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addQuadCurve(
                            to: CGPoint(x: 24, y: 0),
                            control: CGPoint(x: 12, y: 10)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 24, height: 10)

                    // Tongue
                    Ellipse()
                        .fill(Color(red: 0.95, green: 0.7, blue: 0.7))
                        .frame(width: 8, height: 6)
                }

            case .sad:
                // Sad frown
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 8))
                    path.addQuadCurve(
                        to: CGPoint(x: 24, y: 8),
                        control: CGPoint(x: 12, y: 0)
                    )
                }
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 24, height: 8)

            case .tired:
                // Sleepy closed mouth
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2)
                }

            case .neutral:
                // Small line mouth
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 12, height: 1.5)
            }
        }
    }
}

struct TailView: View {
    let position: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addQuadCurve(
                to: CGPoint(x: 50, y: -10),
                control: CGPoint(x: 30, y: 20 + position))
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.91, green: 0.82, blue: 0.73),
                    Color(red: 0.85, green: 0.75, blue: 0.68)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 18, lineCap: .round)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3)
    }
}

#Preview {
    VStack(spacing: 20) {
        CartoonCatView(mood: .happy, showFeedingAnimation: false)
        CartoonCatView(mood: .tired, showFeedingAnimation: false)
        CartoonCatView(mood: .sad, showFeedingAnimation: false)
    }
    .padding()
}
