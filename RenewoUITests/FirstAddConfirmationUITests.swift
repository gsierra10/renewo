import XCTest

final class FirstAddConfirmationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        let suiteName = "UITestDefaults.\(UUID().uuidString)"
        app.launchArguments = [
            "UI_TEST_MODE",
            "UI_TEST_IN_MEMORY",
            "UI_TEST_AUTO_OPEN_ADD",
            "UI_TEST_DEFAULTS=\(suiteName)",
        ]
        app.launch()
    }

    func testFirstAddShowsConfirmationOnlyOnce() {
        let firstName = "Starter \(UUID().uuidString.prefix(6))"
        addSubscription(named: firstName, amount: "9.99")

        let firstAlert = app.alerts["You're set"]
        XCTAssertTrue(firstAlert.waitForExistence(timeout: 2))
        firstAlert.buttons["OK"].tap()

        let addButton = app.buttons["addSubscriptionButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3))
        addButton.tap()

        let secondName = "Second \(UUID().uuidString.prefix(6))"
        addSubscription(named: secondName, amount: "12.49")

        XCTAssertFalse(app.alerts["You're set"].waitForExistence(timeout: 1))
    }

    private func addSubscription(named name: String, amount: String) {
        let nameField = app.textFields["subscriptionNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 4))
        nameField.tap()
        nameField.typeText(name)

        let amountField = app.textFields["subscriptionAmountField"]
        amountField.tap()
        amountField.typeText(amount)

        app.buttons["subscriptionSaveButton"].tap()
    }
}
