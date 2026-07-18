import Foundation
import SwiftData
import WidgetKit

// MARK: - Widget Snapshot (shared with the widget extension via App Group)

/// A tiny, versioned snapshot of what the home-screen widget shows. Written
/// to the App Group shared UserDefaults; the widget extension reads the same
/// keys (mirrored model in widget/Snapshot.swift — keep fields in sync).
struct WidgetSnapshot: Codable {
    var v: Int = 1
    var updatedAt: Date
    var petName: String
    var moodRaw: String
    var hungerLevel: Int
    var energy: Int
    var level: Int
    var lastFedAt: Date?
    var lastHungerUpdateAt: Date?
    var petCreatedAt: Date
    var plantCount: Int
    var plantTopStageRaw: String
    var plantTopName: String
    var tasksDone: Int
    var tasksTotal: Int
    var unreadCount: Int
    var language: String
}

// MARK: - Widget State Store

enum WidgetStateStore {
    static let appGroupID = "group.com.csquare04.Treehole"
    private static let snapshotKey = "widget_snapshot_v1"
    private static let unreadKey = "widget_unread_count"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    /// Persists the last known unread-interactions count on its own — the
    /// unread check (scene activation) and the full snapshot run on
    /// different cadences, and the widget needs the freshest value.
    static func setUnreadCount(_ count: Int) {
        sharedDefaults?.set(count, forKey: unreadKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static var lastUnreadCount: Int {
        sharedDefaults?.integer(forKey: unreadKey) ?? 0
    }

    /// Builds and writes a full snapshot from the current SwiftData state,
    /// then asks the system to refresh the widget. Cheap enough to call on
    /// every backgrounding and after pet/garden actions.
    @MainActor
    static func pushSnapshot(context: ModelContext, language: String) {
        let pets = (try? context.fetch(FetchDescriptor<Pet>())) ?? []
        let plants = (try? context.fetch(FetchDescriptor<Plant>())) ?? []
        let tasks = (try? context.fetch(FetchDescriptor<DailyTask>())) ?? []

        let stageOrder: [String] = GrowthStage.allCases.map(\.rawValue)
        let topPlant = plants.max {
            (stageOrder.firstIndex(of: $0.growthStageRaw) ?? 0) < (stageOrder.firstIndex(of: $1.growthStageRaw) ?? 0)
        }

        let pet = pets.first
        let snapshot = WidgetSnapshot(
            updatedAt: Date(),
            petName: pet?.name ?? "Companion",
            moodRaw: pet?.moodRaw ?? PetMood.neutral.rawValue,
            hungerLevel: pet?.hungerLevel ?? 100,
            energy: pet?.energy ?? 100,
            level: pet?.level ?? 1,
            lastFedAt: pet?.lastFedAt,
            lastHungerUpdateAt: pet?.lastHungerUpdateAt,
            petCreatedAt: pet?.createdAt ?? Date(),
            plantCount: plants.count,
            plantTopStageRaw: topPlant?.growthStageRaw ?? GrowthStage.seed.rawValue,
            plantTopName: topPlant?.name ?? "",
            tasksDone: tasks.filter(\.isCompleted).count,
            tasksTotal: tasks.count,
            unreadCount: lastUnreadCount,
            language: language
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            sharedDefaults?.set(data, forKey: snapshotKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
