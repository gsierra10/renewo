import XCTest
@testable import Renewo

final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: SettingsStore!
    private var suiteName: String?

    override func setUp() {
        super.setUp()
        suiteName = "SettingsStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName ?? UUID().uuidString)
        store = SettingsStore(defaults: defaults)
    }

    override func tearDown() {
        if let suiteName {
            defaults.removePersistentDomain(forName: suiteName)
        }
        store = nil
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsWhenUnset() {
        XCTAssertEqual(store.defaultCurrencyCode, "EUR")
        XCTAssertEqual(store.defaultReminderDays, 3)
        XCTAssertEqual(store.hasSeenNotificationPrompt, false)
        XCTAssertEqual(store.hasShownFirstAddConfirmation, false)
    }

    func testValuesPersist() {
        store.defaultCurrencyCode = "USD"
        store.defaultReminderDays = 7
        store.hasSeenNotificationPrompt = true
        store.hasShownFirstAddConfirmation = true

        let reloaded = SettingsStore(defaults: defaults)

        XCTAssertEqual(reloaded.defaultCurrencyCode, "USD")
        XCTAssertEqual(reloaded.defaultReminderDays, 7)
        XCTAssertEqual(reloaded.hasSeenNotificationPrompt, true)
        XCTAssertEqual(reloaded.hasShownFirstAddConfirmation, true)
    }
}

final class SubscriptionFormValidatorTests: XCTestCase {
    func testParsedAmountSupportsCommaInSpanishLocale() {
        let validator = SubscriptionFormValidator(locale: Locale(identifier: "es_ES"))
        let draft = SubscriptionDraft(amountText: "12,99", currencyCode: "EUR", reminderDays: 3)

        let amount = validator.parsedAmount(from: draft)

        XCTAssertEqual(amount, Decimal(string: "12.99"))
    }

    func testParsedAmountSupportsDotInSpanishLocale() {
        let validator = SubscriptionFormValidator(locale: Locale(identifier: "es_ES"))
        let draft = SubscriptionDraft(amountText: "12.99", currencyCode: "EUR", reminderDays: 3)

        let amount = validator.parsedAmount(from: draft)

        XCTAssertEqual(amount, Decimal(string: "12.99"))
    }

    func testValidateFailsForInvalidAmount() {
        let validator = SubscriptionFormValidator(locale: Locale(identifier: "es_ES"))
        let draft = SubscriptionDraft(
            name: "Service",
            amountText: "not-a-number",
            currencyCode: "EUR",
            reminderDays: 3
        )

        XCTAssertEqual(validator.validate(draft), L10n.tr("validation.amountPositive"))
    }
}
