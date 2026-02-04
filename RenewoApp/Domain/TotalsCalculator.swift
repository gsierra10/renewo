import Foundation

struct RecurringAmount: Equatable {
    let amount: Decimal
    let cycle: BillingCycle
    let currencyCode: String
}

struct TotalsCalculator {
    private let weeksPerYear = Decimal(52)
    private let monthsPerYear = Decimal(12)

    func monthlyTotals(for amounts: [RecurringAmount]) -> [String: Decimal] {
        totals(for: amounts, transform: monthlyAmount(for:))
    }

    func yearlyTotals(for amounts: [RecurringAmount]) -> [String: Decimal] {
        totals(for: amounts, transform: yearlyAmount(for:))
    }

    private func totals(for amounts: [RecurringAmount], transform: (RecurringAmount) -> Decimal) -> [String: Decimal] {
        var grouped: [String: Decimal] = [:]
        for amount in amounts {
            let normalized = transform(amount)
            grouped[amount.currencyCode, default: 0] += normalized
        }
        return grouped
    }

    private func monthlyAmount(for amount: RecurringAmount) -> Decimal {
        switch amount.cycle {
        case .weekly:
            return amount.amount * weeksPerYear / monthsPerYear
        case .monthly:
            return amount.amount
        case .yearly:
            return amount.amount / monthsPerYear
        }
    }

    private func yearlyAmount(for amount: RecurringAmount) -> Decimal {
        switch amount.cycle {
        case .weekly:
            return amount.amount * weeksPerYear
        case .monthly:
            return amount.amount * monthsPerYear
        case .yearly:
            return amount.amount
        }
    }
}
