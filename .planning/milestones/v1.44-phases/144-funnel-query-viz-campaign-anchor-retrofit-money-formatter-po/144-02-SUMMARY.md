---
phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-po
plan: 02
subsystem: webhook
tags: [webhook, dunning, ledger, retrofit, event-payload, campaign-anchor, DAN-02]

# Dependency graph
requires:
  - phase: 143
    provides: "Initial dunning.recovered / dunning.exhausted MRR snapshot ledger payloads (Accrue.Webhook.DefaultHandler emission sites + Events.record + Events.record_multi)"
  - phase: 144-01
    provides: "Accrue.Analytics.Dunning.funnel/1 with COALESCE(?->>'campaign_anchor', '__legacy__') sentinel grouping (DAN-01) — this plan's retrofit is the corresponding write-path forward-fix consumed by the funnel"
provides:
  - "dunning.exhausted event payloads now carry data.campaign_anchor as ISO-8601 string (or nil for Stripe-native non-Accrue dunning paths)"
  - "dunning.recovered event payloads now carry data.campaign_anchor as the ISO-8601 string of the anchor that was just cleared"
  - "Emission-boundary test coverage at both retrofit sites (closes Phase 143 emission-boundary test coverage gap noted in 143-VERIFICATION.md §Notes #1)"
  - "Defensive case-pattern on row.dunning_campaign_started_at at the exhausted edge — no nil.year KeyError on Stripe-native immediate-cancel paths"
  - "Ecto.Multi atomicity invariant preserved at the recovered edge (clear_anchor + Events.record_multi still in one transaction)"
