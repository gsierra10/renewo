# CI Guide

## Workflows and Triggers

- `CI Unit Tests` (`.github/workflows/ci-unit-tests.yml`)
  - Triggers: pull requests to `main`, pushes to `main`
  - Job/check name: `unit-tests`
- `CI Build Release` (`.github/workflows/ci-build-release.yml`)
  - Triggers: pull requests to `main`, pushes to `main`
  - Job/check name: `build-release`
- `UI Tests` (`.github/workflows/ci-ui-tests.yml`)
  - Triggers: manual (`workflow_dispatch`) and weekly schedule
  - Job/check name: `ui-tests`
  - Intended as optional (not a required branch protection check)

## Local CI-Equivalent Commands

Run these from the repository root.

### 1) Unit tests (same `xcodebuild` invocation used in CI)

```bash
xcodebuild \
  -project Renewo.xcodeproj \
  -scheme Renewo \
  -destination "id=<SIMULATOR_UDID>" \
  -only-testing:RenewoTests \
  -resultBundlePath TestResults/UnitTests.xcresult \
  test
```

The CI workflow dynamically selects an available simulator UDID before calling this command.

### 2) Release build (same as CI)

```bash
xcodebuild \
  -project Renewo.xcodeproj \
  -scheme Renewo \
  -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  -resultBundlePath BuildResults/ReleaseBuild.xcresult \
  build
```

### 3) UI tests (same `xcodebuild` invocation used in CI)

```bash
xcodebuild \
  -project Renewo.xcodeproj \
  -scheme Renewo \
  -destination "id=<SIMULATOR_UDID>" \
  -only-testing:RenewoUITests \
  -resultBundlePath TestResults/UITests.xcresult \
  -quiet \
  test
```

The CI workflow picks a simulator dynamically and retries once only when it detects a known transient launch issue: `Test runner never began executing tests after launching`.

## Branch Protection Guidance

Configure branch protection on `main` with these settings:

- Protect `main`.
- Require a pull request before merging.
- Require approvals: at least `1`.
- Require conversation resolution before merging.
- Require status checks to pass before merging:
  - `unit-tests`
  - `build-release`
- Do not require `ui-tests` (keep UI tests optional/manual).
- Restrict force pushes (disable force-push to `main`).
