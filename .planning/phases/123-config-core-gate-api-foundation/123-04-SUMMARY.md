---
phase: 123-config-core-gate-api-foundation
plan: 04
subsystem: entitlements
tags: [entitlements, plan-gating, defdelegate, property-test, stream-data, fail-closed, telemetry, public-api]

# Dependency graph
requires:
  - phase: 123-03
    provides: "Accrue.Entitlements context (entitled?/2, has_active_plan?/2 set-membership, features_for/1, entitlement_quantity/2) + Resolver behaviour/__impl__/0 + LocalMap resolver"
  - phase: 123-01
    provides: ":entitlements config schema + Accrue.Config.entitlements/0 + boot price_id-collision guard"
  - phase: billing-core
    provides: "Accrue.Test.Factory (active/canceled subscription with owner_id/price_id overrides), Accrue.Billing.subscribe/2 (reuse %Customer{}), Accrue.Billable, Accrue.BillingCase"
provides:
  - "Public top-level gate API: Accrue.has_active_plan?/2, Accrue.entitled?/2, Accrue.features_for/1, Accrue.entitlement_quantity/2 (4 defdelegates to Accrue.Entitlements with @doc/@spec)"
  - "Load-bearing D-10 fail-closed property test: never-true-on-garbage AND true-iff-affirmative-match, across the public Accrue.* delegates"
  - "Multi-active-plan affirmative leg (T-123-12b): has_active_plan? true for BOTH plans of a billable holding two active subs on two mapped plans, via the public delegate"
  - "D-16 doc reconcile: ROADMAP SC#5 + REQUIREMENTS ENT-05 carry the plural [:accrue, :entitlements, :check] event name"
  - "Certified D-14 one-way-dependency invariant (no Accrue.Entitlements back-reference under lib/accrue/billing/**)"
affects: [124-plug-guard, 124-liveview-guard, 125-resolver-behaviour, 126-admin-entitlements, entitlements]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Public gate surface via defdelegate on the top-level Accrue module (mirrors the Accrue.Auth facade house style: @doc + @spec per delegate)"
    - "Fail-closed property test: StreamData.one_of garbage generator + explicit edge fixtures + raising-resolver stub, asserting the 4 public delegates collapse to false/0/[]/false"
    - "Multi-active-plan fixture: ONE customer + active_subscription(price_p1) then Accrue.Billing.subscribe(customer, price_p2) on the SAME %Customer{} (never a second factory call, which mints a distinct owner_id)"

key-files:
  created:
    - accrue/test/property/entitlements_fail_closed_property_test.exs
  modified:
    - accrue/lib/accrue.ex
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "The public gate surface is 4 thin defdelegates on Accrue (no re-implementation) — the fail-closed logic, telemetry, and set-membership all live in Accrue.Entitlements (Plan 03); the delegates only widen reach to the top-level namespace docs/downstream call."
  - "The property test exercises the PUBLIC Accrue.* delegates (not Accrue.Entitlements.* directly) so it proves the delegate wiring AND the fail-closed contract in one pass."
  - "The raising-resolver leg asserts fail-closed even with a real billable + active sub present — proving a billing/availability hiccup never leaks a paid feature for free (D-08)."

patterns-established:
  - "defdelegate gate API on Accrue: each delegate carries its own @doc (with a 'Delegates to ...' line) + @spec (boolean()/[atom()]/non_neg_integer()) matching the target signature"
  - "Dual fail-closed property: a generated never-true-on-garbage property (max_runs: 200) PLUS a true-iff-affirmative-match property (entitled?(b, feat) == MapSet.member?(F, feat)) PLUS an explicit multi-active-plan example test"

requirements-completed: [ENT-02, ENT-03, ENT-04, ENT-05]

# Metrics
duration: 4min
completed: 2026-05-22
---

# Phase 123 Plan 04: Public Gate API + Load-Bearing Fail-Closed Property Test Summary

**Four `defdelegate` shims wire the entitlement gate API onto the top-level `Accrue` module (`has_active_plan?/2`, `entitled?/2`, `features_for/1`, `entitlement_quantity/2`), backed by the load-bearing D-10 fail-closed property test (never-true-on-garbage + true-iff-affirmative-match + a multi-active-plan affirmative leg) exercised through those public delegates, with the D-14 one-way-dependency invariant certified and the D-16 ROADMAP/REQUIREMENTS event name reconciled to the plural `[:accrue, :entitlements, :check]`.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-22T22:47:50Z
- **Completed:** 2026-05-22T22:51:50Z
- **Tasks:** 3 (Task 1 feat, Task 2 TDD property test, Task 3 phase-gate certification)
- **Files modified:** 4 (1 test created, 1 source modified, 2 planning docs reconciled)

