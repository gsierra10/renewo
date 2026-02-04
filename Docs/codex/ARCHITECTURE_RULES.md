# Architecture Rules

- SwiftUI + MVVM (ViewModels are @MainActor).
- Domain logic has no SwiftUI imports.
- Data layer is Core Data behind a repository protocol.
- No singletons except the minimal PersistenceController.
- All new code must compile on iOS 16+.
- Every task must add or adjust tests where reasonable.
