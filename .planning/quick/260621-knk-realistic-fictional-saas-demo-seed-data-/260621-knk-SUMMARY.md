---
phase: 260621-knk
plan: 01
subsystem: examples/accrue_host (demo seed data)
tags: [seeds, demo-data, idempotency, faker, billing-graph]
requires:
  - examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs (existing upsert/upsert_processor helpers)
  - accrue/lib/accrue/billing/{customer,payment_method,subscription,invoice,charge}.ex (changeset shapes)
provides:
  - Realistic Faker-backed page-customer identities + payment methods + linked billing graph
  - Updated phase191 fixture-count assertions + realism coverage assertions
affects:
  - /admin/customers list, KPIs, owner-type filter, and customer detail pages (data only)
tech-stack:
  added: []
  patterns:
    - "Idempotent get-or-insert via upsert_processor keyed on (processor, processor_id)"
    - "Deterministic per-index UUID sub-namespaces to avoid id collisions"
    - "Faker non-determinism is safe under count-based idempotency assertions"
key-files:
  created: []
  modified:
    - examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs
    - examples/accrue_host/test/seeds_idempotency_test.exs
    - examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs
decisions:
  - "N = 10 page customers get a linked sub/invoice/charge graph (bounded reset time)"
  - "23 of 26 page customers get a payment method on file (skip rem(index,7)==0 → 7,14,21) so the column shows both On file / Missing"
  - "Owner-type split: Organization (default), User (rem 3), Workspace (rem 5), Team (rem 9) for filter variety"
  - "Status/currency mix: index 3 past_due+failed, 6 trialing/open, 9 trialing/paid, 10 active/paid JPY, rest active/paid USD"
metrics:
  duration: ~12m
  completed: 2026-06-21
status: complete
---

# Phase 260621-knk Plan 01: Realistic Fictional SaaS Demo Seed Data Summary

Made the `accrue_host` demo seed (`phase191_flow_states.exs`) read like a believable fictional SaaS book of business — Faker company/person names + emails and varied owner_types for the 26 page customers, a payment method on file for 23 of them, and a coherent linked subscription+invoice+charge graph (with a past-due dunning case + a JPY invoice) for the first 10 — all fully idempotent, while preserving every stable identifier, unicode string, and boundary count the host seed tests assert on.

## What Was Built

- **Task 1 — Realistic identities + payment methods (`feat`, 5cbf8806):** Rewrote the `1..26` page-customer loop so each customer gets `Faker.Company.name()`/`Faker.Person.name()` + `Faker.Internet.email()`, a deterministic `owner_type` (Organization/User/Workspace/Team), and — for 23 of 26 — an idempotent `pm_phase191_host_page_NN` PaymentMethod with a back-set `default_payment_method_id` (mirroring the hero_accounts pattern). Fingerprints are per-customer-unique (`fp_phase191_host_page_NN`); card brand/last4/expiry cycle deterministically.
- **Task 2 — Coherent linked billing graph (same commit, `feat`, 5cbf8806):** For the first 10 page customers, added a linked `sub_/in_/ch_phase191_host_page_NN` graph with a realistic status/currency mix: mostly active+paid USD, two trialing, one past_due+failed (with `dunning_campaign_started_at` so the recovery signal lights up), and one JPY zero-decimal invoice. Amounts are internally consistent (subtotal=total=amount_due; paid vs remaining keyed off invoice status). All new UUIDs live in distinct `-400{2,3,4,5}-` sub-namespaces to avoid collisions with customer ids.
- **Task 3 — Test count/structure updates (`test`, fdb6daee):** Updated `phase191_fixture_counts/0` expectations to `subscriptions: 12, invoices: 11, charges: 11` (customers stay 28; coupons/promos/connect/webhooks/events unchanged). Added realism assertions to the reachability test: humanized page-01 name (negative match), ≥1 page customer with a default PM, page-namespace PM/subscription counts > 0, the past_due+dunning at-risk case, and owner-type variety > 1 — all structural, never asserting specific Faker output.

## Why (Idempotency model)

Every new row routes through the file's existing `upsert_processor` get-or-insert helper, keyed on `(processor: "fake", processor_id)` with a deterministic processor_id derived from the page index. Re-seeding collapses to a no-op even though Faker is non-deterministic, because the idempotency test asserts **counts**, not names, and first-insert values stay stable. The `default_payment_method_id` back-set only fires when it differs, keeping re-runs idempotent.

## Verification (exact results)

- `mix compile --warnings-as-errors` — **clean** (accrue/accrue_admin/accrue_host all generated, no warnings).
- `mix test test/seeds_idempotency_test.exs test/accrue_host/phase191_seed_reachability_test.exs` — **5 tests, 0 failures** (2.0s). The idempotency test evals the seed twice; counts stayed stable at 12/11/11. (Log noise: pre-existing `redefining module AccrueHost.Seeds.Helpers` + `no operation_id` warnings, unrelated to this change.)
- Fixture counts confirmed: customers **28** (unchanged); subscriptions **12** (2 existing + 10 page); invoices **11** (1 + 10); charges **11** (1 + 10); payment_methods `pm_phase191_host_page%` = 23 (not asserted by any test).
- Boundary preserved: `paginated_count() == 26`; `cus_phase191_host_one` == 1; zero == 0.
- Preserved strings intact: `株式会社` + `Café` (primary name), `Crème` (coupon), `ÉTÉ191` (promo code) — all green via untouched assertions.
- Primary customer `default_payment_method_id` still **nil** (asserted `is_nil`) — no PM given to primary or one-row customers.

## Deviations from Plan

**1. [Process — atomicity] Tasks 1 and 2 committed together (5cbf8806).** Both tasks modify only `phase191_flow_states.exs` within the same contiguous `1..26` loop rewrite (Task 2's linked graph is built inline per page-customer alongside Task 1's identity/PM work). They are inseparable as a single coherent edit, so they ship as one atomic seed commit rather than two; Task 3 (tests) is its own commit (fdb6daee). No functional change vs. the plan — all three tasks' done-criteria are met.

No auto-fixes (Rules 1–3) were needed; the seed compiled and the tests passed on first run.

## Guardrails Confirmed

- `examples/accrue_host/mix.lock` — **NOT staged/modified** (remains pre-existing dirty, off-limits).
- `.planning/research/.cache/` — untouched.
- `ROADMAP.md` — untouched.
- No `accrue_admin` or core `accrue` lib changes; no CSS/JS bundle rebuild.
- Commits touch only the seed file + the two host seed test files.

## Commits

- `5cbf8806` feat(260621-knk): realistic page-customer identities + payment methods + linked billing graph
- `fdb6daee` test(260621-knk): update phase191 seed fixture counts + add realism assertions

## Self-Check: PASSED

- FOUND: examples/accrue_host/priv/repo/seeds/phase191_flow_states.exs (modified, compiles, tests green)
- FOUND: examples/accrue_host/test/seeds_idempotency_test.exs (counts 12/11/11)
- FOUND: examples/accrue_host/test/accrue_host/phase191_seed_reachability_test.exs (realism assertions added, preserved assertions intact)
- FOUND commit: 5cbf8806
- FOUND commit: fdb6daee
