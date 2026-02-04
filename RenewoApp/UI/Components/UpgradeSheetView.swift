import SwiftUI

struct UpgradeSheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(L10n.tr("upgrade.limit.title"))
                    .font(.title2.weight(.semibold))
                    .accessibilityIdentifier("upgradeLimitTitle")

                Text(L10n.tr("upgrade.limit.message"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(L10n.tr("upgrade.limit.notNow")) {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("upgradeLimitNotNowButton")
            }
            .padding(24)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("upgradeLimitSheet")
            .navigationTitle(L10n.tr("upgrade.limit.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
