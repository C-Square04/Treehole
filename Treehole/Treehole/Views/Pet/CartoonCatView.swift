import SwiftUI

struct CartoonCatView: View {
    let mood: PetMood
    let showFeedingAnimation: Bool
    @State private var isBlinking = false
    @State private var tailPosition: Double = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var breatheScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.95, blue: 0.92),
                            Color(red: 0.95, green: 0.92, blue: 0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 240, height: 240)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)

            VStack(spacing: 0) {
                // Head
                ZStack {
                    Circle()
                        .fill(catFurGradient)
                        .frame(width: 110, height: 110)

                    VStack(spacing: 12) {
                        HStack(spacing: 50) {
                            CatEar()
                            CatEar()
                        }

                        HStack(spacing: 24) {
                            CatEye(mood: mood, isBlinking: isBlinking)
                            CatEye(mood: mood, isBlinking: isBlinking)
                        }
                        .padding(.top, 8)

                        Ellipse()
                            .fill(Color(red: 0.9, green: 0.7, blue: 0.7))
                            .frame(width: 8, height: 6)

                        CatMouth(mood: mood)
                            .frame(height: 20)
                    }
                    .frame(width: 90)
                }

                // Body
                ZStack {
                    RoundedRectangle(cornerRadius: 35)
                        .fill(catFurGradient)
                        .frame(width: 100, height: 90)

                    Ellipse()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 60, height: 65)

                    HStack(spacing: 35) {
                        Circle().fill(Color(red: 0.85, green: 0.75, blue: 0.68)).frame(width: 12, height: 12)
                        Circle().fill(Color(red: 0.85, green: 0.75, blue: 0.68)).frame(width: 12, height: 12)
                    }
                    .offset(y: 35)
                }
                .offset(y: bounceOffset)

                Spacer()
            }
            .frame(height: 240)

            TailView(position: tailPosition)
                .offset(x: 95, y: -20)
        }
        .scaleEffect(showFeedingAnimation ? 1.1 : breatheScale)
        .onAppear { if !reduceMotion { startAnimations() } }
        .accessibilityLabel("Your pet companion, feeling \(mood.labelEN)")
    }

    private var catFurGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.96, green: 0.87, blue: 0.78), Color(red: 0.91, green: 0.82, blue: 0.73)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func startAnimations() {
        Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) { isBlinking = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) { isBlinking = false }
            }
        }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            tailPosition = 15
        }

        if mood == .happy || mood == .excited {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounceOffset = -8
            }
        }

        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            breatheScale = 1.02
        }
    }
}

// MARK: - Cat Components

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}

private struct CatEar: View {
    var body: some View {
        ZStack {
            Triangle()
                .fill(LinearGradient(
                    colors: [Color(red: 0.96, green: 0.87, blue: 0.78), Color(red: 0.91, green: 0.82, blue: 0.73)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 20, height: 28)
            Triangle()
                .fill(Color(red: 0.95, green: 0.75, blue: 0.75))
                .frame(width: 10, height: 16)
        }
    }
}

private struct CatEye: View {
    let mood: PetMood
    let isBlinking: Bool

    private var eyeHeight: CGFloat {
        if isBlinking { return 1 }
        switch mood {
        case .happy, .excited: return 16
        case .sad: return 14
        case .tired: return 6
        case .neutral: return 14
        }
    }

    private var pupilOffset: CGFloat {
        switch mood {
        case .happy, .excited: return 3
        case .sad: return -2
        default: return 0
        }
    }

    var body: some View {
        ZStack {
            Ellipse().fill(.white).frame(width: 16, height: eyeHeight)
            if !isBlinking {
                Circle().fill(.black).frame(width: 8).offset(y: pupilOffset)
                Circle().fill(Color.white.opacity(0.8)).frame(width: 3).offset(x: -2, y: -3)
            }
        }
    }
}

private struct CatMouth: View {
    let mood: PetMood

    var body: some View {
        switch mood {
        case .happy, .excited:
            VStack(spacing: 2) {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(to: CGPoint(x: 24, y: 0), control: CGPoint(x: 12, y: 10))
                }
                .stroke(.black, lineWidth: 2)
                .frame(width: 24, height: 10)
                Ellipse().fill(Color(red: 0.95, green: 0.7, blue: 0.7)).frame(width: 8, height: 6)
            }
        case .sad:
            Path { path in
                path.move(to: CGPoint(x: 0, y: 8))
                path.addQuadCurve(to: CGPoint(x: 24, y: 8), control: CGPoint(x: 12, y: 0))
            }
            .stroke(.black, lineWidth: 1.5)
            .frame(width: 24, height: 8)
        case .tired:
            HStack(spacing: 3) {
                Circle().fill(.black).frame(width: 2)
                Circle().fill(.black).frame(width: 2)
                Circle().fill(.black).frame(width: 2)
            }
        case .neutral:
            Rectangle().fill(.black).frame(width: 12, height: 1.5)
        }
    }
}

private struct TailView: View {
    let position: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addQuadCurve(to: CGPoint(x: 50, y: -10), control: CGPoint(x: 30, y: 20 + position))
        }
        .stroke(
            LinearGradient(
                colors: [Color(red: 0.91, green: 0.82, blue: 0.73), Color(red: 0.85, green: 0.75, blue: 0.68)],
                startPoint: .leading, endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 18, lineCap: .round)
        )
        .shadow(color: .black.opacity(0.1), radius: 3)
    }
}
