import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer
    #if DEBUG
    @State private var isShowingPreviewGallery = false
    #endif

    var body: some View {
        ZStack {
            Color.renewoBackground
                .ignoresSafeArea()
            NavigationStack {
                rootContent
            }
            .tint(.renewoAccent)
            #if DEBUG
            .onLongPressGesture(minimumDuration: 1.2) {
                isShowingPreviewGallery = true
            }
            .sheet(isPresented: $isShowingPreviewGallery) {
                NavigationStack {
                    PreviewGalleryView()
                }
            }
            #endif
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch testRoot {
        case .settings:
            LocalizationProbeView(
                key: "settings.title",
                identifier: "settingsTitleLabel"
            )
            .accessibilityIdentifier("settingsViewRoot")
        case .summary:
            SummaryView()
                .environmentObject(container)
                .environment(\.managedObjectContext, container.coreDataStack.viewContext)
                .accessibilityIdentifier("summaryViewRoot")
        case .add:
            AddEditSubscriptionView(
                entitlementsStore: container.entitlementsStore,
                repository: container.subscriptionsRepository,
                notificationScheduler: container.notificationScheduler,
                settingsStore: container.settingsStore,
                proGating: container.proGating
            )
            .accessibilityIdentifier("addViewRoot")
        case .main:
            SubscriptionsListView()
        }
    }

    private var testRoot: TestRoot {
        guard let value = LaunchArguments.value(prefix: "UI_TEST_ROOT=") else {
            return .main
        }
        return TestRoot(rawValue: value) ?? .main
    }

    private enum TestRoot: String {
        case main
        case settings
        case summary
        case add
    }

    private struct LocalizationProbeView: View {
        let key: String
        let identifier: String

        var body: some View {
            VStack {
                Text(L10n.tr(key))
                    .accessibilityIdentifier(identifier)
            }
            .navigationTitle(L10n.tr(key))
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        let stack = CoreDataStack.inMemory()
        let container = AppContainer(coreDataStack: stack)
        return RootView()
            .environmentObject(container)
            .environment(\.managedObjectContext, stack.viewContext)
    }
}
