import Combine
import CoreData
import Foundation

@MainActor
final class AppContainer: ObservableObject {
    let coreDataStack: CoreDataStack
    let settingsStore: SettingsStore
    let recurrenceEngine: RecurrenceEngine
    let totalsCalculator: TotalsCalculator
    let notificationScheduler: NotificationScheduling
    let entitlementsStore: EntitlementsStore
    let proGating: ProGating
    let subscriptionsRepository: SubscriptionsRepository

    init(coreDataStack: CoreDataStack = AppContainer.makeCoreDataStack()) {
        self.coreDataStack = coreDataStack
        self.settingsStore = SettingsStore()
        self.recurrenceEngine = RecurrenceEngine()
        self.totalsCalculator = TotalsCalculator()
        self.notificationScheduler = UNNotificationScheduler()
        self.entitlementsStore = EntitlementsStore()
        self.proGating = ProGating()
        self.subscriptionsRepository = SubscriptionsRepository(
            context: coreDataStack.viewContext,
            recurrenceEngine: recurrenceEngine,
            scheduler: notificationScheduler,
            gating: proGating,
            settingsStore: settingsStore
        )
        seedSubscriptionsIfNeeded()
    }

    nonisolated private static func makeCoreDataStack() -> CoreDataStack {
        if LaunchArguments.has("UI_TEST_IN_MEMORY") {
            return CoreDataStack(storeType: .inMemory)
        }
        return CoreDataStack()
    }

    private func seedSubscriptionsIfNeeded() {
        guard let count = Self.seedCount() else { return }

        let context = coreDataStack.viewContext
        context.performAndWait {
            let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
            let existingCount = (try? context.count(for: request)) ?? 0
            if existingCount > 0 {
                return
            }
            for index in 1...count {
                guard let entity = NSEntityDescription.entity(forEntityName: "Subscription", in: context) else {
                    continue
                }
                let subscription = Subscription(entity: entity, insertInto: context)
                subscription.id = UUID()
                subscription.name = "Seeded \(index)"
                subscription.amount = NSDecimalNumber(string: "9.99")
                subscription.currencyCode = "USD"
                subscription.billingCycleRaw = BillingCycle.monthly.rawValue
                subscription.renewalDate = Calendar.current.date(byAdding: .day, value: index * 7, to: Date()) ?? Date()
                subscription.reminderDays = 3
                subscription.category = nil
                subscription.createdAt = Date()
                subscription.updatedAt = Date()
            }

            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    assertionFailure("Failed to seed subscriptions: \(error)")
                }
            }
        }
    }

    private static func seedCount() -> Int? {
        LaunchArguments.intValue(prefix: "UI_TEST_SEED_COUNT=")
    }

    func refreshEntitlementsAndNormalize(now: Date = Date()) async {
        await entitlementsStore.refreshEntitlements()
        do {
            try await subscriptionsRepository.normalizeOverdueRenewals(now: now)
            #if DEBUG
            print("Normalized overdue renewals.")
            #endif
        } catch {
            #if DEBUG
            print("Failed to normalize overdue renewals: \(error)")
            #endif
        }
    }
}

enum LaunchArguments {
    private static var all: [String] {
        ProcessInfo.processInfo.arguments
    }

    static var isUITestMode: Bool {
        all.contains("UI_TEST_MODE")
    }

    static func has(_ flag: String) -> Bool {
        guard isUITestMode else { return false }
        return all.contains(flag)
    }

    static func value(prefix: String) -> String? {
        guard isUITestMode else { return nil }
        return all.first(where: { $0.hasPrefix(prefix) })?.replacingOccurrences(of: prefix, with: "")
    }

    static func intValue(prefix: String) -> Int? {
        guard let value = value(prefix: prefix) else { return nil }
        return Int(value)
    }
}
