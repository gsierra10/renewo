import CoreData
import Foundation

final class SubscriptionsRepository {
    struct SubscriptionDraft {
        let name: String
        let amount: Decimal
        let currencyCode: String
        let billingCycle: BillingCycle
        let renewalDate: Date
        let reminderDays: Int?
        let category: String?
    }

    struct SubscriptionChanges {
        let name: String?
        let amount: Decimal?
        let currencyCode: String?
        let billingCycle: BillingCycle?
        let renewalDate: Date?
        let reminderDays: Int?
        let category: String??

        init(
            name: String? = nil,
            amount: Decimal? = nil,
            currencyCode: String? = nil,
            billingCycle: BillingCycle? = nil,
            renewalDate: Date? = nil,
            reminderDays: Int? = nil,
            category: String?? = nil
        ) {
            self.name = name
            self.amount = amount
            self.currencyCode = currencyCode
            self.billingCycle = billingCycle
            self.renewalDate = renewalDate
            self.reminderDays = reminderDays
            self.category = category
        }
    }

    private let context: NSManagedObjectContext
    private let recurrenceEngine: RecurrenceEngine
    private let scheduler: NotificationScheduling
    private let gating: ProGating
    private let settingsStore: SettingsStore
    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(
        context: NSManagedObjectContext,
        recurrenceEngine: RecurrenceEngine = RecurrenceEngine(),
        scheduler: NotificationScheduling,
        gating: ProGating = ProGating(),
        settingsStore: SettingsStore = SettingsStore(),
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.context = context
        self.recurrenceEngine = recurrenceEngine
        self.scheduler = scheduler
        self.gating = gating
        self.settingsStore = settingsStore
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    convenience init(
        stack: CoreDataStack,
        recurrenceEngine: RecurrenceEngine = RecurrenceEngine(),
        scheduler: NotificationScheduling,
        gating: ProGating = ProGating(),
        settingsStore: SettingsStore = SettingsStore(),
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.init(
            context: stack.viewContext,
            recurrenceEngine: recurrenceEngine,
            scheduler: scheduler,
            gating: gating,
            settingsStore: settingsStore,
            calendar: calendar,
            nowProvider: nowProvider
        )
    }

    func add(_ draft: SubscriptionDraft, isPro: Bool) throws {
        let now = nowProvider()
        let reminderDays = try validatedReminderDays(
            enforcedReminderDays(input: draft.reminderDays, isPro: isPro)
        )

        var savedId: UUID?
        var savedName = draft.name
        var savedRenewalDate = draft.renewalDate
        var saveError: Error?

        context.performAndWait {
            do {
                let count = try subscriptionCount()
                guard gating.canAddSubscription(currentCount: count, isPro: isPro) else {
                    throw RepositoryError.freeLimitReached
                }

                let normalizedRenewalDate = recurrenceEngine.normalizedNextRenewal(
                    from: draft.renewalDate,
                    cycle: draft.billingCycle,
                    now: now
                )

                guard let entity = NSEntityDescription.entity(forEntityName: "Subscription", in: context) else {
                    throw RepositoryError.validationFailed(L10n.tr("repo.error.missingEntity"))
                }
                let subscription = Subscription(entity: entity, insertInto: context)
                let id = UUID()
                subscription.id = id
                subscription.name = draft.name
                subscription.amount = NSDecimalNumber(decimal: draft.amount)
                subscription.currencyCode = draft.currencyCode
                subscription.billingCycleRaw = draft.billingCycle.rawValue
                subscription.renewalDate = normalizedRenewalDate
                subscription.reminderDays = reminderDays
                subscription.category = draft.category
                subscription.createdAt = now
                subscription.updatedAt = now

                try context.save()

                savedId = id
                savedName = draft.name
                savedRenewalDate = normalizedRenewalDate
            } catch {
                saveError = error
            }
        }

        if let error = saveError {
            throw error
        }

        guard let id = savedId else {
            return
        }

        try awaitScheduler { [self] in
            try await self.scheduler.scheduleRenewalNotification(
                subscriptionId: id,
                name: savedName,
                renewalDate: savedRenewalDate,
                reminderDays: Int(reminderDays),
                now: now
            )
        }
    }

    func update(_ subscription: Subscription, changes: SubscriptionChanges, isPro: Bool) throws {
        let now = nowProvider()
        var schedulePayload: (UUID, String, Date, Int)?
        var saveError: Error?

        context.performAndWait {
            do {
                if let name = changes.name {
                    subscription.name = name
                }
                if let amount = changes.amount {
                    subscription.amount = NSDecimalNumber(decimal: amount)
                }
                if let currencyCode = changes.currencyCode {
                    subscription.currencyCode = currencyCode
                }
                if let categoryChange = changes.category {
                    subscription.category = categoryChange
                }

                if let billingCycle = changes.billingCycle {
                    subscription.billingCycleRaw = billingCycle.rawValue
                }

                guard let cycleRaw = subscription.billingCycleRaw,
                      let cycle = BillingCycle(rawValue: cycleRaw) else {
                    throw RepositoryError.validationFailed(L10n.tr("repo.error.invalidBillingCycle"))
                }

                guard let renewalBaseDate = changes.renewalDate ?? subscription.renewalDate else {
                    throw RepositoryError.validationFailed(L10n.tr("repo.error.missingRenewalDate"))
                }
                let normalizedRenewalDate = recurrenceEngine.normalizedNextRenewal(
                    from: renewalBaseDate,
                    cycle: cycle,
                    now: now
                )
                subscription.renewalDate = normalizedRenewalDate

                let reminderDaysInput: Int
                if isPro {
                    reminderDaysInput = changes.reminderDays ?? Int(subscription.reminderDays)
                } else {
                    reminderDaysInput = 3
                }

                let reminderDays = try validatedReminderDays(reminderDaysInput)
                subscription.reminderDays = reminderDays

                subscription.updatedAt = now

                try context.save()

                guard let id = subscription.id else {
                    throw RepositoryError.validationFailed(L10n.tr("repo.error.missingId"))
                }
                guard let name = subscription.name else {
                    throw RepositoryError.validationFailed(L10n.tr("repo.error.missingName"))
                }

                schedulePayload = (id, name, normalizedRenewalDate, Int(reminderDays))
            } catch {
                saveError = error
            }
        }

        if let error = saveError {
            throw error
        }

        if let payload = schedulePayload {
            try awaitScheduler { [self] in
                try await self.scheduler.scheduleRenewalNotification(
                    subscriptionId: payload.0,
                    name: payload.1,
                    renewalDate: payload.2,
                    reminderDays: payload.3,
                    now: now
                )
            }
        }
    }

    func delete(_ subscription: Subscription) throws {
        guard let id = subscription.id else {
            throw RepositoryError.validationFailed(L10n.tr("repo.error.missingId"))
        }
        var saveError: Error?

        awaitScheduler { [self] in
            await self.scheduler.cancelNotification(subscriptionId: id)
        }

        context.performAndWait {
            context.delete(subscription)
            do {
                try context.save()
            } catch {
                saveError = error
            }
        }

        if let error = saveError {
            throw error
        }
    }

    func normalizeOverdueRenewals(now: Date) async throws {
        let startOfToday = calendar.startOfDay(for: now)
        let context = self.context
        let recurrenceEngine = self.recurrenceEngine
        var updates: [(UUID, String, Date, Int)] = []
        var fetchError: Error?

        context.performAndWait {
            do {
                let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
                request.predicate = NSPredicate(format: "renewalDate < %@", startOfToday as NSDate)

                let subscriptions = try context.fetch(request)
                for subscription in subscriptions {
                    guard let cycleRaw = subscription.billingCycleRaw,
                          let cycle = BillingCycle(rawValue: cycleRaw) else {
                        throw RepositoryError.validationFailed(L10n.tr("repo.error.invalidBillingCycle"))
                    }
                    guard let id = subscription.id else {
                        throw RepositoryError.validationFailed(L10n.tr("repo.error.missingId"))
                    }
                    guard let name = subscription.name else {
                        throw RepositoryError.validationFailed(L10n.tr("repo.error.missingName"))
                    }

                    guard let existingRenewalDate = subscription.renewalDate else {
                        throw RepositoryError.validationFailed(L10n.tr("repo.error.missingRenewalDate"))
                    }
                    let normalized = recurrenceEngine.normalizedNextRenewal(
                        from: existingRenewalDate,
                        cycle: cycle,
                        now: now
                    )

                    if normalized != subscription.renewalDate {
                        subscription.renewalDate = normalized
                        subscription.updatedAt = now
                        updates.append((id, name, normalized, Int(subscription.reminderDays)))
                    }
                }

                if context.hasChanges {
                    try context.save()
                }
            } catch {
                fetchError = error
            }
        }

        if let error = fetchError {
            throw error
        }

        for update in updates {
            try await scheduler.scheduleRenewalNotification(
                subscriptionId: update.0,
                name: update.1,
                renewalDate: update.2,
                reminderDays: update.3,
                now: now
            )
        }
    }

    func subscriptionCount() throws -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Subscription")
        let count = try context.count(for: request)
        return count == NSNotFound ? 0 : count
    }

