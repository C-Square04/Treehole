import SwiftUI

// MARK: - Treehole Design System
// Warm macaroon color palette with iOS 26 Liquid Glass support

enum TreeholeTheme {

    // MARK: - Primary Warm Tones
    static let warmPeach = Color(red: 1.0, green: 0.85, blue: 0.75)
    static let softRose = Color(red: 0.95, green: 0.80, blue: 0.85)
    static let gentleLavender = Color(red: 0.92, green: 0.85, blue: 0.95)
    static let skyBlue = Color(red: 0.85, green: 0.92, blue: 0.98)
    static let mintCream = Color(red: 0.90, green: 0.96, blue: 0.92)

    // MARK: - Accent Colors
    static let warmGold = Color(red: 1.0, green: 0.88, blue: 0.60)
    static let coral = Color(red: 1.0, green: 0.72, blue: 0.68)
    static let softPurple = Color(red: 0.88, green: 0.78, blue: 0.92)

    // MARK: - Text Colors
    static let textPrimary = Color(red: 0.25, green: 0.22, blue: 0.20)
    static let textSecondary = Color(red: 0.50, green: 0.45, blue: 0.42)
    static let textLight = Color(red: 0.70, green: 0.65, blue: 0.62)

    // MARK: - Gradients
    static let warmBackground = LinearGradient(
        colors: [Color(red: 1.0, green: 0.97, blue: 0.93), Color(red: 0.96, green: 0.92, blue: 0.88)],
        startPoint: .top, endPoint: .bottom
    )
    static let cloudyBackground = LinearGradient(
        colors: [gentleLavender.opacity(0.4), Color(red: 1.0, green: 0.97, blue: 0.93)],
        startPoint: .top, endPoint: .bottom
    )
    static let softSunset = LinearGradient(
        colors: [warmPeach.opacity(0.5), Color(red: 1.0, green: 0.97, blue: 0.93)],
        startPoint: .top, endPoint: .bottom
    )
    static let gardenBackground = LinearGradient(
        colors: [mintCream.opacity(0.5), Color(red: 1.0, green: 0.97, blue: 0.93)],
        startPoint: .top, endPoint: .bottom
    )

    // MARK: - Spacing
    static let spacingTight: CGFloat = 8
    static let spacingSmall: CGFloat = 12
    static let spacingMedium: CGFloat = 16
    static let spacingLarge: CGFloat = 20
    static let spacingXL: CGFloat = 24

    // MARK: - Corner Radius
    static let cornerSmall: CGFloat = 8
    static let cornerMedium: CGFloat = 12
    static let cornerLarge: CGFloat = 16
    static let cornerXL: CGFloat = 24
}

// MARK: - View Extensions

extension View {
    func treeholeBackground(_ gradient: LinearGradient = TreeholeTheme.warmBackground) -> some View {
        self.background(gradient.ignoresSafeArea())
    }

    func glassCard() -> some View {
        self
            .padding(TreeholeTheme.spacingMedium)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
    }

    func accentCard(_ color: Color = TreeholeTheme.warmPeach) -> some View {
        self
            .padding(TreeholeTheme.spacingMedium)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
    }
}
