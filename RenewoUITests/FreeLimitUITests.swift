import XCTest

final class FreeLimitUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "UI_TEST_MODE",
            "UI_TEST_IN_MEMORY",
            "UI_TEST_SEED_COUNT=3",
            "UI_TEST_FORCE_LIMIT"
        ]
        app.launch()
    }

    func testFreeLimitShowsUpgradeSheet() {
        XCTAssertTrue(isUpgradeSheetVisible(timeout: 4))
        XCTAssertFalse(app.textFields["subscriptionNameField"].exists)

        dismissUpgradeSheetIfPresent()
    }

    private func isUpgradeSheetVisible(timeout: TimeInterval) -> Bool {
        let upgradeButton = app.buttons["upgradeLimitNotNowButton"]
        let upgradeTitle = app.staticTexts["upgradeLimitTitle"]
        let upgradeSheet = app.otherElements["upgradeLimitSheet"]
        return upgradeButton.waitForExistence(timeout: timeout)
            || upgradeTitle.waitForExistence(timeout: timeout)
            || upgradeSheet.waitForExistence(timeout: timeout)
    }

    private func dismissUpgradeSheetIfPresent() {
        let upgradeButton = app.buttons["upgradeLimitNotNowButton"]
        if upgradeButton.exists {
            upgradeButton.tap()
            return
        }
    }
}
