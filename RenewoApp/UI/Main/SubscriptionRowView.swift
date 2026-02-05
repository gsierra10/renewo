import Foundation
import SwiftUI

struct SubscriptionRowView: View {
    @ObservedObject var subscription: Subscription
    let formatter: CurrencyFormatter

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name ?? L10n.tr("common.untitled"))
                    .font(.headline)
                    .foregroundColor(.primary)

                if let renewalDate = subscription.renewalDate {
                    Text(Self.dateFormatter.string(from: renewalDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text(L10n.tr("common.placeholder"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 12)

            Text(amountText)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("subscriptionRow")
    }

    private var amountText: String {
        guard let amount = subscription.amount,
              let currencyCode = subscription.currencyCode else {
            return L10n.tr("common.placeholder")
        }
        return formatter.string(from: amount.decimalValue, currencyCode: currencyCode)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private var accessibilityLabel: String {
        let name = subscription.name ?? L10n.tr("common.untitled")
        let renewalText = subscription.renewalDate.map { Self.dateFormatter.string(from: $0) }
            ?? L10n.tr("accessibility.row.unknownDate")
        return L10n.tr("accessibility.row.format", name, renewalText, amountText)
    }
}
