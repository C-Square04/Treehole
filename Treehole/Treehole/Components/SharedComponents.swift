import SwiftUI

// MARK: - Mood Picker

struct MoodPicker: View {
    @Binding var selectedMood: MoodTag

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: TreeholeTheme.spacingSmall) {
                ForEach(MoodTag.allCases) { mood in
                    Button {
                        selectedMood = mood
                    } label: {
                        VStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.title2)
                            Text(L10n.t(mood.labelEN, mood.labelZH))
                                .font(.caption2)
                                .foregroundStyle(selectedMood == mood ? .primary : .secondary)
                        }
                        .padding(.horizontal, TreeholeTheme.spacingTight)
                        .padding(.vertical, TreeholeTheme.spacingSmall)
                        .background(
                            selectedMood == mood
                                ? TreeholeTheme.softPurple.opacity(0.3)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: TreeholeTheme.cornerSmall)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
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
