import SwiftUI

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?

    /// "pills" or "slider" — replaces the old 2D meter mode.
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
                    style = (style == "pills") ? "slider" : "pills"
                    if style == "pills" {
                        // Clear custom coords when switching back to pills
                        customValence = nil
                        customArousal = nil
                    }
                } label: {
                    Image(systemName: style == "pills" ? "slider.horizontal.below.rectangle" : "square.grid.2x2")
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
                MoodSliderView(
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

// MARK: - Slider View (continuous valence picker)

private struct MoodSliderView: View {
    @Binding var selectedMood: MoodTag
    @Binding var customValence: Double?
    @Binding var customArousal: Double?

    /// Continuous slider position. Single source of truth so the slider
    /// remains 100% smooth — we only mirror to the external bindings on commit.
    @State private var sliderValue: Double = 0
    @State private var didInitFromBinding: Bool = false

    /// The mood whose valence is closest to the current slider value.
    private var nearestMood: MoodTag {
        MoodTag.nearestByValence(sliderValue)
    }

    var body: some View {
        VStack(spacing: TreeholeTheme.spacingMedium) {
            Text(L10n.t("How are you feeling right now?", "你现在感觉怎么样？"))
                .font(.subheadline)
                .foregroundStyle(TreeholeTheme.textSecondary)

            // Concentric ripple decoration with the current mood emoji in the center.
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(TreeholeTheme.softPurple.opacity(0.18 - Double(i) * 0.05),
                                lineWidth: 1)
                        .frame(width: CGFloat(60 + i * 28), height: CGFloat(60 + i * 28))
                }
                Circle()
                    .fill(TreeholeTheme.softPurple.opacity(0.18))
                    .frame(width: 64, height: 64)
                Text(nearestMood.emoji)
                    .font(.system(size: 36))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.15), value: nearestMood)
            }
            .frame(height: 130)

            Text(L10n.t(nearestMood.labelEN, nearestMood.labelZH))
                .font(.headline)
                .foregroundStyle(TreeholeTheme.textPrimary)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.15), value: nearestMood)

            // The slider itself — Apple Slider tracks the finger natively
            // and works correctly inside ScrollViews (no gesture conflict).
            VStack(spacing: 4) {
                Slider(value: $sliderValue, in: -1.0...1.0)
                    .tint(TreeholeTheme.softPurple)
                    .padding(.horizontal, TreeholeTheme.spacingSmall)

                HStack {
                    Text(L10n.t("VERY UNPLEASANT", "非常不愉快"))
                        .font(.system(size: 10).weight(.semibold))
                        .foregroundStyle(TreeholeTheme.textLight)
                    Spacer()
                    Text(L10n.t("VERY PLEASANT", "非常愉快"))
                        .font(.system(size: 10).weight(.semibold))
                        .foregroundStyle(TreeholeTheme.textLight)
                }
                .padding(.horizontal, TreeholeTheme.spacingSmall)
            }
        }
        .padding(.vertical, TreeholeTheme.spacingMedium)
        .padding(.horizontal, TreeholeTheme.spacingSmall)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerMedium))
        .onAppear {
            // Initialize from existing custom valence or the selected mood's default.
            if !didInitFromBinding {
                sliderValue = customValence ?? selectedMood.defaultValence
                didInitFromBinding = true
            }
        }
        .onChange(of: sliderValue) { _, newValue in
            // Commit on every change — no gesture state to manage, no race.
            customValence = newValue
            customArousal = nil  // Slider only controls valence
            selectedMood = MoodTag.nearestByValence(newValue)
        }
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
