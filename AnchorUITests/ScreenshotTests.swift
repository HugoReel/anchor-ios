import XCTest

/// Walks every top-level screen and captures a screenshot of each, attached to
/// the test result (kept always) so CI can export them as PNGs. Demo data is
/// seeded in DEBUG builds, so the screens are populated. This test makes no
/// assertions — it is a visual capture, not a pass/fail gate.
final class ScreenshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    @MainActor
    func testCaptureAllScreens() {
        let app = XCUIApplication()
        app.launch()

        // First run: capture onboarding, then skip past it.
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 15) {
            snap(app, "01-onboarding")
            skip.tap()
        }

        _ = app.tabBars.buttons["Today"].waitForExistence(timeout: 15)
        snap(app, "02-today")

        tapTab(app, "Day")
        snap(app, "03-day")
        tapTab(app, "Goals")
        snap(app, "04-goals")
        tapTab(app, "Reflect")
        snap(app, "05-reflect")

        // Settings is pushed from the gear on any tab.
        tapTab(app, "Today")
        let gear = app.buttons["Settings"].firstMatch
        if gear.waitForExistence(timeout: 5) {
            gear.tap()
            snap(app, "06-settings")
            let back = app.navigationBars.buttons.element(boundBy: 0)
            if back.exists { back.tap() }
        }

        // The coping bank is a sheet; capture it last so nothing needs dismissing.
        let coping = app.buttons["Coping bank"].firstMatch
        if coping.waitForExistence(timeout: 5) {
            coping.tap()
            snap(app, "07-coping")
        }
    }

    @MainActor
    private func tapTab(_ app: XCUIApplication, _ title: String) {
        let tab = app.tabBars.buttons[title]
        if tab.waitForExistence(timeout: 5) {
            tab.tap()
        }
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
