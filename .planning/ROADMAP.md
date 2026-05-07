# Roadmap: Accrue

## Active Milestone

### v1.36 — Dual-Provider Core Completion

**Status:** Complete 2026-05-07  
**Phases:** 112-114  
**Requirements:** PROC-21..PROC-24  
**Strategic parent:** [STRATEGY.md](STRATEGY.md)

**Milestone goal:** Close the remaining staged rows in the official Stripe + Braintree gateway-subscription-core contract so the shipped support surface is fully consistent, merge-blocking, and no longer half-staged.

**Requirements:** See [REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md).

| # | Phase | Goal | Requirements | Success Criteria |
|---|-------|------|--------------|------------------|
| 112 | Customer Update Contract Closure | Complete 2026-05-07: `Accrue.Billing.update_customer/2` is now fully first-party across capability labels, adapter truth, facade semantics, deterministic proof, and host-facing usage. | PROC-21 | 4 |
| 113 | Cancellation Semantics Closure | Complete 2026-05-07 (`113-01` through `113-03` complete); verification artifact backfill required before archive. | PROC-22, PROC-23 | 5 |
| 114 | Contract Drift Gate Closeout | Complete 2026-05-07 (`114-01` through `114-03` complete); verification artifact backfill required before archive. | PROC-24 | 4 |
| 115 | Phase 113 Verification Backfill | Create the missing Phase 113 verification artifact so the shipped cancellation semantics evidence satisfies the milestone audit chain. | PROC-22, PROC-23 | 3 |
| 116 | Phase 114 Verification Backfill | Create the missing Phase 114 verification artifact so the support-contract closeout evidence satisfies the milestone audit chain. | PROC-24 | 3 |

### Phase 112: Customer Update Contract Closure

**Status:** Complete 2026-05-07
**Goal:** Make `Accrue.Billing.update_customer/2` an explicit first-party row instead of a staged holdover.

**Success criteria:**
1. Runtime capability labels no longer describe customer update as staged.
2. Stripe, Fake, and Braintree adapter truth for customer update matches the public contract.
3. `Accrue.Billing.update_customer/2` preserves customer projection and event semantics across the supported processors.
4. Deterministic tests and host-facing proof cover the promoted row.

**Outcome:** Completed in three waves with a passed verification report at [112-VERIFICATION.md](/Users/jon/projects/accrue/.planning/phases/112-customer-update-contract-closure/112-VERIFICATION.md). The billing facade is now a bounded remote write-through contract, `customer.update` is `all first-party` in runtime and planning mirrors, and the example host plus installer template expose the same provider-neutral helper.

### Phase 113: Cancellation Semantics Closure

**Status:** Complete 2026-05-07 (`113-01` through `113-03` complete)
**Goal:** Make the shipped cancellation story coherent across facade verbs, capability labels, and Braintree-specific limits.

**Success criteria:**
1. The public contract distinguishes supported immediate cancellation from unsupported or deferred lifecycle mutations without parity theater.
2. Capability labels for `cancel`, `cancel_immediately`, and `cancel_at_period_end` match actual adapter behavior.
3. Braintree cancellation proof covers the supported path through the generic billing facade.
4. Unsupported lifecycle branches fail with explicit, typed semantics instead of ambiguous staging language.
5. Docs and tests use the same cancellation terminology as the runtime contract.

### Phase 114: Contract Drift Gate Closeout

**Status:** Complete 2026-05-07 (`114-01` through `114-03` complete)
**Goal:** Finish the milestone by making the finalized dual-provider core contract the only truth across planning mirrors, docs, and verifier gates.

**Success criteria:**
1. `.planning/processor-support-matrix.md` matches the runtime capability map with no staged leftovers for shipped rows.
2. Public docs and example-host proof artifacts repeat the same closure contract.
3. Merge-blocking tests or scripts fail if staged-vs-first-party drift reappears.
4. `REQUIREMENTS.md`, `ROADMAP.md`, and `STATE.md` all reflect the active milestone cleanly.

