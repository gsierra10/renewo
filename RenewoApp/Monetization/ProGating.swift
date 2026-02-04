import Foundation

struct ProGating {
    static let freeSubscriptionLimit = 3

    func canAddSubscription(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < Self.freeSubscriptionLimit
    }

    func enforcedReminderDays(input: Int, isPro: Bool) -> Int {
        isPro ? input : 3
    }

    func canUseCategories(isPro: Bool) -> Bool {
        isPro
    }

    func canUseCustomReminders(isPro: Bool) -> Bool {
        isPro
    }

    func canExportCSV(isPro: Bool) -> Bool {
        isPro
    }
}
