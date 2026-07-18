---
quick_id: 260718-iwa
title: Remove automatic-tax friction + confusing usage button from /app/billing
status: complete
created: 2026-07-18
---

# Quick Task 260718-iwa: /app/billing demo cleanup

## Goal
Two `/app/billing` (host `SubscriptionLive`) demo issues the user reported:
1. Choosing a plan errored "Please update customer address or shipping before enabling automatic tax"
   because the flow hard-coded `automatic_tax: true` and the demo customer has no address.
   **Decision: remove automatic tax** from the flow (+ the now-pointless "Repair automatic tax input" form).
2. The "Record learner activity" metered-usage button was confusing / off-domain. **Decision: remove it.**

## Tasks
1. `subscription_live.ex` — drop `automatic_tax: true` at the two subscribe call sites; remove the
   `customer_tax_location_invalid` error clauses, the `update_tax_location` handler, the tax-repair
   `<section>`, the `simulate_api_call` handler + "Usage this period" section, the orphaned tax helpers
   (`tax_location_status/attrs/defaults`, `empty_tax_location_form`, `humanize_reason`, `blank_to_nil`),
   the tax copy constants, the `APIError` alias, and the tax assigns in `load_state`.
2. `subscription_live_test.exs` — delete the 3 coupled tests (metered usage, tax repair, tax error path)
   and the now-unused `Plans` alias.
3. e2e — delete `verify01-tax-invalid.spec.js`; trim the tax-form + learner-activity steps from
   `phase13-canonical-demo.spec.js` and `onboarding_and_billing.spec.js`.
4. Leave the generated `accrue_host/billing.ex` untouched (fingerprinted; the now-uncalled
   `report_usage_for_scope`/tax facades are harmless public functions).

## Verification
- `mix compile --warnings-as-errors` → EXIT 0 (all orphaned helpers/aliases removed).
- `mix test test/accrue_host_web/live/subscription_live_test.exs` → 4 tests, 0 failures.
- Playwright: `/app/billing` no longer shows "Record learner activity" / "Usage this period" /
  "Repair automatic tax input" / "Save tax location", and choosing a plan surfaces no tax error.

## Follow-up (separate task)
Removing automatic tax uncovered a pre-existing bug: the Fake processor's sequential IDs
(`sub_fake_00001`…) collide with seeded data on the running server (seeds run in a separate BEAM node),
so create/change subscription crashes with an `accrue_subscriptions_processor_processor_id_index`
constraint error. The tax error was masking it. User chose to fix this properly (boot-time Fake↔DB
consistency) as its own task.
