import Foundation
import UserNotifications

protocol NotificationScheduling {
    func requestAuthorizationIfNeeded() async -> Bool
    func getAuthorizationStatus() async -> UNAuthorizationStatus
    func scheduleRenewalNotification(
        subscriptionId: UUID,
        name: String,
        renewalDate: Date,
        reminderDays: Int,
        now: Date
    ) async throws
    func cancelNotification(subscriptionId: UUID) async
}
