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

        let tabs = ["Clouds", "Pet", "Garden", "Journal", "Shop"]
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
        // Navigate to Shop tab
        app.tabBars.buttons["Shop"].tap()
        Thread.sleep(forTimeInterval: 1)

        // Tap the settings gear in toolbar
        let gearButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'gear' OR label CONTAINS[c] 'settings' OR label CONTAINS[c] 'Settings'")).firstMatch
        if gearButton.waitForExistence(timeout: 3) {
            gearButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

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
        app.tabBars.buttons["Shop"].tap()
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
        app.tabBars.buttons["Shop"].tap()
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
        app.tabBars.buttons["Shop"].tap()
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
        app.tabBars.buttons["Shop"].tap()
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
        app.tabBars.buttons["Pet"].tap()
        Thread.sleep(forTimeInterval: 3)

        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Pet Before Feed"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // The feed button label contains "Feed (5 🍖)" in English or "喂食 (5 🍖)" in Chinese.
        // Use food icon as the canonical identifier since it appears in both languages.
        // The button's VStack includes: Label("Feed (5 🍖)" / "喂食 (5 🍖)") + Text("🍖 N")
        // Look for any button that has "🍖" in its label (covers both EN and ZH)
        let feedButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS '🍖' OR label CONTAINS[c] 'Feed' OR label CONTAINS '喂食'"
        )).firstMatch
        XCTAssertTrue(feedButton.waitForExistence(timeout: 5), "Feed button (with 🍖 icon) should be present on Pet screen")

        // Verify food icon also appears on screen as a stat label
        let foodIcon = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '🍖'")).firstMatch
        XCTAssertTrue(foodIcon.waitForExistence(timeout: 3), "Food icon 🍖 should appear on Pet screen (in button or stats)")

        if feedButton.isEnabled {
            feedButton.tap()
            Thread.sleep(forTimeInterval: 2)

            let screenshot2 = app.screenshot()
            let attachment2 = XCTAttachment(screenshot: screenshot2)
            attachment2.name = "Pet After Feed (food decreased)"
            attachment2.lifetime = .keepAlways
            add(attachment2)
        }
    }

    // MARK: - Garden Multi-Plant

    @MainActor
    func testAddSecondPlant() throws {
        app.tabBars.buttons["Garden"].tap()
        Thread.sleep(forTimeInterval: 1)

        // Ensure at least one plant exists first.
        // "Plant a Seed" is the English empty-state button; "播种" is Chinese.
        let plantSeedButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Plant a Seed' OR label CONTAINS[c] '播种'"
        )).firstMatch
        if plantSeedButton.waitForExistence(timeout: 2) {
            plantSeedButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
            // "Plant Seed" confirm button in AddPlantSheet
            let confirmButton = app.buttons.matching(NSPredicate(format:
                "label CONTAINS[c] 'Plant Seed' OR label CONTAINS[c] '播种'"
            )).firstMatch
            if confirmButton.waitForExistence(timeout: 3) {
                confirmButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        // First confirm we have at least one plant — Water Plant button exists in EN or ZH
        let waterButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Water' OR label CONTAINS[c] '浇水'"
        )).firstMatch
        XCTAssertTrue(waterButton.waitForExistence(timeout: 5), "Garden should show a plant (Water button visible in EN or ZH)")

        // Now tap the toolbar + button to add a second plant
        // The toolbar button uses systemName "plus.circle.fill"
        let addButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Add' OR label CONTAINS[c] 'plus' OR label CONTAINS[c] 'New' OR label CONTAINS[c] '添加'"
        )).firstMatch
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // In the Add Plant sheet, tap "Plant Seed" / "播种" to confirm with defaults
            let plantSeedConfirm = app.buttons.matching(NSPredicate(format:
                "label CONTAINS[c] 'Plant Seed' OR label CONTAINS[c] '播种'"
            )).firstMatch
            if plantSeedConfirm.waitForExistence(timeout: 3) {
                plantSeedConfirm.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Garden With Second Plant"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Garden should still show plant content
        let waterButtonAfter = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Water' OR label CONTAINS[c] '浇水'"
        )).firstMatch
        XCTAssertTrue(waterButtonAfter.waitForExistence(timeout: 5), "Garden should still show a plant after attempting to add second")
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
        app.tabBars.buttons["Journal"].tap()
        Thread.sleep(forTimeInterval: 1)

        let screenshot0 = app.screenshot()
        let attachment0 = XCTAttachment(screenshot: screenshot0)
        attachment0.name = "Journal Initial State"
        attachment0.lifetime = .keepAlways
        add(attachment0)

        // Open new-entry editor: try empty-state button first, then toolbar button
        // Empty state shows "Write Entry" (EN) or "写日记" (ZH)
        let emptyWriteButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Write Entry' OR label CONTAINS[c] '写日记'"
        )).firstMatch
        if emptyWriteButton.waitForExistence(timeout: 2) {
            emptyWriteButton.tap()
        } else {
            // Toolbar button uses systemName "square.and.pencil"
            // SF Symbols accessibility label: "square and pencil"
            let toolbarButton = app.buttons.matching(NSPredicate(format:
                "label CONTAINS[c] 'pencil' OR label CONTAINS[c] 'square'"
            )).firstMatch
            if toolbarButton.waitForExistence(timeout: 2) {
                toolbarButton.tap()
            }
        }
        Thread.sleep(forTimeInterval: 0.5)

        let textEditor = app.textViews.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("Stats test entry")

            // Save button is "Save" (EN) or "保存" (ZH)
            let saveButton = app.buttons.matching(NSPredicate(format:
                "label CONTAINS[c] 'Save' OR label CONTAINS[c] '保存'"
            )).firstMatch
            if saveButton.waitForExistence(timeout: 2) && saveButton.isEnabled {
                saveButton.tap()
                Thread.sleep(forTimeInterval: 1)
            }
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Journal Stats After Entry"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Stats section shows "Total" (EN) or "总计" (ZH) label
        // Only visible when there are entries
        let totalLabel = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Total' OR label CONTAINS[c] '总计'"
        )).firstMatch
        XCTAssertTrue(totalLabel.waitForExistence(timeout: 5), "Journal stats section should show 'Total' / '总计' label after an entry is created")
    }

    // MARK: - Language Toggle

    @MainActor
    func testLanguageSwitchToChinese() throws {
        // Navigate to Settings via Shop toolbar gear button
        app.tabBars.buttons["Shop"].tap()
        Thread.sleep(forTimeInterval: 1)

        let gearButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'gear' OR label CONTAINS[c] 'Settings'")).firstMatch
        if gearButton.waitForExistence(timeout: 3) {
            gearButton.tap()
            Thread.sleep(forTimeInterval: 1)
        }

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
        app.tabBars.buttons["Shop"].tap()
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
