import Foundation
import SwiftUI

struct SubscriptionRowView: View {
    @ObservedObject var subscription: Subscription
    let formatter: CurrencyFormatter

    var body: some View {
        HStack(alignment: .top, spacing: .renewoM) {
            VStack(alignment: .leading, spacing: .renewoXS) {
                Text(subscription.name ?? L10n.tr("common.untitled"))
                    .font(.renewoBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.renewoTextPrimary)

                Text(renewalText)
                    .font(.renewoCaption)
                    .foregroundColor(.renewoTextSecondary)
            }

            Spacer(minLength: .renewoS)

            Text(amountText)
                .font(.renewoSectionHeader)
                .foregroundColor(.renewoTextPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, .renewoS)
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

    private var renewalText: String {
        guard let renewalDate = subscription.renewalDate else {
            return L10n.tr("list.renewsOn.unknown")
        }
        return L10n.tr("list.renewsOn.format", Self.dateFormatter.string(from: renewalDate))
    }
}
