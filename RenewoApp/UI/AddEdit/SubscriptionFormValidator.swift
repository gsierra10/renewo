import Foundation

struct SubscriptionFormValidator {
    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    func validate(_ draft: SubscriptionDraft) -> String? {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return L10n.tr("validation.nameRequired")
        }

        guard let amount = parsedAmount(from: draft), amount > 0 else {
            return L10n.tr("validation.amountPositive")
        }

        let trimmedCurrency = draft.currencyCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedCurrency.isEmpty {
            return L10n.tr("validation.currencyRequired")
        }

        return nil
    }

    func parsedAmount(from draft: SubscriptionDraft) -> Decimal? {
        parseAmount(draft.amountText)
    }

    private func parseAmount(_ rawText: String) -> Decimal? {
        let text = rawText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{00A0}", with: "")

        guard !text.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true

        if let number = formatter.number(from: text)?.decimalValue {
            return number
        }

        let decimalSeparator = formatter.decimalSeparator ?? "."
        let groupingSeparator = formatter.groupingSeparator ?? ","
        guard let normalized = normalizedNumberText(
            text,
            decimalSeparator: decimalSeparator,
            groupingSeparator: groupingSeparator
        ) else {
            return nil
        }

        return formatter.number(from: normalized)?.decimalValue
    }

    private func normalizedNumberText(
        _ text: String,
        decimalSeparator: String,
        groupingSeparator: String
    ) -> String? {
        let hasComma = text.contains(",")
        let hasDot = text.contains(".")
        guard hasComma || hasDot else { return nil }

        var normalized = text
        if hasComma && hasDot {
            guard let lastComma = text.lastIndex(of: ","),
                  let lastDot = text.lastIndex(of: ".") else {
                return nil
            }

            let decimalSymbol = lastComma > lastDot ? "," : "."
            let groupingSymbol = decimalSymbol == "," ? "." : ","
            normalized = normalized.replacingOccurrences(of: groupingSymbol, with: "")
            normalized = normalized.replacingOccurrences(of: decimalSymbol, with: decimalSeparator)
            return normalized
        }

        if hasComma && decimalSeparator != "," {
            normalized = normalized.replacingOccurrences(of: ",", with: decimalSeparator)
        } else if hasDot && decimalSeparator != "." {
            normalized = normalized.replacingOccurrences(of: ".", with: decimalSeparator)
        }

        if !groupingSeparator.isEmpty && groupingSeparator != decimalSeparator {
            normalized = normalized.replacingOccurrences(of: groupingSeparator, with: "")
        }

        return normalized
    }
}
