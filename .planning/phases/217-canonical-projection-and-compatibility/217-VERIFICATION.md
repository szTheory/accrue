---
phase: 217-canonical-projection-and-compatibility
verified: 2026-08-03T02:50:38Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 217: Canonical Projection and Compatibility Verification Report

**Phase Goal:** A host can make entitlement and purchase decisions from one revisioned account snapshot without changing legacy billing behavior or destroying survivor grants.
**Verified:** 2026-08-03T02:50:38Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Any live Stripe or Apple grant contributes to the deduplicated union of plans/features with maximum effective quantity. | ✓ VERIFIED | `Snapshot.from_grants/2` filters live persisted grants, folds mapped products into sorted `MapSet` collections, and uses integer `max/2`; snapshot/property tests exercise cross-rail union, duplicate dedupe, exact maxima, input permutation, and cutoff boundaries. |
| 2 | Revoking one rail preserves an equivalent survivor and duplicate/metadata-only evidence does not advance the revision. | ✓ VERIFIED | `Projector.project/2` locks the account `FOR UPDATE`, compares authorization signatures, has survivor-retraction handling, and returns no-op for stale/unqualified input. SQL-backed projector and property tests exercise survivor, duplicate, stale, quarantined, unmapped, idempotent, and concurrent paths. |
| 3 | Lifecycle actions use persisted resource provenance; Apple is externally managed and cannot enter Accrue-owned mutations. | ✓ VERIFIED | Subscription and item paths resolve `GatewayRegistry` from persisted subscription processor after scoping. `Billing.management(:apple)` returns the exact externally-managed outcome. Dispatch tests cover all 11 lifecycle/item facades, typed provenance errors, Apple guidance, and zero forbidden Fake adapter calls under repeat/concurrency. |
| 4 | Single-processor compatibility remains deterministic through opt-in shadow/parity/cutover, with safe backfill and non-destructive rollback. | ✓ VERIFIED | `Compatibility` retains `LocalMap` for omitted/disabled and shadow modes, requires approved cohort plus clean durable evidence before canonical enablement, backfills through `Projector`, and rollback only changes authority. Integration tests prove idempotent/concurrent backfill, advisory/provider isolation, blocker handling, and evidence-preserving rollback. |
| 5 | Equivalent other-rail purchases block by default; explicit revision-bound warning/override is safe and no automatic cross-rail mutation occurs. | ✓ VERIFIED | `PurchaseDecision` has closed `eligible|block|warn` outcomes based only on different-rail logical-plan sources; continuation rechecks current snapshot and uses durable operation/override capabilities. Tests cover first purchase, stale/tampered overrides, concurrent Apple completion, reconcile-first Stripe ambiguity, and zero cancel/refund/transfer/update calls. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact group | Expected | Status | Details |
| --- | --- | --- | --- |
| Snapshot/projector/public boundary | Canonical snapshot, sole serialized writer, pure read/provision APIs | ✓ VERIFIED | `snapshot.ex` (202 lines), `projector.ex` (233), and `entitlements.ex` (478) are substantive and exercised against PostgreSQL/Oban. |
| Purchase boundary | Typed preflight, durable operation and override, Stripe continuation | ✓ VERIFIED | `purchase_decision.ex` (509) is wired through `Entitlements` and `SubscriptionActions`; its focused integration suite passes. |
| Compatibility boundary | Resolver projection, three-state authority, durable comparison/state evidence | ✓ VERIFIED | `compatibility.ex` (618) calls real `LocalMap`, `Canonical`, repository queries, and `Projector`; `canonical.ex` translates database-backed snapshots into existing resolver shape. |
| Persisted dispatch boundary | Gateway registry, subscription/item routing, Apple management | ✓ VERIFIED | `gateway_registry.ex`, billing facades, action and item modules use persisted processor adapter resolution; resource-dispatch tests run the dispatch inventory. |
| Automated evidence | Snapshot, projector, property, decision, compatibility, and resource-dispatch tests | ✓ VERIFIED | All 18 plan-declared artifacts exist, are substantive, and are run by the focused phase gate below. |

### Key Link Verification

