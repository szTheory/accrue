---
id: SEED-006
status: promoted
planted: 2026-07-31
triggered: 2026-07-31
planted_during: v1.58 closeout / v1.59 roadmap update
trigger_when: TRIGGER FIRED — first concrete offline mobile + web adopter requires coherent Stripe and Apple access for one account
promoted_to: v1.59
scope: large
---

# SEED-006: Account-scoped multi-rail and offline entitlements

## Why This Matters

B2C Alpha is the first concrete adopter to require one human account to remain entitled across web and iOS when payment may originate on Stripe or Apple and core use can remain offline for extended periods. This is a reusable Phoenix-going-mobile scenario, not adopter-specific customization.

## Promoted Direction

Promoted into queued milestone **v1.59 Account-Scoped Multi-Rail & Offline Entitlements** (Phases 215-219). The accepted design is a canonical account entitlement projection fed by rail-specific lifecycle observers, plus a compact signed offline lease. Management remains rail-aware and provider-honest.

## Guardrails

- Host-owned routes, authentication, runtime configuration, and client storage remain host concerns.
- `lattice_stripe` remains the Stripe transport.
- No email-based Apple linking and no fake cross-rail lifecycle parity.
- Existing entitlement gates remain additive-compatible.
- No adopter identity or PII in planning artifacts, tokens, telemetry, or fixtures.

## Durable Source

See `.planning/research/MULTI-RAIL-OFFLINE-ENTITLEMENTS.md` and the v1.59 queued roadmap section.

