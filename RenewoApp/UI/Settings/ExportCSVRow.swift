import SwiftUI

struct ExportCSVRow: View {
    let isPro: Bool
    let action: () -> Void

    var body: some View {
        if isPro {
            Button(action: action) {
                Label(L10n.tr("settings.export.csv"), systemImage: "tray.and.arrow.up")
            }
            .accessibilityIdentifier("settingsExportCSVButton")
        } else {
            HStack {
                Label(L10n.tr("settings.export.csv"), systemImage: "tray.and.arrow.up")
                Spacer()
                Text(L10n.tr("settings.export.locked"))
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("settingsExportCSVLockedLabel")
        }
    }
}
