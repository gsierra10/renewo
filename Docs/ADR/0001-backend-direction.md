# ADR 0001: Backend Direction

Date: 2026-02-05
Status: Proposed

## Context
Renewo is currently a local-first iOS MVP. Data lives on-device (Core Data), and core flows work offline. There is no backend service for authentication, sync, or analytics. The product direction is still open, so we need an explicit decision record to avoid accidental drift.

## Decision Options

### Option A: Remain Local-First (No Backend)
Keep all data on-device. No server-side accounts, sync, or analytics ingestion.

### Option B: Minimal Backend (Auth + Sync + Analytics Events)
Introduce a thin backend to enable authentication, optional multi-device sync, and basic analytics event ingestion.

## Constraints
- Privacy-first by default.
- Keep the codebase small and low-risk.
- Avoid heavy infrastructure or costly operational complexity.
- Do not introduce mandatory accounts for basic use.

## Pros / Cons

### Option A Pros
- Lowest implementation and operational overhead.
- Strong privacy posture (no server data retention).
- Fewer failure modes and no backend outages.

### Option A Cons
- No cross-device sync.
- Limited insights into usage or funnel metrics.
- Harder to restore data across devices.

### Option B Pros
- Enables optional sync and device continuity.
- Allows controlled analytics for product decisions.
- Enables future paid features requiring accounts.

### Option B Cons
- Adds infrastructure and operational burden.
- Increases security and compliance surface area.
- Requires careful data minimization and consent flows.

## Risks
- Option A risks slower iteration due to low visibility into behavior.
- Option B risks privacy missteps and higher maintenance costs.
- Both options risk being difficult to reverse without planning for migration.

## Migration Plan (If Switching Later)
- Design data model to allow export/import.
- Add identifiers that can map local data to remote records.
- Introduce sync as optional and opt-in with clear UX.
- Start with read-only analytics events before adding full sync.

## Expected Codebase Changes

### If Option A
- Keep current local storage and notification scheduling as-is.
- Focus on local backup/export utilities if needed.

### If Option B
- Add authentication and secure token storage.
- Add sync engine + conflict resolution strategy.
- Add backend client layer and request logging.
- Add analytics event batching and upload.

## Decision

**To be filled after product choice.**

Fill in one of:
- "We will remain local-first (Option A)."
- "We will build a minimal backend (Option B)."

## Success Metrics

If Option A:
- 95%+ of users complete core flows without onboarding friction.
- Support tickets related to data loss remain below an agreed threshold.

If Option B:
- Sync adoption rate and retention improve vs local-only baseline.
- Analytics events are >99% delivered with no PII leakage.
- Support tickets related to auth/sync are below an agreed threshold.
