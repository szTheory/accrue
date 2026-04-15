---
phase: 5
slug: connect
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-15
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from `05-RESEARCH.md` Validation Architecture section.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib) + Mox 1.2 + StreamData 1.3 |
| **Config file** | `accrue/test/test_helper.exs`; per-suite cases in `accrue/test/support/` |
| **Quick run command** | `cd accrue && mix test test/accrue/connect/ test/accrue/webhook/connect_handler_test.exs --warnings-as-errors` |
| **Full suite command** | `cd accrue && mix test --warnings-as-errors` |
| **Live Stripe suite** | `cd accrue && mix test --only live_stripe` |
| **Estimated runtime** | ~20s quick / ~90s full / ~45s live_stripe |

---

## Sampling Rate

- **After every task commit:** Run quick command above
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Full suite green + `mix credo --strict` + `mix dialyzer` + `mix test --only live_stripe`
- **Max feedback latency:** 20 seconds (quick), 90 seconds (full)

---

## Per-Task Verification Map

> The planner is responsible for wiring concrete Task IDs to the rows below. Each row represents a requirement-level acceptance sample. Planner MAY split a row across multiple tasks but MUST preserve the command + requirement mapping.

| # | Plan (TBD) | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|------------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 1 | TBD | 0 | PROC-05 | Resolution precedence opts > pdict > config; no leaked platform-scoped calls | unit | `mix test test/accrue/processor/stripe_test.exs` | ❌ W0 | ⬜ pending |
| 2 | TBD | 0 | PROC-05 | `build_client!/1` threads `stripe_account:` into `LatticeStripe.Client.new!/1` | unit (Mox) | `mix test test/accrue/processor/stripe_test.exs` | ❌ W0 | ⬜ pending |
| 3 | TBD | 0 | PROC-05 | Oban middleware carries `stripe_account` across job boundary | integration | `mix test test/accrue/oban/middleware_test.exs` | ❌ W0 | ⬜ pending |
| 4 | TBD | 1 | CONN-01 | `create_account/2` round-trips `:standard` / `:express` / `:custom` via Fake | unit | `mix test test/accrue/connect/account_test.exs` | ❌ W0 | ⬜ pending |
| 5 | TBD | 1 | CONN-01 | `type:` required — missing rejected with `%Accrue.Error{}` | unit | `mix test test/accrue/connect/account_test.exs` | ❌ W0 | ⬜ pending |
| 6 | TBD | 1 | CONN-02 | `create_account_link/2` returns `%AccountLink{}` with `expires_at` | unit | `mix test test/accrue/connect/account_link_test.exs` | ❌ W0 | ⬜ pending |
| 7 | TBD | 1 | CONN-02 | `Inspect.inspect(%AccountLink{})` masks `:url` as `<redacted>` | unit | `mix test test/accrue/connect/account_link_test.exs` | ❌ W0 | ⬜ pending |
| 8 | TBD | 2 | CONN-03 | `account.updated` webhook updates state fields via `force_status_changeset` | integration | `mix test test/accrue/webhook/connect_handler_test.exs` | ❌ W0 | ⬜ pending |
| 9 | TBD | 2 | CONN-03 | Out-of-order `account.updated` seeds local row via `retrieve_account/2` | integration | `mix test test/accrue/webhook/connect_handler_test.exs` | ❌ W0 | ⬜ pending |
| 10 | TBD | 2 | CONN-03 | Predicates `fully_onboarded?/1`, `charges_enabled?/1` reflect post-webhook state | unit | `mix test test/accrue/connect/account_test.exs` | ❌ W0 | ⬜ pending |
| 11 | TBD | 2 | CONN-04 | `destination_charge/2` request body carries `transfer_data.destination` + `application_fee_amount`; header NOT set | unit (Mox) | `mix test test/accrue/connect/charges_test.exs` | ❌ W0 | ⬜ pending |
| 12 | TBD | 2 | CONN-04 | Returns `%Accrue.Billing.Charge{}` projection | integration | `mix test test/accrue/connect/charges_test.exs` | ❌ W0 | ⬜ pending |
| 13 | TBD | 2 | CONN-05 | `separate_charge_and_transfer/2` issues two distinct API calls | unit (Mox) | `mix test test/accrue/connect/charges_test.exs` | ❌ W0 | ⬜ pending |
| 14 | TBD | 2 | CONN-05 | `transfer/2` standalone helper round-trips through Fake | unit | `mix test test/accrue/connect/transfer_test.exs` | ❌ W0 | ⬜ pending |
| 15 | TBD | 1 | CONN-06 | `platform_fee/2` USD: `$100 * 2.9% + $0.30 = $3.20` | unit | `mix test test/accrue/connect/platform_fee_test.exs` | ❌ W0 | ⬜ pending |
| 16 | TBD | 1 | CONN-06 | `platform_fee/2` JPY (0-decimal) preserves precision | unit | `mix test test/accrue/connect/platform_fee_test.exs` | ❌ W0 | ⬜ pending |
| 17 | TBD | 1 | CONN-06 | `platform_fee/2` KWD (3-decimal) preserves precision | unit | `mix test test/accrue/connect/platform_fee_test.exs` | ❌ W0 | ⬜ pending |
| 18 | TBD | 1 | CONN-06 | StreamData property: `fee ≤ gross` ∀ currencies | property | `mix test test/property/connect_platform_fee_property_test.exs` | ❌ W0 | ⬜ pending |
| 19 | TBD | 1 | CONN-06 | StreamData property: `clamp(clamp(x)) == clamp(x)` | property | `mix test test/property/connect_platform_fee_property_test.exs` | ❌ W0 | ⬜ pending |
| 20 | TBD | 1 | CONN-06 | StreamData property: `platform_fee(zero, _) == zero` | property | `mix test test/property/connect_platform_fee_property_test.exs` | ❌ W0 | ⬜ pending |
| 21 | TBD | 1 | CONN-07 | `create_login_link/2` returns `%LoginLink{}` for Express; rejects Standard/Custom | unit | `mix test test/accrue/connect/login_link_test.exs` | ❌ W0 | ⬜ pending |
| 22 | TBD | 1 | CONN-07 | `Inspect.inspect(%LoginLink{})` masks `:url` | unit | `mix test test/accrue/connect/login_link_test.exs` | ❌ W0 | ⬜ pending |
| 23 | TBD | 1 | CONN-08 | `update_account/3` with payout schedule round-trips through Fake | unit | `mix test test/accrue/connect/account_test.exs` | ❌ W0 | ⬜ pending |
| 24 | TBD | 1 | CONN-09 | `update_account/3` with capabilities round-trips through Fake | unit | `mix test test/accrue/connect/account_test.exs` | ❌ W0 | ⬜ pending |
| 25 | TBD | 0 | CONN-10 | Webhook plug verifies `:connect` endpoint event against `:connect` secret, not platform | integration | `mix test test/accrue/webhook/plug_test.exs` | ❌ W0 | ⬜ pending |
| 26 | TBD | 0 | CONN-10 | Tampered Connect-event signature returns 400 | integration | `mix test test/accrue/webhook/plug_test.exs` | ❌ W0 | ⬜ pending |
| 27 | TBD | 0 | CONN-10 | DispatchWorker routes `endpoint == :connect` to ConnectHandler | integration | `mix test test/accrue/webhook/dispatch_worker_test.exs` | ❌ W0 | ⬜ pending |
| 28 | TBD | 2 | CONN-11 | Same `Accrue.Billing.*` call works platform-scoped AND connected-account-scoped | integration | `mix test test/accrue/connect/dual_scope_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `priv/repo/migrations/20260415xxxxxx_create_accrue_connect_accounts.exs` — D5-02 schema
- [ ] `priv/repo/migrations/20260415xxxxxx_add_endpoint_to_accrue_webhook_events.exs` — closes Critical Finding (webhook endpoint persistence gap)
- [ ] `accrue/lib/accrue/webhook/webhook_event.ex` — add `field :endpoint, Ecto.Enum` + thread through ingest/changeset
- [ ] `accrue/lib/accrue/webhook/dispatch_worker.ex` — read `endpoint` from row, build `ctx.endpoint`, branch `:connect` → ConnectHandler
- [ ] `accrue/test/support/connect_case.ex` — Connect-aware setup; `Accrue.Test.Factory.connect_account/1` presets (Standard/Express/Custom × fully/partial)
- [ ] `accrue/test/support/stripe_fixtures.ex` — extend with Connect event fixtures (`account.updated`, `account.application.{authorized,deauthorized}`, `capability.updated`, `payout.*`)
- [ ] `accrue/test/property/connect_platform_fee_property_test.exs` — StreamData generators for `(currency, gross, percent, fixed)` tuples covering JPY/USD/KWD
- [ ] `accrue/test/live_stripe/connect_test.exs` — end-to-end Stripe test-mode round-trip covering all 11 CONN-* requirements
- [ ] Stub test files for all rows in the verification map above (27 files per RESEARCH.md)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Express dashboard login link renders Stripe dashboard | CONN-07 success criterion 5 | Stripe UI owned by external service; automated assertion limited to URL shape + struct fields | Run live_stripe suite, copy returned `%LoginLink{url}`, paste into browser, confirm Stripe-hosted dashboard loads for connected account |
| Account onboarding hosted flow redirects | CONN-02 success criterion 1 | Stripe-hosted onboarding page is external UI | Generate `%AccountLink{url}`, load in browser, complete minimal onboarding, confirm return to `return_url` with account status populated |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify command or Wave 0 dependency declared
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers every ❌ W0 row above before Wave 1 begins
- [ ] No watch-mode flags (`mix test.watch` etc.)
- [ ] Feedback latency < 20s for quick runs
- [ ] `nyquist_compliant: true` set in frontmatter after planner wires Task IDs

**Approval:** pending
