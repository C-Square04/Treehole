import SwiftUI

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?

    @AppStorage("mood_picker_style") private var style: String = "pills"
    @AppStorage("mood_pills_expanded") private var pillsExpanded: Bool = false

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

    /// True when the selected mood is one of the 8 expanded-only cases (rows 3+4 of pills).
    private var selectedMoodIsExpandedOnly: Bool {
        let firstEight: [MoodTag] = [.happy, .sad, .angry, .anxious, .tired, .confused, .hopeful, .calm]
        return !firstEight.contains(selectedMood)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: TreeholeTheme.spacingSmall) {
            // Header row: collapse chevron (pills only) on the left, style toggle on the right.
            HStack(spacing: TreeholeTheme.spacingTight) {
                if style == "pills" {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            pillsExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                                .font(.caption.weight(.semibold))
                                .rotationEffect(.degrees(pillsExpanded ? 180 : 0))
                            Text(pillsExpanded
                                 ? L10n.t("Show less", "收起")
                                 : L10n.t("More moods", "更多情绪"))
                                .font(.caption)
                        }
                        .foregroundStyle(TreeholeTheme.softPurple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(TreeholeTheme.softPurple.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    style = (style == "pills") ? "meter" : "pills"
                    if style == "pills" {
                        // Clear custom coords when switching back to pills
                        customValence = nil
                        customArousal = nil
                    }
                } label: {
                    Image(systemName: style == "pills" ? "circle.grid.cross" : "square.grid.2x2")
                        .font(.subheadline)
                        .foregroundStyle(TreeholeTheme.softPurple)
                        .padding(6)
                        .background(TreeholeTheme.softPurple.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall))
                }
                .buttonStyle(.plain)
            }

            if style == "pills" {
                // Force expanded if the user has selected one of the row-3/4 moods,
                // otherwise the selection would be invisible.
                let effectivelyExpanded = pillsExpanded || selectedMoodIsExpandedOnly
                MoodPillsView(
                    selectedMood: $selectedMood,
                    customValence: $customValence,
                    customArousal: $customArousal,
                    expanded: effectivelyExpanded
                )
            } else {
                // Meter mode is always full-size; no collapse.
                MoodMeterView(
                    selectedMood: $selectedMood,
                    customValence: $customValence,
                    customArousal: $customArousal
                )
            }
        }
    }
}

// MARK: - Pills View

private struct MoodPillsView: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?
    let expanded: Bool

    // 4 columns. 2 rows when collapsed, 4 rows when expanded.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var visibleMoods: [MoodTag] {
        let all = MoodTag.allCases
        return expanded ? all : Array(all.prefix(8))
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(visibleMoods) { mood in
                Button {
                    selectedMood = mood
                    customValence = nil
                    customArousal = nil
                } label: {
                    VStack(spacing: 3) {
                        Text(mood.emoji)
                            .font(.title3)
                        Text(L10n.t(mood.labelEN, mood.labelZH))
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(selectedMood == mood ? .white : TreeholeTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedMood == mood
                            ? TreeholeTheme.softPurple
                            : TreeholeTheme.softPurple.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Meter View

private struct MoodMeterView: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?

    @State private var isDragging = false
    /// Local-only drag position so SwiftUI doesn't re-render every emoji on every frame.
    /// We commit to customValence/customArousal/selectedMood only on .onEnded.
    @State private var dragValence: Double? = nil
    @State private var dragArousal: Double? = nil

    /// Current dot position in valence/arousal space
    private var dotValence: Double {
        dragValence ?? customValence ?? selectedMood.defaultValence
    }
    private var dotArousal: Double {
        dragArousal ?? customArousal ?? selectedMood.defaultArousal
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width  // square

            ZStack {
                // 4-quadrant blended background
                quadrantBackground(size: size)

                // Axis labels
                axisLabels(size: size)

                // Mood dots at fixed positions — opacity is constant during drag
                // (no per-frame re-render of selection state).
                ForEach(MoodTag.allCases) { mood in
                    let pos = position(valence: mood.defaultValence, arousal: mood.defaultArousal, in: size)
                    Text(mood.emoji)
                        .font(.system(size: 16))
                        .position(pos)
                        .opacity(selectedMood == mood && !isDragging ? 1.0 : 0.55)
                }

                // Draggable selection indicator
                let dotPos = position(valence: dotValence, arousal: dotArousal, in: size)
                Circle()
                    .fill(TreeholeTheme.softPurple)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle().strokeBorder(.white, lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 5)
                    .position(dotPos)
                    .scaleEffect(isDragging ? 1.3 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isDragging)
            }
            .frame(width: size, height: size)
            .contentShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
            .clipShape(RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging { isDragging = true }
                        let (v, a) = coords(from: value.location, in: size)
                        // Local-only state — no binding/re-render storm.
                        dragValence = v
                        dragArousal = a
                    }
                    .onEnded { value in
                        let (v, a) = coords(from: value.location, in: size)
                        customValence = v
                        customArousal = a
                        selectedMood = MoodTag.nearest(valence: v, arousal: a)
                        dragValence = nil
                        dragArousal = nil
                        isDragging = false
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
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
