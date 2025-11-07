//
//  TreeholeTheme.swift
//  Treehole
//
//  Created by Kayli Cheung & Jimmy Chen on 2025-11-06.
//

import SwiftUI

struct TreeholeTheme {
    // MARK: - Color Palette (Warm Macaroon Colors)

    // Primary warm tones
    static let warmPeach = Color(red: 1.0, green: 0.85, blue: 0.75)      // Warm peach
    static let softRose = Color(red: 0.95, green: 0.80, blue: 0.85)      // Soft rose
    static let gentleLavender = Color(red: 0.92, green: 0.85, blue: 0.95) // Gentle lavender
    static let skyBlue = Color(red: 0.85, green: 0.92, blue: 0.98)       // Sky blue
    static let mintCream = Color(red: 0.90, green: 0.96, blue: 0.92)     // Mint cream

    // Accent colors
    static let warmGold = Color(red: 1.0, green: 0.88, blue: 0.60)       // Warm gold
    static let coral = Color(red: 1.0, green: 0.72, blue: 0.68)          // Coral
    static let softPurple = Color(red: 0.88, green: 0.78, blue: 0.92)    // Soft purple

    // Neutral/Glass backgrounds
    static let glassLight = Color.white.opacity(0.85)                    // Liquid glass light
    static let glassMedium = Color.white.opacity(0.70)                   // Liquid glass medium
    static let glassDark = Color.white.opacity(0.50)                     // Liquid glass dark

    // Text colors
    static let textPrimary = Color(red: 0.25, green: 0.25, blue: 0.30)   // Warm dark gray
    static let textSecondary = Color(red: 0.55, green: 0.55, blue: 0.60) // Medium gray
    static let textLight = Color(red: 0.75, green: 0.75, blue: 0.80)     // Light gray

    // MARK: - Gradients

    static var warmBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.98, green: 0.95, blue: 0.93), // Warm cream
                Color(red: 0.96, green: 0.92, blue: 0.92)  // Warm taupe
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cloudyBackground: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.95, green: 0.93, blue: 0.98), // Lavender tint
                Color(red: 0.98, green: 0.96, blue: 0.94)  // Cream
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var softSunset: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 1.0, green: 0.88, blue: 0.75), // Warm peach
                Color(red: 0.98, green: 0.92, blue: 0.88)  // Light cream
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Spacing
    static let spacing8 = CGFloat(8)
    static let spacing12 = CGFloat(12)
    static let spacing16 = CGFloat(16)
    static let spacing20 = CGFloat(20)
    static let spacing24 = CGFloat(24)

    // MARK: - Corner Radius
    static let cornerSmall = CGFloat(8)
    static let cornerMedium = CGFloat(12)
    static let cornerLarge = CGFloat(16)
    static let cornerXL = CGFloat(24)

    // MARK: - Blur Effects
    static let blurSmall = CGFloat(4)
    static let blurMedium = CGFloat(8)
    static let blurLarge = CGFloat(12)
}

// MARK: - View Extension for Easy Theme Access
extension View {
    func treeholeBackground() -> some View {
        self.background(TreeholeTheme.warmBackground)
    }

    func glassCard() -> some View {
        self
            .background(TreeholeTheme.glassLight)
            .cornerRadius(TreeholeTheme.cornerMedium)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    func textPrimary() -> some View {
        self.foregroundColor(TreeholeTheme.textPrimary)
    }
}
