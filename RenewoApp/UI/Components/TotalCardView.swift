import Foundation
import SwiftUI

struct TotalCardView: View {
    let totals: [String: Decimal]
    let formatter: CurrencyFormatter
    let title: String
    let accessibilityLabel: String

    var body: some View {
        RenewoCard {
            VStack(alignment: .leading, spacing: .renewoS) {
                Text(title)
                    .font(.renewoSectionHeader)
                    .foregroundColor(.renewoTextSecondary)

                if totals.isEmpty {
                    Text(L10n.tr("common.placeholder"))
                        .font(.renewoAmountLarge)
                        .foregroundColor(.renewoTextPrimary)
                } else if totals.count == 1, let code = totals.keys.first, let amount = totals[code] {
                    Text(formatter.string(from: amount, currencyCode: code))
                        .font(.renewoAmountLarge)
                        .foregroundColor(.renewoTextPrimary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(alignment: .leading, spacing: .renewoXS) {
                        ForEach(sortedTotals, id: \.code) { entry in
                            HStack(alignment: .firstTextBaseline, spacing: .renewoS) {
                                Text(entry.code)
                                    .font(.renewoCaption)
                                    .foregroundColor(.renewoTextSecondary)
                                Text(formatter.string(from: entry.amount, currencyCode: entry.code))
                                    .font(.renewoBody.weight(.semibold))
                                    .foregroundColor(.renewoTextPrimary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }

    private var sortedTotals: [(code: String, amount: Decimal)] {
        totals
            .map { (code: $0.key, amount: $0.value) }
            .sorted { $0.code < $1.code }
    }

    private var accessibilityValue: String {
        guard !totals.isEmpty else {
            return L10n.tr("total.noSubscriptions")
        }

        if totals.count == 1, let code = totals.keys.first, let amount = totals[code] {
            return formatter.string(from: amount, currencyCode: code)
        }

        return sortedTotals
            .map { "\(formatter.string(from: $0.amount, currencyCode: $0.code))" }
            .joined(separator: ", ")
    }
}
