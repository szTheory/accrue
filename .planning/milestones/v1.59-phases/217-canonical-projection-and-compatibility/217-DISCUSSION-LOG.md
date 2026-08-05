# Phase 217: Canonical projection and compatibility - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-02
**Phase:** 217-canonical-projection-and-compatibility
**Areas discussed:** Revisioned snapshot contract, cross-rail purchase eligibility, legacy compatibility cutover, provider-honest lifecycle dispatch

---

## Revisioned Snapshot Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Revisioned live projection from grants | One read-only host value folded from current effective grants; material access changes advance revision transactionally. | ✓ |
| Persisted denormalized snapshot cache | Store a snapshot row/blob for cheap reads, accepting invalidation and split-brain risk. | |
| Extend the legacy resolver | Make the existing resolver the multi-rail contract, without a distinct revisioned account object. | |
| Event-sourced observation replay | Reconstruct authorization from evidence delivery history. | |

**User's choice:** Asked for one coherent expert recommendation set and approved all recommendations.
**Notes:** The selected contract preserves current boolean/scalar gates, keeps reads side-effect free, makes one projector the sole revision writer, and rejects advisory caches or provider delivery order as authorization truth.

---

## Cross-Rail Purchase Eligibility

| Option | Description | Selected |
|--------|-------------|----------|
| Advisory eligibility query only | Return a preflight answer that hosts may ignore and that is not revision-rechecked at purchase time. | |
| Revision-bound typed decision | Return eligible/block/warn with stable reasons, recheck before purchase, and audit explicit overrides. | ✓ |
| Serializable purchase reservations | Add durable expiring reservations around purchase attempts, including client-owned Apple flows. | |

**User's choice:** Approved the recommended revision-bound decision contract.
**Notes:** Equivalence is the same logical plan on another live rail. Bare product IDs, feature overlap, price, quantity, email, customer rows, and device identity are not equivalence. No automatic cancellation, transfer, refund, migration, merge, or proration follows.

---

## Legacy Compatibility Cutover

| Option | Description | Selected |
|--------|-------------|----------|
| Permanent alternate resolver | Keep two long-lived entitlement authorities selected only by resolver configuration. | |
| One-shot global switch | Backfill and switch every account at once. | |
| Disabled → shadow → enabled | Backfill idempotently, compare semantic parity, enable by cohort, and retain non-destructive rollback. | ✓ |
| Per-request legacy fallback | Try canonical reads and silently fall back on mismatch or failure. | |

**User's choice:** Approved the recommended tri-state cutover.
**Notes:** Legacy behavior remains authoritative until explicit enablement. Mismatches block enablement and stay observable. Rollback changes authority only and preserves canonical evidence for repair.

---

## Provider-Honest Lifecycle Dispatch

| Option | Description | Selected |
|--------|-------------|----------|
| Global configured processor | Route every mutation through the process-global/default adapter. | |
| Separate provider APIs | Create independent Stripe and Apple public lifecycle contexts and require host branching. | |
| Persisted-resource dispatch with capability outcomes | Keep gateway facade ergonomics, choose the adapter from persisted provenance, and represent Apple management as actionable success. | ✓ |
| Caller-supplied rail | Let the caller select a rail for an already-persisted resource. | |

**User's choice:** Approved persisted-resource dispatch and typed capability outcomes.
**Notes:** Existing gateway lifecycle signatures and bang conventions remain. Apple grants never enter Stripe-shaped subscriptions or gateway mutations; externally managed is a successful guidance result, while unavailable/unknown/unauthorized states use typed errors.

---

## the agent's Discretion

- Exact module, function, struct, error, task, transaction-helper, outbox, and telemetry-event names.
- Deterministic public collection representation for snapshots.
- Host cohort expression, backfill chunk size, and retry cadence.
- Exact name of the rail-neutral management query.
- Internal adapter-registry representation, provided persisted provenance remains authoritative.

## Deferred Ideas

None. UI implementation, Apple observation/repair, offline proof, adopter release proof, and Google Play remain in their assigned later phases or seed.
