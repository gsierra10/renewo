import XCTest
@testable import Renewo

final class RecurrenceEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }

    func testNextRenewalWeekly() {
        let engine = RecurrenceEngine(calendar: calendar)
        let start = makeDate(year: 2024, month: 1, day: 1)
        let expected = makeDate(year: 2024, month: 1, day: 8)

        XCTAssertEqual(engine.nextRenewal(after: start, cycle: .weekly), expected)
    }

    func testNextRenewalMonthly() {
        let engine = RecurrenceEngine(calendar: calendar)
        let start = makeDate(year: 2024, month: 1, day: 15)
        let expected = makeDate(year: 2024, month: 2, day: 15)

        XCTAssertEqual(engine.nextRenewal(after: start, cycle: .monthly), expected)
    }

    func testNextRenewalYearly() {
        let engine = RecurrenceEngine(calendar: calendar)
        let start = makeDate(year: 2024, month: 1, day: 15)
        let expected = makeDate(year: 2025, month: 1, day: 15)

        XCTAssertEqual(engine.nextRenewal(after: start, cycle: .yearly), expected)
    }

    func testMonthlyJan31RollsToLastDayOfFebruary() {
        let engine = RecurrenceEngine(calendar: calendar)
        let start = makeDate(year: 2024, month: 1, day: 31)
        let expected = makeDate(year: 2024, month: 2, day: 29)

        XCTAssertEqual(engine.nextRenewal(after: start, cycle: .monthly), expected)
    }

    func testNormalizedOverdueFarPast() {
        let engine = RecurrenceEngine(calendar: calendar)
        let start = makeDate(year: 2010, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 12, minute: 0)
        let expected = makeDate(year: 2024, month: 1, day: 1)

        XCTAssertEqual(engine.normalizedNextRenewal(from: start, cycle: .yearly, now: now), expected)
    }

    func testNormalizedIsNotBeforeStartOfToday() {
        let engine = RecurrenceEngine(calendar: calendar)
        let start = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 10, hour: 15, minute: 30)
        let result = engine.normalizedNextRenewal(from: start, cycle: .weekly, now: now)

        let startOfToday = calendar.startOfDay(for: now)
        XCTAssertTrue(result >= startOfToday)
        XCTAssertEqual(result, makeDate(year: 2024, month: 1, day: 15))
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        guard let date = calendar.date(from: components) else {
            XCTFail("Failed to build date")
            return Date(timeIntervalSince1970: 0)
        }

        return date
    }
}
