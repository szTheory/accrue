---
phase: 123
slug: config-core-gate-api-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-22
---

# Phase 123 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `123-RESEARCH.md` § Validation Architecture (codebase-verified).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib) + `ExUnitProperties`/`StreamData ~> 1.3` (already declared, `accrue/mix.exs` L93) |
| **Config file** | `accrue/mix.exs`; test helper `accrue/test/test_helper.exs` |
| **Case templates** | `Accrue.BillingCase` (SQL Sandbox + Fake processor + test clock + factory aliases); plain `ExUnit.Case, async: false` for config-mutating tests |
| **Quick run command** | `cd accrue && mix test test/accrue/entitlements_test.exs` |
| **Full suite command** | `cd accrue && mix test test/accrue/entitlements_test.exs test/accrue/entitlements/ test/accrue/config_entitlements_test.exs test/property/entitlements_fail_closed_property_test.exs` |
| **Estimated runtime** | ~10 s (phase subset); full `mix test` per phase gate |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/entitlements_test.exs` (fast unit/example subset)
- **After every plan wave:** Run the phase subset command above + `mix credo --strict` + the D-14 grep gate
- **Before `/gsd:verify-work`:** Full `mix test` green + `mix dialyzer` + `mix credo --strict`
- **Max feedback latency:** ~10 seconds (per-task subset)

---

## Per-Requirement Verification Map

> Plan/task IDs are TBD until planning completes; this map is keyed on requirement + behavior.
> The planner must ensure each row maps to at least one `<acceptance_criteria>` with an automated command.

| Requirement | Behavior | Test Type | Automated Command | File (Wave 0) |
|-------------|----------|-----------|-------------------|---------------|
| ENT-01 | Valid `:entitlements` config validates at boot | unit | `mix test test/accrue/config_entitlements_test.exs` | ❌ W0 |
| ENT-01 | Invalid `:entitlements` (bad type) raises at boot | unit | same file | ❌ W0 |
| ENT-01 | Duplicate price_id across two plans raises `Accrue.ConfigError` at boot | unit | same file | ❌ W0 |
| ENT-02 | `has_active_plan?/2` true for active sub on mapped plan (atom + price_id string) | example | `mix test test/accrue/entitlements_test.exs` | ❌ W0 |
| ENT-02 | `has_active_plan?/2` reuses `Subscription.active?/1` truth (trialing → true; canceled → false) | example | same file | ❌ W0 |
| ENT-02 | `has_active_plan?/2` true for BOTH plans when a billable holds two active subs on two different mapped plans (multi-active-plan: resolver carries the active_plans SET, has_active_plan? tests set membership, not a single representative) | example + property | `mix test test/accrue/entitlements_test.exs test/property/entitlements_fail_closed_property_test.exs` | ❌ W0 |
| ENT-03 | `entitled?/2` true iff resolved active feature set contains feature | example + property | `mix test test/property/entitlements_fail_closed_property_test.exs` | ❌ W0 |
| ENT-03 | `features_for/1` sorted, deduped UNION across active subs; never returns `MapSet` | example | `mix test test/accrue/entitlements_test.exs` | ❌ W0 |
| ENT-03 | Fail-closed: nil / non-billable / no-customer / no-active-sub / unmapped / raising-stub → `false` / `[]` / `0` | property | `mix test test/property/entitlements_fail_closed_property_test.exs` | ❌ W0 |
| ENT-04 | `entitlement_quantity/2` = `min(cap, quantity)` when cap exists, else quantity; `0` fail-closed | example | `mix test test/accrue/entitlements_test.exs` | ❌ W0 |
| ENT-05 | `[:accrue, :entitlements, :check, :start/:stop/:exception]` emitted with D-18 metadata | example (telemetry handler) | `mix test test/accrue/entitlements_test.exs` | ❌ W0 |
| ENT-05 | `reason: :unmapped_plan` in `:stop` metadata on unmapped-plan deny | example | same file | ❌ W0 |
| ENT-05 | OTel `sanitize_attributes/1` retains the 6 new keys (`:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`, atom + string) | unit | `mix test test/accrue/telemetry/otel_test.exs` (extend) | ❌ W0 |
| ENT-05 | Ledger boundary: `Accrue.Events.record/1` NOT called during a check | example | `mix test test/accrue/entitlements_test.exs` | ❌ W0 |
| D-14 | No file under `lib/accrue/billing/**` references `Accrue.Entitlements.*` | static grep / Credo | `! grep -rq "Accrue.Entitlements" accrue/lib/accrue/billing/ accrue/lib/accrue/billing.ex` | ✅ passes today |

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · W0 = created in Wave 0*

---

## Load-Bearing Property Test (D-10)

File: `test/property/entitlements_fail_closed_property_test.exs` (`use ExUnit.Case` + `use ExUnitProperties`; mirror `test/property/connect_platform_fee_property_test.exs`).

**Garbage / edge generators (assert never-true):**
- `StreamData.one_of([constant(nil), term(), integer(), string(:ascii), atom(:alphanumeric)])` — nil + arbitrary non-billable terms
- billable struct with valid shape but **no** `accrue_customers` row
- billable with a customer but **no** active subscription (e.g. only `canceled_subscription/1`)
- billable with an **active** subscription whose `price_id` is **unmapped**
- a **raising resolver/Repo stub** (proves `try/rescue/catch` collapses to fail-closed)

**Invariants for all of the above:** `entitled?/2 == false`, `entitlement_quantity/2 == 0`, `features_for/1 == []`, `has_active_plan?/2 == false`.

**Affirmative-match (true-iff):** for a billable with an active subscription on a mapped plan whose feature set is `F`, `entitled?(billable, feat) == MapSet.member?(F, feat)` for `feat ∈ F ∪ {unmapped_feature}`. This pins the dual property: never-true-on-garbage **AND** true-iff-affirmative-match.

**Multi-active-plan affirmative (load-bearing for ENT-02):** for ONE billable holding **two** active subscriptions on **two different** mapped plans `:p1` (price `"price_p1"`) and `:p2` (price `"price_p2"`) — built by one `active_subscription/1` (`"price_p1"`) then a second `Accrue.Billing.subscribe(result.customer, "price_p2")` on the SAME customer (NOT two factory calls, which would mint two distinct customers) — `has_active_plan?(billable, :p1) == true` AND `has_active_plan?(billable, :p2) == true` (and true for both price_id strings); `has_active_plan?(billable, :unmapped) == false`; `features_for(billable)` is the sorted union of `:p1`'s and `:p2`'s feature sets. This proves the resolver carries the **set** of active plans (`active_plans`) and `has_active_plan?/2` tests set membership — not a single representative `:plan` that would yield a fail-closed-but-wrong false negative for the second active plan. Lives as a concrete example in `entitlements_test.exs` (resolver/context) and the property-test file's affirmative leg (`has_active_plan?` via the public `Accrue.*` delegate).

---

## Wave 0 Requirements

- [ ] `test/accrue/config_entitlements_test.exs` — boot validation + collision raise (ENT-01)
- [ ] `test/accrue/entitlements_test.exs` — 4-fn happy/edge + multi-active-plan has_active_plan? + telemetry + ledger boundary (ENT-02..05)
- [ ] `test/accrue/entitlements/local_map_test.exs` — resolver read-path + active_plans SET (incl. two-different-active-plans) (ENT-02/03/04)
- [ ] `test/property/entitlements_fail_closed_property_test.exs` — D-10 dual property + multi-active-plan affirmative leg (ENT-03/ENT-02)
- [ ] Extend `test/accrue/telemetry/otel_test.exs` — assert the 6 new allowlist keys retained (ENT-05 / D-19)
- [ ] No new fixtures needed — `Accrue.Test.Factory` + `Accrue.BillingCase` cover customer/subscription/item creation with `:price_id` override. NOTE: two active subs on ONE billable are built by one `active_subscription/1` then a second `Accrue.Billing.subscribe(result.customer, "price_p2")` on the SAME customer (subscribe/2 fetch-or-create reuses it) — NOT two factory calls (each mints a fresh owner_id, yielding two distinct customers, and a forced shared owner_id hits the `accrue_customers_owner_type_owner_id_processor` unique index)
- [ ] No framework install needed — ExUnit + `stream_data` already present

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Atomic seat *enforcement* | ENT-04 (boundary) | Host-owned by decision (D-06); not a core API | Documented recipe only — verify the guide/moduledoc states enforcement is host-owned, no core function to test |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
