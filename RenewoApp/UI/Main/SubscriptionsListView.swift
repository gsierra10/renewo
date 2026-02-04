import CoreData
import SwiftUI

struct SubscriptionsListView: View {
    @EnvironmentObject private var container: AppContainer
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Subscription.renewalDate, ascending: true),
            NSSortDescriptor(keyPath: \Subscription.name, ascending: true),
        ],
        animation: .default
    )
    private var subscriptions: FetchedResults<Subscription>
    @State private var isPresentingAdd = false
    @State private var selectedSubscription: SelectedSubscription?
    @State private var deleteErrorMessage: String?
    @State private var isPresentingSummary = false
    @State private var isPresentingSettings = false
    @State private var isPresentingUpgrade = false

    private let currencyFormatter = CurrencyFormatter()

    init() {
        if LaunchArguments.has("UI_TEST_AUTO_OPEN_ADD") {
            _isPresentingAdd = State(initialValue: true)
        }
        if LaunchArguments.has("UI_TEST_FORCE_LIMIT") {
            _isPresentingUpgrade = State(initialValue: true)
        }
    }

    var body: some View {
        List {
            TotalCardView(
                totals: monthlyTotals,
                formatter: currencyFormatter,
                title: L10n.tr("total.monthly.title"),
                accessibilityLabel: L10n.tr("accessibility.total.monthly")
            )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)

            if subscriptions.isEmpty {
                EmptyStateView {
                    isPresentingAdd = true
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
                .listRowBackground(Color.clear)
            } else {
                ForEach(subscriptions, id: \.objectID) { subscription in
                    SubscriptionRowView(
                        subscription: subscription,
                        formatter: currencyFormatter
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSubscription = SelectedSubscription(subscription: subscription)
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .listStyle(.plain)
        .navigationTitle(L10n.tr("main.title"))
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    isPresentingSummary = true
                } label: {
                    Image(systemName: "chart.bar")
                }
                .accessibilityLabel(L10n.tr("main.summary"))
                .accessibilityIdentifier("summaryButton")

                Button {
                    isPresentingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel(L10n.tr("main.settings"))
                .accessibilityIdentifier("settingsButton")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if LaunchArguments.has("UI_TEST_FORCE_LIMIT") {
                        isPresentingUpgrade = true
                        return
                    }
                    if container.proGating.canAddSubscription(
                        currentCount: currentSubscriptionCount(),
                        isPro: container.entitlementsStore.isPro
                    ) {
                        isPresentingAdd = true
                    } else {
                        isPresentingUpgrade = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(L10n.tr("main.add"))
                .accessibilityIdentifier("addSubscriptionButton")
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            AddEditSubscriptionView(
                entitlementsStore: container.entitlementsStore,
                repository: container.subscriptionsRepository,
                notificationScheduler: container.notificationScheduler,
                settingsStore: container.settingsStore,
                proGating: container.proGating
            )
        }
        .sheet(item: $selectedSubscription) { selection in
            AddEditSubscriptionView(
                entitlementsStore: container.entitlementsStore,
                repository: container.subscriptionsRepository,
                notificationScheduler: container.notificationScheduler,
                settingsStore: container.settingsStore,
                proGating: container.proGating,
                subscription: selection.subscription
            )
        }
        .sheet(isPresented: $isPresentingSummary) {
            NavigationStack {
                SummaryView()
                    .environmentObject(container)
                    .environment(\.managedObjectContext, container.coreDataStack.viewContext)
            }
        }
        .sheet(isPresented: $isPresentingSettings) {
            NavigationStack {
                SettingsView(
                    entitlementsStore: container.entitlementsStore,
                    settingsStore: container.settingsStore,
                    notificationScheduler: container.notificationScheduler
                )
            }
        }
        .sheet(isPresented: $isPresentingUpgrade) {
            UpgradeSheetView()
        }
        .alert(L10n.tr("main.delete.error.title"), isPresented: Binding(get: { deleteErrorMessage != nil }, set: { isPresented in
            if !isPresented { deleteErrorMessage = nil }
        })) {
            Button(L10n.tr("common.ok"), role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    private var monthlyTotals: [String: Decimal] {
        container.totalsCalculator.monthlyTotals(for: recurringAmounts)
    }

    private var recurringAmounts: [RecurringAmount] {
        subscriptions.compactMap { subscription in
            guard let amount = subscription.amount,
                  let currencyCode = subscription.currencyCode,
                  let cycleRaw = subscription.billingCycleRaw,
                  let cycle = BillingCycle(rawValue: cycleRaw) else {
                return nil
            }
            return RecurringAmount(
                amount: amount.decimalValue,
                cycle: cycle,
                currencyCode: currencyCode
            )
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let subscription = subscriptions[index]
            do {
                try container.subscriptionsRepository.delete(subscription)
            } catch {
                deleteErrorMessage = L10n.tr("main.delete.error.message")
            }
        }
    }

    private func currentSubscriptionCount() -> Int {
        let request: NSFetchRequest<Subscription> = Subscription.fetchRequest()
        do {
            return try container.coreDataStack.viewContext.count(for: request)
        } catch {
            return subscriptions.count
        }
    }
}

private struct SelectedSubscription: Identifiable {
    let subscription: Subscription

    var id: NSManagedObjectID {
        subscription.objectID
    }
}

struct SubscriptionsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SubscriptionsListView()
                .environmentObject(populatedContainer)
                .environment(\.managedObjectContext, populatedContainer.coreDataStack.viewContext)
                .previewDisplayName("With Data")

            SubscriptionsListView()
                .environmentObject(emptyContainer)
                .environment(\.managedObjectContext, emptyContainer.coreDataStack.viewContext)
                .previewDisplayName("Empty")
        }
    }

    private static let populatedContainer: AppContainer = {
        let stack = CoreDataStack.inMemory()
        let container = AppContainer(coreDataStack: stack)
        let context = stack.viewContext

        let first = Subscription(context: context)
        first.id = UUID()
        first.name = "Netflix"
        first.amount = NSDecimalNumber(string: "9.99")
        first.currencyCode = "USD"
        first.billingCycleRaw = BillingCycle.monthly.rawValue
        first.renewalDate = Date().addingTimeInterval(86400 * 7)
        first.reminderDays = 3
        first.category = "Entertainment"
        first.createdAt = Date()
        first.updatedAt = Date()

        let second = Subscription(context: context)
        second.id = UUID()
        second.name = "Spotify"
        second.amount = NSDecimalNumber(string: "4.99")
        second.currencyCode = "EUR"
        second.billingCycleRaw = BillingCycle.monthly.rawValue
        second.renewalDate = Date().addingTimeInterval(86400 * 14)
        second.reminderDays = 3
        second.category = "Music"
        second.createdAt = Date()
        second.updatedAt = Date()

        try? context.save()
        return container
    }()

    private static let emptyContainer: AppContainer = {
        let stack = CoreDataStack.inMemory()
        return AppContainer(coreDataStack: stack)
    }()
}
