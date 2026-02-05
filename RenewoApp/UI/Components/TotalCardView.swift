import Foundation
import SwiftUI

struct TotalCardView: View {
    let totals: [String: Decimal]
    let formatter: CurrencyFormatter
    let title: String
    let accessibilityLabel: String
    let amountAccessibilityIdentifier: String?

    init(
        totals: [String: Decimal],
        formatter: CurrencyFormatter,
        title: String,
        accessibilityLabel: String,
        amountAccessibilityIdentifier: String? = nil
    ) {
        self.totals = totals
        self.formatter = formatter
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.amountAccessibilityIdentifier = amountAccessibilityIdentifier
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if totals.isEmpty {
                if let amountAccessibilityIdentifier {
                    Text(L10n.tr("common.placeholder"))
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                        .accessibilityIdentifier(amountAccessibilityIdentifier)
                } else {
                    Text(L10n.tr("common.placeholder"))
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                }
            } else if totals.count == 1, let code = totals.keys.first, let amount = totals[code] {
                if let amountAccessibilityIdentifier {
                    Text(formatter.string(from: amount, currencyCode: code))
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier(amountAccessibilityIdentifier)
                } else {
                    Text(formatter.string(from: amount, currencyCode: code))
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(sortedTotals, id: \.code) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(entry.code)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatter.string(from: entry.amount, currencyCode: entry.code))
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.primary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
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
