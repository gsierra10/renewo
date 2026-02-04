import UserNotifications
import XCTest
@testable import Renewo

final class NotificationSchedulerTests: XCTestCase {
    func testScheduleCalledOnceWithCorrectIdentifier() async throws {
        let scheduler = MockNotificationScheduler()
        let id = UUID()

        try await scheduler.scheduleRenewalNotification(
            subscriptionId: id,
            name: "Netflix",
            renewalDate: Date(),
            reminderDays: 3,
            now: Date()
        )

        XCTAssertEqual(scheduler.scheduleCallCount, 1)
        XCTAssertEqual(scheduler.scheduledIdentifiers, [id.uuidString])
    }

    func testCancelCalledOnDelete() async {
        let scheduler = MockNotificationScheduler()
        let id = UUID()

        await scheduler.cancelNotification(subscriptionId: id)

        XCTAssertEqual(scheduler.cancelCallCount, 1)
        XCTAssertEqual(scheduler.cancelledIdentifiers, [id.uuidString])
    }

    func testUNSchedulerUsesLocalizedBodyWithLocaleFormattedDate() async throws {
        let center = NotificationCenterMock()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let locale = Locale(identifier: "es_ES")
        let scheduler = UNNotificationScheduler(center: center, calendar: calendar, locale: locale)

        let renewalDate = makeDate(year: 2026, month: 2, day: 4, calendar: calendar)
        try await scheduler.scheduleRenewalNotification(
            subscriptionId: UUID(),
            name: "Netflix",
            renewalDate: renewalDate,
            reminderDays: 3,
            now: makeDate(year: 2026, month: 1, day: 1, calendar: calendar)
        )

        guard let request = center.lastAddedRequest else {
            XCTFail("Expected a scheduled notification request.")
            return
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let expectedBody = L10n.tr("notifications.renewal.body", formatter.string(from: renewalDate))

        XCTAssertEqual(request.content.title, "Netflix")
        XCTAssertEqual(request.content.body, expectedBody)
    }

    private func makeDate(year: Int, month: Int, day: Int, calendar: Calendar) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }
}

final class MockNotificationScheduler: NotificationScheduling {
    private(set) var scheduleCallCount = 0
    private(set) var cancelCallCount = 0
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
        scheduleCallCount += 1
        scheduledIdentifiers.append(subscriptionId.uuidString)
    }

    func cancelNotification(subscriptionId: UUID) async {
        cancelCallCount += 1
        cancelledIdentifiers.append(subscriptionId.uuidString)
    }
}

private final class NotificationCenterMock: UserNotificationCenterType {
    private(set) var lastAddedRequest: UNNotificationRequest?

    func notificationSettings() async -> UNNotificationSettings {
        fatalError("Not used in this test.")
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func add(_ request: UNNotificationRequest) async throws {
        lastAddedRequest = request
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
}
