import Foundation
import Observation

// MARK: - Report Reasons (UGC moderation, App Review guideline 1.2)

enum CloudReportReason: String, CaseIterable {
    case harmful
    case spam
    case hateful
    case other

    /// Localized label shown in the report confirmation dialog.
    var label: String {
        switch self {
        case .harmful: return L10n.t("Harmful or unsafe", "有害或不安全")
        case .spam: return L10n.t("Spam or ads", "垃圾信息或广告")
        case .hateful: return L10n.t("Hateful content", "仇恨内容")
        case .other: return L10n.t("Other", "其他")
        }
    }
}

// MARK: - Hidden Posts Store

/// Local moderation state for cloud posts (App Review guideline 1.2).
/// Hidden post IDs and blocked author device IDs persist in UserDefaults so
/// reported/blocked content stays gone across launches — server-side takedown
/// is asynchronous and must never be the only thing protecting the user.
@MainActor @Observable
final class HiddenPostsStore {
    static let shared = HiddenPostsStore()

    static let hiddenPostsKey = "hiddenCloudPostIDs"
    static let blockedAuthorsKey = "blockedCloudAuthorDeviceIDs"

    private let defaults: UserDefaults
    private(set) var hiddenPostIDs: Set<String>
    private(set) var blockedAuthorDeviceIDs: Set<String>

    /// Injectable defaults for tests — production uses .standard.
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hiddenPostIDs = Set(defaults.stringArray(forKey: Self.hiddenPostsKey) ?? [])
        blockedAuthorDeviceIDs = Set(defaults.stringArray(forKey: Self.blockedAuthorsKey) ?? [])
    }

    func hidePost(id: String) {
        hiddenPostIDs.insert(id)
        // Sorted so the persisted array is deterministic (Set order is not)
        defaults.set(hiddenPostIDs.sorted(), forKey: Self.hiddenPostsKey)
    }

    func blockAuthor(deviceId: String) {
        blockedAuthorDeviceIDs.insert(deviceId)
        defaults.set(blockedAuthorDeviceIDs.sorted(), forKey: Self.blockedAuthorsKey)
    }

    /// Clears all hidden/blocked state. Called after a full account deletion
    /// wipes UserDefaults — otherwise the stale in-memory sets would be
    /// re-persisted on the next hide/block call, resurrecting "deleted" data.
    func reset() {
        hiddenPostIDs = []
        blockedAuthorDeviceIDs = []
        defaults.removeObject(forKey: Self.hiddenPostsKey)
        defaults.removeObject(forKey: Self.blockedAuthorsKey)
    }

    func isHidden(_ post: RemoteCloudPost) -> Bool {
        hiddenPostIDs.contains(post.id) || blockedAuthorDeviceIDs.contains(post.deviceId)
    }

    func filter(_ posts: [RemoteCloudPost]) -> [RemoteCloudPost] {
        posts.filter { !isHidden($0) }
    }
}
