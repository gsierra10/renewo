import CoreData
import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject private var entitlementsStore: EntitlementsStore
    private let settingsStore: SettingsStore
    private let notificationScheduler: NotificationScheduling

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Subscription.name, ascending: true)
        ]
    )
    private var subscriptions: FetchedResults<Subscription>

    @State private var selectedCurrency: String
    @State private var notificationStatus: NotificationAuthorizationStatus = .unknown
    @State private var showUpgradeSheet = false
    @State private var errorMessage: String?
    @State private var shareItems: [Any] = []
    @State private var isPresentingShareSheet = false
    @State private var isRestoringPurchases = false

    init(
        entitlementsStore: EntitlementsStore,
        settingsStore: SettingsStore,
        notificationScheduler: NotificationScheduling
    ) {
        self.entitlementsStore = entitlementsStore
        self.settingsStore = settingsStore
        self.notificationScheduler = notificationScheduler
        _selectedCurrency = State(initialValue: settingsStore.defaultCurrencyCode)
    }

    var body: some View {
        settingsContent
            .navigationTitle(L10n.tr("settings.title"))
            .task {
                await refreshNotificationStatus()
            }
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeProView(entitlementsStore: entitlementsStore)
            }
            .sheet(isPresented: $isPresentingShareSheet) {
                ShareSheet(items: shareItems)
            }
            .alert(L10n.tr("settings.alert.title"), isPresented: Binding(get: { errorMessage != nil }, set: { isPresented in
                if !isPresented { errorMessage = nil }
            })) {
                Button(L10n.tr("common.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
    }

    @ViewBuilder
    private var settingsContent: some View {
        if LaunchArguments.has("UI_TEST_MINIMAL_SETTINGS") {
            List {
                Text(L10n.tr("settings.title"))
                    .accessibilityIdentifier("settingsTitleLabel")
                ExportCSVRow(isPro: entitlementsStore.isPro) {}
            }
            .accessibilityIdentifier("settingsViewRoot")
        } else {
            formContent
        }
    }

    private var formContent: some View {
        Form {
            Section(L10n.tr("settings.section.preferences")) {
                Picker(L10n.tr("settings.defaultCurrency"), selection: currencyBinding) {
                    ForEach(Self.currencyCodes, id: \.self) { code in
                        Text(code).tag(code)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityIdentifier("settingsCurrencyPicker")
                .accessibilityValue(settingsStore.defaultCurrencyCode)

                if entitlementsStore.isPro {
                    Stepper(value: reminderBinding, in: 0...60) {
                        Text(L10n.tr("settings.defaultReminder.pro.format", settingsStore.defaultReminderDays))
                    }
                    .accessibilityIdentifier("settingsReminderStepper")
                } else {
                    HStack {
                        Text(L10n.tr("settings.defaultReminder.free.label"))
                        Spacer()
                        Text(L10n.tr("settings.defaultReminder.free.value"))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("settingsReminderFreeLabel")
                }
            }

            Section(L10n.tr("settings.section.notifications")) {
                NotificationStatusRow(status: notificationStatus)
            }

            Section(L10n.tr("settings.section.data")) {
                ExportCSVRow(isPro: entitlementsStore.isPro) {
                    exportCSV()
                }
            }

            Section(L10n.tr("settings.section.pro")) {
                HStack {
                    Text(L10n.tr("settings.pro.status.title"))
                    Spacer()
                    Text(entitlementsStore.isPro
                         ? L10n.tr("settings.pro.status.pro")
                         : L10n.tr("settings.pro.status.free"))
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("settingsProStatusValueLabel")
                }
                .accessibilityIdentifier("settingsProStatusRow")

                if entitlementsStore.isPro {
                    Text(L10n.tr("settings.pro.unlocked"))
                        .foregroundColor(.secondary)
                        .accessibilityIdentifier("settingsProUnlockedLabel")
                } else {
                    Button(L10n.tr("settings.pro.upgrade")) {
                        showUpgradeSheet = true
                    }
                    .accessibilityIdentifier("settingsUpgradeButton")
                }

                Button {
                    restorePurchases()
                } label: {
                    if isRestoringPurchases {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(L10n.tr("settings.pro.restore.processing"))
                        }
                    } else {
                        Text(L10n.tr("settings.pro.restore"))
                    }
                }
                .disabled(isRestoringPurchases)
                .accessibilityIdentifier("settingsRestoreButton")
            }
        }
        .accessibilityIdentifier("settingsView")
    }

    private func exportCSV() {
        guard entitlementsStore.isPro else { return }

        let rows = subscriptions.map { subscription in
            CSVExporter.Row(
                name: subscription.name ?? L10n.tr("common.untitled"),
                amount: subscription.amount?.decimalValue ?? 0,
                currencyCode: subscription.currencyCode ?? settingsStore.defaultCurrencyCode,
                billingCycle: subscription.billingCycleRaw ?? BillingCycle.monthly.rawValue,
                renewalDate: subscription.renewalDate ?? Date(),
                reminderDays: Int(subscription.reminderDays),
                category: subscription.category
            )
        }

        do {
            let exporter = CSVExporter()
            let url = try exporter.writeCSV(rows: rows)
            shareItems = [url]
            isPresentingShareSheet = true
        } catch {
            errorMessage = L10n.tr("settings.error.export")
        }
    }

    private var currencyBinding: Binding<String> {
        Binding(
            get: { selectedCurrency },
            set: { newValue in
                selectedCurrency = newValue
                settingsStore.defaultCurrencyCode = newValue
            }
        )
    }

    private var reminderBinding: Binding<Int> {
        Binding(
            get: { settingsStore.defaultReminderDays },
            set: { settingsStore.defaultReminderDays = $0 }
        )
    }

    private func refreshNotificationStatus() async {
        if LaunchArguments.has("UI_TEST_NOTIFICATIONS_DENIED") {
            notificationStatus = .denied
            return
        }
        let status = await notificationScheduler.getAuthorizationStatus()
        notificationStatus = NotificationAuthorizationStatus(from: status)
    }

    private func restorePurchases() {
        errorMessage = nil
        isRestoringPurchases = true
        Task {
            defer { isRestoringPurchases = false }
            do {
                try await entitlementsStore.restorePurchases()
            } catch {
                errorMessage = L10n.tr("settings.error.restore")
            }
        }
    }

    private static let currencyCodes: [String] = {
        Locale.commonISOCurrencyCodes.sorted()
    }()
}

enum NotificationAuthorizationStatus: Equatable {
    case authorized
    case denied
    case notDetermined
    case unknown

    init(from status: UNAuthorizationStatus) {
        switch status {
        case .authorized, .provisional, .ephemeral:
            self = .authorized
        case .denied:
            self = .denied
        case .notDetermined:
            self = .notDetermined
        @unknown default:
            self = .unknown
        }
    }

    var label: String {
        switch self {
        case .authorized:
            return L10n.tr("settings.notifications.status.allowed")
        case .denied:
            return L10n.tr("settings.notifications.status.denied")
        case .notDetermined:
            return L10n.tr("settings.notifications.status.notRequested")
        case .unknown:
            return L10n.tr("settings.notifications.status.unknown")
        }
    }
}
