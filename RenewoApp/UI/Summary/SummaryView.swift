import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var container: AppContainer
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Subscription.renewalDate, ascending: true),
            NSSortDescriptor(keyPath: \Subscription.name, ascending: true),
        ],
        animation: .default
    )
    private var subscriptions: FetchedResults<Subscription>

    private let formatter = CurrencyFormatter()

    var body: some View {
        List {
            Section {
                TotalCardView(
                    totals: monthlyTotals,
                    formatter: formatter,
                    title: L10n.tr("total.monthly.title"),
                    accessibilityLabel: L10n.tr("accessibility.total.monthly")
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: .renewoS, leading: .renewoM, bottom: .renewoM, trailing: .renewoM))
                .listRowBackground(Color.clear)
            } header: {
                Text(L10n.tr("summary.section.monthly"))
                    .font(.renewoSectionHeader)
                    .foregroundColor(.renewoTextSecondary)
                    .textCase(nil)
            }

            Section {
                TotalCardView(
                    totals: yearlyTotals,
                    formatter: formatter,
                    title: L10n.tr("total.yearly.title"),
                    accessibilityLabel: L10n.tr("accessibility.total.yearly")
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: .renewoS, leading: .renewoM, bottom: .renewoM, trailing: .renewoM))
                .listRowBackground(Color.clear)
            } header: {
                Text(L10n.tr("summary.section.yearly"))
                    .font(.renewoSectionHeader)
                    .foregroundColor(.renewoTextSecondary)
                    .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.renewoBackground)
        .navigationTitle(L10n.tr("summary.title"))
    }

    private var monthlyTotals: [String: Decimal] {
        container.totalsCalculator.monthlyTotals(for: recurringAmounts)
    }

    private var yearlyTotals: [String: Decimal] {
        container.totalsCalculator.yearlyTotals(for: recurringAmounts)
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
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
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
        first.createdAt = Date()
        first.updatedAt = Date()

        let second = Subscription(context: context)
        second.id = UUID()
        second.name = "Spotify"
        second.amount = NSDecimalNumber(string: "4.99")
        second.currencyCode = "EUR"
        second.billingCycleRaw = BillingCycle.yearly.rawValue
        second.renewalDate = Date().addingTimeInterval(86400 * 14)
        second.reminderDays = 3
        second.createdAt = Date()
        second.updatedAt = Date()

        try? context.save()

        return NavigationStack {
            SummaryView()
                .environmentObject(container)
                .environment(\.managedObjectContext, stack.viewContext)
        }
    }
}
