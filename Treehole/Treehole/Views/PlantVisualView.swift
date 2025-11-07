//
//  PlantVisualView.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-07.
//

import SwiftUI

struct PlantVisualView: View {
    let growthStage: PlantState.GrowthStage
    let hydrationLevel: Int
    let experience: Int
    @State private var isGrowing = false

    var body: some View {
        ZStack {
            // Soil/Pot
            VStack(spacing: 0) {
                Spacer()
                SoilView()
                    .frame(height: 60)
            }

            // Plant based on growth stage
            VStack(spacing: 0) {
                switch growthStage {
                case .seed:
                    SeedView(isGrowing: isGrowing, hydrationLevel: hydrationLevel)
                        .transition(.scale.combined(with: .opacity))

                case .sprout:
                    SproutView(isGrowing: isGrowing, progress: Double(experience) / 100.0)
                        .transition(.scale.combined(with: .opacity))

                case .growing:
                    GrowingPlantView(isGrowing: isGrowing, progress: Double(experience) / 100.0)
                        .transition(.scale.combined(with: .opacity))

                case .blooming:
                    BloomingPlantView(isGrowing: isGrowing, progress: Double(experience) / 100.0)
                        .transition(.scale.combined(with: .opacity))

                case .mature:
                    MaturePlantView(isGrowing: isGrowing)
                        .transition(.scale.combined(with: .opacity))
                }

                Spacer()
            }
        }
        .frame(height: 300)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isGrowing = true
            }
        }
    }
}

// MARK: - Seed Stage
struct SeedView: View {
    let isGrowing: Bool
    let hydrationLevel: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                // Seed shell
                Ellipse()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.6, green: 0.5, blue: 0.3),
                                Color(red: 0.5, green: 0.4, blue: 0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 60)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 2, y: 2)

                // Seed interior
                Ellipse()
                    .fill(Color(red: 0.8, green: 0.7, blue: 0.5))
                    .frame(width: 40, height: 48)

                // Growth indicator
                if hydrationLevel > 50 {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.6, blue: 0.2))
                        .frame(width: 8, height: 8)
                        .offset(y: -5)
                        .scaleEffect(isGrowing ? 1.1 : 1.0)
                }
            }

            Text("Seed")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Sprout Stage
struct SproutView: View {
    let isGrowing: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                // Soil
                SoilView()
                    .frame(height: 40)

                VStack(spacing: 0) {
                    // Stem
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.3, green: 0.6, blue: 0.3))
                        .frame(width: 6, height: CGFloat(20 + (progress * 20)))

                    // Small leaves
                    HStack(spacing: 8) {
                        LeafShape()
                            .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                            .frame(width: 12, height: 20)
                            .rotationEffect(.degrees(-30))

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.3, green: 0.6, blue: 0.3))
                            .frame(width: 6, height: 8)

                        LeafShape()
                            .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                            .frame(width: 12, height: 20)
                            .rotationEffect(.degrees(30))
                    }
                    .offset(y: -8)

                    Spacer()
                }
                .offset(y: -20)
            }

            Text("Sprout")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Growing Stage
struct GrowingPlantView: View {
    let isGrowing: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                SoilView()
                    .frame(height: 40)

                VStack(spacing: 0) {
                    // Main stem
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.25, green: 0.55, blue: 0.25))
                        .frame(width: 8, height: CGFloat(40 + (progress * 20)))

                    // Left branch
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            LeafShape()
                                .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                                .frame(width: 16, height: 28)
                                .rotationEffect(.degrees(-45))

                            LeafShape()
                                .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                                .frame(width: 14, height: 24)
                                .rotationEffect(.degrees(-40))
                        }
                        .offset(x: -20)

                        Spacer()

                        // Right branch
                        VStack(spacing: 2) {
                            LeafShape()
                                .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                                .frame(width: 16, height: 28)
                                .rotationEffect(.degrees(45))

                            LeafShape()
                                .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                                .frame(width: 14, height: 24)
                                .rotationEffect(.degrees(40))
                        }
                        .offset(x: 20)
                    }
                    .frame(height: 60)
                    .offset(y: -30)

                    Spacer()
                }
                .offset(y: -20)
            }

            Text("Growing")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Blooming Stage
struct BloomingPlantView: View {
    let isGrowing: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                SoilView()
                    .frame(height: 40)

                VStack(spacing: 0) {
                    // Flower petals
                    ZStack {
                        // Petals arranged in circle
                        ForEach(0..<5, id: \.self) { index in
                            PetalShape()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1.0, green: 0.7, blue: 0.8),
                                            Color(red: 0.95, green: 0.6, blue: 0.7)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 18, height: 28)
                                .offset(y: -14)
                                .rotationEffect(.degrees(Double(index) * 72))
                                .scaleEffect(isGrowing ? 1.0 : 0.8)
                        }

