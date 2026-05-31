# Roadmap: Accrue

## Milestones

- ✅ **v1.46 Maintenance & Closure** — Phases 151-153 (shipped 2026-05-30) — [archive](milestones/v1.46-ROADMAP.md)
- ✅ **v1.47 ENT-10 Polish + Adopter-Proof Completeness** — Phases 154-158 (shipped 2026-05-31) — [archive](milestones/v1.47-ROADMAP.md)
- 📋 **Recommended next milestone: Release Readiness + Stable Core Posture** — not started; publish post-1.3.0 v1.47 work, harden release truth, then pause broad feature work

## Planning Doctrine

Accrue is in **stable core / demand-driven expansion** posture as of 2026-05-31. The default next milestone should be release-readiness or maintenance, not feature expansion.

Future feature milestones require at least one of:
- a concrete adopter failure mode,
- a correctness/security/data-loss risk,
- a repeated support issue,
- or an explicit strategy change recorded in `.planning/PROJECT.md` / `.planning/STRATEGY.md`.

Stop rule: if proposed work is polish-only with a documented workaround and no release/adopter failure mode, record it as deferred with a revisit trigger and do not create a milestone for it.

## Phases

<details>
<summary>✅ v1.46 Maintenance & Closure (Phases 151-153) — SHIPPED 2026-05-30</summary>

- [x] Phase 151: Maintenance & Triage (3/3 plans) — completed 2026-05-30
- [x] Phase 152: Close v1.46 closure gaps: @since warnings, verification, Hex publish + tag (3/3 plans) — completed 2026-05-30
- [x] Phase 153: Close v1.46 audit trail: VERIFICATION.md for Phase 151, ROADMAP + REQUIREMENTS checkbox updates (2/2 plans) — completed 2026-05-30

Full details: [v1.46 roadmap archive](milestones/v1.46-ROADMAP.md)

</details>

<details>
<summary>✅ v1.47 ENT-10 Polish + Adopter-Proof Completeness (Phases 154-158) — SHIPPED 2026-05-31</summary>

- [x] Phase 154: Advisory Cache Core Correctness (1/1 plan) — completed 2026-05-31
- [x] Phase 155: StripeFixtures Polish + Telemetry Counters (1/1 plan) — completed 2026-05-31
- [x] Phase 156: Entitlements Gating Adopter Proof (1/1 plan) — completed 2026-05-31
- [x] Phase 157: Metered Usage Adopter Proof (1/1 plan) — completed 2026-05-31
- [x] Phase 158: Oban Cron Wiring Adopter Proof (1/1 plan) — completed 2026-05-31

Full details: [v1.47 roadmap archive](milestones/v1.47-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 151. Maintenance & Triage | v1.46 | 3/3 | Complete | 2026-05-30 |
| 152. Close v1.46 closure gaps | v1.46 | 3/3 | Complete | 2026-05-30 |
| 153. Close v1.46 audit trail | v1.46 | 2/2 | Complete | 2026-05-30 |
| 154. Advisory Cache Core Correctness | v1.47 | 1/1 | Complete | 2026-05-31 |
| 155. StripeFixtures Polish + Telemetry Counters | v1.47 | 1/1 | Complete | 2026-05-31 |
| 156. Entitlements Gating Adopter Proof | v1.47 | 1/1 | Complete | 2026-05-31 |
| 157. Metered Usage Adopter Proof | v1.47 | 1/1 | Complete | 2026-05-31 |
| 158. Oban Cron Wiring Adopter Proof | v1.47 | 1/1 | Complete | 2026-05-31 |

## Historical Backlog Anchors (not active scope)

These v1.17 FRG anchors are retained for traceability only. They should not create new milestone scope unless a fresh sourced friction row reopens them.

- [INT-10 Phase 63](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--int-10-phase-63) — Braintree/multi-processor integration; materially shipped across v1.31+ and reflected in the processor support matrix.
- [BIL-03 Phase 64](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--bil-03-phase-64) — Billing portal configuration; materially shipped via `accrue_portal`, guides, and host proof.
- [ADM-12 Phase 65](.planning/research/v1.17-FRICTION-INVENTORY.md#backlog--adm-12-phase-65) — Admin UI role-based access; reopen only for a concrete security/compliance requirement.
