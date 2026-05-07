# Roadmap: Accrue

## Active Milestone

### v1.36 — Dual-Provider Core Completion

**Status:** Proposed 2026-05-06  
**Phases:** 112-114  
**Requirements:** PROC-21..PROC-24  
**Strategic parent:** [STRATEGY.md](STRATEGY.md)

**Milestone goal:** Close the remaining staged rows in the official Stripe + Braintree gateway-subscription-core contract so the shipped support surface is fully consistent, merge-blocking, and no longer half-staged.

**Requirements:** See [REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md).

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 112 | Customer Update Contract Closure | Promote `Accrue.Billing.update_customer/2` from staged to fully first-party across capability labels, adapter truth, facade semantics, and deterministic proof. | PROC-21 | 4 |
| 113 | Cancellation Semantics Closure | Normalize the shipped Stripe/Fake/Braintree cancellation surface and capability labels so immediate cancel vs end-of-period cancel are explicit, truthful, and bounded. | PROC-22, PROC-23 | 5 |
| 114 | Contract Drift Gate Closeout | Align the processor support matrix, public docs, example-host proofs, and merge-blocking verifiers to the finalized dual-provider core contract. | PROC-24 | 4 |

### Phase 112: Customer Update Contract Closure

**Goal:** Make `Accrue.Billing.update_customer/2` an explicit first-party row instead of a staged holdover.

**Success criteria:**
1. Runtime capability labels no longer describe customer update as staged.
2. Stripe, Fake, and Braintree adapter truth for customer update matches the public contract.
3. `Accrue.Billing.update_customer/2` preserves customer projection and event semantics across the supported processors.
4. Deterministic tests and host-facing proof cover the promoted row.

### Phase 113: Cancellation Semantics Closure

**Goal:** Make the shipped cancellation story coherent across facade verbs, capability labels, and Braintree-specific limits.

**Success criteria:**
1. The public contract distinguishes supported immediate cancellation from unsupported or deferred lifecycle mutations without parity theater.
2. Capability labels for `cancel`, `cancel_immediately`, and `cancel_at_period_end` match actual adapter behavior.
3. Braintree cancellation proof covers the supported path through the generic billing facade.
4. Unsupported lifecycle branches fail with explicit, typed semantics instead of ambiguous staging language.
5. Docs and tests use the same cancellation terminology as the runtime contract.

### Phase 114: Contract Drift Gate Closeout

**Goal:** Finish the milestone by making the finalized dual-provider core contract the only truth across planning mirrors, docs, and verifier gates.

**Success criteria:**
1. `.planning/processor-support-matrix.md` matches the runtime capability map with no staged leftovers for shipped rows.
2. Public docs and example-host proof artifacts repeat the same closure contract.
3. Merge-blocking tests or scripts fail if staged-vs-first-party drift reappears.
4. `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` all reflect the active milestone cleanly.

## Recent Milestones

- ✅ **v1.35 Dual-Provider Supportability Closure** — Phases **109–111** shipped **2026-05-07**. Provider-honest support contract mirrors, lifecycle semantics SSOT, and Braintree webhook/operator recovery proof. Archives: [milestones/v1.35-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-REQUIREMENTS.md).
- ✅ **v1.34 Rendro Native Invoice PDF Default** — Phases **106–108** shipped **2026-05-06**. Rendro default invoice path, explicit Chromic compatibility path, and Hex-backed release proof. Archives: [milestones/v1.34-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-ROADMAP.md), [milestones/v1.34-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-REQUIREMENTS.md).
- ✅ **v1.33 Braintree Full Maturity** — Phases **101–104** shipped **2026-05-06**. Braintree local checkout/portal, discount mapping, local metering, and explicit Hyperwallet no-go boundary. Archives: [milestones/v1.33-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.33-ROADMAP.md), [milestones/v1.33-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.33-REQUIREMENTS.md).
- ✅ **v1.32 Braintree Production Parity** — Phases **97–100** shipped **2026-05-01**. Advanced subscription lifecycle, payment-method CRUD, refunds/invoice parity, and billing-portal semantics. Archives: [milestones/v1.32-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-ROADMAP.md), [milestones/v1.32-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-REQUIREMENTS.md).
- ✅ **v1.31 PROC-08 Phase 1: boundary hardening + thin slice** — Phases **94–96** shipped **2026-04-29**. Strategy lock, processor conformance harness, and the initial Braintree thin slice. Archives: [milestones/v1.31-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.31-ROADMAP.md), [milestones/v1.31-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.31-REQUIREMENTS.md).

## Notes

- Phase numbering continues from v1.35, so the next planning phase starts at **112**.
- `FIN-03`, Hyperwallet reopening, advanced scheduling, preview/proration parity, and broader processor expansion remain out of scope for this milestone.
- Earlier shipped phase detail remains preserved in per-milestone archives under `.planning/milestones/`.

---
*Last updated: 2026-05-06 — opened **v1.36** to close the remaining staged rows in the dual-provider core contract.*