                        // Flower center
                        Circle()
                            .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                            .frame(width: 16, height: 16)
                    }

                    // Stem
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.25, green: 0.55, blue: 0.25))
                        .frame(width: 8, height: 50)

                    // Leaves
                    HStack(spacing: 0) {
                        LeafShape()
                            .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                            .frame(width: 18, height: 30)
                            .rotationEffect(.degrees(-45))
                            .offset(x: -15)

                        Spacer()

                        LeafShape()
                            .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                            .frame(width: 18, height: 30)
                            .rotationEffect(.degrees(45))
                            .offset(x: 15)
                    }
                    .frame(height: 50)
                    .offset(y: -20)

                    Spacer()
                }
                .offset(y: -30)
            }

            Text("Blooming")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Mature Stage
struct MaturePlantView: View {
    let isGrowing: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                SoilView()
                    .frame(height: 40)

                VStack(spacing: 0) {
                    // Multiple flowers
                    HStack(spacing: 16) {
                        SmallFlower(petalColor1: Color(red: 1.0, green: 0.7, blue: 0.8), petalColor2: Color(red: 0.95, green: 0.6, blue: 0.7))
                        SmallFlower(petalColor1: Color(red: 0.8, green: 0.9, blue: 1.0), petalColor2: Color(red: 0.7, green: 0.85, blue: 0.95))
                        SmallFlower(petalColor1: Color(red: 1.0, green: 0.7, blue: 0.8), petalColor2: Color(red: 0.95, green: 0.6, blue: 0.7))
                    }

                    // Main stem
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.2))
                        .frame(width: 10, height: 60)

                    // Large leaves
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            LeafShape()
                                .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                                .frame(width: 20, height: 35)
                                .rotationEffect(.degrees(-50))

                            LeafShape()
                                .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                                .frame(width: 22, height: 38)
                                .rotationEffect(.degrees(-40))
                        }
                        .offset(x: -25)

                        Spacer()

                        VStack(spacing: 6) {
                            LeafShape()
                                .fill(Color(red: 0.35, green: 0.65, blue: 0.35))
                                .frame(width: 20, height: 35)
                                .rotationEffect(.degrees(50))

                            LeafShape()
                                .fill(Color(red: 0.4, green: 0.7, blue: 0.4))
                                .frame(width: 22, height: 38)
                                .rotationEffect(.degrees(40))
                        }
                        .offset(x: 25)
                    }
                    .frame(height: 80)

                    Spacer()
                }
                .offset(y: -40)
            }

            Text("Mature")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Supporting Views
struct SoilView: View {
    var body: some View {
        ZStack {
            // Pot
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.8, green: 0.7, blue: 0.6),
                                Color(red: 0.7, green: 0.6, blue: 0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 50)

                // Soil inside
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .frame(height: 40)
            }
            .frame(maxWidth: 120)
        }
    }
}

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let midY = rect.midY

        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: midY),
            control: CGPoint(x: rect.maxX - 5, y: rect.minY + 10)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control: CGPoint(x: rect.maxX - 5, y: rect.maxY - 10)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: midY),
            control: CGPoint(x: rect.minX + 5, y: rect.maxY - 10)
        )
        path.addQuadCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control: CGPoint(x: rect.minX + 5, y: rect.minY + 10)
        )
        return path
    }
}

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + (height * 0.3)),
            control2: CGPoint(x: rect.maxX, y: rect.maxY - (height * 0.3))
        )
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.maxY - (height * 0.3)),
            control2: CGPoint(x: rect.minX, y: rect.minY + (height * 0.3))
        )
        return path
    }
}

struct SmallFlower: View {
    let petalColor1: Color
    let petalColor2: Color

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                PetalShape()
                    .fill(index % 2 == 0 ? petalColor1 : petalColor2)
                    .frame(width: 12, height: 18)
                    .offset(y: -9)
                    .rotationEffect(.degrees(Double(index) * 90))
            }

            Circle()
                .fill(Color(red: 1.0, green: 0.84, blue: 0.0))
                .frame(width: 10, height: 10)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        PlantVisualView(growthStage: .seed, hydrationLevel: 80, experience: 50)
        PlantVisualView(growthStage: .sprout, hydrationLevel: 80, experience: 50)
        PlantVisualView(growthStage: .growing, hydrationLevel: 80, experience: 50)
        PlantVisualView(growthStage: .blooming, hydrationLevel: 80, experience: 50)
        PlantVisualView(growthStage: .mature, hydrationLevel: 80, experience: 50)
    }
    .padding()
}
