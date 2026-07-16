import SwiftUI

struct PlantVisualView: View {
    let growthStage: GrowthStage
    let hydrationLevel: Int
    let experience: Int
    @State private var isGrowing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                SoilView().frame(height: 60)
            }

            VStack(spacing: 0) {
                switch growthStage {
                case .seed:
                    SeedView(isGrowing: isGrowing, hydrationLevel: hydrationLevel)
                case .sprout:
                    SproutView(isGrowing: isGrowing, progress: Double(experience) / 100.0)
                case .growing:
                    GrowingPlantView(isGrowing: isGrowing, progress: Double(experience) / 100.0)
                case .blooming:
                    BloomingPlantView(isGrowing: isGrowing, progress: Double(experience) / 100.0)
                case .mature:
                    MaturePlantView(isGrowing: isGrowing)
                }
                Spacer()
            }
        }
        .frame(height: 300)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isGrowing = true
            }
        }
        .accessibilityLabel(L10n.t(
            "Plant at \(growthStage.labelEN) stage, hydration \(hydrationLevel)%",
            "植物处于\(growthStage.labelZH)阶段，水分\(hydrationLevel)%"
        ))
    }
}

// MARK: - Seed Stage

private struct SeedView: View {
    let isGrowing: Bool
    let hydrationLevel: Int

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Ellipse()
                    .fill(LinearGradient(colors: [Color(red: 0.6, green: 0.5, blue: 0.3), Color(red: 0.5, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 60)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                Ellipse()
                    .fill(Color(red: 0.8, green: 0.7, blue: 0.5))
                    .frame(width: 40, height: 48)
                if hydrationLevel > 50 {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.6, blue: 0.2))
                        .frame(width: 8, height: 8)
                        .offset(y: -5)
                        .scaleEffect(isGrowing ? 1.1 : 1.0)
                }
            }
            Text(L10n.t("Seed", "种子")).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Sprout Stage

private struct SproutView: View {
    let isGrowing: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.3, green: 0.6, blue: 0.3))
                        .frame(width: 6, height: CGFloat(20 + (progress * 20)))
                    HStack(spacing: 8) {
                        LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 12, height: 20).rotationEffect(.degrees(-30))
                        RoundedRectangle(cornerRadius: 3).fill(Color(red: 0.3, green: 0.6, blue: 0.3)).frame(width: 6, height: 8)
                        LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 12, height: 20).rotationEffect(.degrees(30))
                    }
                    .offset(y: -8)
                    Spacer()
                }
                .offset(y: -20)
            }
            Text(L10n.t("Sprout", "幼苗")).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Growing Stage

private struct GrowingPlantView: View {
    let isGrowing: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.25, green: 0.55, blue: 0.25))
                        .frame(width: 8, height: CGFloat(40 + (progress * 20)))
                    HStack(spacing: 0) {
                        VStack(spacing: 2) {
                            LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 16, height: 28).rotationEffect(.degrees(-45))
                            LeafShape().fill(Color(red: 0.35, green: 0.65, blue: 0.35)).frame(width: 14, height: 24).rotationEffect(.degrees(-40))
                        }
                        .offset(x: -20)
                        Spacer()
                        VStack(spacing: 2) {
                            LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 16, height: 28).rotationEffect(.degrees(45))
                            LeafShape().fill(Color(red: 0.35, green: 0.65, blue: 0.35)).frame(width: 14, height: 24).rotationEffect(.degrees(40))
                        }
                        .offset(x: 20)
                    }
                    .frame(height: 60)
                    .offset(y: -30)
                    Spacer()
                }
                .offset(y: -20)
            }
            Text(L10n.t("Growing", "成长中")).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Blooming Stage

private struct BloomingPlantView: View {
    let isGrowing: Bool
    let progress: Double

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                VStack(spacing: 0) {
                    ZStack {
                        ForEach(0..<5, id: \.self) { index in
                            PetalShape()
                                .fill(LinearGradient(colors: [Color(red: 1.0, green: 0.7, blue: 0.8), Color(red: 0.95, green: 0.6, blue: 0.7)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 18, height: 28)
                                .offset(y: -14)
                                .rotationEffect(.degrees(Double(index) * 72))
                                .scaleEffect(isGrowing ? 1.0 : 0.8)
                        }
                        Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 16)
                    }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.25, green: 0.55, blue: 0.25))
                        .frame(width: 8, height: 50)
                    HStack(spacing: 0) {
                        LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 18, height: 30).rotationEffect(.degrees(-45)).offset(x: -15)
                        Spacer()
                        LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 18, height: 30).rotationEffect(.degrees(45)).offset(x: 15)
                    }
                    .frame(height: 50)
                    .offset(y: -20)
                    Spacer()
                }
                .offset(y: -30)
            }
            Text(L10n.t("Blooming", "开花中")).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Mature Stage

private struct MaturePlantView: View {
    let isGrowing: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                VStack(spacing: 0) {
                    HStack(spacing: 16) {
                        SmallFlower(color1: Color(red: 1.0, green: 0.7, blue: 0.8), color2: Color(red: 0.95, green: 0.6, blue: 0.7))
                        SmallFlower(color1: Color(red: 0.8, green: 0.9, blue: 1.0), color2: Color(red: 0.7, green: 0.85, blue: 0.95))
                        SmallFlower(color1: Color(red: 1.0, green: 0.7, blue: 0.8), color2: Color(red: 0.95, green: 0.6, blue: 0.7))
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.2))
                        .frame(width: 10, height: 60)
                    HStack(spacing: 0) {
                        VStack(spacing: 6) {
                            LeafShape().fill(Color(red: 0.35, green: 0.65, blue: 0.35)).frame(width: 20, height: 35).rotationEffect(.degrees(-50))
                            LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 22, height: 38).rotationEffect(.degrees(-40))
                        }
                        .offset(x: -25)
                        Spacer()
                        VStack(spacing: 6) {
                            LeafShape().fill(Color(red: 0.35, green: 0.65, blue: 0.35)).frame(width: 20, height: 35).rotationEffect(.degrees(50))
                            LeafShape().fill(Color(red: 0.4, green: 0.7, blue: 0.4)).frame(width: 22, height: 38).rotationEffect(.degrees(40))
                        }
                        .offset(x: 25)
                    }
                    .frame(height: 80)
                    Spacer()
                }
                .offset(y: -40)
            }
            Text(L10n.t("Mature", "成熟")).font(.caption).foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Supporting Shapes

private struct SoilView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [Color(red: 0.8, green: 0.7, blue: 0.6), Color(red: 0.7, green: 0.6, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 50)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.5, green: 0.4, blue: 0.3))
                .frame(height: 40)
        }
        .frame(maxWidth: 120)
    }
}

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.maxX - 5, y: rect.minY + 10))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control: CGPoint(x: rect.maxX - 5, y: rect.maxY - 10))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.minX + 5, y: rect.maxY - 10))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + 5, y: rect.minY + 10))
        return path
    }
}

private struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX, y: rect.minY + (rect.height * 0.3)), control2: CGPoint(x: rect.maxX, y: rect.maxY - (rect.height * 0.3)))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.maxY - (rect.height * 0.3)), control2: CGPoint(x: rect.minX, y: rect.minY + (rect.height * 0.3)))
        return path
    }
}

private struct SmallFlower: View {
    let color1: Color
    let color2: Color

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                PetalShape()
                    .fill(index % 2 == 0 ? color1 : color2)
                    .frame(width: 12, height: 18)
                    .offset(y: -9)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.0)).frame(width: 10)
        }
    }
}
