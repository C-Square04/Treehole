import SwiftUI

// Cloud reaction UI components (breeze / hug / starlight), shared by
// GrabbedCloudView in CloudPostListView.swift.

// MARK: - Reaction Bar

struct ReactionBar: View {
    let postId: String
    let reactionCounts: ReactionCounts?
    @Binding var myReactions: Set<String>
    @Binding var showBreezeEffect: Bool
    @Binding var showHugEffect: Bool
    @Binding var showStarlightEffect: Bool
    let onCountsUpdated: (ReactionCounts) -> Void

    // Local optimistic counts
    @State private var localBreeze: Int = 0
    @State private var localHug: Int = 0
    @State private var localStarlight: Int = 0

    // Reaction types with a network request in flight — taps are ignored until it settles,
    // otherwise a double-tap races an add against a remove and desyncs from the server
    @State private var inFlightReactions: Set<String> = []

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingSmall) {
            ReactionButton(
                emoji: "🌬️",
                label: L10n.t("Breeze", "微风"),
                count: localBreeze,
                isActive: myReactions.contains("breeze"),
                activeColor: TreeholeTheme.skyBlue
            ) {
                Task { await toggleReaction("breeze") }
            }

            Divider()
                .frame(height: 28)
                .opacity(0.4)

            ReactionButton(
                emoji: "🤗",
                label: L10n.t("Hug", "拥抱"),
                count: localHug,
                isActive: myReactions.contains("hug"),
                activeColor: TreeholeTheme.coral
            ) {
                Task { await toggleReaction("hug") }
            }

            Divider()
                .frame(height: 28)
                .opacity(0.4)

            ReactionButton(
                emoji: "✨",
                label: L10n.t("Starlight", "星光"),
                count: localStarlight,
                isActive: myReactions.contains("starlight"),
                activeColor: TreeholeTheme.warmGold
            ) {
                Task { await toggleReaction("starlight") }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TreeholeTheme.spacingSmall)
        .padding(.horizontal, TreeholeTheme.spacingMedium)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerLarge))
        .onAppear {
            if let counts = reactionCounts {
                syncCounts(counts)
            }
        }
        .onChange(of: reactionCounts?.totalCount) { _, _ in
            if let counts = reactionCounts {
                syncCounts(counts)
            }
        }
    }

    private func syncCounts(_ counts: ReactionCounts) {
        localBreeze = counts.breezeCount
        localHug = counts.hugCount
        localStarlight = counts.starlightCount
    }

    private func toggleReaction(_ type: String) async {
        guard !inFlightReactions.contains(type) else { return }
        inFlightReactions.insert(type)
        defer { inFlightReactions.remove(type) }

        let isCurrentlyReacted = myReactions.contains(type)

        // Optimistic update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if isCurrentlyReacted {
                myReactions.remove(type)
                adjustCount(type: type, delta: -1)
            } else {
                myReactions.insert(type)
                adjustCount(type: type, delta: 1)
                triggerEffect(type: type)
            }
        }

        // Persist
        do {
            if isCurrentlyReacted {
                try await SupabaseService.removeReaction(postId: postId, type: type)
            } else {
                try await SupabaseService.addReaction(postId: postId, type: type)
                AnalyticsService.track("cloud_reacted", properties: ["type": type])
            }
            // Refresh counts from server
            let updated = try await SupabaseService.fetchReactionCounts(postId: postId)
            onCountsUpdated(updated)
            syncCounts(updated)
        } catch {
            // Revert optimistic update on failure
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if isCurrentlyReacted {
                    myReactions.insert(type)
                    adjustCount(type: type, delta: 1)
                } else {
                    myReactions.remove(type)
                    adjustCount(type: type, delta: -1)
                }
            }
        }
    }

    private func adjustCount(type: String, delta: Int) {
        switch type {
        case "breeze": localBreeze = max(0, localBreeze + delta)
        case "hug": localHug = max(0, localHug + delta)
        case "starlight": localStarlight = max(0, localStarlight + delta)
        default: break
        }
    }

    private func triggerEffect(type: String) {
        switch type {
        case "breeze":
            showBreezeEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                showBreezeEffect = false
            }
        case "hug":
            showHugEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                showHugEffect = false
            }
        case "starlight":
            showStarlightEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                showStarlightEffect = false
            }
        default: break
        }
    }
}

