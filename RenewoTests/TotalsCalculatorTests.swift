import XCTest
@testable import Renewo

final class TotalsCalculatorTests: XCTestCase {
    func testMonthlyConversions() {
        let calculator = TotalsCalculator()
        let amounts = [
            RecurringAmount(amount: decimal("12"), cycle: .weekly, currencyCode: "USD"),
            RecurringAmount(amount: decimal("20"), cycle: .monthly, currencyCode: "USD"),
            RecurringAmount(amount: decimal("120"), cycle: .yearly, currencyCode: "USD"),
        ]

        let totals = calculator.monthlyTotals(for: amounts)
        let expectedWeekly = decimal("12") * Decimal(52) / Decimal(12)
        let expected = expectedWeekly + decimal("20") + (decimal("120") / Decimal(12))

        XCTAssertEqual(totals["USD"], expected)
    }

    func testYearlyConversions() {
        let calculator = TotalsCalculator()
        let amounts = [
            RecurringAmount(amount: decimal("10"), cycle: .weekly, currencyCode: "USD"),
            RecurringAmount(amount: decimal("10"), cycle: .monthly, currencyCode: "USD"),
            RecurringAmount(amount: decimal("10"), cycle: .yearly, currencyCode: "USD"),
        ]

        let totals = calculator.yearlyTotals(for: amounts)
        let expected = decimal("10") * Decimal(52) + decimal("10") * Decimal(12) + decimal("10")

        XCTAssertEqual(totals["USD"], expected)
    }

    func testGroupingByCurrency() {
        let calculator = TotalsCalculator()
        let amounts = [
            RecurringAmount(amount: decimal("5"), cycle: .monthly, currencyCode: "USD"),
            RecurringAmount(amount: decimal("7"), cycle: .monthly, currencyCode: "EUR"),
        ]

        let totals = calculator.monthlyTotals(for: amounts)

        XCTAssertEqual(totals["USD"], decimal("5"))
        XCTAssertEqual(totals["EUR"], decimal("7"))
    }

    func testDecimalPrecisionIsPreserved() {
        let calculator = TotalsCalculator()
        let amounts = [
            RecurringAmount(amount: decimal("0.1"), cycle: .weekly, currencyCode: "USD"),
        ]

        let totals = calculator.monthlyTotals(for: amounts)
        let expected = decimal("0.1") * Decimal(52) / Decimal(12)

        XCTAssertEqual(totals["USD"], expected)
    }

    private func decimal(_ string: String, file: StaticString = #filePath, line: UInt = #line) -> Decimal {
        guard let value = Decimal(string: string) else {
            XCTFail("Invalid decimal input: \(string)", file: file, line: line)
            return 0
        }
        return value
    }
}
