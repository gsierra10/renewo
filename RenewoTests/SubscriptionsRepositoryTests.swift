import CoreData
import UserNotifications
import XCTest
@testable import Renewo

final class SubscriptionsRepositoryTests: XCTestCase {
    private var stack: CoreDataStack!
    private var scheduler: RepositoryNotificationSchedulerMock!
    private var settingsStore: SettingsStore!
    private var repository: SubscriptionsRepository!
    private var now: Date!
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        stack = CoreDataStack.inMemory()
        scheduler = RepositoryNotificationSchedulerMock()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        now = makeDate(year: 2024, month: 1, day: 10)

        let suiteName = "SubscriptionsRepositoryTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        settingsStore = SettingsStore(defaults: defaults)
        settingsStore.defaultReminderDays = 5

        repository = SubscriptionsRepository(
            context: stack.viewContext,
            recurrenceEngine: RecurrenceEngine(calendar: calendar),
            scheduler: scheduler,
            gating: ProGating(),
            settingsStore: settingsStore,
            calendar: calendar,
            nowProvider: { [weak self] in self?.now ?? Date() }
        )
    }

    override func tearDown() {
        stack = nil
        scheduler = nil
        settingsStore = nil
        repository = nil
        now = nil
        calendar = nil
        super.tearDown()
    }

    func testAddUpdateDelete() throws {
        let draft = SubscriptionsRepository.SubscriptionDraft(
            name: "Netflix",
            amount: Decimal(string: "9.99") ?? 9.99,
            currencyCode: "USD",
            billingCycle: .monthly,
            renewalDate: makeDate(year: 2024, month: 1, day: 1),
            reminderDays: 7,
            category: "Entertainment"
        )

        try repository.add(draft, isPro: true)
        let subscription = try fetchSingleSubscription()

        XCTAssertEqual(subscription.name, "Netflix")
        XCTAssertEqual(subscription.currencyCode, "USD")
        XCTAssertEqual(subscription.reminderDays, Int16(7))
        guard let subscriptionId = subscription.id else {
            XCTFail("Expected subscription id to exist.")
            return
        }
        XCTAssertEqual(scheduler.scheduledIdentifiers, [subscriptionId.uuidString])

        let changes = SubscriptionsRepository.SubscriptionChanges(
            name: "Netflix Plus",
            amount: Decimal(string: "12.99"),
            reminderDays: 10
        )
        try repository.update(subscription, changes: changes, isPro: true)

        XCTAssertEqual(subscription.name, "Netflix Plus")
        XCTAssertEqual(subscription.reminderDays, Int16(10))
        XCTAssertEqual(scheduler.scheduledIdentifiers.count, 2)

        try repository.delete(subscription)

        XCTAssertEqual(try fetchSubscriptions().count, 0)
        XCTAssertEqual(scheduler.cancelledIdentifiers, [subscriptionId.uuidString])
    }

    func testFreeLimitReached() throws {
        let draft = SubscriptionsRepository.SubscriptionDraft(
            name: "Service",
            amount: 10,
            currencyCode: "USD",
            billingCycle: .monthly,
            renewalDate: now,
            reminderDays: nil,
            category: nil
        )

        try repository.add(draft, isPro: false)
        try repository.add(draft, isPro: false)
        try repository.add(draft, isPro: false)

        XCTAssertThrowsError(try repository.add(draft, isPro: false)) { error in
            XCTAssertEqual(error as? RepositoryError, .freeLimitReached)
        }
    }

    func testNormalizeOverdueRenewalsUpdatesDates() async throws {
        guard let entity = NSEntityDescription.entity(forEntityName: "Subscription", in: stack.viewContext) else {
            XCTFail("Missing Subscription entity.")
            return
        }
        let subscription = Subscription(entity: entity, insertInto: stack.viewContext)
        subscription.id = UUID()
        subscription.name = "Old"
        subscription.amount = NSDecimalNumber(value: 5)
        subscription.currencyCode = "USD"
        subscription.billingCycleRaw = BillingCycle.weekly.rawValue
        subscription.renewalDate = makeDate(year: 2024, month: 1, day: 1)
        subscription.reminderDays = 3
        subscription.createdAt = now
        subscription.updatedAt = now
        try stack.viewContext.save()

        try await repository.normalizeOverdueRenewals(now: now)

        let fetched = try fetchSingleSubscription()
        XCTAssertEqual(fetched.renewalDate, makeDate(year: 2024, month: 1, day: 15))
        XCTAssertEqual(scheduler.scheduledIdentifiers.count, 1)
        guard let subscriptionId = subscription.id else {
            XCTFail("Expected subscription id to exist.")
            return
        }
        XCTAssertEqual(scheduler.scheduledIdentifiers.first, subscriptionId.uuidString)
    }

    private func fetchSubscriptions() throws -> [Subscription] {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        return try stack.viewContext.fetch(request)
    }

    private func fetchSingleSubscription() throws -> Subscription {
        let subscriptions = try fetchSubscriptions()
        guard let subscription = subscriptions.first else {
            XCTFail("Expected subscription to exist.")
            throw RepositoryError.validationFailed("Missing subscription.")
        }
        return subscription
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}

final class RepositoryNotificationSchedulerMock: NotificationScheduling {
    private(set) var scheduledIdentifiers: [String] = []
    private(set) var cancelledIdentifiers: [String] = []

    func requestAuthorizationIfNeeded() async -> Bool {
        true
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        .authorized
    }

    func scheduleRenewalNotification(
        subscriptionId: UUID,
        name: String,
        renewalDate: Date,
        reminderDays: Int,
        now: Date
    ) async throws {
        scheduledIdentifiers.append(subscriptionId.uuidString)
    }

    func cancelNotification(subscriptionId: UUID) async {
        cancelledIdentifiers.append(subscriptionId.uuidString)
    }
}
