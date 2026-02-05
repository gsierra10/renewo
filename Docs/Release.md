# Release Guide

## Overview
The manual GitHub Action `Release TestFlight` builds and uploads a TestFlight build using Fastlane `pilot` and an App Store Connect API key.

## Required GitHub Secrets
Set these repository secrets:
- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_KEY_P8`
  - Accepts raw `.p8` content or base64-encoded content.
  - The Fastlane lane detects raw content by the `BEGIN PRIVATE KEY` header.

## Run in GitHub Actions
1. Open the `Release TestFlight` workflow.
2. Click **Run workflow**.
3. Optionally provide:
   - `version` (e.g. `1.2.0`)
   - `build_number` (e.g. `123`)

## Run Locally

```bash
bundle exec fastlane testflight
```

Or, without Bundler:

```bash
fastlane testflight
```

Required environment variables:

```bash
export ASC_KEY_ID="..."
export ASC_ISSUER_ID="..."
export ASC_KEY_P8="..."  # raw or base64
```

Optional inputs:
- `version:1.2.0`
- `build_number:123`

Example:

```bash
fastlane testflight version:1.2.0 build_number:123
```

## What This Does
- Increments build number (or uses provided `build_number`).
- Optionally sets `version`.
- Builds an App Store archive via `gym`.
- Uploads to TestFlight via `pilot`.

## What This Does Not Do
- Manage signing certificates or profiles.
- Tag releases or update changelogs.
