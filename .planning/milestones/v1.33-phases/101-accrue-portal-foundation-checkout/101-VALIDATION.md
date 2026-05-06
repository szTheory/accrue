---
phase: 101
slug: accrue-portal-foundation-checkout
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-01
---

# Phase 101 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source-of-truth detail in `101-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) + Phoenix.LiveViewTest 1.1 + LazyHTML |
| **Config file** | `accrue_portal/test/test_helper.exs` (Wave 0 — mirror `accrue_admin/test/test_helper.exs`) |
| **Quick run command** | `cd accrue_portal && mix test --stale` (per modified package) |
| **Full suite command** | `cd accrue && mix test.all && cd ../accrue_admin && mix test && cd ../accrue_portal && mix test` |
| **Estimated runtime** | ~60 seconds per package, ~3 min total |
| **Property test framework** | `:stream_data` (already in `accrue/mix.exs:92`) |
| **Mock framework** | `:mox` (already in `accrue/mix.exs:91`) |

---

## Sampling Rate

- **After every task commit:** Run `cd <modified_package> && mix test --stale`
- **After every plan wave:** Run all three per-package suites (full)
- **Before `/gsd-verify-work`:** Full suite green; `mix deps.audit` clean; Dialyzer clean; release-please dry-run succeeds for 3-package linked release
- **Max feedback latency:** ~60 seconds per package quick run

---

## Per-Task Verification Map

