import Foundation

struct CurrencyFormatter {
    private let locale: Locale

    init(locale: Locale = .current) {
        self.locale = locale
    }

    func string(from amount: Decimal, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.currencyCode = currencyCode

        let number = NSDecimalNumber(decimal: amount)
        return formatter.string(from: number) ?? "\(currencyCode) \(number.stringValue)"
    }
}
