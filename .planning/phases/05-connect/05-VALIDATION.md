---
phase: 5
slug: connect
status: approved
nyquist_compliant: true
wave_0_complete: true
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

| # | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 1 | 05-01 | 0 | PROC-05 | Resolution precedence opts > pdict > config; no leaked platform-scoped calls | unit | `mix test test/accrue/processor/stripe_test.exs` | ✅ | ✅ green |
| 2 | 05-01 | 0 | PROC-05 | `build_client!/1` threads `stripe_account:` into `LatticeStripe.Client.new!/1` | unit (Mox) | `mix test test/accrue/processor/stripe_test.exs` | ✅ | ✅ green |
| 3 | 05-01 | 0 | PROC-05 | Oban middleware carries `stripe_account` across job boundary | integration | `mix test test/accrue/oban/middleware_test.exs` | ✅ | ✅ green |
| 4 | 05-02 | 1 | CONN-01 | `create_account/2` round-trips `:standard` / `:express` / `:custom` via Fake | unit | `mix test test/accrue/connect/account_test.exs` | ✅ | ✅ green |
| 5 | 05-02 | 1 | CONN-01 | `type:` required — missing rejected with `%Accrue.Error{}` | unit | `mix test test/accrue/connect/account_test.exs` | ✅ | ✅ green |
| 6 | 05-03 | 1 | CONN-02 | `create_account_link/2` returns `%AccountLink{}` with `expires_at` | unit | `mix test test/accrue/connect/account_link_test.exs` | ✅ | ✅ green |
| 7 | 05-03 | 1 | CONN-02 | `Inspect.inspect(%AccountLink{})` masks `:url` as `<redacted>` | unit | `mix test test/accrue/connect/account_link_test.exs` | ✅ | ✅ green |
| 8 | 05-06 | 2 | CONN-03 | `account.updated` webhook updates state fields via `force_status_changeset` | integration | `mix test test/accrue/webhook/connect_handler_test.exs` | ✅ | ✅ green |
| 9 | 05-06 | 2 | CONN-03 | Out-of-order `account.updated` seeds local row via `retrieve_account/2` | integration | `mix test test/accrue/webhook/connect_handler_test.exs` | ✅ | ✅ green |
| 10 | 05-02 | 2 | CONN-03 | Predicates `fully_onboarded?/1`, `charges_enabled?/1` reflect post-webhook state | unit | `mix test test/accrue/connect/account_test.exs` | ✅ | ✅ green |
| 11 | 05-05 | 2 | CONN-04 | `destination_charge/2` request body carries `transfer_data.destination` + `application_fee_amount`; header NOT set | unit (Mox) | `mix test test/accrue/connect/charges_test.exs` | ✅ | ✅ green |
| 12 | 05-05 | 2 | CONN-04 | Returns `%Accrue.Billing.Charge{}` projection | integration | `mix test test/accrue/connect/charges_test.exs` | ✅ | ✅ green |
| 13 | 05-05 | 2 | CONN-05 | `separate_charge_and_transfer/2` issues two distinct API calls | unit (Mox) | `mix test test/accrue/connect/charges_test.exs` | ✅ | ✅ green |
| 14 | 05-05 | 2 | CONN-05 | `transfer/2` standalone helper round-trips through Fake | unit | `mix test test/accrue/connect/transfer_test.exs` | ✅ | ✅ green |
| 15 | 05-04 | 1 | CONN-06 | `platform_fee/2` USD: `$100 * 2.9% + $0.30 = $3.20` | unit | `mix test test/accrue/connect/platform_fee_test.exs` | ✅ | ✅ green |
| 16 | 05-04 | 1 | CONN-06 | `platform_fee/2` JPY (0-decimal) preserves precision | unit | `mix test test/accrue/connect/platform_fee_test.exs` | ✅ | ✅ green |
| 17 | 05-04 | 1 | CONN-06 | `platform_fee/2` KWD (3-decimal) preserves precision | unit | `mix test test/accrue/connect/platform_fee_test.exs` | ✅ | ✅ green |
| 18 | 05-04 | 1 | CONN-06 | StreamData property: `fee ≤ gross` ∀ currencies | property | `mix test test/property/connect_platform_fee_property_test.exs` | ✅ | ✅ green |
| 19 | 05-04 | 1 | CONN-06 | StreamData property: `clamp(clamp(x)) == clamp(x)` | property | `mix test test/property/connect_platform_fee_property_test.exs` | ✅ | ✅ green |
| 20 | 05-04 | 1 | CONN-06 | StreamData property: `platform_fee(zero, _) == zero` | property | `mix test test/property/connect_platform_fee_property_test.exs` | ✅ | ✅ green |
| 21 | 05-03 | 1 | CONN-07 | `create_login_link/2` returns `%LoginLink{}` for Express; rejects Standard/Custom | unit | `mix test test/accrue/connect/login_link_test.exs` | ✅ | ✅ green |
| 22 | 05-03 | 1 | CONN-07 | `Inspect.inspect(%LoginLink{})` masks `:url` | unit | `mix test test/accrue/connect/login_link_test.exs` | ✅ | ✅ green |
| 23 | 05-02 | 1 | CONN-08 | `update_account/3` with payout schedule round-trips through Fake | unit | `mix test test/accrue/connect/account_test.exs` | ✅ | ✅ green |
| 24 | 05-02 | 1 | CONN-09 | `update_account/3` with capabilities round-trips through Fake | unit | `mix test test/accrue/connect/account_test.exs` | ✅ | ✅ green |
| 25 | 05-01 | 0 | CONN-10 | Webhook plug verifies `:connect` endpoint event against `:connect` secret, not platform | integration | `mix test test/accrue/webhook/plug_test.exs` | ✅ | ✅ green |
| 26 | 05-01 | 0 | CONN-10 | Tampered Connect-event signature returns 400 | integration | `mix test test/accrue/webhook/plug_test.exs` | ✅ | ✅ green |
| 27 | 05-01 | 0 | CONN-10 | DispatchWorker routes `endpoint == :connect` to ConnectHandler | integration | `mix test test/accrue/webhook/dispatch_worker_test.exs` | ✅ | ✅ green |
| 28 | 05-02 | 2 | CONN-11 | Same `Accrue.Billing.*` call works platform-scoped AND connected-account-scoped | integration | `mix test test/accrue/connect/dual_scope_test.exs` | ✅ | ✅ green |
| 29 | 05-07 | 3 | Sign-off | Dual-scope + live_stripe coverage — guide + Pitfall 5 boot warning | integration | `mix test test/accrue/connect/dual_scope_test.exs && mix test --only live_stripe` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `priv/repo/migrations/20260415120100_create_accrue_connect_accounts.exs` — D5-02 schema
- [x] `priv/repo/migrations/20260415120000_add_endpoint_to_accrue_webhook_events.exs` — closes Critical Finding (webhook endpoint persistence gap)
- [x] `accrue/lib/accrue/webhook/webhook_event.ex` — `field :endpoint, Ecto.Enum` threaded through ingest/changeset
- [x] `accrue/lib/accrue/webhook/dispatch_worker.ex` — reads `endpoint` from row, builds `ctx.endpoint`, branches `:connect` → ConnectHandler
- [x] `accrue/test/support/connect_case.ex` — Connect-aware setup with pdict scope cleanup
- [x] `accrue/test/support/stripe_fixtures.ex` — extended with Connect event fixtures
- [x] `accrue/test/property/connect_platform_fee_property_test.exs` — StreamData coverage for JPY/USD/KWD
- [x] `accrue/test/live_stripe/connect_test.exs` — end-to-end Stripe test-mode round-trip (Plan 07)
- [x] Test files for all 29 rows in the verification map above

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Express dashboard login link renders Stripe dashboard | CONN-07 success criterion 5 | Stripe UI owned by external service; automated assertion limited to URL shape + struct fields | Run live_stripe suite, copy returned `%LoginLink{url}`, paste into browser, confirm Stripe-hosted dashboard loads for connected account |
| Account onboarding hosted flow redirects | CONN-02 success criterion 1 | Stripe-hosted onboarding page is external UI | Generate `%AccountLink{url}`, load in browser, complete minimal onboarding, confirm return to `return_url` with account status populated |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify command or Wave 0 dependency declared
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers every ❌ W0 row above before Wave 1 begins
- [x] No watch-mode flags (`mix test.watch` etc.)
- [x] Feedback latency < 20s for quick runs
- [x] `nyquist_compliant: true` set in frontmatter after planner wires Task IDs

**Approval:** approved — planner (Plan 07 nyquist sign-off, 2026-04-14)
