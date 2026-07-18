import WidgetKit
import SwiftUI

// MARK: - Snapshot Loading

enum WidgetSnapshotStore {
    private static let snapshotKey = "widget_snapshot_v1"

    static func load() -> WidgetSnapshot {
        guard let data = UserDefaults(suiteName: "group.com.csquare04.Treehole")?.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .fallback
        }
        return snapshot
    }
}

// MARK: - Timeline

struct TreeholeEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct TreeholeProvider: TimelineProvider {
    func placeholder(in context: Context) -> TreeholeEntry {
        TreeholeEntry(date: Date(), snapshot: .fallback)
    }

    func getSnapshot(in context: Context, completion: @escaping (TreeholeEntry) -> Void) {
        completion(TreeholeEntry(date: Date(), snapshot: WidgetSnapshotStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TreeholeEntry>) -> Void) {
        // Hourly entries for the next 6 hours — the cat keeps living on the
        // home screen (hunger decays 1/h, sleeps overnight), so each entry
        // renders slightly differently even without an app launch.
        let now = Date()
        let snapshot = WidgetSnapshotStore.load()
        let entries = (0..<6).compactMap { hours -> TreeholeEntry? in
            guard let date = Calendar.current.date(byAdding: .hour, value: hours, to: now) else { return nil }
            return TreeholeEntry(date: date, snapshot: snapshot)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Palette (mirrors TreeholeTheme; widget can't import app code)

private enum WidgetColors {
    static let textPrimary = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1)
        : UIColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1)
    })
    static let textSecondary = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.70, green: 0.65, blue: 0.60, alpha: 1)
        : UIColor(red: 0.50, green: 0.45, blue: 0.42, alpha: 1)
    })
    static let accentPurple = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.78, green: 0.65, blue: 0.95, alpha: 1)
        : UIColor(red: 0.60, green: 0.46, blue: 0.74, alpha: 1)
    })
    static let coral = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.90, green: 0.50, blue: 0.44, alpha: 1)
        : UIColor(red: 0.85, green: 0.55, blue: 0.50, alpha: 1)
    })
    static let sky = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.45, green: 0.60, blue: 0.78, alpha: 1)
        : UIColor(red: 0.45, green: 0.62, blue: 0.85, alpha: 1)
    })
}

// MARK: - Small Widget

struct TreeholeWidgetSmallView: View {
    let entry: TreeholeEntry

    var body: some View {
        let s = entry.snapshot
        let lang = s.language
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(s.moodEmoji(at: entry.date))
                    .font(.system(size: 34))
                Spacer()
                if s.unreadCount > 0 {
                    Text("🫧 \(s.unreadCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(WidgetColors.sky)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(WidgetColors.sky.opacity(0.15), in: Capsule())
                }
            }
            Text(s.petName)
                .font(.headline)
                .foregroundStyle(WidgetColors.textPrimary)
                .lineLimit(1)
            Text(WL.t("Lv.\(s.level) · Hunger \(s.hunger(at: entry.date))", "Lv.\(s.level) · 饥饿 \(s.hunger(at: entry.date))", lang: lang))
                .font(.caption2)
                .foregroundStyle(WidgetColors.textSecondary)
            ProgressView(value: Double(s.hunger(at: entry.date)), total: 100)
                .tint(WidgetColors.coral)
            if s.tasksTotal > 0 {
                Text(WL.t("Tasks \(s.tasksDone)/\(s.tasksTotal)", "任务 \(s.tasksDone)/\(s.tasksTotal)", lang: lang))
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.textSecondary)
            }
        }
        .widgetURL(URL(string: "treehole://pet"))
    }
}

// MARK: - Medium Widget

struct TreeholeWidgetMediumView: View {
    let entry: TreeholeEntry

    var body: some View {
        let s = entry.snapshot
        let lang = s.language
        HStack(spacing: 0) {
            // Pet half
            Link(destination: URL(string: "treehole://pet")!) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        Text(s.moodEmoji(at: entry.date))
                            .font(.system(size: 38))
                        Spacer()
                        Text("Lv.\(s.level)")
                            .font(.caption.bold())
                            .foregroundStyle(WidgetColors.accentPurple)
                    }
                    Text(s.petName)
                        .font(.headline)
                        .foregroundStyle(WidgetColors.textPrimary)
                        .lineLimit(1)
                    statRow(label: WL.t("Hunger", "饥饿", lang: lang), value: s.hunger(at: entry.date), tint: WidgetColors.coral)
                    statRow(label: WL.t("Energy", "能量", lang: lang), value: s.energy, tint: WidgetColors.sky)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider().padding(.horizontal, 8)

            // Garden + tasks half
            Link(destination: URL(string: "treehole://garden")!) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(s.stageEmoji).font(.title3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(s.plantCount > 0
                                 ? (s.plantTopName.isEmpty ? WL.t("Garden", "花园", lang: lang) : s.plantTopName)
                                 : WL.t("Garden", "花园", lang: lang))
                                .font(.subheadline.bold())
                                .foregroundStyle(WidgetColors.textPrimary)
                                .lineLimit(1)
                            Text(s.plantCount > 0
                                 ? WL.t("\(s.plantCount) plant(s)", "\(s.plantCount) 株植物", lang: lang)
                                 : WL.t("Plant a seed", "播下种子", lang: lang))
                                .font(.caption2)
                                .foregroundStyle(WidgetColors.textSecondary)
                        }
                    }
                    Spacer(minLength: 0)
                    if s.tasksTotal > 0 {
                        Text(WL.t("Tasks \(s.tasksDone)/\(s.tasksTotal) today", "今日任务 \(s.tasksDone)/\(s.tasksTotal)", lang: lang))
                            .font(.caption)
                            .foregroundStyle(WidgetColors.textSecondary)
                        ProgressView(value: Double(s.tasksDone), total: Double(s.tasksTotal))
                            .tint(WidgetColors.accentPurple)
                    }
                    if s.unreadCount > 0 {
                        Text(WL.t("🫧 \(s.unreadCount) new repl(ies)", "🫧 \(s.unreadCount) 条新回复", lang: lang))
                            .font(.caption.bold())
                            .foregroundStyle(WidgetColors.sky)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func statRow(label: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(label) \(value)")
                .font(.caption2)
                .foregroundStyle(WidgetColors.textSecondary)
            ProgressView(value: Double(value), total: 100)
                .tint(tint)
        }
    }
}

// MARK: - Widget Configuration

struct TreeholeWidget: Widget {
    let kind = "TreeholeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TreeholeProvider()) { entry in
            TreeholeWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(UIColor { $0.userInterfaceStyle == .dark
                        ? UIColor(red: 0.12, green: 0.10, blue: 0.08, alpha: 1)
                        : UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1)
                    })
                }
        }
        .configurationDisplayName(WL.t("Pet & Garden", "宠物与花园", lang: Locale.current.language.languageCode?.identifier == "zh" ? "zh-Hans" : "en"))
        .description(WL.t("Your Treehole companion, garden, and cloud replies at a glance.", "一眼看到树洞伙伴、花园与云朵回复。", lang: Locale.current.language.languageCode?.identifier == "zh" ? "zh-Hans" : "en"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private struct TreeholeWidgetEntryView: View {
    let entry: TreeholeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            TreeholeWidgetMediumView(entry: entry)
        default:
            TreeholeWidgetSmallView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    TreeholeWidget()
} timeline: {
    TreeholeEntry(date: .now, snapshot: .fallback)
}

#Preview(as: .systemMedium) {
    TreeholeWidget()
} timeline: {
    TreeholeEntry(date: .now, snapshot: .fallback)
}
