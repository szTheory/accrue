---
phase: 127-optional-stripe-native-sync-isolated-off-by-default
plan: 02
subsystem: webhooks
tags: [entitlements, stripe, webhooks, telemetry, ledger, ecto, tdd]

# Dependency graph
requires:
  - phase: 127-01
    provides: "accrue_entitlement_summaries schema + force_changeset/2; stripe_native_sync config enum + stripe_native_sync?/0 accessor; entitlement_summary_event/2 fixture; 3 RED test scaffolds tagged :pending_plan_02"
provides:
  - "Config-gated entitlements.active_entitlement_summary.updated dispatch clause in DefaultHandler (off lane DB-free, byte-for-byte Phase-126 behavior)"
  - "reduce_entitlement_summary/3 monotonic-snapshot reducer: skip-stale (reuses check_stale/2 + stamp_watermark/3), orphan/malformed tolerance, truncation honesty, [:accrue, :entitlements, :sync] span + summary_synced event + entitlement_summary_truncated ops"
  - "On-change-only accrue_events ledger (entitlements.summary.synced, idempotency-keyed, IDs/counts only)"
  - "Accrue.Entitlements.StripeSync.summary_for_customer/1 read-only observational seam (one-way seam->billing, gate path cache-free)"
affects: [127-03-isolation-gate, entitlements, webhooks, telemetry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Monotonic-snapshot reducer (not refetch-canonical): lattice_stripe 1.1 has no Entitlements list API, so ordering is enforced via check_stale/2 on the event watermark rather than an API round-trip"
    - "On-change-only ledger: material change = sorted {feature_id, lookup_key} pairs OR truncated differs; first-ever write material; byte-identical re-delivery -> result: :unchanged telemetry, no ledger row"
    - "Observational-only advisory cache wired through a one-way read seam; gate path statically cache-free"

key-files:
  created:
    - accrue/lib/accrue/entitlements/stripe_sync.ex
  modified:
    - accrue/lib/accrue/webhook/default_handler.ex
    - accrue/test/test_helper.exs
    - accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs
    - accrue/test/support/telemetry_ops_inventory.ex
    - accrue/lib/accrue/telemetry/metrics.ex
    - accrue/guides/telemetry.md

key-decisions:
  - "Reducer lives as a private clause/helper set in default_handler.ex (D-Discretion), not a delegated module — keeps the monotonic-snapshot guard reuse (check_stale/2, stamp_watermark/3, dual get/2, record_event/5) in one file; ConnectHandler-style comment documents WHY snapshot not refetch"
  - "StripeSync is a dedicated new module (D-Discretion) rather than a sibling fn in Admin — keeps the observational cache seam separate from the resolver-drift diagnostic seam"
  - "Material-change comparison reads the existing row's stored set from row.data['entitlements']['data'] via the dual get/2 and compares sorted {feature, lookup_key} pairs + truncated; never deserializes the raw payload into the ledger"
  - "New [:accrue, :ops, :entitlement_summary_truncated] event registered in the ops inventory + metrics defaults/0 + guides/telemetry.md (two merge-blocking contract gates)"

patterns-established:
  - "Config-gated webhook dispatch clause: runtime gate (stripe_native_sync?/0) checked FIRST, off lane early-returns {:ok, :ignored} before any Repo call"
  - "summary_material_change?/3 + entitlement_pairs/1: idempotent on-change ledger comparison tolerant of nil/non-list/missing-key payloads"

requirements-completed: [ENT-10]

# Metrics
duration: 6min
completed: 2026-05-24
---

# Phase 127 Plan 02: Config-gated entitlement-summary reducer + read-only seam Summary

**The heart of ENT-10: a config-gated, off-by-default webhook reducer that writes the advisory entitlement-summary cache with monotonic ordering, on-change-only ledgering, full span/event/ops telemetry, and orphan/malformed tolerance — plus a one-way read seam that exposes the cache without ever touching the gate path. Turns all three Plan 01 RED scaffolds GREEN.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-24T12:07:54Z
- **Completed:** 2026-05-24T12:13:37Z
- **Tasks:** 2 (+ 1 deviation fix)
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments

- **Config-gated dispatch clause (D-04 layer 1):** `dispatch("entitlements.active_entitlement_summary.updated", ...)` checks `Accrue.Config.stripe_native_sync?/0` FIRST and early-returns `{:ok, :ignored}` BEFORE any `Repo` call on the off lane — the disabled default is provably DB-free (proven by the runtime zero-cache-read isolation test).
- **Monotonic-snapshot reducer (D-06):** `reduce_entitlement_summary/3` reuses `check_stale/2` and `stamp_watermark/3` verbatim — `:lt` skips with `[:accrue, :webhooks, :stale_event]` (`object_type: :entitlement_summary`), `:eq`/`:gt` proceed. The ConnectHandler-style comment documents why this path uses monotonic-snapshot (no `lattice_stripe` 1.1 Entitlements list API) instead of refetch-canonical. The monotonic property test proves the final cache row always equals the highest-ts snapshot regardless of delivery order.
- **Orphan/malformed tolerance (D-06):** customer-not-found clones the `orphan_charge` pattern → `[:accrue, :webhooks, :orphan_entitlement_summary]` + `{:ok, :deferred}` (never raises, never creates a customer); missing `customer` / non-list `entitlements.data` → `{:ok, :ignored}` with no garbage write.
- **Truncation honesty (D-07):** `truncated <- entitlements.has_more`; `[:accrue, :ops, :entitlement_summary_truncated]` fires only when `has_more: true`.
- **Telemetry (D-09):** the write is wrapped in a `[:accrue, :entitlements, :sync]` span (mirroring the `:check` span); `[:accrue, :entitlements, :summary_synced]` emits `result: :written | :unchanged`. The OTel `@allowed_attributes` allowlist was NOT widened.
- **On-change-only ledger (D-08):** an `accrue_events` row (`entitlements.summary.synced`, `idempotency_key: "entitlements.summary.synced:" <> evt_id`, IDs/counts only) is appended ONLY on material change (sorted `{feature_id, lookup_key}` pairs OR `truncated` differs; first write = material). Byte-identical re-delivery emits `result: :unchanged` and writes no ledger row; stale/orphan/malformed write no ledger row.
- **Read-only seam (D-11):** `Accrue.Entitlements.StripeSync.summary_for_customer/1` exposes the cached row one-way (seam → billing read), `@doc false`, with a moduledoc declaring the observational-only / gate-path-MUST-NOT-reference contract. Gate-path purity verified: 0 `EntitlementSummary`/`StripeSync` references in `entitlements.ex`, `resolver.ex`, `local_map.ex`.
- Removed the `:pending_plan_02` exclusion from `test_helper.exs` — the three Wave 0 scaffolds now run in the default suite.

## Task Commits

Each task was committed atomically:

1. **Task 1: Config-gated dispatch clause + monotonic reducer (D-04/06/07/09)** - `ee38cfb` (feat)
2. **Task 2: On-change-only ledger (D-08) + read-only StripeSync seam (D-11)** - `759a7c2` (feat)
3. **Deviation: register entitlement_summary_truncated ops event** - `aa8f238` (chore — Rule 3)

**Plan metadata:** (final docs commit — this SUMMARY + STATE/ROADMAP/REQUIREMENTS)

_Note on TDD shape: this is a TDD plan whose RED scaffolds were checked in by Plan 01 (3 files tagged `:pending_plan_02`). The RED state was confirmed before implementation (the orphan-customer case returned `{:ok, :ignored}` via the catch-all). Task 1 turned the integration write/stale/tie/orphan/malformed/truncated + monotonic property GREEN; Task 2 added the ledger + seam (no scaffold directly asserts those — they are source-grep/gate-purity acceptance criteria) and turned the isolation scaffold GREEN. So the cycle was RED (pre-existing) → GREEN (feat commits), with no separate `test(...)` commit this plan since the failing tests already existed on disk._

## Files Created/Modified

- `accrue/lib/accrue/entitlements/stripe_sync.ex` (created) — read-only observational seam `summary_for_customer/1`, one-way `seam → billing`, `@doc false`, observational-only moduledoc.
- `accrue/lib/accrue/webhook/default_handler.ex` (modified) — `EntitlementSummary` alias; config-gated dispatch clause; `reduce_entitlement_summary/3` + helpers (`reduce_entitlement_summary_for_customer/6`, `write_entitlement_summary/8`, `upsert_entitlement_summary/2`, `maybe_record_summary_event/3`, `summary_material_change?/3`, `entitlement_pairs/1`, `synced_at_from_event/1`, `emit_summary_malformed/2`).
- `accrue/test/test_helper.exs` (modified) — removed `:pending_plan_02` from the default exclude list.
- `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` (modified) — corrected the surface-parity seat assertion to the canonical `min(cap, item.quantity) == 1` (Rule 1).
- `accrue/test/support/telemetry_ops_inventory.ex` (modified) — added `[:accrue, :ops, :entitlement_summary_truncated]` to `expected_ops_events/0`.
- `accrue/lib/accrue/telemetry/metrics.ex` (modified) — added `counter("accrue.ops.entitlement_summary_truncated.count")` to `defaults/0`.
- `accrue/guides/telemetry.md` (modified) — added the new ops event to the event-reference table and the operator-remediation table.

## Decisions Made

- **Reducer in `default_handler.ex` (not a delegated module)** (D-Discretion): keeps the verbatim reuse of `check_stale/2`, `stamp_watermark/3`, dual `get/2`, and `record_event/5` in one file alongside the other reducers. A ConnectHandler-style comment block documents the monotonic-snapshot rationale (no `lattice_stripe` 1.1 Entitlements list API to refetch).
- **`Accrue.Entitlements.StripeSync` dedicated module** (D-Discretion): separates the observational advisory-cache seam from `Accrue.Entitlements.Admin` (the resolver-drift diagnostic), each with its own one-way moduledoc stance.
- **Material-change reads the prior set from `row.data`**: `summary_material_change?/3` extracts `row.data["entitlements"]["data"]` via the dual `get/2` and compares sorted `{feature, lookup_key}` pairs plus `truncated`; the ledger `data` itself never carries the raw payload (V7).
- **New ops event fully registered**: `[:accrue, :ops, :entitlement_summary_truncated]` added to the ops inventory, the metrics `defaults/0` counter list, and both `guides/telemetry.md` tables to satisfy the two merge-blocking contract gates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the isolation surface-parity seat assertion**
- **Found during:** Task 2 (after removing the `:pending_plan_02` exclusion, the isolation scaffold ran in the default suite).
- **Issue:** `stripe_sync_disabled_isolation_test.exs` asserted `Accrue.entitlement_quantity(billable, :seats) == 5`, but the factory subscription has the default item `quantity: 1`. The canonical Phase-126 SSOT (`local_map.ex` `merge_plan/5`, confirmed by `local_map_test.exs:73`) resolves `quantities[quota_key] = min(cap, item.quantity) = min(5, 1) = 1`. The scaffold conflated the configured `seats` cap with the resolved quantity.
- **Fix:** changed the assertion to `== 1` with a comment pointing at the canonical `min(cap, quantity)` semantics, preserving the test's "byte-for-byte Phase-126 surface" intent.
- **Files modified:** `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs`
- **Commit:** `759a7c2`

**2. [Rule 3 - Blocking] Registered the new ops event across the contract gates**
- **Found during:** full-suite regression after Task 2.
- **Issue:** the new `[:accrue, :ops, :entitlement_summary_truncated]` emit tripped two merge-blocking contract tests: `OpsEventContractTest` (every ops literal in `lib/` must be in `TelemetryOpsInventory.expected_ops_events/0` and documented in `guides/telemetry.md`) and `MetricsOpsParityTest` (every canonical ops tuple needs a `defaults/0` metric).
- **Fix:** added the tuple to the ops inventory, a `counter(...)` to `Accrue.Telemetry.Metrics.defaults/0`, and entries to both `guides/telemetry.md` tables.
- **Files modified:** `accrue/test/support/telemetry_ops_inventory.ex`, `accrue/lib/accrue/telemetry/metrics.ex`, `accrue/guides/telemetry.md`
- **Commit:** `aa8f238`

## Authentication Gates

None — no external service authentication was required.

## Known Stubs

None — the reducer and seam are fully wired; the advisory cache is written, ledgered, telemetered, and exposed. The cache being observational-only (never gate-consulted) is the locked D-01 design, not a stub; full pagination of >10 entitlements is the documented `lattice_stripe >= 1.2` deferral (carried in the project Deferred Items), surfaced honestly via `truncated` + the truncation ops event.

## Threat Flags

None — no new network endpoints, auth paths, file-access patterns, or trust-boundary schema changes beyond the threat register. The webhook trust boundary (untrusted snapshot → cache) and the read-seam → gate-path boundary are both mitigated as planned (monotonic skip-stale, defensive extraction, observational-only seam with a clean gate-path grep).

## Issues Encountered

- **Library has no `:repo` outside `:test` env** (carried from Plan 01): all `mix test` / verify commands run under `MIX_ENV=test`. Not a defect — a pre-existing property of the library.
- **Full default suite now includes the scaffolds:** test count moved from the Plan-01 baseline (1462) to 1475 (+11 scaffold tests + the property + isolation tests). Full suite green at `--seed 0`: 1475 tests, 50 properties, 0 failures (11 excluded = live_stripe/slow/compile_matrix).

## Next Phase Readiness

- **Plan 03 (isolation static gate) is unblocked:** the cache write path (`reduce_entitlement_summary/3`), the read seam (`Accrue.Entitlements.StripeSync`), and the `EntitlementSummary` schema all exist; the gate path is already cache-free (grep returns 0), so `scripts/ci/verify_entitlement_sync_isolation.sh` (Plan 03's static twin of the runtime isolation proof) will pass against this state.
- No blockers.

## Self-Check: PASSED

- Created file `accrue/lib/accrue/entitlements/stripe_sync.ex` exists on disk.
- All 3 task commits exist in git history (`ee38cfb`, `759a7c2`, `aa8f238`).
- `MIX_ENV=test mix compile --warnings-as-errors` clean; the integration test (8/0), the monotonic property (1/0), and the isolation test (2/0) are GREEN; full accrue suite green at `--seed 0` (1475 tests / 50 properties / 0 failures); `credo --strict` on the modified lib files found no issues; the OTel `@allowed_attributes` allowlist is unchanged (`git diff --stat` empty); gate-path purity grep returns 0 across `entitlements.ex` / `resolver.ex` / `local_map.ex`.

---
*Phase: 127-optional-stripe-native-sync-isolated-off-by-default*
*Completed: 2026-05-24*
