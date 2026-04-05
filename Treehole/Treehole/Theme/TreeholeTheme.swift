import SwiftUI

// MARK: - Treehole Design System
// Warm macaroon color palette with iOS 26 Liquid Glass support
// All primary colors are dark-mode adaptive using dynamic UIColor

enum TreeholeTheme {

    // MARK: - Primary Warm Tones (adaptive)
    static let warmPeach = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.25, blue: 0.20, alpha: 1) // warm brown
            : UIColor(red: 1.0, green: 0.85, blue: 0.75, alpha: 1)  // original peach
    })
    static let softRose = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.32, green: 0.22, blue: 0.26, alpha: 1)
            : UIColor(red: 0.95, green: 0.80, blue: 0.85, alpha: 1)
    })
    static let gentleLavender = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.28, green: 0.24, blue: 0.35, alpha: 1)
            : UIColor(red: 0.92, green: 0.85, blue: 0.95, alpha: 1)
    })
    static let skyBlue = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.28, blue: 0.38, alpha: 1)
            : UIColor(red: 0.85, green: 0.92, blue: 0.98, alpha: 1)
    })
    static let mintCream = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.30, blue: 0.26, alpha: 1)
            : UIColor(red: 0.90, green: 0.96, blue: 0.92, alpha: 1)
    })

    // MARK: - Accent Colors (slightly more saturated in dark mode)
    static let warmGold = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.80, blue: 0.35, alpha: 1)
            : UIColor(red: 1.0, green: 0.88, blue: 0.60, alpha: 1)
    })
    static let coral = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.90, green: 0.50, blue: 0.44, alpha: 1)
            : UIColor(red: 1.0, green: 0.72, blue: 0.68, alpha: 1)
    })
    static let softPurple = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.55, blue: 0.88, alpha: 1)
            : UIColor(red: 0.88, green: 0.78, blue: 0.92, alpha: 1)
    })

    // MARK: - Text Colors (adaptive)
    static let textPrimary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1) // light cream
            : UIColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1) // dark brown
    })
    static let textSecondary = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.65, blue: 0.60, alpha: 1)
            : UIColor(red: 0.50, green: 0.45, blue: 0.42, alpha: 1)
    })
    static let textLight = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.50, green: 0.46, blue: 0.43, alpha: 1)
            : UIColor(red: 0.70, green: 0.65, blue: 0.62, alpha: 1)
    })

    // MARK: - Gradients (adaptive)
    static let warmBackground = LinearGradient(
        colors: [
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
                : UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1)
            }),
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.15, blue: 0.12, alpha: 1)
                : UIColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 1)
            })
        ],
        startPoint: .top, endPoint: .bottom
    )
    static let cloudyBackground = LinearGradient(
        colors: [
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.15, blue: 0.22, alpha: 1)
                : UIColor(red: 0.92, green: 0.85, blue: 0.95, alpha: 0.4)
            }),
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
                : UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1)
            })
        ],
        startPoint: .top, endPoint: .bottom
    )
    static let softSunset = LinearGradient(
        colors: [
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.22, green: 0.15, blue: 0.12, alpha: 1)
                : UIColor(red: 1.0, green: 0.85, blue: 0.75, alpha: 0.5)
            }),
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
                : UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1)
            })
        ],
        startPoint: .top, endPoint: .bottom
    )
    static let gardenBackground = LinearGradient(
        colors: [
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.20, blue: 0.16, alpha: 1)
                : UIColor(red: 0.90, green: 0.96, blue: 0.92, alpha: 0.5)
            }),
            Color(UIColor { $0.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
                : UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1)
            })
        ],
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
