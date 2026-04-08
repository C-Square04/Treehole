import SwiftUI

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?

    @AppStorage("mood_picker_style") private var style: String = "pills"

    /// Convenience init for call sites that don't need custom coordinates (e.g. CloudPostCreationView)
    init(selectedMood: Binding<MoodTag>) {
        self._selectedMood = selectedMood
        self._customValence = .constant(nil)
        self._customArousal = .constant(nil)
    }

    /// Full init for JournalEntryEditor
    init(
        selectedMood: Binding<MoodTag>,
        customValence: Binding<Double?>,
        customArousal: Binding<Double?>
    ) {
        self._selectedMood = selectedMood
        self._customValence = customValence
        self._customArousal = customArousal
    }

    var body: some View {
        if style == "pills" {
            MoodPillsView(
                selectedMood: $selectedMood,
                customValence: $customValence,
                customArousal: $customArousal,
                onToggleStyle: toggleStyle
            )
        } else {
            MoodMeterView(
                selectedMood: $selectedMood,
                customValence: $customValence,
                customArousal: $customArousal,
                onToggleStyle: toggleStyle
            )
        }
    }

    private func toggleStyle() {
        style = (style == "pills") ? "meter" : "pills"
        if style == "pills" {
            // Clear custom coords when switching back to pills
            customValence = nil
            customArousal = nil
        }
    }
}

// MARK: - Pills View (compact horizontal scroll)

