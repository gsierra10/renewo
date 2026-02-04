import Foundation

struct CSVExporter {
    struct Row {
        let name: String
        let amount: Decimal
        let currencyCode: String
        let billingCycle: String
        let renewalDate: Date
        let reminderDays: Int
        let category: String?
    }

    func makeCSV(rows: [Row]) -> String {
        var lines = [Self.header]
        lines.reserveCapacity(rows.count + 1)

        for row in rows {
            let values = [
                escape(row.name),
                escape(Self.decimalString(row.amount)),
                escape(row.currencyCode),
                escape(row.billingCycle),
                escape(Self.isoDateString(row.renewalDate)),
                escape(String(row.reminderDays)),
                escape(row.category ?? "")
            ]
            lines.append(values.joined(separator: ","))
        }

        return lines.joined(separator: "\n")
    }

    func writeCSV(rows: [Row], filename: String = "renewo_subscriptions.csv") throws -> URL {
        let csv = makeCSV(rows: rows)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") else {
            return value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private static func isoDateString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: date)
    }

    private static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    private static let header = "name,amount,currencyCode,billingCycle,renewalDate,reminderDays,category"
}