// MARK: - Reaction Button

private struct ReactionButton: View {
    let emoji: String
    let label: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                pressed = false
            }
            action()
        }) {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.callout)
                    .scaleEffect(pressed ? 1.35 : 1.0)
                Text(count > 0 ? "\(count)" : label)
                    .font(.caption)
                    .foregroundStyle(isActive ? activeColor : TreeholeTheme.textSecondary)
                    .fontWeight(isActive ? .semibold : .regular)
            }
            .padding(.horizontal, TreeholeTheme.spacingTight)
            .padding(.vertical, 6)
            .background(
                isActive
                    ? activeColor.opacity(0.18)
                    : Color.clear,
                in: Capsule()
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: pressed)
        .animation(.easeInOut(duration: 0.2), value: isActive)
        .accessibilityLabel(count > 0 ? "\(label), \(count)" : label)
        .accessibilityHint(L10n.t("Sends this reaction to the cloud", "向这朵云发送此互动"))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - Reaction Effects Overlay

struct ReactionEffectsOverlay: View {
    let showBreezeEffect: Bool
    let showHugEffect: Bool
    let showStarlightEffect: Bool

    var body: some View {
        ZStack {
            // Breeze: animated wind lines
            if showBreezeEffect {
                BreezeEffect()
                    .transition(.opacity)
            }

            // Hug: heart pop
            if showHugEffect {
                Image(systemName: "heart.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(TreeholeTheme.coral)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.3).combined(with: .opacity),
                            removal: .scale(scale: 1.6).combined(with: .opacity)
                        )
                    )
            }

            // Starlight: scattered stars
            if showStarlightEffect {
                StarlightEffect()
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.35), value: showBreezeEffect)
        .animation(.spring(response: 0.4, dampingFraction: 0.55), value: showHugEffect)
        .animation(.easeInOut(duration: 0.35), value: showStarlightEffect)
    }
}

// MARK: - Breeze Effect

private struct BreezeEffect: View {
    @State private var progress: CGFloat = 0

    private let lines: [(yOffset: CGFloat, length: CGFloat, delay: Double)] = [
        (-60, 80, 0.0),
        (-20, 120, 0.08),
        (20, 90, 0.15),
        (60, 70, 0.05)
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<lines.count, id: \.self) { i in
                let line = lines[i]
                Path { path in
                    let y = geo.size.height / 2 + line.yOffset
                    let startX = geo.size.width * 0.2
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: startX + line.length * progress, y: y))
                }
                .stroke(
                    TreeholeTheme.skyBlue.opacity(0.8 * (1 - progress)),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Starlight Effect

private struct StarlightEffect: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.9

    private let stars: [(angle: Double, radius: CGFloat, size: CGFloat)] = [
        (0, 60, 8),
        (60, 80, 6),
        (120, 55, 10),
        (180, 70, 7),
        (240, 65, 9),
        (300, 75, 6)
    ]

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2
            ForEach(0..<stars.count, id: \.self) { i in
                let star = stars[i]
                let rad = star.angle * .pi / 180
                let x = cx + cos(rad) * star.radius * scale
                let y = cy + sin(rad) * star.radius * scale
                Circle()
                    .fill(TreeholeTheme.warmGold)
                    .frame(width: star.size * scale, height: star.size * scale)
                    .position(x: x, y: y)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) {
                scale = 1.0
            }
            withAnimation(.easeIn(duration: 0.35).delay(0.5)) {
                opacity = 0
            }
        }
    }
}
