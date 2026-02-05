# Observability

## Sentry (Crash + Performance)

Renewo uses the Sentry iOS SDK for crash reporting and lightweight performance tracing. It is disabled by default and only starts when a DSN is provided.

### How to enable locally

Provide `SENTRY_DSN` via one of:
- `Info.plist` key: `SENTRY_DSN`
- Environment variable: `SENTRY_DSN`

Example (environment variable):

```bash
SENTRY_DSN="https://examplePublicKey@o0.ingest.sentry.io/0"
```

### Debug behavior

- Debug builds default to **no performance tracing**.
- To enable tracing in Debug, set `SENTRY_ENABLE_DEBUG_TRACING=1`.
- Release builds use a conservative trace sample rate of `0.1`.

### Data collected

- Crashes and basic performance traces only.
- `sendDefaultPii` is disabled.
- No user-identifying data is captured.
- Avoid adding subscription names or amounts to breadcrumbs/events.

### Safe defaults

- App runs normally when `SENTRY_DSN` is missing.
- No build phase uploads are used; CI does not require secrets.
