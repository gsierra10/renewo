# Architecture

## Overview
Renewo is a local-first iOS app built with SwiftUI. The app stores data on-device using Core Data and keeps the runtime surface small with a lightweight dependency container (`AppContainer`). There is no backend layer in the current implementation.

## Dependency Container (AppContainer)
- `AppContainer` is the main composition root.
- It owns and constructs shared services (Core Data stack, repositories, schedulers, stores).
- It is injected into SwiftUI via `.environmentObject(container)`.

Key dependencies created in `AppContainer`:
- `CoreDataStack`
- `SettingsStore`
- `RecurrenceEngine`
- `TotalsCalculator`
- `UNNotificationScheduler` (through the `NotificationScheduling` protocol)
- `EntitlementsStore` (StoreKit)
- `ProGating`
- `SubscriptionsRepository`

## Data Layer (Core Data)
- `CoreDataStack` wraps `NSPersistentContainer` and exposes a main `viewContext`.
- Automatic lightweight migration is enabled.
- Repository operations use the main context with `performAndWait` for writes.

## Repository Responsibilities
- `SubscriptionsRepository` is the primary data access layer for subscriptions.
- It performs validation, normalizes renewal dates, and persists changes.
- It coordinates reminder scheduling via `NotificationScheduling`.
- It applies pro/free gating through `ProGating` and uses `SettingsStore` for preference data.

## Notifications
- `NotificationScheduling` is the protocol abstraction.
- `UNNotificationScheduler` implements scheduling/canceling local notifications using `UNUserNotificationCenter`.
- The repository triggers scheduling after writes and cancels on deletions.

## Monetization (StoreKit)
- `EntitlementsStore` manages StoreKit entitlements and purchase/restore flows.
- `isPro` is the single source of truth for pro access.
- UITest overrides use `LaunchArguments` and `UserDefaults` to simulate purchase outcomes.

## UI Layer
- SwiftUI views bind directly to repositories/stores and `@EnvironmentObject` dependencies.
- There is no dedicated ViewModel layer in the current codebase.
- State is managed with `@State`, `@StateObject`, and `@EnvironmentObject` in views.