> Filled in concretely after planner emits PLAN.md files. Skeleton derived from RESEARCH.md §Validation Architecture phase-requirements-to-test map. The planner's per-task `<acceptance_criteria>` will reference these test commands directly.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 101-01-01 | 01 | 1 | BT-02 | T-101-01/T-101-03 | checkout sessions persist explicit URL/config state and reuse `operation_id` safely | unit | `cd accrue && mix test test/accrue/processor/braintree_local_portal_test.exs test/accrue/checkout/local_session_test.exs test/accrue/config_test.exs -x` | ✅ planned | ⬜ pending |
| 101-01-02 | 01 | 1 | BT-02 | T-101-02 | migration, fixture, and schema/index coverage prove the DB-backed contract | integration | `cd accrue && mix ecto.migrate && mix test test/accrue/processor/braintree_local_portal_test.exs test/accrue/checkout/local_session_test.exs test/accrue/config_test.exs -x` | ✅ planned | ⬜ pending |
| 101-02-01 | 02 | 1 | BT-01 | T-101-04/T-101-05 | production router/auth/CSP shell exposes the locked mount contract before shell proofs move to Plan 07 | static | `cd accrue_portal && mix compile && rg -n 'live_session :accrue_portal|ensure_customer_no_create|current_customer|js\\.braintreegateway\\.com|braintree-api\\.com' lib/accrue_portal/router.ex lib/accrue_portal/auth_hook.ex lib/accrue_portal/csp_plug.ex` | ✅ planned | ⬜ pending |
| 101-02-02 | 02 | 1 | BT-01 | T-101-06 | package-local browser harness base exists for later shell and LiveView tests | static | `cd accrue_portal && mix compile && test -f test/test_helper.exs && test -f test/support/conn_case.ex` | ✅ planned | ⬜ pending |
| 101-03-01 | 03 | 2 | BT-02 | T-101-07/T-101-08 | Braintree adapter implements checkout and billing-portal support behind the existing facade | unit | `cd accrue && mix test test/accrue/processor/capabilities_test.exs test/accrue/processor/braintree_local_portal_test.exs test/accrue/billing/checkout_session_facade_test.exs test/accrue/billing/billing_portal_session_facade_test.exs -x` | ✅ planned | ⬜ pending |
| 101-03-02 | 03 | 2 | BT-02 | T-101-09 | facade docs/tests preserve redirect semantics and Stripe non-regression | unit | `cd accrue && mix test test/accrue/processor/braintree_local_portal_test.exs test/accrue/billing/checkout_session_facade_test.exs test/accrue/billing/billing_portal_session_facade_test.exs -x` | ✅ planned | ⬜ pending |
| 101-07-01 | 07 | 2 | BT-01 | T-101-06 | `accrue_portal` publishes the exact D-04 runtime dependency contract without adapter SDK runtime deps | static | `cd accrue_portal && mix deps.tree --only prod | rg ' phoenix$| phoenix_live_view$| phoenix_html$| plug$| jason$| accrue$' && ! mix deps.tree --only prod | rg ' braintree$| lattice_stripe$'` | ✅ planned | ⬜ pending |
| 101-07-02 | 07 | 2 | BT-01 | T-101-04/T-101-05 | package-local shell tests prove router/auth/CSP behavior and install shared Braintree mocks | unit | `cd accrue_portal && mix test test/accrue_portal/router_test.exs test/accrue_portal/auth_hook_test.exs test/accrue_portal/csp_plug_test.exs -x` | ✅ planned | ⬜ pending |
| 101-04-01 | 04 | 3 | BT-02 | T-101-10/T-101-11 | Hosted Fields tokenize → `CheckoutLive.handle_event/3` → server `subscribe/3` round-trip; rendered Braintree CDN script tags carry pinned `integrity=` + `crossorigin=\"anonymous\"`; CheckoutLive renders and handles inline errors | integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs -x && rg -n 'integrity=\"sha384-(rNv6rxT4CpVv9Kb8luV4l/GpBwbhHTmZxWbI74/LX\\+ShrJzh/b9AL7nynSmHDpRC|QAzc9uX3XQPGzTESbnMNOUn9hY9jVL/L10Eq3Gxt4NKXIZZWzGlhnEscA3iGj8Jp)\"|crossorigin=\"anonymous\"' accrue_portal/lib/accrue_portal/live/checkout_live.ex accrue_portal/priv/static/accrue_portal.js` | ✅ planned | ⬜ pending |
| 101-04-02 | 04 | 3 | BT-02 | T-101-10/T-101-11 | checkout interaction contract stays pinned to package-local LiveView coverage | integration | `cd accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs -x` | ✅ planned | ⬜ pending |
| 101-05-01 | 05 | 4 | BT-03 | T-101-13/T-101-14 | dashboard + subscription production code is customer-scoped and copy-centralized before fixture/property proofs land | static | `cd accrue_portal && mix compile && rg -n 'No active subscriptions|Manage subscriptions|Cancel subscription|Keep subscription' lib/accrue_portal/copy.ex && ! rg -n 'No active subscriptions|Manage subscriptions|Cancel subscription|Keep subscription' lib/accrue_portal/live/home_live.ex lib/accrue_portal/live/subscriptions_live.ex lib/accrue_portal/live/subscription_live.ex` | ✅ planned | ⬜ pending |
| 101-08-01 | 08 | 4 | BT-02 | T-101-12 | successful checkout enqueues and persists a synthetic `accrue.portal.checkout.completed` event | integration | `cd accrue && mix test test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs -x && cd ../accrue_portal && mix test test/accrue_portal/live/checkout_live_test.exs -x` | ✅ planned | ⬜ pending |
| 101-08-02 | 08 | 4 | BT-02 | T-101-12 | portal completion telemetry stays covered independently of the checkout UI slice | unit | `cd accrue && mix test test/accrue/webhook/default_handler_portal_event_test.exs test/accrue/telemetry/portal_checkout_completed_test.exs -x` | ✅ planned | ⬜ pending |
| 101-06-01 | 06 | 5 | BT-03 | T-101-16 | payment-method and invoice production code is routed and copy-centralized before focused coverage lands | static | `cd accrue_portal && mix compile && rg -n 'No payment methods on file|Add a card|Save card|Discard card|Delete card|Keep card|No invoices yet' lib/accrue_portal/copy.ex && ! rg -n 'No payment methods on file|Add a card|Save card|Discard card|Delete card|Keep card|No invoices yet' lib/accrue_portal/live/payment_methods_live.ex lib/accrue_portal/live/add_payment_method_live.ex lib/accrue_portal/live/invoices_live.ex` | ✅ planned | ⬜ pending |
| 101-09-01 | 09 | 5 | BT-03 | T-101-15 | shared fixtures and authorization assertions exist for the subscription slice | static | `cd accrue_portal && test -f test/support/fixtures.ex && test -f test/support/authorize_assertions.ex` | ✅ planned | ⬜ pending |
| 101-09-02 | 09 | 5 | BT-03 | T-101-13/T-101-15 | dashboard, subscription, and wrong-tenant property tests prove D-19 with real fixtures | property | `cd accrue_portal && mix test test/accrue_portal/live/home_live_test.exs test/accrue_portal/live/subscriptions_live_test.exs test/accrue_portal/live/subscription_live_test.exs test/accrue_portal/live/wrong_tenant_property_test.exs -x` | ✅ planned | ⬜ pending |
| 101-10-01 | 10 | 6 | BT-03 | T-101-16 | router, payment-method, add-card, and invoice tests prove the remaining pages plus wrong-tenant denial cases | integration | `cd accrue_portal && mix test test/accrue_portal/router_test.exs test/accrue_portal/live/payment_methods_live_test.exs test/accrue_portal/live/add_payment_method_live_test.exs test/accrue_portal/live/invoices_live_test.exs test/accrue_portal/live/payment_methods_wrong_tenant_test.exs test/accrue_portal/live/invoices_wrong_tenant_test.exs -x` | ✅ planned | ⬜ pending |
| 101-11-01 | 11 | 6 | BT-01/02/03 | T-101-17 | release metadata and the example host prove the three-package sibling-mount contract | integration | `node -e 'const cfg=require(\"./release-please-config.json\"); const group=cfg.plugins.find((p)=>p.type===\"linked-versions\"); const want=[\"accrue\",\"accrue_admin\",\"accrue_portal\"]; if(!group) throw new Error(\"missing linked-versions plugin\"); if(JSON.stringify(group.components)!==JSON.stringify(want)) throw new Error(\`unexpected components: \${JSON.stringify(group.components)}\`); for (const key of want) if (!cfg.packages[key]) throw new Error(\`missing package \${key}\`); console.log(\"linked-release config ok\");' && cd examples/accrue_host && mix compile` | ✅ planned | ⬜ pending |
| 101-11-02 | 11 | 6 | BT-02/03 | T-101-18 | docs state the v1.33 session-resolved boundary and the host-owned `/checkout/start?token=...` escape hatch | static | `rg -n '/checkout/start\\?token=|session-resolved-customer-only|accrue_portal|braintree-local-portal|accrue_admin \"/admin\"|accrue_portal \"/billing\"' accrue_portal/README.md accrue/guides/braintree-local-portal.md examples/accrue_host/lib/accrue_host_web/router.ex` | ✅ planned | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Task IDs are now bound to the concrete Plan 01-11 task set above.

---

## Wave 0 Requirements

All net-new test infrastructure now has explicit plan ownership:

- [x] `accrue_portal/test/test_helper.exs` — owned by Plan 02 Task 2
- [x] `accrue_portal/test/support/conn_case.ex` — owned by Plan 02 Task 2
- [x] `accrue_portal/test/support/braintree_mox.ex` — owned by Plan 07 Task 2
- [x] `accrue/test/support/checkout_session_fixture.ex` — owned by Plan 01 Task 2
- [x] Migration test / schema-coverage assertions for `accrue_checkout_sessions` — owned by Plan 01 Task 2
- [x] `accrue_portal/test/support/fixtures.ex` — owned by Plan 09 Task 1
- [x] `accrue_portal/test/support/authorize_assertions.ex` for D-19 wrong-tenant enforcement — owned by Plan 09 Task 1
- [x] Portal package test deps (`:lazy_html`, `:plug_cowboy` as needed) — owned by Plan 07 Task 1

**Framework install:** None — ExUnit is in-stack.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hosted Fields iframe loads from `js.braintreegateway.com` with valid SRI hash in a real browser | BT-02 | SRI + cross-origin script load not feasible in headless ExUnit/LiveViewTest | `cd examples/portal_demo && mix phx.server` → open Chrome devtools Network tab → confirm `client.min.js` and `hosted-fields.min.js` load with `crossorigin=anonymous` and pass SRI integrity check |
| Real Braintree sandbox tokenize → vault round-trip | BT-02 | Requires live Braintree sandbox merchant credentials | `cd examples/portal_demo && BRAINTREE_ENV=sandbox MERCHANT_ID=… mix phx.server` → submit Hosted Fields with sandbox card 4111-1111-1111-1111 → confirm `Accrue.Billing.subscribe/3` returns `{:ok, %Subscription{}}` |
| CSP `frame-ancestors 'self'` actually blocks attacker iframe | T5 | Requires loading the portal in a hostile parent iframe | Manual: host attacker page that `<iframe src="…/portal/checkout">` → confirm browser refuses to render |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<acceptance_criteria>` referencing the per-task command above OR a Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all former ❌ W0 references in the per-task map
- [x] No watch-mode flags (`mix test.watch`, `--stale --listen-on-stdin`) in CI commands
- [x] Feedback latency < 60 seconds per package quick run
- [x] `nyquist_compliant: true` set in frontmatter once planner has bound every task to a row above

**Approval:** pending
