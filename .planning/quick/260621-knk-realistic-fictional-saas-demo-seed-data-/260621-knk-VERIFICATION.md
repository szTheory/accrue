---
phase: 260621-knk
verified: 2026-06-21T15:46:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 260621-knk: Realistic Fictional SaaS Demo Seed Data Verification Report

**Phase Goal:** Part C — make the `accrue_host` demo seed data a realistic fictional SaaS (realistic names/emails, payment methods on file, coherent linked subscriptions/invoices/charges so detail pages + KPIs + signals populate) WITHOUT breaking tests that assert stable identifiers/counts/unicode strings. examples/accrue_host only, data-only.
**Verified:** 2026-06-21T15:46:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Page customers show realistic company/person names + emails, not "Phase 191 Page Customer NN" | ✓ VERIFIED | `phase191_flow_states.exs:358-362` — `Faker.Person.name()` for User-owned, `Faker.Company.name()` otherwise; `email: Faker.Internet.email()` (line 376). Placeholder name removed. Reachability test `refute page_one.name =~ ~r/Phase 191 Page Customer/` passes. |
| 2 | Most page customers have a non-null `default_payment_method_id` backed by a `pm_phase191_host_page_NN` PM via the upsert helper | ✓ VERIFIED | `page_has_payment_method? = rem(index,7) != 0` → 23 of 26 (lines 344, 386-418). PM inserted via `upsert_processor.(PaymentMethod, ...)`, then `default_payment_method_id` back-set only when differing (idempotent). Varied owner_type (lines 332-339). |
| 3 | A bounded subset has linked sub/invoice/charge with realistic status mix incl. a past_due/at-risk case | ✓ VERIFIED | `linked_graph_count = 10` (line 349). First 10 page customers each get `sub_/in_/ch_phase191_host_page_NN` via `upsert_processor` (lines 425-541). Status mix: index 3 past_due+failed+dunning anchor, 6/9 trialing, 10 JPY zero-decimal, rest active+paid USD. |
| 4 | Re-running the seed twice does not crash and does not change row counts (idempotent) | ✓ VERIFIED | Every new row routes through `upsert_processor` keyed on `(processor:"fake", processor_id)` with deterministic per-index processor_id. Idempotency test `Code.eval_file` evals the seed TWICE; `phase191_fixture_counts()` stable at 12/11/11. Tests green. |
| 5 | Every preserved processor_id, idempotency key, unicode string, and 26-page boundary count intact | ✓ VERIFIED | Primary `cus_phase191_host_customer` name still `株式会社`+`Café`, email unchanged, `default_payment_method_id` STILL nil (lines 89-90, 102; reachability test line 66 `is_nil` passes). Coupon `Crème` (line 179), promo `ÉTÉ191` (line 200) untouched. `paginated_count() == 26` passes. `cus_phase191_host%` == 28. |
| 6 | Test count coupling updated to match seed totals | ✓ VERIFIED | `seeds_idempotency_test.exs:115-125` asserts subscriptions:12, invoices:11, charges:11, customers:28, others unchanged. Matches seed comment (lines 544-549). Arithmetic exact: 2+10, 1+10, 1+10. PMs (23) not asserted — correct. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs` | Faker-backed page customers + PMs + linked graph, idempotent | ✓ VERIFIED | Contains `Faker.Company.name`, `pm_phase191_host_page`, `default_payment_method_id`, `sub_/in_/ch_phase191_host_page`. Compiles clean. |
| `examples/accrue_host/test/seeds_idempotency_test.exs` | Updated fixture counts | ✓ VERIFIED | `phase191_fixture_counts` map updated to 12/11/11; route ids untouched. |
| `examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs` | Preserved unicode/boundary + new realism assertions | ✓ VERIFIED | `paginated_count` + all unicode/primary-nil assertions intact; new test "page customers carry realistic identities..." added (humanized name, ≥1 PM, page subs > 0, past_due+dunning, owner-type variety). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| seed | `payment_method.ex` | `PaymentMethod.changeset/2` inserts `pm_phase191_host_page_NN`, customer back-points | ✓ WIRED | Lines 391-417: PM upserted then `default_payment_method_id` set via `Customer.changeset`. |
| seed | `seeds_idempotency_test.exs` | `like(processor_id,'sub_phase191_host%')` counts; updated in lockstep | ✓ WIRED | Counts 12/11/11 match seed arithmetic; verified by passing test (2-eval). |

### Metadata Type Check (Task 4)

| Location | `phase191_index` placement | metadata values | Status |
| -------- | -------------------------- | --------------- | ------ |
| page customer / PM / sub / invoice / charge | in `data` (integer) | all strings (`"more-than-one-page"`, `"demo-book-of-business"`) | ✓ PASS — changeset accepts; rows insert |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Gating seed tests (2-eval idempotency + preservation) | `mix test test/seeds_idempotency_test.exs test/accrue_host/phase191_seed_reachability_test.exs` | 5 tests, 0 failures (2.0s) | ✓ PASS |
| Broader host suite | `mix test` | 197 tests, 1 failure (`AdminWebhookReplayTest` — unrelated) | ✓ PASS (in scope) |

### Anti-Patterns Found

None blocking. No TBD/FIXME/XXX in modified files. No append-only `accrue_events` rows added/updated (immutability trigger never hit).

### Guardrails Confirmed

| Guardrail | Status |
| --------- | ------ |
| examples/accrue_host only | ✓ — commits touch only the seed + 2 host test files |
| mix.lock NOT in commits | ✓ — `mix.lock` remains unstaged/dirty (pre-existing), not in either commit |
| No `.planning/research/.cache/` committed | ✓ — untracked, not in commits |
| No accrue_admin / core-lib changes | ✓ — none in commit stat |
| No ROADMAP.md | ✓ |
| No bundle rebuild | ✓ |
| 2 commits | ✓ — `5cbf8806` (feat), `fdb6daee` (test) |

### Out-of-Scope Failure (noted, not a gap)

`AdminWebhookReplayTest:141` fails on a missing `[data-role='prepare-bulk-replay']` LiveView selector. This test file is NOT touched by either knk commit, lives in the admin webhook-replay UI, and cannot be affected by a data-only seed change (the seed does not render or alter that element). It belongs to the preceding Part B / admin-UI territory, not Part C. Out of scope for this task.

### Human Verification (informational only — not a gap)

The subjective "looks realistic in /admin/customers" judgement is the only inherently-human part. All underlying data is verified structurally (humanized names, On-file PMs for 23/26, KPI-backing non-null `default_payment_method_id`, populated detail-page graph for 10, past-due recovery signal). No functional gap; a maintainer may optionally eyeball `/admin/customers` after `make reset`.

### Gaps Summary

No gaps. All 6 must-haves verified against the actual seed + test code and a live 2-eval test run. Every preserved identifier/unicode/boundary assertion is intact, the new realistic data + linked billing graph is idempotent, and the test count coupling matches the seed arithmetic exactly. The single broader-suite failure is a pre-existing, unrelated admin-UI test outside this data-only task's scope.

---

_Verified: 2026-06-21T15:46:00Z_
_Verifier: Claude (gsd-verifier)_
