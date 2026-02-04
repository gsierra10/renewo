import Foundation
import StoreKit

@MainActor
final class EntitlementsStore: ObservableObject {
    @Published private(set) var isPro: Bool = false

    let productId = "com.renewo.pro.lifetime"
    private var purchaseOutcomeQueue: [UITestOutcome]
    private var restoreOutcomeQueue: [UITestOutcome]

    init() {
        purchaseOutcomeQueue = Self.parseOutcomeQueue(
            listPrefix: "UI_TEST_PURCHASE_RESULTS=",
            singlePrefix: "UI_TEST_PURCHASE_RESULT="
        )
        restoreOutcomeQueue = Self.parseOutcomeQueue(
            listPrefix: "UI_TEST_RESTORE_RESULTS=",
            singlePrefix: "UI_TEST_RESTORE_RESULT="
        )

        if LaunchArguments.isUITestMode {
            if LaunchArguments.has("UI_TEST_FORCE_FREE_STATE") {
                UserDefaults.standard.removeObject(forKey: Self.uiTestProStateKey)
                isPro = false
                return
            }
            if LaunchArguments.has("UI_TEST_RESET_PRO_STATE") {
                UserDefaults.standard.removeObject(forKey: Self.uiTestProStateKey)
            }
            isPro = UserDefaults.standard.bool(forKey: Self.uiTestProStateKey)
        }
    }

    func refreshEntitlements() async {
        if LaunchArguments.isUITestMode {
            isPro = UserDefaults.standard.bool(forKey: Self.uiTestProStateKey)
            return
        }

        var hasPro = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if transaction.productID == productId {
                hasPro = true
                break
            }
        }

        isPro = hasPro
    }

    func purchasePro() async throws {
        if LaunchArguments.isUITestMode {
            try await executeUITestPurchaseFlow()
            return
        }

        let products = try await Product.products(for: [productId])
        guard let product = products.first else {
            throw PurchaseError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw PurchaseError.failedVerification
            }
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw PurchaseError.userCancelled
        case .pending:
            throw PurchaseError.pending
        @unknown default:
            throw PurchaseError.unknown
        }
    }

    func restorePurchases() async throws {
        if LaunchArguments.isUITestMode {
            try await executeUITestRestoreFlow()
            return
        }

        try await AppStore.sync()
        await refreshEntitlements()
    }

    private func executeUITestPurchaseFlow() async throws {
        try await Self.maybeDelay(prefix: "UI_TEST_PURCHASE_DELAY_MS=")

        let outcome = dequeueOutcome(from: &purchaseOutcomeQueue) ?? .success
        switch outcome {
        case .success:
            setUITestProState(true)
            isPro = true
        case .productNotFound:
            throw PurchaseError.productNotFound
        case .failedVerification:
            throw PurchaseError.failedVerification
        case .userCancelled:
            throw PurchaseError.userCancelled
        case .pending:
            throw PurchaseError.pending
        case .unknown:
            throw PurchaseError.unknown
        }
    }

    private func executeUITestRestoreFlow() async throws {
        try await Self.maybeDelay(prefix: "UI_TEST_RESTORE_DELAY_MS=")

        let outcome = dequeueOutcome(from: &restoreOutcomeQueue) ?? .success
        switch outcome {
        case .success:
            setUITestProState(true)
            isPro = true
        case .productNotFound:
            throw PurchaseError.productNotFound
        case .failedVerification:
            throw PurchaseError.failedVerification
        case .userCancelled:
            throw PurchaseError.userCancelled
        case .pending:
            throw PurchaseError.pending
        case .unknown:
            throw PurchaseError.unknown
        }
    }

    private func dequeueOutcome(from queue: inout [UITestOutcome]) -> UITestOutcome? {
        guard !queue.isEmpty else { return nil }
        return queue.removeFirst()
    }

    private func setUITestProState(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: Self.uiTestProStateKey)
    }

    private static func maybeDelay(prefix: String) async throws {
        guard let delayMs = LaunchArguments.intValue(prefix: prefix), delayMs > 0 else { return }
        try await Task.sleep(nanoseconds: UInt64(delayMs) * 1_000_000)
    }

    private static func parseOutcomeQueue(listPrefix: String, singlePrefix: String) -> [UITestOutcome] {
        if let value = LaunchArguments.value(prefix: listPrefix) {
            return value
                .split(separator: ",")
                .compactMap { parseOutcome(String($0)) }
        }

        if let value = LaunchArguments.value(prefix: singlePrefix),
           let outcome = parseOutcome(value) {
            return [outcome]
        }

        return []
    }

    private static func parseOutcome(_ raw: String) -> UITestOutcome? {
        let normalized = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "_")
            .lowercased()

        switch normalized {
        case "success":
            return .success
        case "product_not_found", "productnotfound":
            return .productNotFound
        case "failed_verification", "failedverification":
            return .failedVerification
        case "user_cancelled", "usercancelled", "cancelled", "canceled":
            return .userCancelled
        case "pending":
            return .pending
        case "unknown", "failure", "failed":
            return .unknown
        default:
            return nil
        }
    }

    private static let uiTestProStateKey = "ui_test_is_pro_state"
}

enum PurchaseError: Error {
    case productNotFound
    case failedVerification
    case userCancelled
    case pending
    case unknown
}

private enum UITestOutcome: String {
    case success
    case productNotFound = "product_not_found"
    case failedVerification = "failed_verification"
    case userCancelled = "user_cancelled"
    case pending
    case unknown
}
