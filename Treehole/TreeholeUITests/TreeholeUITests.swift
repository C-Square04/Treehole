import XCTest

final class TreeholeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()

        // If onboarding appears, swipe through pages and tap "Continue as Guest"
        let guestButton = app.buttons["Continue as Guest"]
        if !guestButton.exists {
            // Swipe left 3 times to reach the last onboarding page
            let screen = app.windows.firstMatch
            for _ in 0..<3 {
                screen.swipeLeft()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
        if guestButton.waitForExistence(timeout: 3) {
            guestButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    // MARK: - Tab Navigation

    @MainActor
    func testAllTabsAccessible() throws {
        // Check all 5 tabs exist and are tappable
        let tabBar = app.tabBars.firstMatch

        let tabs = ["Clouds", "Pet", "Garden", "Journal", "Settings"]
        for tabName in tabs {
            let tab = tabBar.buttons[tabName]
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "Tab '\(tabName)' should exist")
            tab.tap()
            // Small delay for animation
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Take screenshot of final tab (Settings)
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Settings Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Pet Tab

    @MainActor
    func testPetFeedButton() throws {
        // Navigate to Pet tab
        let petTab = app.tabBars.buttons["Pet"]
        XCTAssertTrue(petTab.waitForExistence(timeout: 5), "Pet tab should exist")
        petTab.tap()
        Thread.sleep(forTimeInterval: 3)

        // Screenshot to see what's on screen
        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Pet Tab State"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Try finding Feed button with various approaches
        let feedButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Feed'")).firstMatch

        if feedButton.waitForExistence(timeout: 3) && feedButton.isEnabled {
            feedButton.tap()
            Thread.sleep(forTimeInterval: 1)

            let screenshot2 = app.screenshot()
            let attachment2 = XCTAttachment(screenshot: screenshot2)
            attachment2.name = "Pet After Feed"
            attachment2.lifetime = .keepAlways
            add(attachment2)
        }
        // Don't assert — just capture state
    }

    @MainActor
    func testPetRestButton() throws {
        app.tabBars.buttons["Pet"].tap()
        Thread.sleep(forTimeInterval: 3)

        let restButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Rest'")).firstMatch
        if restButton.waitForExistence(timeout: 5) && restButton.isEnabled {
            restButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Pet After Rest"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Garden Tab

    @MainActor
    func testGardenWaterButton() throws {
        app.tabBars.buttons["Garden"].tap()
        Thread.sleep(forTimeInterval: 1)

        // If empty state, tap "Plant a Seed"
        let plantSeedButton = app.buttons["Plant a Seed"]
        if plantSeedButton.waitForExistence(timeout: 2) {
            plantSeedButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // In the sheet, tap "Plant Seed"
            let confirmButton = app.buttons["Plant Seed"]
            if confirmButton.waitForExistence(timeout: 2) {
                confirmButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        // Look for Water button
        let waterButton = app.buttons["Water Plant"]
        if waterButton.waitForExistence(timeout: 3) && waterButton.isEnabled {
            waterButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Garden After Water"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Cloud Post

    @MainActor
    func testCreateCloudPost() throws {
        app.tabBars.buttons["Clouds"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap + button or "Write a Cloud"
        let writeButton = app.buttons["Write a Cloud"]
        let plusButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus'")).firstMatch

        if writeButton.waitForExistence(timeout: 2) {
            writeButton.tap()
        } else if plusButton.waitForExistence(timeout: 2) {
            plusButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Type in text editor
        let textEditor = app.textViews.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("Testing from UI test!")

            // Tap Post button
            let postButton = app.buttons["Post"]
            if postButton.waitForExistence(timeout: 2) && postButton.isEnabled {
                postButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Clouds After Post"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Journal

    @MainActor
    func testCreateJournalEntry() throws {
        app.tabBars.buttons["Journal"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap write button (toolbar pencil icon or "Write Entry")
        let writeEntryButton = app.buttons["Write Entry"]
        let pencilButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'pencil'")).firstMatch

        if writeEntryButton.waitForExistence(timeout: 2) {
            writeEntryButton.tap()
        } else if pencilButton.waitForExistence(timeout: 2) {
            pencilButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        let textEditor = app.textViews.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("Journal test entry")

            let saveButton = app.buttons["Save"]
            if saveButton.waitForExistence(timeout: 2) && saveButton.isEnabled {
                saveButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Journal After Entry"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Settings

    @MainActor
    func testSettingsDarkModeToggle() throws {
        app.tabBars.buttons["Settings"].tap()
        Thread.sleep(forTimeInterval: 0.5)

        let darkToggle = app.switches["Dark Mode"]
        if darkToggle.waitForExistence(timeout: 3) {
            darkToggle.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Settings Dark Mode On"
            attachment.lifetime = .keepAlways
            add(attachment)

            // Toggle back
            darkToggle.tap()
        }
    }
}