## Accomplishments

- **Public gate surface (ENT-02/03/04):** added the four `defdelegate`s to `Accrue` (`accrue.ex`) — `has_active_plan?/2`, `entitled?/2`, `features_for/1`, `entitlement_quantity/2` — each with `@doc` (incl. a "Delegates to ..." line) and `@spec` per the `Accrue.Auth` house style, plus a moduledoc "Entitlement gate API" section. The fail-closed logic itself stays in `Accrue.Entitlements` (Plan 03); these are thin shims that widen reach to the top-level namespace the docs and downstream phases call.
- **Load-bearing fail-closed property test (D-10, the phase's correctness deliverable):** created `entitlements_fail_closed_property_test.exs` (`use Accrue.BillingCase, async: false` + `use ExUnitProperties`). It contains two property blocks and three explicit edge tests, all asserting against the **public `Accrue.*` delegates**:
  - **never-true-on-garbage** property over `StreamData.one_of([constant(nil), term(), integer(), string(:ascii), atom(:alphanumeric)])` (max_runs: 200): `entitled? == false`, `entitlement_quantity == 0`, `features_for == []`, `has_active_plan? == false`.
  - explicit edge fixtures: no-customer billable; customer with only a `canceled_subscription/1`; active sub on an unmapped `price_id`; and the **raising-resolver leg** (swaps `:entitlements` resolver to a stub whose `resolve/2` raises) — fail-closed even with a real active sub present (D-08).
  - **true-iff-affirmative-match** property: `entitled?(billable, feat) == MapSet.member?(F, feat)` for `feat ∈ F ∪ {unmapped_sentinel}`.
  - **multi-active-plan affirmative leg (T-123-12b):** ONE billable with two active subs (`:p1`/"price_p1" via factory + `:p2`/"price_p2" via `Accrue.Billing.subscribe/2` on the SAME customer) — `has_active_plan?` true for BOTH plans (atom + price_id forms), `refute` for unmapped `:enterprise`, and `features_for/1` equal to the sorted union `[:api, :export, :reports]`.
- **D-16 doc reconcile (ENT-05):** changed only the event token from singular `[:accrue, :entitlement, :check]` to plural `[:accrue, :entitlements, :check]` in ROADMAP Success Criterion #5 and REQUIREMENTS ENT-05 (no other content touched), matching the events Plan 03 actually emits.
- **Phase gate certified (Task 3):** entitlement test subset (config + entitlements + local_map + property + otel) is **49 tests / 2 properties / 0 failures**; D-14 grep gate exits 0; `mix credo --strict` reports no issues (398 files, 3403 mods/funs); `mix dialyzer` passed; `mix compile --warnings-as-errors` clean. Full `mix test` is green except the 6 pre-existing, out-of-scope `Accrue.Docs.PackageDocsVerifierTest` failures (red on main since 2026-05-08 — not caused by phase 123).

## Task Commits

Each task was committed atomically:

1. **Task 1: 4 defdelegates on Accrue + plural event reconcile** - `fb55e00` (feat)
2. **Task 2: load-bearing fail-closed property + multi-active-plan leg (D-10)** - `4566095` (test)
3. **Task 3: phase-gate certification** - no commit (certification only; all gates green, no file changes; the one remaining suite failure is the documented pre-existing PackageDocsVerifier red, explicitly out of scope)

**Plan metadata:** (this SUMMARY + STATE/ROADMAP/REQUIREMENTS state updates) — `docs(123-04)` final commit.

## Files Created/Modified

- `accrue/lib/accrue.ex` — added the 4 entitlement gate `defdelegate`s (`has_active_plan?/2`, `entitled?/2`, `features_for/1`, `entitlement_quantity/2`) to `Accrue.Entitlements`, each with `@doc`/`@spec`, plus a moduledoc "Entitlement gate API" section.
- `accrue/test/property/entitlements_fail_closed_property_test.exs` — the D-10 dual fail-closed property (never-true-on-garbage + true-iff-affirmative-match) plus the multi-active-plan affirmative leg, all asserted through the public `Accrue.*` delegates; inline `RaisingResolver` stub for the D-08 collapse leg.
- `.planning/ROADMAP.md` — SC#5 event name singular → plural (D-16).
- `.planning/REQUIREMENTS.md` — ENT-05 event name singular → plural (D-16).

## Decisions Made

- **Thin delegates, no re-implementation.** The public surface is four `defdelegate`s; all fail-closed logic, telemetry spans, and `active_plans`-SET membership live in `Accrue.Entitlements` (Plan 03). This keeps a single source of truth and means the property test, by hitting `Accrue.*`, simultaneously proves the delegate wiring and the underlying contract.
- **Property test targets the public delegates.** Rather than re-test `Accrue.Entitlements.*` (already covered in Plan 03's `entitlements_test.exs`), this test asserts against `Accrue.entitled?/2` etc., so the load-bearing fail-closed proof is bound to the exact surface host code calls.
- **Raising-resolver leg asserts fail-closed WITH a real active sub.** The stub leg seeds a genuine active subscription on a mapped plan, then swaps in a raising resolver — proving the `try/rescue/catch` collapse holds even when affirmative data exists (a stricter form of D-08 than a no-data billable alone).

## Deviations from Plan

None - plan executed exactly as written. The four delegate target signatures in `Accrue.Entitlements` matched the interfaces block exactly, the factory `owner_id`/`price_id` override and same-customer `subscribe/2` multi-active-plan path worked as the plan's `<read_first>` notes described, and all gates were green on the first run (no defect surfaced in Task 3, so no remedial edits were needed).

## Issues Encountered

- The full `mix test` run shows 6 failures, all in `Accrue.Docs.PackageDocsVerifierTest`. These are pre-existing (red on `main` since 2026-05-08 because `.planning/PROJECT.md` lacks the "gateway subscription core" needle the verifier script requires) and explicitly out of scope per the sequential-execution instructions. Confirmed unrelated: this plan's commits touched only `accrue/lib/accrue.ex`, `accrue/test/property/...`, `.planning/ROADMAP.md`, and `.planning/REQUIREMENTS.md` — none of which the package-docs verifier inspects. Not fixed (instructions forbid touching PROJECT.md or the verifier script).

## Threat Surface

- **T-123-12 (EoP — fail-open on garbage/error) mitigated:** the D-10 property test exhaustively asserts never-true-on-garbage (nil, non-billable terms, no-customer, canceled-only, unmapped, raising-stub) AND true-iff-affirmative-match across all four public `Accrue.*` delegates — the load-bearing proof of the fail-closed contract.
- **T-123-12b (EoP — multi-active-plan false negative) mitigated:** the multi-active-plan affirmative leg asserts `Accrue.has_active_plan?` is true for BOTH plans of a billable holding two active subs on two mapped plans (atom + price_id forms), proving the public delegate tests the `active_plans` SET, not a single representative (D-06/D-09).
- **T-123-13 (Tampering — billing→entitlements back-reference) mitigated:** the D-14 grep gate (`! grep -rq "Accrue.Entitlements" accrue/lib/accrue/billing/ accrue/lib/accrue/billing.ex`) was run in the phase gate and exits 0 — the dependency stays acyclic and one-way.
- **T-123-14 (Repudiation — singular/plural event drift) mitigated:** D-16 reconcile fixes ROADMAP SC#5 + REQUIREMENTS ENT-05 to the plural `[:accrue, :entitlements, :check]` matching the emitted events (grep-asserted: plural present in both, singular absent).
- **T-123-SC (npm/pip/cargo installs) N/A:** zero external packages added in this plan.
- No threat surface introduced beyond the plan's `<threat_model>`.

## Known Stubs

None. The four delegates are real `defdelegate`s wired to the fully-implemented `Accrue.Entitlements` context (Plan 03), exercised end-to-end by the property test against factory-seeded subscription state. The only stub is the test-local `RaisingResolver`, which is an intentional fail-closed test fixture, not production code.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Phase 124** (Plug + LiveView guards) can call the public `Accrue.has_active_plan?/2` and `Accrue.entitled?/2` directly; the fail-closed contract they inherit is now property-pinned.
- **Phase 125** (resolver behaviour + capability matrix) extends `Accrue.Entitlements.Resolver`; the public delegates remain stable.
- Phase 123 core gate API foundation is complete: config schema (P01), OTel allowlist (P02), the entitlements context + resolver (P03), and now the public surface + load-bearing fail-closed proof + D-14/D-16 closure (P04).
- No migrations, no Ecto schema, no external dependency added across the phase.

## Self-Check: PASSED

- FOUND: accrue/lib/accrue.ex (4 defdelegates present)
- FOUND: accrue/test/property/entitlements_fail_closed_property_test.exs
- FOUND commit: fb55e00 (Task 1 feat)
- FOUND commit: 4566095 (Task 2 test)
- VERIFIED: plural `[:accrue, :entitlements, :check]` present in ROADMAP.md + REQUIREMENTS.md; singular absent
- VERIFIED: D-14 grep gate exits 0; phase test subset 49 tests / 2 properties / 0 failures; credo --strict clean; dialyzer passed

---
*Phase: 123-config-core-gate-api-foundation*
*Completed: 2026-05-22*
