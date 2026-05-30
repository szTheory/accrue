# Phase 154: Advisory Cache Core Correctness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-30
**Phase:** 154-Advisory-Cache-Core-Correctness
**Areas discussed:** Stale skip signal path (ADV-03), livemode carry-forward scope (POL-02)

---

## Stale skip signal path (ADV-03)

Research surfaced a critical implementation detail: Ecto returns `{:error, :stale}` (not `{:ok, existing_row}`) when `INSERT ... ON CONFLICT DO UPDATE WHERE <ts_guard>` fires and 0 rows are updated — because PostgreSQL's `RETURNING` emits nothing for a no-op conflict branch.

| Option | Description | Selected |
|--------|-------------|----------|
| A: Convert internally | `upsert_entitlement_summary/2` catches `{:error, :stale}` from `Repo.insert` and returns `{:ok, :stale}`. Caller adds one case branch: stale → emit `result: :unchanged` telemetry + return early, no ledger write. | ✓ |
| B: Propagate to caller | Let `{:error, :stale}` bubble up; caller restructures `with` into `case`. Risks Oban treating unhandled `{:error, :stale}` as a retryable failure. | |

**User's choice:** A — Convert internally (recommended)
**Notes:** Keeps Ecto adapter detail internal to the upsert function. Caller's `with` chain becomes a `case` only for the stale branch, not a full restructure.

---

## livemode carry-forward scope (POL-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A: Nil-check sufficiency | Carry prior row's `livemode` forward whenever `get(obj, :livemode)` returns nil. Treats absent key and explicit nil identically — correct per Stripe's wire format (livemode is always a boolean on valid payloads). Mirrors `stamp_summary_watermark/4` pattern. | ✓ |
| B: Explicit key-presence check | Add `has_livemode_key?/1` helper; carry forward only on true key absence. Semantically precise but over-engineers a distinction that doesn't exist in Stripe's wire format. | |

**User's choice:** A — Nil-check sufficiency (recommended)
**Notes:** Simpler and equally correct. The nil-vs-absent distinction is a non-issue in Stripe's contract.

---

## Claude's Discretion

- All other implementation decisions (ADV-01, ADV-02, ADV-04, POL-01) were pre-locked in REQUIREMENTS.md + research artifacts before discussion. No user input needed — planner can proceed directly from CONTEXT.md.
- Concurrent test sandbox strategy (`Sandbox.allow/3` vs `:shared` mode) — specified in ADV-04 requirement, not re-discussed.

## Deferred Ideas

- IN-03 (StripeFixtures `:omit_livemode` + moduledoc polish) → Phase 155
- IN-04 (Telemetry Metrics counters) → Phase 155