**Outcome:** Completed in three waves. The processor support matrix is now the settled canonical wording spine, package docs and example-host proof stay thin and provider-honest, and the named support-contract bundle (`verify_processor_support_matrix.sh`, `verify_package_docs.sh`, `verify_verify01_readme_contract.sh`, `verify_adoption_proof_matrix.sh`) is documented and merge-blocking before milestone closeout.

### Phase 115: Phase 113 Verification Backfill

**Status:** Planned 2026-05-07
**Goal:** Restore the missing Phase 113 verification artifact so `PROC-22` and `PROC-23` are represented in the audit-required verification chain.

**Success criteria:**
1. `113-VERIFICATION.md` exists and explicitly traces `PROC-22` and `PROC-23`.
2. The verification artifact cites the already-green cancellation, portal, admin, and host proof lanes accurately.
3. The milestone audit no longer reports Phase 113 requirements as orphaned.

**Gap closure:** Closes the `PROC-22` and `PROC-23` audit gaps caused solely by the missing Phase 113 verification report.

### Phase 116: Phase 114 Verification Backfill

**Status:** Planned 2026-05-07
**Goal:** Restore the missing Phase 114 verification artifact so `PROC-24` is represented in the audit-required verification chain.

**Success criteria:**
1. `114-VERIFICATION.md` exists and explicitly traces `PROC-24`.
2. The verification artifact cites the green support-contract verifier bundle and host-proof evidence accurately.
3. The milestone audit no longer reports Phase 114 requirements as orphaned.

**Gap closure:** Closes the `PROC-24` audit gap caused solely by the missing Phase 114 verification report.

## Recent Milestones

- ✅ **v1.35 Dual-Provider Supportability Closure** — Phases **109–111** shipped **2026-05-07**. Provider-honest support contract mirrors, lifecycle semantics SSOT, and Braintree webhook/operator recovery proof. Archives: [milestones/v1.35-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-ROADMAP.md), [milestones/v1.35-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.35-REQUIREMENTS.md).
- ✅ **v1.34 Rendro Native Invoice PDF Default** — Phases **106–108** shipped **2026-05-06**. Rendro default invoice path, explicit Chromic compatibility path, and Hex-backed release proof. Archives: [milestones/v1.34-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-ROADMAP.md), [milestones/v1.34-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.34-REQUIREMENTS.md).
- ✅ **v1.33 Braintree Full Maturity** — Phases **101–104** shipped **2026-05-06**. Braintree local checkout/portal, discount mapping, local metering, and explicit Hyperwallet no-go boundary. Archives: [milestones/v1.33-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.33-ROADMAP.md), [milestones/v1.33-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.33-REQUIREMENTS.md).
- ✅ **v1.32 Braintree Production Parity** — Phases **97–100** shipped **2026-05-01**. Advanced subscription lifecycle, payment-method CRUD, refunds/invoice parity, and billing-portal semantics. Archives: [milestones/v1.32-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-ROADMAP.md), [milestones/v1.32-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.32-REQUIREMENTS.md).
- ✅ **v1.31 PROC-08 Phase 1: boundary hardening + thin slice** — Phases **94–96** shipped **2026-04-29**. Strategy lock, processor conformance harness, and the initial Braintree thin slice. Archives: [milestones/v1.31-ROADMAP.md](/Users/jon/projects/accrue/.planning/milestones/v1.31-ROADMAP.md), [milestones/v1.31-REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/milestones/v1.31-REQUIREMENTS.md).

## Notes

- Phase numbering now continues through the audit-closeout follow-up phases, so the next unused planning phase starts at **117**.
- `FIN-03`, Hyperwallet reopening, advanced scheduling, preview/proration parity, and broader processor expansion remain out of scope for this milestone.
- Earlier shipped phase detail remains preserved in per-milestone archives under `.planning/milestones/`.

---
*Last updated: 2026-05-07 — audit gaps planned as Phases **115-116** before **v1.36** archival.
