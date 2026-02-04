import Foundation

struct SubscriptionDraft {
    var name: String
    var amountText: String
    var currencyCode: String
    var billingCycle: BillingCycle
    var renewalDate: Date
    var reminderDays: Int
    var category: String

    init(
        name: String = "",
        amountText: String = "",
        currencyCode: String,
        billingCycle: BillingCycle = .monthly,
        renewalDate: Date = Date(),
        reminderDays: Int,
        category: String = ""
    ) {
        self.name = name
        self.amountText = amountText
        self.currencyCode = currencyCode
        self.billingCycle = billingCycle
        self.renewalDate = renewalDate
        self.reminderDays = reminderDays
        self.category = category
    }
}
