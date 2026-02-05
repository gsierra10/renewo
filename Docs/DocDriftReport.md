# Doc Drift Report

Date: 2026-02-05

## Docs Reviewed
- `Docs/CI.md`
- `Docs/Observability.md`
- `Docs/Release.md`
- No existing architecture documentation was present.

## Claims in Docs
- CI workflows and their triggers/check names.
- Sentry observability is optional and disabled without a DSN.
- Manual TestFlight release via Fastlane.

## What the Code Actually Does
- SwiftUI app with a lightweight dependency container (`AppContainer`).
- Local-first data storage using Core Data with a single main context.
- Repository-driven data access and notification scheduling.
- StoreKit-based entitlements via `EntitlementsStore`.
- No dedicated ViewModel layer; views bind directly to stores/repositories.

## Differences / Drift
- Architecture documentation was missing, so current structure was undocumented.

## Recommendation
Update docs to reflect the current architecture (preferred over refactor).

## Actions Taken
- Added `Docs/Architecture.md` describing the actual structure.
