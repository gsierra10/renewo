import XCTest

final class RenewoBasicFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TEST_MODE", "UI_TEST_IN_MEMORY", "UI_TEST_AUTO_OPEN_ADD"]
        app.launch()
    }

    func testAddEditDeleteSubscription() {
        let name = "Netflix \(UUID().uuidString.prefix(6))"
        let updatedName = "\(name) Plus"

        let nameField = app.textFields["subscriptionNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 4))
        nameField.tap()
        nameField.typeText(name)

        let amountField = app.textFields["subscriptionAmountField"]
        amountField.tap()
        amountField.typeText("9.99")

        app.buttons["subscriptionSaveButton"].tap()
        handleSystemAlertIfPresent()

        let createdCell = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", name))
            .firstMatch
        XCTAssertTrue(createdCell.waitForExistence(timeout: 3))
        createdCell.tap()

        let editNameField = app.textFields["subscriptionNameField"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 2))
        replaceText(in: editNameField, with: updatedName)

        app.buttons["subscriptionSaveButton"].tap()

        let updatedCell = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", updatedName))
            .firstMatch
        XCTAssertTrue(updatedCell.waitForExistence(timeout: 3))

        updatedCell.swipeLeft()
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()

        XCTAssertFalse(updatedCell.waitForExistence(timeout: 2))
    }

    func testSettingsPreferencesAndProSection() {
        app.terminate()
        app.launchArguments = ["UI_TEST_MODE", "UI_TEST_IN_MEMORY", "UI_TEST_NOTIFICATIONS_DENIED"]
        app.launch()

        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3))
        settingsButton.tap()

        let reminderStepper = app.steppers["settingsReminderStepper"]
        if reminderStepper.exists {
            reminderStepper.buttons.element(boundBy: 0).tap()
        } else {
            XCTAssertTrue(app.staticTexts["settingsReminderFreeLabel"].exists)
        }

        let notificationLabel = app.staticTexts["notificationStatusLabel"]
        XCTAssertTrue(notificationLabel.exists)
        if app.buttons["notificationOpenSettingsButton"].exists {
            XCTAssertTrue(app.buttons["notificationOpenSettingsButton"].isHittable)
        }

        let upgradeButton = app.buttons["settingsUpgradeButton"]
        if upgradeButton.exists {
            upgradeButton.tap()
            XCTAssertTrue(app.buttons["upgradePurchaseButton"].waitForExistence(timeout: 2))
            XCTAssertTrue(app.buttons["upgradeRestoreButton"].exists)
            app.buttons["upgradeCloseButton"].tap()
        } else {
            XCTAssertTrue(app.staticTexts["settingsProUnlockedLabel"].exists)
        }

        XCTAssertTrue(app.buttons["settingsRestoreButton"].exists)
    }

    private func handleSystemAlertIfPresent() {
        let alert = app.alerts.firstMatch
        guard alert.waitForExistence(timeout: 1) else { return }

        if alert.buttons["Allow"].exists {
            alert.buttons["Allow"].tap()
        } else if alert.buttons["OK"].exists {
            alert.buttons["OK"].tap()
        } else {
            alert.buttons.element(boundBy: 0).tap()
        }
    }

    private func replaceText(in element: XCUIElement, with value: String) {
        element.tap()
        let existingValue = element.value as? String ?? ""
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existingValue.count)
        element.typeText(deleteString + value)
    }
}
