import SwiftUI

struct EmptyStateView: View {
    let action: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(L10n.tr("main.empty.title"))
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(L10n.tr("main.empty.subtitle"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(L10n.tr("main.add"))
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