affects: [Phase 144-03 FunnelChart, Phase 144-04 RecoveryLive, Phase 145 window selector, Phase 146 at-risk drill-down, Phase 148 BREAKING widening + recovery_rate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Asymmetric event-payload retrofit: defensive `case row.field do %DateTime{} = dt -> DateTime.to_iso8601(dt); _ -> nil end` where field may be nil (exhausted edge); reuse already-in-scope iso_anchor binding where the with-clause guarantees non-nil (recovered edge)"
    - "Emission-boundary test extension: assert `is_binary(ledger.data[key])` + `DateTime.from_iso8601/1` round-trip + exact-string match against the original DateTime — pattern usable for any future ISO-8601-string event payload field"

key-files:
  created: []
  modified:
    - "accrue/lib/accrue/webhook/default_handler.ex"
    - "accrue/test/accrue/webhook/dunning_exhaustion_test.exs"
    - "accrue/test/accrue/webhook/dunning_campaign_keying_test.exs"

key-decisions:
  - "Defensive `case` on row.dunning_campaign_started_at at the exhausted edge (NOT bare DateTime.to_iso8601/1) — Subscription.dunning_sweepable?/1 only checks status: :past_due, so a Stripe-native past_due → canceled/unpaid transition can hit the exhausted-write site with a nil anchor. Bare DateTime.to_iso8601(nil) raises KeyError on `nil.year`."
  - "Reuse the already-in-scope iso_anchor binding (line 884) at the recovered edge — the enclosing `with %DateTime{} = anchor <- row.dunning_campaign_started_at` clause guarantees non-nil at that lexical point. No recompute, no defensive case."
  - "Atomic Ecto.Multi shape preserved at the recovered edge — campaign_anchor is appended to the existing data map; clear_anchor + dunning_recovered_event remain in the same Multi. The retrofit is a payload-only widening, not a transaction-shape change."
  - "Closes Phase 143 emission-boundary test coverage gap (143-VERIFICATION.md §Notes #1) by extending existing DUN-08 observability describe blocks rather than creating new files — co-locates the new assertions with the existing assertions on `source` / `to_status`."

patterns-established:
  - "Asymmetric retrofit-by-site: identify whether the existing local binding satisfies non-nil precondition for the new field — if so, append one map key; if not, compute defensively before the call site. Documented inline at both sites with comment blocks explaining the rationale (Stripe-native vs Accrue-set dunning paths)."

requirements-completed: [DAN-02]

# Metrics
duration: 6min
completed: 2026-05-27
---

# Phase 144 Plan 02: Campaign-anchor retrofit on dunning.recovered / dunning.exhausted (DAN-02) Summary

**Snapshotted campaign_anchor as ISO-8601 string onto both dunning lifecycle event payloads at their emission sites — the forward-fix DAN-01's DISTINCT-`(subject_id, campaign_anchor)` funnel needs to avoid double-counting cycled dunning.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-27T16:32:10Z (Plan 01 close)
- **Completed:** 2026-05-27T16:38:00Z
- **Tasks:** 2 (both TDD: RED → GREEN)
- **Files modified:** 3 (1 source, 2 tests)

## Accomplishments

- **Exhausted-edge retrofit (line ~794):** Added defensive `iso_anchor = case row.dunning_campaign_started_at do %DateTime{} = dt -> DateTime.to_iso8601(dt); _ -> nil end` block before the `Events.record/1` call inside `maybe_emit_dunning_exhaustion/3`. Appended `campaign_anchor: iso_anchor` to the data map. Handles both anchored (Accrue-driven dunning) and nil-anchored (Stripe-native immediate-cancel) cases without raising.
- **Recovered-edge retrofit (line ~894):** Single-line append `campaign_anchor: iso_anchor` to the `Events.record_multi/3` data map inside `maybe_finalize_dunning_campaign/3`'s recovery branch. Reuses the existing `iso_anchor` binding at line 884 — no recompute. Atomic Ecto.Multi shape (clear_anchor + dunning_recovered_event in one transaction) preserved.
- **Three new emission-boundary assertions:**
  1. `dunning_exhaustion_test.exs` — "records campaign_anchor when an anchor was set (DAN-02)": asserts `is_binary` + `DateTime.from_iso8601/1` round-trip + exact-string match to `DateTime.to_iso8601(anchor)`.
  2. `dunning_exhaustion_test.exs` — "records campaign_anchor: nil when no anchor was set (Stripe-native path; DAN-02)": asserts `is_nil(ledger.data["campaign_anchor"])` AND the handler does not raise on the defensive branch.
  3. `dunning_campaign_keying_test.exs` — extended the existing "the past_due→active recovery records a ledger event AND fires telemetry" test with `is_binary` + ISO-8601 round-trip + exact-string match + Ecto.Multi atomicity invariant (`is_nil(Repo.reload!(sub).dunning_campaign_started_at)`).
- **`grep -c 'campaign_anchor:' default_handler.ex` returns 2** — one per emission site, satisfying both task acceptance criteria.
- **Broader retrofit-adjacent suite stays green:** 34/34 tests pass across `dunning_exhaustion_test.exs` (11), `dunning_campaign_keying_test.exs` (10), `dunning_campaign_start_test.exs` (TBD), `dunning_sweeper_test.exs` (TBD) — no regression on existing dunning webhook behaviour.

## Task Commits

Each task followed TDD (RED → GREEN). Plan executed atomically with one test commit and one feat commit per task.

1. **Task 1 RED — failing tests for dunning.exhausted campaign_anchor** — `a82b9ceb` (test)
2. **Task 1 GREEN — defensive iso_anchor + payload retrofit on exhausted edge** — `891e22e1` (feat)
3. **Task 2 RED — failing assertions for dunning.recovered campaign_anchor + atomicity** — `af77e11b` (test)
4. **Task 2 GREEN — append campaign_anchor: iso_anchor on recovered edge** — `d384c475` (feat)

**Plan metadata commit:** TBD (created with this SUMMARY)

## Files Created/Modified

- `accrue/lib/accrue/webhook/default_handler.ex` — Added defensive `iso_anchor` computation + `campaign_anchor: iso_anchor` in the `dunning.exhausted` `Events.record/1` data map (line ~794–798, ~828); appended `campaign_anchor: iso_anchor` to the `dunning.recovered` `Events.record_multi/3` data map (line ~899). Both sites carry inline doc comments explaining the asymmetry between defensive (Stripe-native may hit nil) and pass-through (with-clause guarantees non-nil) handling.
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` — Added two new tests inside `describe "dunning.exhausted observability (DUN-08)"`: anchor-present branch (asserts ISO-8601 binary + round-trip + exact match) and nil-anchor branch (asserts is_nil + no raise).
- `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` — Extended the existing recovered-edge observability test with three assertions on `ledger.data["campaign_anchor"]` and one assertion on the post-recovery `is_nil(Repo.reload!(sub).dunning_campaign_started_at)` Ecto.Multi-atomicity invariant.

## Decisions Made

- **Asymmetric retrofit at the two emission sites.** The exhausted edge gets a fresh defensive `case` because `Subscription.dunning_sweepable?/1` only checks `status: :past_due` (a Stripe-native past_due → canceled/unpaid transition reaches this site with a nil anchor). The recovered edge reuses the existing `iso_anchor` binding at line 884 because the enclosing `with %DateTime{} = anchor <- row.dunning_campaign_started_at` clause guarantees non-nil. Inline doc comments explain the rationale at both sites.
- **Tests co-located with existing `describe "dunning.{exhausted,recovered} observability (DUN-08)"` blocks** — chose to extend rather than create new test files. Closes the Phase 143 emission-boundary gap (143-VERIFICATION.md §Notes #1) directly in the test surfaces operators search for "DUN-08 observability".
- **No new telemetry / no new event types.** Per CONTEXT D-08/D-09 + the task's `<action>` ("Do NOT add `:telemetry` event emissions or new telemetry metadata"), the retrofit is payload-only.

## Deviations from Plan

None — plan executed exactly as written. Both tasks followed the locked decisions (D-08 inject at write site; D-09 ISO-8601 string; D-10 emission-boundary tests). The defensive `case` pattern at the exhausted edge is the RESEARCH.md Pitfall #2 mitigation prescribed by the plan's `<action>` block.

## Issues Encountered

None — the plan's `<read_first>` blocks and the PATTERNS.md / RESEARCH.md cross-references were precise enough that both tasks landed in one TDD pass.

Minor note: the existing `dunning_exhaustion_test.exs` setup creates a `past_due` subscription without an anchor, so the nil-anchor "records campaign_anchor: nil" test could reuse the default setup directly — no additional fixture state needed. This is the canonical Stripe-native immediate-cancel branch.

## User Setup Required

None — no external service configuration required. This is a write-path retrofit on an existing webhook handler; no new env vars, no new infra.

## Verification Evidence

- `grep -c 'campaign_anchor:' accrue/lib/accrue/webhook/default_handler.ex` → `2` (one per emission site).
- `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs` → `11 tests, 0 failures` (includes 2 new DAN-02 tests).
- `cd accrue && mix test test/accrue/webhook/dunning_campaign_keying_test.exs` → `10 tests, 0 failures` (extended DUN-08 observability assertions pass).
- `cd accrue && mix test test/accrue/webhook/dunning_exhaustion_test.exs test/accrue/webhook/dunning_campaign_keying_test.exs test/accrue/webhook/dunning_campaign_start_test.exs test/accrue/jobs/dunning_sweeper_test.exs` → `34 tests, 0 failures` (no broader regression on retrofit-adjacent suite).

## Next Phase Readiness

- **Plan 144-03 (FunnelChart component)** can now proceed in Wave 2. The retrofit is independent of Plan 01's `funnel/1` (different file, no overlap); Plan 03 only depends on the existence of `Dunning.funnel/1` shipped by Plan 01 — which is already in main.
- **Plan 144-04 (RecoveryLive integration)** in Wave 3 will consume `funnel/1` output that now distinguishes cycled-dunning campaigns by `campaign_anchor`. The DISTINCT-tuple invariant `recovered + exhausted + active ≤ entered` is now testable end-to-end against newly-emitted events.
- **Forward-compat for Plan 148 (BREAKING widening, DAN-07):** The retrofit adds a payload field but does NOT change the `recovered_vs_lost_mrr/1` return shape — Phase 148 still owns the single clean BREAKING per-currency widening.
- **No follow-up debt.** Both retrofit sites carry inline doc comments explaining the asymmetric defensive-vs-pass-through handling; future maintainers reading `default_handler.ex` will not be surprised.

## Self-Check: PASSED

All claims verified:
- `accrue/lib/accrue/webhook/default_handler.ex` contains `iso_anchor = case row.dunning_campaign_started_at do` (line 794) — verified via Read.
- `accrue/lib/accrue/webhook/default_handler.ex` contains `campaign_anchor: iso_anchor` exactly 2 times — verified via `grep -c`.
- `accrue/test/accrue/webhook/dunning_exhaustion_test.exs` contains 7 `campaign_anchor` references — verified via `grep -c`.
- `accrue/test/accrue/webhook/dunning_campaign_keying_test.exs` contains 4 `campaign_anchor` references — verified via `grep -c`.
- All 4 task commits exist in git log — verified via `git log --oneline -6`.

---
*Phase: 144-funnel-query-viz-campaign-anchor-retrofit-money-formatter-polish*
*Plan: 02*
*Completed: 2026-05-27*
