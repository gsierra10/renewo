import Foundation

struct RecurrenceEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func nextRenewal(after date: Date, cycle: BillingCycle) -> Date {
        let base = calendar.startOfDay(for: date)
        switch cycle {
        case .weekly:
            return adding(.day, value: 7, to: base)
        case .monthly:
            return adding(.month, value: 1, to: base)
        case .yearly:
            return adding(.year, value: 1, to: base)
        }
    }

    func normalizedNextRenewal(from date: Date, cycle: BillingCycle, now: Date) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        var candidate = calendar.startOfDay(for: date)

        while candidate < startOfToday {
            let next = nextRenewal(after: candidate, cycle: cycle)
            if next <= candidate {
                break
            }
            candidate = next
        }

        return candidate
    }

    private func adding(_ component: Calendar.Component, value: Int, to date: Date) -> Date {
        guard let next = calendar.date(byAdding: component, value: value, to: date) else {
            return date
        }
        return calendar.startOfDay(for: next)
    }
}
