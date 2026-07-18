---
quick_id: 260718-iwa
title: Remove automatic-tax friction + confusing usage button from /app/billing
status: complete
date: 2026-07-18
commit: a4661ee1
---

# Quick Task 260718-iwa — Summary

## What changed
- `subscription_live.ex` — removed `automatic_tax: true` from both subscribe call sites; deleted the
  `customer_tax_location_invalid` error clauses, the `update_tax_location` handler, the "Repair automatic
  tax input" `<section>`, the `simulate_api_call` handler + "Usage this period"/"Record learner activity"
  section, the orphaned tax helpers, the tax copy constants, the `APIError` alias, and the tax assigns.
- `subscription_live_test.exs` — deleted the 3 coupled tests (metered usage, tax repair, tax error path)
  and the now-unused `Plans` alias.
- e2e — deleted `verify01-tax-invalid.spec.js`; trimmed the tax-form + learner-activity steps from
  `phase13-canonical-demo.spec.js` and `onboarding_and_billing.spec.js` (renumbered the latter's steps).
- Left the generated (fingerprinted) `accrue_host/billing.ex` untouched.

## Verification
- `mix compile --warnings-as-errors` → EXIT 0.
- `mix test test/accrue_host_web/live/subscription_live_test.exs` → 4 tests, 0 failures.
- Playwright: `/app/billing` no longer renders "Record learner activity" / "Usage this period" /
  "Repair automatic tax input" / "Save tax location", and choosing a plan surfaces no tax error.

## Important follow-up (uncovered during verification)
Removing automatic tax revealed a **pre-existing** bug the tax gate was masking: the Fake processor uses
sequential deterministic IDs (`sub_fake_00001`…) starting from zero, but the seeds run in a **separate
BEAM node** from the server, so the seeded DB rows already occupy those IDs while the running server's Fake
counter starts fresh. Any create/change subscription therefore collides on
`accrue_subscriptions_processor_processor_id_index` and crashes the LiveView (no flash). So "Choose plan"
has never actually completed on the seeded demo server — it only ever showed the tax error.

User chose to **fix this properly** (boot-time consistency between the running Fake and the seeded DB) —
tracked as the next task. `AccrueHost.DemoBrand` unchanged; pre-existing dirty files untouched.
