import XCTest
@testable import Renewo

final class ProGatingTests: XCTestCase {
    private let gating = ProGating()

    func testFreeAllowsUpToThreeSubscriptions() {
        XCTAssertTrue(gating.canAddSubscription(currentCount: 0, isPro: false))
        XCTAssertTrue(gating.canAddSubscription(currentCount: 1, isPro: false))
        XCTAssertTrue(gating.canAddSubscription(currentCount: 2, isPro: false))
        XCTAssertFalse(gating.canAddSubscription(currentCount: 3, isPro: false))
    }

    func testProAllowsBeyondThreeSubscriptions() {
        XCTAssertTrue(gating.canAddSubscription(currentCount: 4, isPro: true))
        XCTAssertTrue(gating.canAddSubscription(currentCount: 10, isPro: true))
    }

    func testFreeReminderAlwaysThree() {
        XCTAssertEqual(gating.enforcedReminderDays(input: 1, isPro: false), 3)
        XCTAssertEqual(gating.enforcedReminderDays(input: 10, isPro: false), 3)
    }
}
