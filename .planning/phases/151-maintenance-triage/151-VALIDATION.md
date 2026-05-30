---
phase: "151"
name: "maintenance-triage"
validated_date: "2026-05-30"
validator: "nyquist-adversarial"
overall_status: compliant
---

# Phase 151: Maintenance & Triage — Validation

## Overall Verdict

**COMPLIANT.** All 3 plans executed cleanly. One gap was found during audit
(the ENT-10 cross-processor collision isolation path was not independently tested)
and filled by adding a new test case. All 11 tests pass. Both CI scripts exit 0.

---

## Per-Requirement Coverage Table

| Req ID | Requirement | Source | Test File | Coverage |
|--------|-------------|--------|-----------|----------|
| P01-T1a | `Repo.get_by` scopes by both `processor_id` AND `processor` — matching webhook processor succeeds | 151-01-PLAN Task 1, Behavior 1 | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1b | Webhook processor differs from customer processor → no customer match (cross-processor isolation) | 151-01-PLAN Task 1, Behavior 2 | `default_handler_entitlement_summary_test.exs` | COVERED (gap filled 2026-05-30) |
| P01-T1c | `handle_event/3` (DispatchWorker) path: enabled advisory sync writes row via lean event + ctx | 151-01-PLAN, CR-01 regression | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1d | `handle_event/3` (DispatchWorker) path: disabled writes no row | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1e | Stale event (strict `:lt` watermark) skips with `[:accrue, :webhooks, :stale_event]` telemetry and no clobber | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1f | Timestamp tie (`:eq`) proceeds — not skipped | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1g | Orphan customer → `{:ok, :deferred}` + `[:accrue, :webhooks, :orphan_entitlement_summary]` telemetry, no raise, no row | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1h | Malformed payload (missing `customer`) → `{:ok, :ignored}`, no garbage write | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1i | Malformed payload (non-list entitlements) → `{:ok, :ignored}`, no garbage write | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1j | `has_more: true` sets `truncated: true` on the persisted row | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P01-T1k | Default off-lane (`stripe_native_sync` disabled) → `{:ok, :ignored}`, no row | 151-01-PLAN | `default_handler_entitlement_summary_test.exs` | COVERED |
| P02-T1 | Dependency bumps across all packages; full test suite remains green after update | 151-02-PLAN Task 1 | `mix test` (all packages) | COVERED |
| P03-T1a | `./scripts/ci/verify_adoption_proof_matrix.sh` exits 0 | 151-03-PLAN Task 1 | CI script | COVERED |
| P03-T1b | `./scripts/ci/verify_package_docs.sh` exits 0 | 151-03-PLAN Task 1 | CI script | COVERED |
| P03-T2 | Final Hex publish — human-action gate | 151-03-PLAN Task 2 | N/A (human-action checkpoint) | SKIP (human gate, non-automated by design) |

---

## Gap Audit

### Gap Found: P01-T1b — Cross-processor isolation not independently tested

**Status before audit:** PARTIAL

The plan explicitly stated two required behaviors:
- Behavior 1: Webhook processor matches customer processor → success
- Behavior 2: Webhook processor differs from customer processor → no match

Behavior 1 was covered by multiple existing tests (the setup inserts a
`processor: "stripe"` customer and all "enabled" tests hit it). Behavior 2 was
not covered. The existing "orphan customer" test (`cus_does_not_exist`) exercises
a missing customer row, not the ENT-10 collision scenario of same `processor_id`
under a different `processor` value.

**Resolution:** Added test `"same processor_id under 'fake' processor is invisible to a :stripe webhook"` to `describe "ENT-10 cross-processor isolation (processor differs -> no match)"` in the existing test file. The test inserts a second `Customer` row with `processor: "fake"` and the same `processor_id: "cus_fake_ent_summary"` as the stripe customer, fires a Stripe webhook, and asserts:
1. The result is `{:ok, %EntitlementSummary{}}` linked to the stripe customer
2. No `EntitlementSummary` row exists for the fake customer

**Status after audit:** FILLED

**SQL evidence from test run:**
The `Repo.get_by` query generated is:
```sql
WHERE ((a0."processor_id" = $1) AND (a0."processor" = $2))
-- params: ["cus_fake_ent_summary", "stripe"]
```
This confirms the two-column scope is enforced at the DB level.

---

## Test Infrastructure

| Item | Value |
|------|-------|
| Framework | ExUnit |
| Case template | `Accrue.BillingCase` (`use Accrue.BillingCase, async: false`) |
| Test file | `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs` |
| Test count (after gap fill) | 11 tests |
| Run command | `cd accrue && mix test test/accrue/webhook/default_handler_entitlement_summary_test.exs` |
| Full suite command | `cd accrue && mix test` |
| Full suite result | 58 properties, 1635 tests, 0 failures (11 excluded) |
| Fixtures | `Accrue.Test.StripeFixtures.entitlement_summary_event/2` |

---

## CI Verification

| Script | Command | Exit Code | Output |
|--------|---------|-----------|--------|
| Adoption proof matrix | `./scripts/ci/verify_adoption_proof_matrix.sh` | 0 | `verify_adoption_proof_matrix: OK` |
| Package docs | `./scripts/ci/verify_package_docs.sh` | 0 | `package docs verified for accrue 1.3.0, accrue_admin 1.3.0, and accrue_portal 1.3.0` |

---

## Acceptance Criteria

- [x] Dependency bumps applied to all packages (`accrue`, `accrue_admin`, `accrue_portal`).
- [x] Test suites are completely green — 1635 tests, 0 failures.
- [x] The "Three Zeros" audit scripts return exit code 0.
- [x] No regressions in webhook handling behaviors.
- [x] ENT-10 cross-processor scoping is independently verified by a dedicated test case.

---

## Nyquist Compliance Status

**COMPLIANT.**

All requirements from all 3 plans have passing automated tests or an explicit
justified SKIP (the Hex publish human-action gate is non-automatable by design).
The one gap found (P01-T1b cross-processor isolation) was filled during this
audit by adding a test that can fail if the implementation regresses. That test
passes with the current implementation and its SQL trace confirms the two-column
`(processor_id, processor)` scope is active at the database level.

---

## Files Modified During Validation

- `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs`
  — Added `describe "ENT-10 cross-processor isolation"` block with 1 new test.
  Test count: 10 → 11. All pass.
