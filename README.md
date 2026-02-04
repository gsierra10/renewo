# Renewo

Local-first subscription tracker for iOS 16+ built with SwiftUI and Core Data.

## Manual QA checklist

- Notifications permission flow
  - First save prompts for notifications.
  - Deny and verify Settings shows "Denied" and Open Settings works.
  - Allow and verify Settings shows "Allowed".
- Notification timing sanity
  - Set device date forward and confirm overdue renewals normalize on foreground.
- Purchases (sandbox)
  - Purchase Pro; verify Pro sections unlock.
  - Restore Purchases; verify entitlement refresh.
- Offline behavior
  - Airplane mode: add/edit/delete still works.
  - CSV export still produces a file.
- Accessibility
  - Large Text (XL/AX sizes) shows totals without truncation.
  - VoiceOver reads totals and subscription rows clearly.

## UI tests

Run UI tests from Xcode: Test Navigator (⌘6) → RenewoUITests.

- `RenewoBasicFlowUITests` covers add/edit/delete and Settings basics.
- `FreeLimitUITests` verifies the free limit upgrade sheet.

## CI helper

After pushing to `main`, wait for GitHub Actions and fail fast if CI fails:

```bash
scripts/watch_ci.sh
```

Optional arguments:

```bash
scripts/watch_ci.sh "CI Unit Tests" main
```
