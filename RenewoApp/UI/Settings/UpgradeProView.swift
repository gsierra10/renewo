import SwiftUI

struct UpgradeProView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entitlementsStore: EntitlementsStore

    @State private var errorMessage: String?
    @State private var processingAction: ProcessingAction?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.tr("upgrade.pro.title"))
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Label(L10n.tr("upgrade.pro.unlimited"), systemImage: "infinity")
                    Label(L10n.tr("upgrade.pro.categories"), systemImage: "tag")
                    Label(L10n.tr("upgrade.pro.customReminders"), systemImage: "bell")
                    Label(L10n.tr("upgrade.pro.csv"), systemImage: "tray.and.arrow.up")
                }
                .font(.body)
                .foregroundColor(.secondary)

                Spacer()

                Button {
                    purchase()
                } label: {
                    if processingAction == .purchase {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(L10n.tr("upgrade.pro.processing.purchase"))
                        }
                    } else {
                        Text(L10n.tr("upgrade.pro.purchase"))
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing)
                .accessibilityIdentifier("upgradePurchaseButton")

                Button {
                    restore()
                } label: {
                    if processingAction == .restore {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(L10n.tr("upgrade.pro.processing.restore"))
                        }
                    } else {
                        Text(L10n.tr("upgrade.pro.restore"))
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
                .accessibilityIdentifier("upgradeRestoreButton")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("upgradeErrorMessage")
                }

                if isProcessing {
                    ProgressView()
                        .accessibilityIdentifier("upgradeProcessingIndicator")
                }
            }
            .padding(24)
            .navigationTitle(L10n.tr("upgrade.pro.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("upgrade.pro.close")) {
                        dismiss()
                    }
                    .disabled(isProcessing)
                    .accessibilityIdentifier("upgradeCloseButton")
                }
            }
        }
    }

    private var isProcessing: Bool {
        processingAction != nil
    }

    private func purchase() {
        errorMessage = nil
        processingAction = .purchase
        Task {
            defer { processingAction = nil }
            do {
                try await entitlementsStore.purchasePro()
                dismiss()
            } catch {
                errorMessage = Self.errorMessage(for: error)
            }
        }
    }

    private func restore() {
        errorMessage = nil
        processingAction = .restore
        Task {
            defer { processingAction = nil }
            do {
                try await entitlementsStore.restorePurchases()
            } catch {
                errorMessage = Self.errorMessage(for: error)
            }
        }
    }

    private static func errorMessage(for error: Error) -> String {
        if let purchaseError = error as? PurchaseError {
            switch purchaseError {
            case .productNotFound:
                return L10n.tr("upgrade.pro.error.notFound")
            case .failedVerification:
                return L10n.tr("upgrade.pro.error.unverified")
            case .userCancelled:
                return L10n.tr("upgrade.pro.error.cancelled")
            case .pending:
                return L10n.tr("upgrade.pro.error.pending")
            case .unknown:
                return L10n.tr("upgrade.pro.error.unknown")
            }
        }
        return L10n.tr("upgrade.pro.error.unknown")
    }
}

private enum ProcessingAction {
    case purchase
    case restore
}
