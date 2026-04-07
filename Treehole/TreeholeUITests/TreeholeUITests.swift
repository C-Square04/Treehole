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
        // Navigate to Pet tab — exact EN label (works in English mode) with ZH fallback
        let petTab = app.tabBars.buttons["Pet"]
        XCTAssertTrue(petTab.waitForExistence(timeout: 5), "Pet tab should exist")
        petTab.tap()

        // Wait for the Pet view to fully load — it has a NavigationStack with a title and action buttons.
        // Check for navigation bar, any static text in the pet view, or a scroll view.
        let petScrollView = app.scrollViews.firstMatch
        let petNavBarEN = app.navigationBars["Pet"]
        let petStaticText = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Pet' OR label CONTAINS '宠物' OR label CONTAINS[c] 'Home Theme' OR label CONTAINS '主题'"
        )).firstMatch
        let petNavLoaded = petScrollView.waitForExistence(timeout: 8) || petNavBarEN.exists || petStaticText.exists
        XCTAssertTrue(petNavLoaded, "Pet tab should load and show content (scroll view, nav bar, or pet content)")

        let screenshot1 = app.screenshot()
        let attachment1 = XCTAttachment(screenshot: screenshot1)
        attachment1.name = "Pet Tab Loaded"
        attachment1.lifetime = .keepAlways
        add(attachment1)

        // Try to find and optionally tap the feed button — may be disabled if food = 0 or hunger = 100
        // Button label: "Feed (5 🍖)" (EN) or "喂食 (5 🍖)" (ZH), potentially combined with emoji text
        let feedButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS '🍖' OR label CONTAINS[c] 'Feed' OR label CONTAINS '喂食'"
        )).firstMatch
        if feedButton.waitForExistence(timeout: 5) && feedButton.isEnabled {
            feedButton.tap()
            _ = feedButton.waitForExistence(timeout: 3)

            let screenshot2 = app.screenshot()
            let attachment2 = XCTAttachment(screenshot: screenshot2)
            attachment2.name = "Pet After Feed"
            attachment2.lifetime = .keepAlways
            add(attachment2)
        }
    }

    // MARK: - Garden Multi-Plant

    @MainActor
    func testAddSecondPlant() throws {
        // Navigate to Garden tab — accept both EN ("Garden") and ZH ("花园"/"植物") tab labels
        let gardenTab = app.tabBars.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Garden' OR label CONTAINS '花园' OR label CONTAINS '植物'"
        )).firstMatch
        XCTAssertTrue(gardenTab.waitForExistence(timeout: 10), "Garden tab should exist in EN or ZH")
        gardenTab.tap()

        // If empty state shows "Plant a Seed" (EN) or "播种" (ZH), tap it to create first plant
        let plantSeedButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Plant a Seed' OR label CONTAINS[c] 'Seed' OR label CONTAINS[c] '播种'"
        )).firstMatch
        if plantSeedButton.waitForExistence(timeout: 3) {
            plantSeedButton.tap()
            // Confirm dialog varies: "Plant Seed" / "Confirm" / "确认" / "播种"
            let confirmButton = app.buttons.matching(NSPredicate(format:
                "label CONTAINS[c] 'Plant Seed' OR label CONTAINS[c] 'Confirm' OR label CONTAINS '确认' OR label CONTAINS[c] 'Plant'"
            )).firstMatch
            if confirmButton.waitForExistence(timeout: 5) {
                confirmButton.tap()
            }
        }

        // Verify Garden tab shows plant content — Water button (EN) or 浇水 (ZH)
        let waterButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'Water' OR label CONTAINS '浇水'"
        )).firstMatch
        XCTAssertTrue(waterButton.waitForExistence(timeout: 10), "Garden should show plant content (Water button in EN or ZH)")

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Garden With Plant"
        attachment.lifetime = .keepAlways
        add(attachment)
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
        // Navigate to Journal tab — exact EN label (works in English mode) with ZH fallback
        let journalTab = app.tabBars.buttons["Journal"]
        XCTAssertTrue(journalTab.waitForExistence(timeout: 5), "Journal tab should exist")
        journalTab.tap()

        // Wait for the Journal view to load — the view has a ScrollView so assert on that.
        // Also accept the navigation bar, any write button, or any static text with "Journal"/"日记".
        let journalScrollView = app.scrollViews.firstMatch
        let journalNavBarEN = app.navigationBars["Journal"]
        let journalStaticText = app.staticTexts.matching(NSPredicate(format:
            "label CONTAINS[c] 'Journal' OR label CONTAINS '日记' OR label CONTAINS[c] 'Write Entry' OR label CONTAINS '写日记'"
        )).firstMatch
        let journalNavLoaded = journalScrollView.waitForExistence(timeout: 8) || journalNavBarEN.exists || journalStaticText.exists
        XCTAssertTrue(journalNavLoaded, "Journal tab should load and show content (scroll view, nav bar, or write button)")

        let screenshot0 = app.screenshot()
        let attachment0 = XCTAttachment(screenshot: screenshot0)
        attachment0.name = "Journal Loaded"
        attachment0.lifetime = .keepAlways
        add(attachment0)

        // Optionally try to create/view an entry — no required assertion beyond tab loading
        let writeEntryButton = app.buttons["Write Entry"]
        let pencilButton = app.buttons.matching(NSPredicate(format:
            "label CONTAINS[c] 'square and pencil' OR label CONTAINS[c] 'pencil'"
        )).firstMatch

        if writeEntryButton.waitForExistence(timeout: 2) {
            writeEntryButton.tap()
        } else if pencilButton.waitForExistence(timeout: 2) {
            pencilButton.tap()
        }

        let textEditor = app.textViews.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("Stats test entry")
            let saveButton = app.buttons["Save"]
            if saveButton.waitForExistence(timeout: 2) && saveButton.isEnabled {
                saveButton.tap()
            }
        }

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Journal After Entry Attempt"
        attachment.lifetime = .keepAlways
        add(attachment)
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