All 16 plan-declared key links verified by source-pattern query and manual trace: 5 in Plan 01, 2 in Plan 02, 3 in Plan 03, 3 in Plan 04, and 3 in Plan 05. In particular, the critical paths are `Projector → Snapshot → persisted Grant`, `Compatibility → Projector`, `PurchaseDecision → Snapshot/config → durable operation`, and existing-resource billing actions/items → `GatewayRegistry` using persisted processor provenance.

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `Snapshot` | plans/features/quantities/sources | `Grant` rows queried by account ID | Real repository query over current grants | ✓ FLOWING |
| `Projector` | before/after authorization snapshots and revision | Row-locked `Account`, persisted `Observation`/`Grant`, audit and Oban insert | Transactional PostgreSQL/Oban writes | ✓ FLOWING |
| Canonical resolver/compatibility | resolver entitlement map and parity evidence | Account lookup, `Snapshot.fetch/2`, `LocalMap.resolve/2`, persisted audit/state | Real database and legacy resolver reads | ✓ FLOWING |
| Purchase decision | snapshot revision and source summaries | Current canonical snapshot and qualified catalog | Real snapshot/config inputs; durable operation/override repository records | ✓ FLOWING |
| Resource dispatch | adapter selection | Scoped persisted subscription/item `processor` | Real persisted provenance; no global processor for existing-resource mutations | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| ACCT-01 through ACCT-05 executable contract | `cd accrue && mix test test/accrue/entitlements/snapshot_test.exs test/accrue/entitlements/projector_test.exs test/accrue/entitlements/decision_cases_test.exs test/accrue/entitlements/purchase_decision_test.exs test/accrue/entitlements/compatibility_test.exs test/accrue/billing/resource_dispatch_test.exs test/property/entitlement_projection_property_test.exs --exclude live_stripe` | 83 tests, 4 properties, 0 failures (current HEAD `4fc6f07f`) | ✓ PASS |
| Compilation | `cd accrue && mix compile --warnings-as-errors` | Exit 0 | ✓ PASS |
| Phase-owned formatting | `cd accrue && mix format --check-formatted` on all phase-owned production modules | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| ACCT-01 | 217-01, 217-02 | Canonical union/dedupe/maximum snapshot | ✓ SATISFIED | SQL snapshot/projector tests and four property tests pass. |
| ACCT-02 | 217-01, 217-02 | Survivor-safe retraction and revision idempotency | ✓ SATISFIED | Row-lock/signature implementation plus survivor, no-op, idempotency, and concurrency tests pass. |
| ACCT-03 | 217-05 | Persisted rail lifecycle dispatch and Apple isolation | ✓ SATISFIED | Resource dispatch inventory/guidance/negative-call tests pass. |
| ACCT-04 | 217-04 | Legacy parity, opt-in cutover, safe backfill/rollback | ✓ SATISFIED | Compatibility integration tests pass, including no provider/advisory mutation during concurrent backfill. |
| ACCT-05 | 217-03 | Safe cross-rail purchase eligibility and explicit override | ✓ SATISFIED | Purchase-decision tests pass, including default block and cross-rail no-mutation checks. |

All five requirement IDs mapped to Phase 217 are claimed by at least one plan; no orphaned Phase 217 requirement was found. `REQUIREMENTS.md` still displays ACCT-04 and ACCT-05 as pending in its tracking checklist, but that is planning-state metadata, not contrary implementation evidence.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`, `FIXME`, `XXX`, placeholder, or empty implementation marker found in the 18 plan-declared artifact files. | ℹ️ None | No auditable stub/debt blocker. |

### Disconfirmation Pass

The likely false-pass paths were checked directly: (1) source-only retraction is tested to keep the surviving Apple grant and revision; (2) exact logical-plan provenance tests prevent rail-wide over-blocking; (3) a concurrent Apple completion is tested to record diagnostic evidence while Fake lifecycle counters remain zero; and (4) concurrent backfill tests preserve byte-identical legacy customer/subscription/advisory records with no provider calls. No uncovered blocker was demonstrated.

### Human Verification Required

None. This is an explicitly `backend-zero-human` phase, and every behavior-dependent roadmap truth has executable focused test evidence.

### Gaps Summary

None. No later-phase deferral analysis was required because no implementation gap was found.

---

_Verified: 2026-08-03T02:50:38Z_
_Verifier: the agent (gsd-verifier)_
