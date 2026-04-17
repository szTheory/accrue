# Phase 21 plan 06 — summary

- Added `## VERIFY-01 (Phase 21)` to `examples/accrue_host/README.md` with explicit `cd examples/accrue_host` commands: E2E seed (`ACCRUE_HOST_E2E_FIXTURE` + `accrue_host_seed_e2e.exs`), `mix test --warnings-as-errors`, and `npx playwright test`; Fake-first, no `sk_live` guidance.
- Extended `billing_facade_test.exs`: `customer_for_scope` / `billing_state_for_scope` / `subscribe_active_organization` return `{:error, :no_active_organization}` without active org; `cancel_active_organization/2` returns `{:error, :forbidden}` when the subscription belongs to a different organization than the active scope.
- Extended `subscription_live_test.exs`: billing page HTML includes `Organization billing state` and `AccrueHost.Billing`.

Verification: `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/live/subscription_live_test.exs`.