private struct MoodPillsView: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?
    let onToggleStyle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(MoodTag.allCases) { mood in
                        Button {
                            selectedMood = mood
                            customValence = nil
                            customArousal = nil
                        } label: {
                            HStack(spacing: 4) {
                                Text(mood.emoji)
                                    .font(.system(size: 16))
                                Text(L10n.t(mood.labelEN, mood.labelZH))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(selectedMood == mood ? .white : TreeholeTheme.textPrimary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                selectedMood == mood
                                    ? TreeholeTheme.softPurple
                                    : TreeholeTheme.softPurple.opacity(0.10),
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }

            Button(action: onToggleStyle) {
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TreeholeTheme.softPurple)
                    .frame(width: 30, height: 30)
                    .background(TreeholeTheme.softPurple.opacity(0.12), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Meter View

private struct MoodMeterView: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?
    let onToggleStyle: () -> Void

    /// Local-only drag position. Updated 60fps without touching parent state.
    /// nil = not currently dragging; render from binding instead.
    @GestureState private var liveLocation: CGPoint? = nil

    /// What the dot should display: prefer live drag position, else custom coords, else mood default.
    private func dotPosition(in size: CGFloat) -> CGPoint {
        if let loc = liveLocation {
            return CGPoint(
                x: min(size, max(0, loc.x)),
                y: min(size, max(0, loc.y))
            )
        }
        let v = customValence ?? selectedMood.defaultValence
        let a = customArousal ?? selectedMood.defaultArousal
        return position(valence: v, arousal: a, in: size)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Spacer()
                Button(action: onToggleStyle) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TreeholeTheme.softPurple)
                        .frame(width: 30, height: 30)
                        .background(TreeholeTheme.softPurple.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Show the chosen mood label inline so the user always knows what they picked
            Text("\(selectedMood.emoji)  \(L10n.t(selectedMood.labelEN, selectedMood.labelZH))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TreeholeTheme.textPrimary)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height)
                let dotPos = dotPosition(in: size)

                ZStack {
                    quadrantBackground(size: size)
                    axisLabels(size: size)

                    // Mood dots at fixed positions
                    ForEach(MoodTag.allCases) { mood in
                        let pos = position(valence: mood.defaultValence, arousal: mood.defaultArousal, in: size)
                        Text(mood.emoji)
                            .font(.system(size: 16))
                            .position(pos)
                            .opacity(selectedMood == mood ? 1.0 : 0.45)
                            .allowsHitTesting(false)
                    }

                    // Draggable selection indicator
                    Circle()
                        .fill(TreeholeTheme.softPurple)
                        .frame(width: 26, height: 26)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2.5))
                        .shadow(color: .black.opacity(0.25), radius: 4)
                        .position(dotPos)
                        .scaleEffect(liveLocation != nil ? 1.2 : 1.0)
                        .animation(.spring(response: 0.2), value: liveLocation != nil)
                        .allowsHitTesting(false)
                }
                .frame(width: size, height: size)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                .contentShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .updating($liveLocation) { value, state, _ in
                            // 60fps local update — does NOT trigger parent re-render.
                            state = value.location
                        }
                        .onEnded { value in
                            // Only commit to parent state on release.
                            let (v, a) = coords(from: value.location, in: size)
                            customValence = v
                            customArousal = a
                            selectedMood = MoodTag.nearest(valence: v, arousal: a)
                        }
                )
            }
            .frame(height: 200)
        }
    }

    // Convert valence/arousal to CGPoint within the square
    private func position(valence: Double, arousal: Double, in size: CGFloat) -> CGPoint {
        let x = CGFloat((valence + 1.0) / 2.0) * size
        let y = CGFloat(1.0 - arousal) * size
        return CGPoint(x: x, y: y)
    }

    // Convert drag location to clamped valence/arousal
    private func coords(from point: CGPoint, in size: CGFloat) -> (Double, Double) {
        let valence = Double(point.x / size) * 2.0 - 1.0
        let arousal = 1.0 - Double(point.y / size)
        return (
            min(1.0, max(-1.0, valence)),
            min(1.0, max(0.0, arousal))
        )
    }

    @ViewBuilder
    private func quadrantBackground(size: CGFloat) -> some View {
        // 4 colored rectangles with heavy blur to create smooth gradient transitions
        ZStack {
            // Top-left: high arousal + negative = red/coral
            Rectangle()
                .fill(TreeholeTheme.coral.opacity(0.6))
                .frame(width: size / 2, height: size / 2)
                .position(x: size / 4, y: size / 4)

            // Top-right: high arousal + positive = yellow/gold
            Rectangle()
                .fill(TreeholeTheme.warmGold.opacity(0.6))
                .frame(width: size / 2, height: size / 2)
                .position(x: size * 3 / 4, y: size / 4)

            // Bottom-right: low arousal + positive = green/mint
            Rectangle()
                .fill(TreeholeTheme.mintCream.opacity(0.8))
                .frame(width: size / 2, height: size / 2)
                .position(x: size * 3 / 4, y: size * 3 / 4)

            // Bottom-left: low arousal + negative = blue/sky
            Rectangle()
                .fill(TreeholeTheme.skyBlue.opacity(0.8))
                .frame(width: size / 2, height: size / 2)
                .position(x: size / 4, y: size * 3 / 4)
        }
        .blur(radius: size * 0.2)
    }

    @ViewBuilder
    private func axisLabels(size: CGFloat) -> some View {
        let labelFont = Font.system(size: 9).weight(.medium)
        let labelColor = TreeholeTheme.textSecondary.opacity(0.8)

        // Top center: energetic
        Text(L10n.t("Energetic ↑", "精力充沛 ↑"))
            .font(labelFont)
            .foregroundStyle(labelColor)
            .position(x: size / 2, y: 10)

        // Bottom center: calm
        Text(L10n.t("↓ Calm", "↓ 平静"))
            .font(labelFont)
            .foregroundStyle(labelColor)
            .position(x: size / 2, y: size - 10)

        // Left center: negative
        Text(L10n.t("← Negative", "← 消极"))
            .font(labelFont)
            .foregroundStyle(labelColor)
            .rotationEffect(.degrees(-90))
            .position(x: 14, y: size / 2)

        // Right center: positive
        Text(L10n.t("Positive →", "积极 →"))
            .font(labelFont)
            .foregroundStyle(labelColor)
            .rotationEffect(.degrees(90))
            .position(x: size - 14, y: size / 2)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let label: String
    let value: String
    let icon: String
    var color: Color = TreeholeTheme.warmPeach

    var body: some View {
        HStack(spacing: TreeholeTheme.spacingTight) {
            Image(systemName: icon)
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let value: Int
    let maxValue: Int
    var color: Color = TreeholeTheme.coral

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.2))
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(value) / CGFloat(max(1, maxValue)))
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(TreeholeTheme.softPurple)
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(TreeholeTheme.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(TreeholeTheme.coral)
            }
        }
        .padding(TreeholeTheme.spacingXL)
    }
}
