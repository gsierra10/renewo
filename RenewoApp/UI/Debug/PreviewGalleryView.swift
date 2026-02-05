#if DEBUG
import CoreData
import SwiftUI

struct PreviewGalleryView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .renewoL) {
                gallerySection(title: "Main (Empty)") {
                    previewHost(container: makeContainer(seedCount: 0)) {
                        SubscriptionsListView()
                    }
                }

                gallerySection(title: "Main (Populated)") {
                    previewHost(container: makeContainer(seedCount: 3)) {
                        SubscriptionsListView()
                    }
                }

                gallerySection(title: "Summary") {
                    previewHost(container: makeContainer(seedCount: 4)) {
                        SummaryView()
                    }
                }

                gallerySection(title: "Settings") {
                    let container = makeContainer(seedCount: 1)
                    previewHost(container: container) {
                        SettingsView(
                            entitlementsStore: container.entitlementsStore,
                            settingsStore: container.settingsStore,
                            notificationScheduler: container.notificationScheduler
                        )
                    }
                }
            }
            .padding(.renewoL)
        }
        .background(Color.renewoBackground)
        .navigationTitle("Preview Gallery")
    }

    private func gallerySection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: .renewoS) {
            Text(title)
                .font(.renewoSectionHeader)
                .foregroundColor(.renewoTextPrimary)

            content()
                .frame(maxWidth: .infinity)
                .frame(height: 620)
                .background(Color.renewoBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.renewoDivider, lineWidth: 1)
                )
        }
    }

    private func previewHost<Content: View>(
        container: AppContainer,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            content()
                .environmentObject(container)
                .environment(\.managedObjectContext, container.coreDataStack.viewContext)
        }
    }

    private func makeContainer(seedCount: Int) -> AppContainer {
        let stack = CoreDataStack.inMemory()
        let container = AppContainer(coreDataStack: stack)
        if seedCount > 0 {
            seedSubscriptions(count: seedCount, context: stack.viewContext)
        }
        return container
    }

    private func seedSubscriptions(count: Int, context: NSManagedObjectContext) {
        context.performAndWait {
            for index in 1...count {
                let subscription = Subscription(context: context)
                subscription.id = UUID()
                subscription.name = "Sample \(index)"
                subscription.amount = NSDecimalNumber(string: index % 2 == 0 ? "12.99" : "8.49")
                subscription.currencyCode = index % 2 == 0 ? "USD" : "EUR"
                subscription.billingCycleRaw = BillingCycle.monthly.rawValue
                subscription.renewalDate = Calendar.current.date(byAdding: .day, value: index * 7, to: Date())
                subscription.reminderDays = 3
                subscription.createdAt = Date()
                subscription.updatedAt = Date()
            }

            if context.hasChanges {
                try? context.save()
            }
        }
    }
}

struct PreviewGalleryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PreviewGalleryView()
        }
    }
}
#endif
