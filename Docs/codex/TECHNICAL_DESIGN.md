# Technical Design

## Purpose
Frozen reference for the MVP implementation decisions.

## Scope
- SwiftUI app target: RenewoApp
- iOS 16+ deployment target
- MVVM: Views bind to @MainActor ViewModels
- Data persistence via Core Data behind repository protocols

## Decisions
- Keep domain logic free of SwiftUI imports.
- Use dependency injection (no singletons except PersistenceController).
- Favor testable, pure domain services for calculations and formatting.
