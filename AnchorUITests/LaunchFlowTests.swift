import XCTest

/// Launch smoke: the app comes up, the four fixed tabs are present, and the
/// coping bank is reachable in one tap from a tab. First run shows onboarding,
/// which this test skips past.
final class LaunchFlowTests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsTabsAndCopingIsReachable() {
        let app = XCUIApplication()
        app.launch()

        // First run shows onboarding; skip past it if it appears.
        let skip = app.buttons["Skip"]
        if skip.waitForExistence(timeout: 15) {
            skip.tap()
        }

        // The four fixed tabs are present.
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.tabBars.buttons["Day"].exists)
        XCTAssertTrue(app.tabBars.buttons["Goals"].exists)
        XCTAssertTrue(app.tabBars.buttons["Reflect"].exists)

        // The coping bank is one tap away from every tab.
        let coping = app.buttons["Coping bank"].firstMatch
        XCTAssertTrue(coping.waitForExistence(timeout: 5))
        coping.tap()

        XCTAssertEqual(app.state, .runningForeground)
    }
}
