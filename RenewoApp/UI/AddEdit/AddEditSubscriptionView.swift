import Foundation
import SwiftUI

struct AddEditSubscriptionView: View {
    private enum Mode {
        case add
        case edit(Subscription)
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var entitlementsStore: EntitlementsStore

    private let repository: SubscriptionsRepository
    private let notificationScheduler: NotificationScheduling
    private let settingsStore: SettingsStore
    private let proGating: ProGating
    private let validator = SubscriptionFormValidator()
    private let mode: Mode

    @State private var draft: SubscriptionDraft
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showUpgradeSheet = false
    @State private var showFirstAddConfirmation = false

    init(
        entitlementsStore: EntitlementsStore,
        repository: SubscriptionsRepository,
        notificationScheduler: NotificationScheduling,
        settingsStore: SettingsStore,
        proGating: ProGating,
        subscription: Subscription? = nil
    ) {
        self.entitlementsStore = entitlementsStore
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.settingsStore = settingsStore
        self.proGating = proGating
        self.mode = subscription.map { .edit($0) } ?? .add
        _draft = State(initialValue: Self.initialDraft(
            subscription: subscription,
            settingsStore: settingsStore
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.tr("add.section.details")) {
                    TextField(L10n.tr("add.field.name"), text: $draft.name)
                        .accessibilityIdentifier("subscriptionNameField")

                    TextField(L10n.tr("add.field.amount"), text: $draft.amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("subscriptionAmountField")

                    Picker(L10n.tr("add.field.currency"), selection: $draft.currencyCode) {
                        ForEach(Self.currencyCodes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .accessibilityIdentifier("subscriptionCurrencyPicker")

                    Picker(L10n.tr("add.field.billingCycle"), selection: $draft.billingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Text(cycle.displayName).tag(cycle)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("subscriptionBillingCyclePicker")

                    DatePicker(L10n.tr("add.field.renewsOn"), selection: $draft.renewalDate, displayedComponents: .date)
                        .accessibilityIdentifier("subscriptionRenewalDatePicker")
                }

                Section(L10n.tr("add.section.reminders")) {
                    if entitlementsStore.isPro {
                        Stepper(value: $draft.reminderDays, in: 0...60) {
                            Text(L10n.tr("add.reminder.pro.format", draft.reminderDays))
                        }
                        .accessibilityIdentifier("subscriptionReminderStepper")
                    } else {
                        HStack {
                            Text(L10n.tr("add.reminder.free.label"))
                            Spacer()
                            Text(L10n.tr(
                                "add.reminder.free.value",
                                proGating.enforcedReminderDays(input: draft.reminderDays, isPro: false)
                            ))
                                .foregroundColor(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                if entitlementsStore.isPro {
                    Section(L10n.tr("add.section.category")) {
                        TextField(L10n.tr("add.field.category"), text: $draft.category)
                            .accessibilityIdentifier("subscriptionCategoryField")
                    }
                }
            }
            .navigationTitle(isEditing ? L10n.tr("add.title.edit") : L10n.tr("add.title.add"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.tr("add.cancel")) {
                        dismiss()
                    }
                    .accessibilityIdentifier("subscriptionCancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("add.save")) {
                        save()
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("subscriptionSaveButton")
                }
            }
            .alert(L10n.tr("add.alert.title"), isPresented: Binding(get: { errorMessage != nil }, set: { isPresented in
                if !isPresented { errorMessage = nil }
            })) {
                Button(L10n.tr("common.ok"), role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .alert(L10n.tr("firstAdd.title"), isPresented: $showFirstAddConfirmation) {
                Button(L10n.tr("common.ok"), role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(L10n.tr("firstAdd.message"))
            }
            .sheet(isPresented: $showUpgradeSheet) {
                UpgradeSheetView()
            }
        }
    }

    private func save() {
        if let error = validator.validate(draft) {
            errorMessage = error
            return
        }

        guard let amount = validator.parsedAmount(from: draft) else {
            errorMessage = L10n.tr("validation.amountPositive")
            return
        }

        isSaving = true
        Task {
            defer { isSaving = false }

            if !settingsStore.hasSeenNotificationPrompt {
                if !LaunchArguments.isUITestMode {
                    _ = await notificationScheduler.requestAuthorizationIfNeeded()
                }
                settingsStore.hasSeenNotificationPrompt = true
            }

            let reminderDays = entitlementsStore.isPro ? draft.reminderDays : 3
            let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let categoryChange: String??
            if entitlementsStore.isPro {
                categoryChange = trimmedCategory
            } else {
                categoryChange = nil
            }

            do {
                switch mode {
                case .add:
                    let shouldShowFirstAdd = (try? repository.subscriptionCount()) == 0
                        && !settingsStore.hasShownFirstAddConfirmation
                    let repositoryDraft = SubscriptionsRepository.SubscriptionDraft(
                        name: trimmedName,
                        amount: amount,
                        currencyCode: draft.currencyCode,
                        billingCycle: draft.billingCycle,
                        renewalDate: draft.renewalDate,
                        reminderDays: reminderDays,
                        category: entitlementsStore.isPro ? trimmedCategory : nil
                    )
                    try repository.add(repositoryDraft, isPro: entitlementsStore.isPro)
                    if shouldShowFirstAdd {
                        settingsStore.hasShownFirstAddConfirmation = true
                        showFirstAddConfirmation = true
                    } else {
                        dismiss()
                    }
                case .edit(let subscription):
                    let changes = SubscriptionsRepository.SubscriptionChanges(
                        name: trimmedName,
                        amount: amount,
                        currencyCode: draft.currencyCode,
                        billingCycle: draft.billingCycle,
                        renewalDate: draft.renewalDate,
                        reminderDays: reminderDays,
                        category: categoryChange
                    )
                    try repository.update(subscription, changes: changes, isPro: entitlementsStore.isPro)
                    dismiss()
                }
            } catch let error as RepositoryError {
                switch error {
                case .freeLimitReached:
                    showUpgradeSheet = true
                case .validationFailed(let message):
                    errorMessage = message
                }
            } catch {
                errorMessage = L10n.tr("add.alert.generic")
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode {
            return true
        }
        return false
    }

    private var trimmedCategory: String? {
        let trimmed = draft.category.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func initialDraft(
        subscription: Subscription?,
        settingsStore: SettingsStore
    ) -> SubscriptionDraft {
        guard let subscription else {
            return SubscriptionDraft(
                currencyCode: settingsStore.defaultCurrencyCode,
                reminderDays: settingsStore.defaultReminderDays
            )
        }

        let currencyCode = subscription.currencyCode ?? settingsStore.defaultCurrencyCode
        let billingCycle = BillingCycle(rawValue: subscription.billingCycleRaw ?? "") ?? .monthly
        let renewalDate = subscription.renewalDate ?? Date()
        let reminderDays = Int(subscription.reminderDays)
        let amountText = subscription.amount?.stringValue ?? ""
        let category = subscription.category ?? ""

        return SubscriptionDraft(
            name: subscription.name ?? "",
            amountText: amountText,
            currencyCode: currencyCode,
            billingCycle: billingCycle,
            renewalDate: renewalDate,
            reminderDays: reminderDays,
            category: category
        )
    }

    private static let currencyCodes: [String] = {
        let codes = Locale.commonISOCurrencyCodes
        return codes.sorted()
    }()
}

private extension BillingCycle {
    var displayName: String {
        switch self {
        case .weekly: return L10n.tr("billing.weekly")
        case .monthly: return L10n.tr("billing.monthly")
        case .yearly: return L10n.tr("billing.yearly")
        }
    }
}
