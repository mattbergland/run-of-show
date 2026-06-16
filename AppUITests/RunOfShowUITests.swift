import XCTest

/// End-to-end UI test that launches the app in deterministic, offline mock mode
/// (`-UITEST_MOCK 1`), drives it from the input screen to the fully-populated
/// results screen, and captures screenshots of both for CI artifacts and docs.
final class RunOfShowUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testGenerateRunOfShowAndCaptureScreenshots() {
        let app = XCUIApplication()
        app.launchArguments += ["-UITEST_MOCK", "1"]
        app.launch()

        // 1) Input screen — the single input, tagline and primary button.
        let tagline = app.staticTexts["tagline"]
        XCTAssertTrue(tagline.waitForExistence(timeout: 10), "Tagline should be visible on the input screen")

        let generate = app.buttons["generateButton"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5), "Primary button should exist")

        attachScreenshot(named: "01-input-screen")

        // 2) Generate the plan (input is prefilled with the example in mock mode).
        generate.tap()

        // 3) Results screen — every required output card must be present.
        let results = app.scrollViews["resultsScreen"]
        XCTAssertTrue(results.waitForExistence(timeout: 20), "Results screen should appear")

        let requiredCards = [
            "card_runOfShow",
            "card_venueRequirements",
            "card_budget",
            "card_inviteCopy",
            "card_staffingPlan",
            "card_vendorChecklist",
            "card_dayOfTimeline",
            "card_followUpPlan"
        ]
        for identifier in requiredCards {
            let card = app.descendants(matching: .any)[identifier]
            scrollUntilVisible(card, in: app)
            XCTAssertTrue(card.exists, "Results screen is missing required card: \(identifier)")
        }

        // Scroll back to the top so the screenshot leads with the populated plan.
        results.swipeDown()
        results.swipeDown()
        attachScreenshot(named: "02-results-screen")
    }

    // MARK: - Helpers

    private func attachScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 12) {
        var swipes = 0
        while !element.exists && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }
}
