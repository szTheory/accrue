---
id: SEED-007
status: backlogged
planted: 2026-07-31
planted_during: v1.59 roadmap update
trigger_when: when Android delivery is scheduled or a second concrete adopter requires Google Play Billing
scope: medium
depends_on: v1.59 account-scoped multi-rail foundation
---

# SEED-007: Google Play Billing rail

## Why This Matters

The v1.59 seam must prove that Apple is an adapter, not a one-off branch. Google Play is the next likely observer rail, but implementing it before Android is scheduled would add lifecycle and test burden without current adopter value.

## When to Surface

Surface when either:

- B2C Alpha schedules Android delivery; or
- another concrete adopter requires Google Play Billing.

## Expected Scope

- Play Billing purchase token/account linkage
- Google Play Developer API verification and Real-time Developer Notifications
- rail-qualified product mapping and lifecycle projection
- restore/reconciliation, refunds/revocations, grace/hold/pause semantics
- conformance against the v1.59 rail behavior and offline lease fixtures

Do not create a second entitlement model or widen the common projection merely to mimic every Google lifecycle operation.
