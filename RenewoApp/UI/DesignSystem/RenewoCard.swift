import SwiftUI

struct RenewoCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(RenewoTheme.cardPadding)
            .background(Color.renewoSurface)
            .cornerRadius(RenewoTheme.cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}
