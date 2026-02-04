import SwiftUI
import UIKit

struct NotificationStatusRow: View {
    @Environment(\.openURL) private var openURL
    let status: NotificationAuthorizationStatus

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr("settings.notifications.title"))
                Text(status.label)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("notificationStatusLabel")
            }
            Spacer()
            if status == .denied {
                Button(L10n.tr("settings.notifications.openSettings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .accessibilityIdentifier("notificationOpenSettingsButton")
            }
        }
    }
}
