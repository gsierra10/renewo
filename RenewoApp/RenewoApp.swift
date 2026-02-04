import SwiftUI

@main
struct RenewoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var container = AppContainer()
    @State private var didPerformInitialRefresh = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(container)
                .environment(\.managedObjectContext, container.coreDataStack.viewContext)
                .task {
                    if LaunchArguments.isUITestMode {
                        didPerformInitialRefresh = true
                        return
                    }
                    guard !didPerformInitialRefresh else { return }
                    didPerformInitialRefresh = true
                    await container.refreshEntitlementsAndNormalize()
                }
                .onChange(of: scenePhase) { newPhase in
                    if LaunchArguments.isUITestMode {
                        return
                    }
                    guard newPhase == .active, didPerformInitialRefresh else { return }
                    Task {
                        await container.refreshEntitlementsAndNormalize()
                    }
                }
        }
    }
}
