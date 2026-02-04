import Foundation

final class SettingsStore {
    enum Keys {
        static let defaultCurrencyCode = "defaultCurrencyCode"
        static let defaultReminderDays = "defaultReminderDays"
        static let hasSeenNotificationPrompt = "hasSeenNotificationPrompt"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var defaultCurrencyCode: String {
        get { defaults.string(forKey: Keys.defaultCurrencyCode) ?? "EUR" }
        set { defaults.set(newValue, forKey: Keys.defaultCurrencyCode) }
    }

    var defaultReminderDays: Int {
        get {
            let value = defaults.object(forKey: Keys.defaultReminderDays) as? Int
            return value ?? 3
        }
        set { defaults.set(newValue, forKey: Keys.defaultReminderDays) }
    }

    var hasSeenNotificationPrompt: Bool {
        get { defaults.object(forKey: Keys.hasSeenNotificationPrompt) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Keys.hasSeenNotificationPrompt) }
    }
}
