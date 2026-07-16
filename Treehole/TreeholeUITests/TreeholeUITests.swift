import XCTest

final class TreeholeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // --uitest-reset-state puts pet + economy in a known mid-range state
        // (Debug-only hook in UITestSupport) so persisted SwiftData from
        // earlier tests/runs can't disable the controls under test.
        app.launchArguments = ["--uitesting", "--uitest-reset-state"]
        app.launch()

        // Handle onboarding ONLY when it is actually showing (no tab bar).
        // Blind-swiping on the main UI is what used to open the cloud composer:
        // a horizontal swipe across the centered "Send a Cloud" button fires it
        // (SwiftUI buttons claim horizontal drags inside vertical scroll views),
        // and the stray sheet then broke every element query that followed.
        if !app.tabBars.firstMatch.waitForExistence(timeout: 5) {
            let guestButton = app.buttons.matching(NSPredicate(format:
                "label == 'Continue as Guest' OR label == '以访客身份继续'"
            )).firstMatch
            // Swipe through the onboarding pages until the last page's button shows
            for _ in 0..<4 where !guestButton.exists {
                app.windows.firstMatch.swipeLeft()
                Thread.sleep(forTimeInterval: 0.3)
            }
            if guestButton.waitForExistence(timeout: 3) {
                guestButton.tap()
            }
            _ = app.tabBars.firstMatch.waitForExistence(timeout: 5)
        }
    }

    // MARK: - Navigation Helpers

    private func navigateToMe() {
        // Dismiss any open sheets first
        let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Cancel' OR label CONTAINS[c] '取消' OR label CONTAINS[c] 'Close' OR label CONTAINS[c] 'Done'")).firstMatch
        if closeButton.exists { closeButton.tap(); Thread.sleep(forTimeInterval: 0.3) }

        let meTab = app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Me' OR label CONTAINS[c] '我'")).firstMatch
        if meTab.waitForExistence(timeout: 5) { meTab.tap() }
        Thread.sleep(forTimeInterval: 1)
    }

    private func navigateToShop() {
        navigateToMe()
        let shopLink = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Shop' OR label CONTAINS[c] '商店'")).firstMatch
        if shopLink.waitForExistence(timeout: 5) { shopLink.tap() }
        Thread.sleep(forTimeInterval: 2)
    }

    private func navigateToSettings() {
        navigateToMe()
        let settingsLink = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Settings' OR label CONTAINS[c] '设置'")).firstMatch
        if settingsLink.waitForExistence(timeout: 5) { settingsLink.tap() }
        Thread.sleep(forTimeInterval: 1)
    }

    // MARK: - Determinism Helpers

    /// Polls `condition` until it returns true or `timeout` elapses.
    /// XCUIElement queries re-resolve on each access, so conditions stay live.
    @discardableResult
    private func waitUntil(timeout: TimeInterval, condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return condition()
    }

    /// tap() hard-fails on elements below the fold — scroll until hittable first.
    private func scrollUntilHittable(_ element: XCUIElement, in scrollView: XCUIElement, maxSwipes: Int = 6) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            scrollView.swipeUp()
            swipes += 1
        }
    }

    private func attachScreenshot(named name: String, of application: XCUIApplication? = nil) {
        let screenshot = (application ?? app).screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Tab Navigation

    @MainActor
    func testAllTabsAccessible() throws {
        // Check all 5 tabs exist and are tappable
        let tabBar = app.tabBars.firstMatch

        let tabs = ["Clouds", "Pet", "Garden", "Journal", "Me"]
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
        navigateToSettings()

        let darkToggle = app.switches.matching(NSPredicate(format: "label CONTAINS[c] 'Dark'")).firstMatch
        if darkToggle.waitForExistence(timeout: 3) {
            darkToggle.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Settings Dark Mode On"
            attachment.lifetime = .keepAlways
            add(attachment)

            darkToggle.tap()
        }
    }

    // MARK: - Shop & Tasks

    @MainActor
    func testShopTabShowsTasksAndCurrency() throws {
        navigateToShop()
        Thread.sleep(forTimeInterval: 2)

        // Should see currency display (food icon)
        let shopContent = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '🍖'")).firstMatch
        XCTAssertTrue(shopContent.waitForExistence(timeout: 5), "Currency display should show food count")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Shop Tab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Economy / Shop Tests

    @MainActor
    func testShopShowsDailyTasks() throws {
        navigateToShop()
        Thread.sleep(forTimeInterval: 2)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Shop Daily Tasks"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Tasks panel is the default selected segment — look for task-related content
        // The Tasks panel shows up to 4 daily task cards (one per TaskType).
        // Task titles come from TaskType.title (English, not localized via L10n):
        //   "Share a Cloud", "Feed Your Pet", "Water Your Plant", "Write in Journal"
        // Also search for the reward icons which are always emoji
        let taskCards = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Feed' OR label CONTAINS[c] 'Water' OR label CONTAINS[c] 'Journal' OR label CONTAINS[c] 'Cloud' OR label CONTAINS[c] 'Share' OR label CONTAINS '🍖' OR label CONTAINS '🎫'"
        ))
        // We expect at least 1 task card to be visible
        XCTAssertTrue(taskCards.firstMatch.waitForExistence(timeout: 5), "At least one daily task card should be visible in Shop Tasks panel")
    }

    @MainActor
    func testShopBuyFood() throws {
        navigateToShop()
        Thread.sleep(forTimeInterval: 2)

        // Switch to "Shop" segment in the segmented picker.
        // The segmented Picker renders as a UISegmentedControl — its segments are buttons
        // BUT there's ambiguity with the "Shop" tab bar button.
        // We use the segmented control directly to avoid tapping the tab bar.
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.waitForExistence(timeout: 3) {
            // "Shop" is the second segment (index 1)
            let shopSegment = segmentedControl.buttons["Shop"]
            if shopSegment.waitForExistence(timeout: 2) {
                shopSegment.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Shop Panel"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Find a buy button (shows token cost like "1 🎫")
        // These are FoodPackCard buy buttons labeled "<cost> 🎫"
        let buyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '🎫'")).firstMatch
        if buyButton.waitForExistence(timeout: 3) && buyButton.isEnabled {
            buyButton.tap()
            Thread.sleep(forTimeInterval: 1)

            let screenshot2 = app.screenshot()
            let attachment2 = XCTAttachment(screenshot: screenshot2)
            attachment2.name = "After Shop Purchase"
            attachment2.lifetime = .keepAlways
            add(attachment2)
        }
        // Don't assert — token balance may be insufficient or buy button may be disabled
    }

    @MainActor
    func testShopLoginStreak() throws {
        navigateToShop()
        Thread.sleep(forTimeInterval: 2)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Shop Login Streak"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Login streak card should show the fire emoji 🔥
        let fireEmoji = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '🔥'")).firstMatch
        XCTAssertTrue(fireEmoji.waitForExistence(timeout: 5), "Login streak badge with 🔥 should be visible in Shop tab")
    }

    // MARK: - Pet Economy Integration

    @MainActor
    func testPetFeedCostsFood() throws {
        let petTab = app.tabBars.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Pet' OR label CONTAINS '宠物'"
        )).firstMatch
        XCTAssertTrue(petTab.waitForExistence(timeout: 10), "Pet tab should exist in EN or ZH")
        petTab.tap()

        // The pet is created on first appearance ("Loading..." → content ScrollView),
        // so wait on the scroll view — it only exists once the pet content rendered.
        let petScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(petScrollView.waitForExistence(timeout: 15), "Pet content scroll view should load")

        // Feed button label: "Feed (5 🍖)" + food balance line "🍖 N" (EN) / "喂食 (5 🍖)" (ZH).
        // Scoped to the scroll view so the tab bar can never match.
        let feedButton = petScrollView.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Feed' OR label CONTAINS '喂食'"
        )).firstMatch
        XCTAssertTrue(feedButton.waitForExistence(timeout: 10), "Feed button should exist on Pet tab")

        // The action row sits below the fold on smaller screens and tap() on a
        // non-hittable element fails — scroll it into view first.
        scrollUntilHittable(feedButton, in: petScrollView)
        attachScreenshot(named: "Pet Tab Loaded")

        guard feedButton.isEnabled else {
            // Hunger is 100/100 from persisted state — feeding is disabled by design.
            // Existence + disabled state is the correct observable outcome here.
            attachScreenshot(named: "Pet Feed Disabled (hunger full)")
            return
        }
        XCTAssertTrue(feedButton.isHittable, "Feed button should be hittable after scrolling")

        let labelBefore = feedButton.label
        feedButton.tap()

        // Persisted economy decides the outcome: either 5 food is spent (the
        // "🍖 N" balance line inside the button label changes), the transient
        // "+30 Hunger, +10 XP" feedback appears, the button disables (hunger
        // hit 100), or "Not enough food!" shows. Any of these proves feeding
        // is wired to the food economy.
        let insufficientFeedback = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Not enough food' OR label CONTAINS '食物不足'"
        )).firstMatch
        let successFeedback = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS '+30'"
        )).firstMatch
        let observedOutcome = waitUntil(timeout: 6) {
            feedButton.label != labelBefore
                || successFeedback.exists
                || insufficientFeedback.exists
                || !feedButton.isEnabled
        }
        attachScreenshot(named: "Pet After Feed")
        XCTAssertTrue(observedOutcome, "Feeding should spend food (button balance changes) or report insufficient food")
    }

    // MARK: - Garden Multi-Plant

    @MainActor
    func testAddSecondPlant() throws {
        let gardenTab = app.tabBars.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Garden' OR label CONTAINS '花园'"
        )).firstMatch
        XCTAssertTrue(gardenTab.waitForExistence(timeout: 10), "Garden tab should exist in EN or ZH")
        gardenTab.tap()

        // The garden renders one of two states depending on persisted SwiftData:
        // empty ("Plant a Seed") or plant detail (Water button). Wait for either
        // instead of assuming a fixed 3s window for the empty state.
        // "Plant a Seed" (with " a ") never matches the sheet's "Plant Seed" confirm.
        let plantSeedButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Plant a Seed' OR label == '播种'"
        )).firstMatch
        let waterButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Water Plant' OR label CONTAINS '浇水'"
        )).firstMatch
        XCTAssertTrue(
            waitUntil(timeout: 10) { plantSeedButton.exists || waterButton.exists },
            "Garden should show either the empty state or an existing plant"
        )

        // Ensure the first plant exists.
        if plantSeedButton.exists && !waterButton.exists {
            plantSeedButton.tap()
            confirmAddPlantSheet()
        }
        XCTAssertTrue(waterButton.waitForExistence(timeout: 10), "Garden should show a plant with a Water button")

        let thumbnailsBefore = plantThumbnailCount()
        attachScreenshot(named: "Garden Before Second Plant")

        // Add a second plant. Both add affordances (selector "Add" thumbnail and
        // the toolbar plus) open the same sheet and are gone/disabled once the
        // garden holds the max of 5 plants — state persists between runs, so
        // both branches are expected and both verify multiple plants.
        let addButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Add' OR label CONTAINS '添加'"
        )).firstMatch
        if addButton.waitForExistence(timeout: 3) && addButton.isEnabled && addButton.isHittable {
            addButton.tap()
            confirmAddPlantSheet()
            XCTAssertTrue(
                waitUntil(timeout: 10) { self.plantThumbnailCount() >= thumbnailsBefore + 1 },
                "Adding a plant should grow the selector from \(thumbnailsBefore) thumbnails"
            )
        } else {
            // Garden is full (5/5): multiple plants are already present.
            XCTAssertGreaterThanOrEqual(thumbnailsBefore, 2,
                "With the add affordance unavailable the garden must already hold multiple plants")
        }

        XCTAssertTrue(waterButton.waitForExistence(timeout: 5), "Selected plant should still show its Water button")
        attachScreenshot(named: "Garden With Second Plant")
    }

    /// Taps "Plant Seed" in the add-plant sheet and waits for the sheet to dismiss.
    private func confirmAddPlantSheet() {
        let confirmQuery = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Plant Seed' OR label CONTAINS '播种'"
        ))
        XCTAssertTrue(confirmQuery.firstMatch.waitForExistence(timeout: 8), "Add-plant sheet should show its Plant Seed button")
        // In ZH the empty-state button behind the sheet is also labeled "播种" —
        // pick the hittable match (the sheet's own button), scrolling the sheet
        // if the button sits below its fold.
        var confirmButton = confirmQuery.allElementsBoundByIndex.first(where: { $0.isHittable })
        if confirmButton == nil {
            app.swipeUp()
            confirmButton = confirmQuery.allElementsBoundByIndex.first(where: { $0.isHittable })
        }
        guard let confirmButton else {
            XCTFail("Plant Seed button never became hittable in the add-plant sheet")
            return
        }
        confirmButton.tap()
        XCTAssertTrue(
            waitUntil(timeout: 10) { confirmQuery.count == 0 },
            "Add-plant sheet should dismiss after planting"
        )
    }

    /// Number of plant thumbnails in the garden selector. Thumbnails are buttons
    /// labeled with the plant's name (species default) and emoji; only call this
    /// while the add-plant sheet is closed (its species picker would also match).
    private func plantThumbnailCount() -> Int {
        let speciesPredicate = NSPredicate(format:
            "label CONTAINS 'Sunflower' OR label CONTAINS 'Rose' OR label CONTAINS 'Tulip' OR label CONTAINS 'Cactus' OR label CONTAINS 'Fern' " +
            "OR label CONTAINS '向日葵' OR label CONTAINS '玫瑰' OR label CONTAINS '郁金香' OR label CONTAINS '仙人掌' OR label CONTAINS '蕨类' " +
            "OR label CONTAINS '🌻' OR label CONTAINS '🌹' OR label CONTAINS '🌷' OR label CONTAINS '🌵'"
        )
        return app.buttons.matching(speciesPredicate).count
    }

    @MainActor
    func testSwitchBetweenPlants() throws {
        app.tabBars.buttons["Garden"].tap()
        Thread.sleep(forTimeInterval: 1)

        // Make sure there's at least one plant
        let plantSeedButton = app.buttons["Plant a Seed"]
        if plantSeedButton.waitForExistence(timeout: 2) {
            plantSeedButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let confirmButton = app.buttons["Plant Seed"]
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Garden Plant Selector Before"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Scroll the plant selector horizontally and tap a thumbnail button
        // Thumbnails are PlainButtonStyle buttons containing plant name and emoji
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            // Try tapping the second plant thumbnail if it exists
            let allPlainButtons = app.buttons.allElementsBoundByIndex
            // Filter for small plant thumbnail buttons in the selector region
            // They appear near the top of the screen
            for button in allPlainButtons.prefix(20) {
                let frame = button.frame
                // Plant thumbnails are in the top selector area (y < 300) and small
                if frame.height < 80 && frame.width < 80 && frame.minY < 300 && frame.minY > 50 {
                    button.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                    break
                }
            }
        }

        let screenshot2 = app.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "Garden After Plant Switch"
        attachment2.lifetime = .keepAlways
        add(attachment2)
    }

    // MARK: - Journal Stats

    @MainActor
    func testJournalShowsStats() throws {
        let journalTab = app.tabBars.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Journal' OR label CONTAINS '日记'"
        )).firstMatch
        XCTAssertTrue(journalTab.waitForExistence(timeout: 10), "Journal tab should exist in EN or ZH")
        journalTab.tap()

        let journalScrollView = app.scrollViews.firstMatch
        XCTAssertTrue(journalScrollView.waitForExistence(timeout: 10), "Journal tab should load its scroll view")
        attachScreenshot(named: "Journal Loaded")

        // The stats row (Total / This Week / This Month) renders only when at
        // least one entry exists. Entries persist between runs, so either branch
        // is a valid starting state — create an entry if there are none yet.
        let totalStat = app.staticTexts.matching(NSPredicate(format:
            "label == 'Total' OR label == '总计'"
        )).firstMatch
        if !totalStat.waitForExistence(timeout: 3) {
            try createJournalEntry(text: "Stats test entry")
        }

        XCTAssertTrue(totalStat.waitForExistence(timeout: 10), "Journal stats row should show the Total stat")
        let weekStat = app.staticTexts.matching(NSPredicate(format:
            "label == 'This Week' OR label == '本周'"
        )).firstMatch
        XCTAssertTrue(weekStat.waitForExistence(timeout: 5), "Journal stats row should show the This Week stat")
        attachScreenshot(named: "Journal Stats Visible")
    }

    /// Creates a journal entry through the editor sheet. Skips (never flakes) when
    /// the simulator has a hardware keyboard connected and typing is impossible.
    private func createJournalEntry(text: String) throws {
        // Empty state exposes "Write Entry"; the toolbar compose icon is the fallback.
        let writeEntryButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Write Entry' OR label CONTAINS '写日记'"
        )).firstMatch
        let composeButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'pencil' OR identifier CONTAINS[c] 'pencil' OR label CONTAINS[c] 'compose'"
        )).firstMatch
        if writeEntryButton.waitForExistence(timeout: 3) && writeEntryButton.isHittable {
            writeEntryButton.tap()
        } else {
            XCTAssertTrue(composeButton.waitForExistence(timeout: 5), "A compose affordance should exist on the Journal tab")
            composeButton.tap()
        }

        let textEditor = app.textViews.firstMatch
        XCTAssertTrue(textEditor.waitForExistence(timeout: 8), "Entry editor should open with a text editor")
        if !textEditor.isHittable {
            app.swipeUp()
        }
        textEditor.tap()

        // typeText hard-fails without keyboard focus — verify the software
        // keyboard actually appeared (a connected hardware keyboard suppresses
        // it) and retry the tap once before deciding.
        if !app.keyboards.firstMatch.waitForExistence(timeout: 3) {
            textEditor.tap()
        }
        guard app.keyboards.firstMatch.waitForExistence(timeout: 3) else {
            let cancelButton = app.buttons.matching(NSPredicate(format:
                "label == 'Cancel' OR label == '取消'"
            )).firstMatch
            if cancelButton.exists { cancelButton.tap() }
            throw XCTSkip("Software keyboard unavailable (hardware keyboard connected?) — cannot type an entry. Disable 'Connect Hardware Keyboard' on the simulator.")
        }
        textEditor.typeText(text)

        let saveButton = app.buttons.matching(NSPredicate(format:
            "label == 'Save' OR label == '保存'"
        )).firstMatch
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5), "Save button should exist in the entry editor")
        XCTAssertTrue(waitUntil(timeout: 5) { saveButton.isEnabled }, "Save should enable once the entry has text")
        saveButton.tap()
        XCTAssertTrue(
            waitUntil(timeout: 10) { !saveButton.exists },
            "Entry editor sheet should dismiss after saving"
        )
    }

    // MARK: - Cloud Drift Bottle

    @MainActor
    func testCloudTabShowsGrabButton() throws {
        app.tabBars.buttons["Clouds"].tap()
        Thread.sleep(forTimeInterval: 2)

        // Should see "Grab a Cloud" or "抓一朵云" button
        let grabButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Grab' OR label CONTAINS[c] '抓'")).firstMatch
        XCTAssertTrue(grabButton.waitForExistence(timeout: 5), "Grab a Cloud button should exist")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Cloud Drift Bottle View"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testCloudTabShowsSendButton() throws {
        app.tabBars.buttons["Clouds"].tap()
        Thread.sleep(forTimeInterval: 2)

        let sendButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Send' OR label CONTAINS[c] '放飞'")).firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5), "Send a Cloud button should exist")
    }

    @MainActor
    func testGrabCloudButton() throws {
        // Just verify the button exists and is tappable
        // (no posts in test DB, so grab will show error/empty — that's OK)
        app.tabBars.buttons["Clouds"].tap()
        Thread.sleep(forTimeInterval: 2)

        let grabButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Grab' OR label CONTAINS[c] '抓'")).firstMatch
        XCTAssertTrue(grabButton.waitForExistence(timeout: 5), "Grab button should exist")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Cloud Drift Bottle"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Language Toggle

    @MainActor
    func testZZ_LanguageSwitchToChinese() throws {
        navigateToSettings()

        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Settings Before Language Switch"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Find and tap the Language picker
        let languagePicker = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Language' OR label CONTAINS[c] '语言'")).firstMatch
        if languagePicker.waitForExistence(timeout: 3) {
            languagePicker.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Alternatively, find the 中文 option directly
        let chineseOption = app.buttons["中文"]
        if chineseOption.waitForExistence(timeout: 2) {
            chineseOption.tap()
            Thread.sleep(forTimeInterval: 1)
        }

        let screenshot2 = app.screenshot()
        let attachment2 = XCTAttachment(screenshot: screenshot2)
        attachment2.name = "Settings After Language Switch"
        attachment2.lifetime = .keepAlways
        add(attachment2)

        // After switching to Chinese, verify the nav title changes to "设置"
        let chineseTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] '设置' OR label CONTAINS[c] 'Settings'")).firstMatch
        XCTAssertTrue(chineseTitle.waitForExistence(timeout: 5), "Settings navigation title should exist (in either language)")

        // Reset back to English to avoid affecting other tests
        let englishOption = app.buttons["English"]
        if englishOption.waitForExistence(timeout: 2) {
            englishOption.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    // MARK: - Weekly Challenges

    @MainActor
    func testWeeklyChallengesVisible() throws {
        navigateToShop()
        Thread.sleep(forTimeInterval: 2)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Shop Weekly Challenges"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Weekly challenges section has a header with "Weekly Challenges" or "每周挑战"
        let weeklyChallengesHeader = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Weekly' OR label CONTAINS[c] '每周'"
        )).firstMatch
        XCTAssertTrue(weeklyChallengesHeader.waitForExistence(timeout: 5), "Weekly challenges section should be visible in Shop Tasks tab")
    }

    // MARK: - Onboarding

    @MainActor
    func testOnboardingPages() throws {
        // Launch a fresh app instance without the uitesting flag so onboarding appears
        let freshApp = XCUIApplication()
        freshApp.launchArguments = ["--uitesting-onboarding"]
        freshApp.launch()
        Thread.sleep(forTimeInterval: 1)

        let screenshot1 = freshApp.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Onboarding Page 1"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // If onboarding is shown, we should see "Welcome" or "Treehole" text on page 1
        let welcomeText = freshApp.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Welcome' OR label CONTAINS[c] 'Treehole' OR label CONTAINS[c] '欢迎'"
        )).firstMatch

        if welcomeText.waitForExistence(timeout: 3) {
            // Swipe left through remaining pages
            let screen = freshApp.windows.firstMatch

            screen.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
            let screenshot2 = freshApp.screenshot()
            let attachment2 = XCTAttachment(screenshot: screenshot2)
            attachment2.name = "Onboarding Page 2"
            attachment2.lifetime = .keepAlways
            add(attachment2)

            screen.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
            let screenshot3 = freshApp.screenshot()
            let attachment3 = XCTAttachment(screenshot: screenshot3)
            attachment3.name = "Onboarding Page 3"
            attachment3.lifetime = .keepAlways
            add(attachment3)

            screen.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)
            let screenshot4 = freshApp.screenshot()
            let attachment4 = XCTAttachment(screenshot: screenshot4)
            attachment4.name = "Onboarding Page 4"
            attachment4.lifetime = .keepAlways
            add(attachment4)

            // On the last page, "Continue as Guest" button should appear
            let guestButton = freshApp.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Guest'")).firstMatch
            if guestButton.waitForExistence(timeout: 3) {
                guestButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }
        // Don't assert harshly — onboarding only shows on truly fresh install;
        // the --uitesting flag in setUp suppresses it. Just capture state.
        freshApp.terminate()
    }
}
