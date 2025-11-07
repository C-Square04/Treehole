//
//  InteractivePetView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct InteractivePetView: View {
    let mood: PetState.PetMood
    let showFeedingAnimation: Bool
    @State private var idleRotation: Double = 0
    @State private var tailWag: Double = 0
    @State private var earTwitch: Double = 0
    @State private var isPressed: Bool = false

    var body: some View {
        ZStack {
            // Cat Body
            VStack(spacing: -10) {
                // Ears
                HStack(spacing: 50) {
                    Ear()
                        .rotation3DEffect(.degrees(earTwitch), axis: (x: 0, y: 1, z: 0))
                    Ear()
                        .rotation3DEffect(.degrees(-earTwitch), axis: (x: 0, y: 1, z: 0))
                }
                .offset(y: 15)

                // Head
                ZStack {
                    // Head base
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.95, green: 0.85, blue: 0.75),
                                    Color(red: 0.90, green: 0.80, blue: 0.70)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5)

                    // Face features
                    VStack(spacing: 8) {
                        // Eyes
                        HStack(spacing: 20) {
                            Eye(mood: mood)
                            Eye(mood: mood)
                        }

                        // Nose and mouth
                        VStack(spacing: 2) {
                            Circle()
                                .fill(Color(red: 0.8, green: 0.5, blue: 0.5))
                                .frame(width: 8, height: 8)

                            // Mouth expression based on mood
                            MouthExpression(mood: mood)
                        }
                    }
                }

                // Body
                ZStack {
                    // Main body
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.95, green: 0.85, blue: 0.75),
                                    Color(red: 0.88, green: 0.78, blue: 0.68)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 100)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5)

                    // Belly patch
                    Ellipse()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 60, height: 70)
                        .offset(y: 5)
                }
                .offset(y: -10)

                // Legs
                HStack(spacing: 30) {
                    Leg()
                    Leg()
                    Leg()
                    Leg()
                }
                .offset(y: -30)
            }

            // Tail (positioned separately for better control)
            Tail()
                .offset(x: 70, y: -10)
                .rotationEffect(.degrees(tailWag), anchor: .leading)
        }
        .scaleEffect(showFeedingAnimation ? 1.15 : (isPressed ? 0.95 : 1.0))
        .rotation3DEffect(.degrees(idleRotation), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: showFeedingAnimation)
        .onAppear {
            startIdleAnimations()
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }
    }

    private func startIdleAnimations() {
        // Subtle idle rotation
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            idleRotation = 5
        }

        // Tail wagging
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            tailWag = 15
        }

        // Ear twitching
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            earTwitch = 5
        }
    }
}

// MARK: - Pet Body Components

struct Ear: View {
    var body: some View {
        ZStack {
            // Outer ear
            Triangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.85, blue: 0.75),
                            Color(red: 0.90, green: 0.80, blue: 0.70)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 35)
                .shadow(color: Color.black.opacity(0.15), radius: 3, x: 2, y: 2)

            // Inner ear
            Triangle()
                .fill(Color(red: 0.9, green: 0.7, blue: 0.7))
                .frame(width: 18, height: 22)
        }
    }
}

struct Eye: View {
    let mood: PetState.PetMood

    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white)
                .frame(width: 18, height: 20)

            // Pupil changes based on mood
            Ellipse()
                .fill(Color.black)
                .frame(width: pupilSize, height: pupilSize)
                .offset(x: pupilOffset.x, y: pupilOffset.y)

            // Shine
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 4, height: 4)
                .offset(x: -3, y: -4)
        }
    }

    private var pupilSize: CGFloat {
        switch mood {
        case .happy, .excited:
            return 10
        case .neutral:
            return 8
        case .sad:
            return 6
        case .tired:
            return 4
        }
    }

    private var pupilOffset: CGPoint {
        switch mood {
        case .happy, .excited:
            return CGPoint(x: 0, y: 2)
        case .sad:
            return CGPoint(x: 0, y: -2)
        default:
            return .zero
        }
    }
}

struct MouthExpression: View {
    let mood: PetState.PetMood

    var body: some View {
        Group {
            switch mood {
            case .happy, .excited:
                // Smile
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: 20, y: 0),
                        control: CGPoint(x: 10, y: 8)
                    )
                }
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 20, height: 8)

            case .sad:
                // Frown
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 8))
                    path.addQuadCurve(
                        to: CGPoint(x: 20, y: 8),
                        control: CGPoint(x: 10, y: 0)
                    )
                }
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 20, height: 8)

            case .tired:
                // Sleepy curve
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 4))
                    path.addQuadCurve(
                        to: CGPoint(x: 16, y: 4),
                        control: CGPoint(x: 8, y: 0)
                    )
                }
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 16, height: 4)

            case .neutral:
                // Small line
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 12, height: 1.5)
            }
        }
    }
}

struct Leg: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.92, green: 0.82, blue: 0.72),
                        Color(red: 0.85, green: 0.75, blue: 0.65)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 18, height: 40)
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 2, y: 2)
            .overlay(
                // Paw pad
                Circle()
                    .fill(Color(red: 0.8, green: 0.5, blue: 0.5).opacity(0.6))
                    .frame(width: 12, height: 12)
                    .offset(y: 12)
            )
    }
}

struct Tail: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addQuadCurve(
                to: CGPoint(x: 40, y: -10),
                control: CGPoint(x: 25, y: 30)
            )
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.92, green: 0.82, blue: 0.72),
                    Color(red: 0.85, green: 0.75, blue: 0.65)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 16, lineCap: .round)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 3, x: 2, y: 2)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.97, blue: 1.0)
            .ignoresSafeArea()

        InteractivePetView(mood: .happy, showFeedingAnimation: false)
    }
}