    private func enforcedReminderDays(input: Int?, isPro: Bool) -> Int {
        let fallback = settingsStore.defaultReminderDays
        let value = input ?? fallback
        return gating.enforcedReminderDays(input: value, isPro: isPro)
    }

    private func validatedReminderDays(_ value: Int) throws -> Int16 {
        guard value >= 0 else {
            throw RepositoryError.validationFailed(L10n.tr("repo.error.reminderNegative"))
        }
        guard value <= Int(Int16.max) else {
            throw RepositoryError.validationFailed(L10n.tr("repo.error.reminderTooLarge"))
        }
        return Int16(value)
    }

    private func awaitScheduler(_ operation: @escaping () async throws -> Void) throws {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "com.renewo.scheduler")
        var capturedError: Error?
        group.enter()
        Task.detached(priority: .userInitiated) {
            do {
                try await operation()
            } catch {
                queue.sync {
                    capturedError = error
                }
            }
            group.leave()
        }
        group.wait()
        if let error = queue.sync(execute: { capturedError }) {
            throw error
        }
    }

    private func awaitScheduler(_ operation: @escaping () async -> Void) {
        let group = DispatchGroup()
        group.enter()
        Task.detached(priority: .userInitiated) {
            await operation()
            group.leave()
        }
        group.wait()
    }
}
