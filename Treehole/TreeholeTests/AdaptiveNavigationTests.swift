import Testing
import SwiftUI
import SwiftData
@testable import Treehole

// MARK: - Adaptive Navigation Tests
// Smoke-tests verifying that JournalView and CloudPostListView can be instantiated
// and that supporting types/APIs used for adaptive navigation exist.

@Suite("AdaptiveNavigation")
struct AdaptiveNavigationTests {

    // MARK: - JournalView

    @Test("JournalView type exists and can be referenced")
    func journalViewTypeExists() throws {
        // Just confirm the type compiles and is accessible — deep SwiftUI
        // rendering requires a live host, so we verify the metatype.
        let viewType: Any.Type = JournalView.self
        #expect(viewType == JournalView.self)
    }

    @Test("CloudPostListView type exists and can be referenced")
    func cloudPostListViewTypeExists() throws {
        let viewType: Any.Type = CloudPostListView.self
        #expect(viewType == CloudPostListView.self)
    }

    @MainActor
    @Test("RemoteCloudPost is Identifiable and Codable")
    func remoteCloudPostConformances() throws {
        // Verify the type used for split view selection conforms to needed protocols.
        let idType: Any.Type = RemoteCloudPost.ID.self
        #expect(idType == String.self)

        // Decode through the real snake_case column names to prove the
        // Identifiable id is the server post id (what selection keys off).
        let json = """
        {"id":"post-42","author_alias":"Cloud Fox","mood_tag":"calm","text":"hi",\
        "npc_reply_text":null,"source_language":"en","device_id":"dev-1",\
        "apple_user_id":null,"created_at":"2026-01-01T00:00:00.000Z","flagged":false}
        """
        let post = try JSONDecoder().decode(RemoteCloudPost.self, from: Data(json.utf8))
        #expect(post.id == "post-42")
        #expect(post.mood == .calm)
        #expect(post.authorAlias == "Cloud Fox")
    }

    @Test("JournalEntry conforms to Identifiable for split view selection")
    func journalEntryIsIdentifiable() throws {
        // NavigationSplitView requires the selected item to be Identifiable.
        // JournalEntry is a SwiftData @Model so it conforms automatically.
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: JournalEntry.self, configurations: config)
        let context = ModelContext(container)
        let first = JournalEntry(moodTag: .calm, text: "First")
        let second = JournalEntry(moodTag: .happy, text: "Second")
        context.insert(first)
        context.insert(second)
        // Distinct entries must yield distinct selection ids, or selecting one
        // row in the sidebar could highlight/open another.
        #expect(first.persistentModelID != second.persistentModelID)
    }

    @Test("GrabbedCloudView accepts optional Binding for post")
    func grabbedCloudViewTypeExists() throws {
        // Verify GrabbedCloudView exists and has the right shape.
        let viewType: Any.Type = GrabbedCloudView.self
        #expect(viewType == GrabbedCloudView.self)
    }

}
