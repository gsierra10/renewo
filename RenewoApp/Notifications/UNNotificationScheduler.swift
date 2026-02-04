import Foundation
import UserNotifications

protocol UserNotificationCenterType {
    func notificationSettings() async -> UNNotificationSettings
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenterType {}

final class UNNotificationScheduler: NotificationScheduling {
    private let center: UserNotificationCenterType
    private let calendar: Calendar
    private let locale: Locale

    init(
        center: UserNotificationCenterType = UNUserNotificationCenter.current(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.center = center
        self.calendar = calendar
        self.locale = locale
    }

    func requestAuthorizationIfNeeded() async -> Bool {
        let status = await getAuthorizationStatus()
        switch status {
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                return false
            }
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleRenewalNotification(
        subscriptionId: UUID,
        name: String,
        renewalDate: Date,
        reminderDays: Int,
        now: Date
    ) async throws {
        let identifier = subscriptionId.uuidString
        let fireDate = computeFireDate(
            renewalDate: renewalDate,
            reminderDays: reminderDays,
            now: now
        )

        let content = UNMutableNotificationContent()
        content.title = name
        content.body = makeLocalizedBody(for: renewalDate)
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelNotification(subscriptionId: UUID) async {
        center.removePendingNotificationRequests(withIdentifiers: [subscriptionId.uuidString])
    }

    private func computeFireDate(renewalDate: Date, reminderDays: Int, now: Date) -> Date {
        var candidateRenewalDate = calendar.startOfDay(for: renewalDate)
        var scheduledDate = fireDate(from: candidateRenewalDate, reminderDays: reminderDays)

        while scheduledDate < now {
            guard let nextRenewalDate = calendar.date(byAdding: .day, value: 1, to: candidateRenewalDate) else {
                break
            }
            candidateRenewalDate = nextRenewalDate
            scheduledDate = fireDate(from: candidateRenewalDate, reminderDays: reminderDays)
        }

        return scheduledDate
    }

    private func fireDate(from renewalDate: Date, reminderDays: Int) -> Date {
        let reminderDate = calendar.date(byAdding: .day, value: -reminderDays, to: renewalDate) ?? renewalDate
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: reminderDate) ?? reminderDate
    }

    private func makeLocalizedBody(for renewalDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return L10n.tr("notifications.renewal.body", formatter.string(from: renewalDate))
    }
}
