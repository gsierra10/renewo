import XCTest

final class PurchaseRestoreUXUITests: XCTestCase {
    func testPurchaseSuccessUpdatesProStateImmediately() {
        let app = launchApp(arguments: [
            "UI_TEST_PURCHASE_RESULT=success",
            "UI_TEST_PURCHASE_DELAY_MS=1200"
        ])

        openUpgradeSheet(app)

        let purchaseButton = app.buttons["upgradePurchaseButton"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 2))
        purchaseButton.tap()

        XCTAssertTrue(app.staticTexts["settingsProUnlockedLabel"].waitForExistence(timeout: 4))
    }

    func testPurchaseFailureShowsErrorAndAllowsRetry() {
        let app = launchApp(arguments: [
            "UI_TEST_PURCHASE_RESULTS=failed_verification,failed_verification",
            "UI_TEST_PURCHASE_DELAY_MS=300"
        ])

        openUpgradeSheet(app)

        let purchaseButton = app.buttons["upgradePurchaseButton"]
        XCTAssertTrue(purchaseButton.waitForExistence(timeout: 2))
        purchaseButton.tap()

        let errorText = app.staticTexts["upgradeErrorMessage"]
        XCTAssertTrue(errorText.waitForExistence(timeout: 3))
        XCTAssertFalse(errorText.label.isEmpty)
        XCTAssertTrue(waitForEnabledState(element: purchaseButton, isEnabled: true, timeout: 2))

        purchaseButton.tap()
        XCTAssertTrue(errorText.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForEnabledState(element: purchaseButton, isEnabled: true, timeout: 2))
    }

    func testRestoreFailureShowsErrorAndAllowsRetry() {
        let app = launchApp(arguments: [
            "UI_TEST_RESTORE_RESULTS=pending,pending",
            "UI_TEST_RESTORE_DELAY_MS=300"
        ])

        openUpgradeSheet(app)

        let restoreButton = app.buttons["upgradeRestoreButton"]
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 2))
        restoreButton.tap()

        let errorText = app.staticTexts["upgradeErrorMessage"]
        XCTAssertTrue(errorText.waitForExistence(timeout: 3))
        XCTAssertFalse(errorText.label.isEmpty)
        XCTAssertTrue(waitForEnabledState(element: restoreButton, isEnabled: true, timeout: 2))

        restoreButton.tap()
        XCTAssertTrue(errorText.waitForExistence(timeout: 3))
        XCTAssertTrue(waitForEnabledState(element: restoreButton, isEnabled: true, timeout: 2))
    }

    private func launchApp(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "UI_TEST_MODE",
            "UI_TEST_IN_MEMORY",
            "UI_TEST_NOTIFICATIONS_DENIED",
            "UI_TEST_RESET_PRO_STATE",
            "UI_TEST_FORCE_FREE_STATE"
        ] + arguments
        app.launch()
        return app
    }

    private func openUpgradeSheet(_ app: XCUIApplication) {
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        let upgradeButton = app.buttons["settingsUpgradeButton"]
        if !upgradeButton.waitForExistence(timeout: 2) {
            let settingsView = app.collectionViews["settingsView"]
            for _ in 0..<4 where !upgradeButton.exists {
                if settingsView.exists {
                    settingsView.swipeUp()
                } else {
                    app.swipeUp()
                }
            }
        }
        XCTAssertTrue(upgradeButton.exists)
        upgradeButton.tap()
        XCTAssertTrue(app.buttons["upgradePurchaseButton"].waitForExistence(timeout: 2))
    }

    private func waitForEnabledState(element: XCUIElement, isEnabled: Bool, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == %@", NSNumber(value: isEnabled))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
