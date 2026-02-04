import XCTest

final class SmokeUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TEST_MODE", "UI_TEST_IN_MEMORY", "UI_TEST_NOTIFICATIONS_DENIED"] + arguments
        app.launch()
        return app
    }

    func testLaunchHasMainButtons() {
        let app = launchApp()
        XCTAssertTrue(app.buttons["addSubscriptionButton"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["settingsButton"].exists)
        XCTAssertTrue(app.buttons["summaryButton"].exists)
    }

    func testSpanishMainLocalization() {
        let app = launchApp(arguments: ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"])
        XCTAssertTrue(app.staticTexts["Suscripciones"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["main.title"].exists)
    }

    func testSpanishSummaryLocalization() {
        let app = launchApp(arguments: ["UI_TEST_ROOT=summary", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"])
        XCTAssertTrue(app.staticTexts["Resumen"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["summary.title"].exists)
    }

    func testSpanishAddLocalization() {
        let app = launchApp(arguments: ["UI_TEST_ROOT=add", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"])
        XCTAssertTrue(app.staticTexts["Añadir suscripción"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["add.title.add"].exists)
    }

    func testSpanishSettingsLocalization() {
        let app = launchApp(arguments: ["UI_TEST_ROOT=settings", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"])
        let labeledElement = app.descendants(matching: .any).matching(identifier: "settingsTitleLabel").firstMatch
        if labeledElement.waitForExistence(timeout: 2) {
            XCTAssertEqual(labeledElement.label, "Configuración")
        } else {
            XCTAssertTrue(app.staticTexts["Configuración"].waitForExistence(timeout: 2))
        }
        XCTAssertFalse(app.staticTexts["settings.title"].exists)
    }
}
