---
phase: 10-host-app-dogfood-harness
verified: 2026-04-16T17:17:36Z
status: verified
score: 5/5 must-haves verified
overrides_applied: 0
human_verification: []
uat_automation:
  script: scripts/ci/accrue_host_uat.sh
  workflow: .github/workflows/accrue_host_uat.yml
  last_passed: 2026-04-16T18:08:56Z
---

# Phase 10: Host App Dogfood Harness Verification Report

**Phase Goal:** Canonical minimal Phoenix app that installs and uses `accrue` + `accrue_admin` through public APIs.
**Verified:** 2026-04-16T17:17:36Z
**Status:** verified
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A clean checkout can build the host app from documented commands, run migrations, and boot without hidden machine-local state. | ✓ VERIFIED | [examples/accrue_host/README.md](/Users/jon/projects/accrue/examples/accrue_host/README.md) documents `mix deps.get`, `mix accrue.install`, `mix ecto.create`, `mix ecto.migrate`, `mix test`, and `mix phx.server`. Host-owned repo/runtime wiring is in [examples/accrue_host/config/test.exs](/Users/jon/projects/accrue/examples/accrue_host/config/test.exs) and [examples/accrue_host/config/runtime.exs](/Users/jon/projects/accrue/examples/accrue_host/config/runtime.exs). `mix compile` and full `mix test` passed in `examples/accrue_host`. |
| 2 | The host app uses the public installer and generated host-facing billing facade rather than hand-wiring private Accrue internals. | ✓ VERIFIED | [examples/accrue_host/lib/accrue_host/billing.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing.ex) and [examples/accrue_host/lib/accrue_host/billing_handler.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/billing_handler.ex) carry installer generation markers and delegate through public modules. [examples/accrue_host/test/install_boundary_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/install_boundary_test.exs) asserts installer-owned router/runtime/billing boundaries. |
| 3 | A Fake-backed user-facing flow creates or updates realistic billing state through checkout/subscription APIs. | ✓ VERIFIED | [examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex) calls the host facade and reloads persisted customer/subscription state from `Accrue.Billing.Customer` and `Accrue.Billing.Subscription`. [examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs) proved start and cancel behavior with persisted DB records. |
| 4 | The host app mounts a scoped webhook endpoint and processes signed Fake/Stripe-shaped webhook payloads through the normal ingest path. | ✓ VERIFIED | [examples/accrue_host/lib/accrue_host_web/router.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host_web/router.ex) mounts `accrue_webhook("/stripe", :stripe)` under `/webhooks`. [examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs) posts a signed payload, verifies idempotent ingest, runs `Accrue.Webhook.DispatchWorker`, and checks persisted `accrue_webhook_events` plus ledger events. |
| 5 | `accrue_admin` is mounted behind a realistic auth/session boundary and can inspect state plus perform one audited admin action. | ✓ VERIFIED | [examples/accrue_host/lib/accrue_host/auth.ex](/Users/jon/projects/accrue/examples/accrue_host/lib/accrue_host/auth.ex) implements the host auth adapter over real host sessions and `billing_admin`. [examples/accrue_host/test/accrue_host_web/admin_mount_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_mount_test.exs) denies anonymous/non-admin access and mounts `/billing` for admins. [examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs](/Users/jon/projects/accrue/examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs) proves inspect-and-replay behavior and persisted `admin.webhook.replay.completed` audit evidence. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `examples/accrue_host/mix.exs` | Host Phoenix app with local sibling deps | ✓ VERIFIED | Contains `app: :accrue_host`, `{:accrue, path: "../../accrue"}`, and `{:accrue_admin, path: "../../accrue_admin"}`. |
| `examples/accrue_host/config/test.exs` | Host-owned test repo and Fake wiring | ✓ VERIFIED | Configures `AccrueHost.Repo`, sandbox DB, `processor: Accrue.Processor.Fake`, and `repo: AccrueHost.Repo`. |
| `examples/accrue_host/lib/accrue_host/repo.ex` | Host-owned repo | ✓ VERIFIED | Real `Ecto.Repo` module used by host app config and tests. |
| `examples/accrue_host/lib/accrue_host/accounts/user.ex` | Host-owned auth + billable schema | ✓ VERIFIED | Real `users` schema with `use Accrue.Billable, billable_type: "User"` and `billing_admin` flag. |
| `examples/accrue_host/lib/accrue_host_web/user_auth.ex` | Host session/auth helpers | ✓ VERIFIED | Phoenix auth scaffold with session token loading, `live_session` hooks, and redirects. |
| `examples/accrue_host/test/support/accrue_case.ex` | Host integration harness | ✓ VERIFIED | Host-owned case template built on repo sandbox plus `Accrue.Test`. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | Generated host billing facade | ✓ VERIFIED | Non-stub facade with public `subscribe`, `swap_plan`, `cancel`, and `customer_for` delegates. |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | User billing UI | ✓ VERIFIED | 382 lines, wired to host facade and repo-backed billing state. |
| `examples/accrue_host/lib/accrue_host/billing_handler.ex` | Host webhook handler | ✓ VERIFIED | Records `host.webhook.handled` events from normal webhook dispatch. |
| `examples/accrue_host/lib/accrue_host/auth.ex` | Admin auth adapter | ✓ VERIFIED | Enforces admin access through host session token lookup and `billing_admin`. |
| `examples/accrue_host/README.md` | Clean-checkout command path | ✓ VERIFIED | Documents rebuild/install/migrate/test/boot commands and local defaults. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `examples/accrue_host/mix.exs` | `../../accrue` | path dependency | ✓ WIRED | Local path dep present. |
| `examples/accrue_host/mix.exs` | `../../accrue_admin` | path dependency | ✓ WIRED | Local path dep present. |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | `AccrueHostWeb.UserAuth` | authenticated session wiring | ✓ WIRED | `pipe_through([:browser, :require_authenticated_user])` and `live_session` on-mount hooks are present. |
| `examples/accrue_host/lib/accrue_host/billing.ex` | `Accrue.Billing` | generated public facade | ✓ WIRED | Host facade delegates through `Billing.subscribe/3`, `swap_plan/3`, `cancel/2`, and `customer/1`. |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | `examples/accrue_host/lib/accrue_host/billing.ex` | public host facade call | ✓ WIRED | Manual verification shows alias `AccrueHost.Billing` plus `Billing.subscribe/3` and `Billing.cancel/2`. `gsd-tools verify key-links` missed this because it searched for the fully qualified call. |
| `examples/accrue_host/lib/accrue_host_web/controllers/page_html/home.html.heex` | `/app/billing` route | signed-in navigation link | ✓ WIRED | Signed-in home page renders a visible `Go to billing` link. |
| `examples/accrue_host/lib/accrue_host_web/router.ex` | `/webhooks/stripe` | scoped public webhook mount | ✓ WIRED | Raw-body pipeline plus `accrue_webhook("/stripe", :stripe)` inside `/webhooks` scope. |
| `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` | `/webhooks/stripe` | signed payload POST | ✓ WIRED | Test posts through router and asserts persisted results. |
| `examples/accrue_host/lib/accrue_host/auth.ex` | `examples/accrue_host/lib/accrue_host/accounts/user.ex` | host admin/user lookup | ✓ WIRED | Uses `Accounts.get_user_by_session_token/1`, `User`, and `billing_admin`. |
| `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | `admin.webhook.replay.completed` | event-ledger assertion | ✓ WIRED | Test queries persisted audit event after replay. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | `@customer`, `@subscription` | `fetch_customer/1` and `current_subscription/1` query `Accrue.Billing.Customer` and preloaded subscriptions through `AccrueHost.Repo` after facade calls | Yes - `subscription_flow_test` proves persisted customer and subscription rows exist and are reloaded into the LiveView | ✓ FLOWING |
| `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` | `webhook`, ledger events | POST `/webhooks/stripe` -> router webhook macro -> `WebhookEvent` insert -> `DispatchWorker.perform/1` -> `AccrueHost.BillingHandler` -> `Accrue.Events` | Yes - test asserts one webhook row, one job, succeeded status, and persisted `webhook.received` plus `host.webhook.handled` events | ✓ FLOWING |
| `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | subscription page, webhook page, audit event | Real seeded `Customer`, `Subscription`, `WebhookEvent`, and `Oban.Job` rows rendered through mounted `accrue_admin` LiveViews | Yes - test renders `/billing/subscriptions/:id`, `/billing/webhooks/:id`, `/billing/events`, replays a row, and queries persisted `admin.webhook.replay.completed` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Host app compiles as its own Phoenix app | `cd examples/accrue_host && mix compile` | exit 0 | ✓ PASS |
| Public-boundary proof files execute | `cd examples/accrue_host && mix test test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs test/accrue_host_web/admin_mount_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` | 16 tests, 0 failures | ✓ PASS |
| Full host suite stays green | `cd examples/accrue_host && mix test` | 127 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| HOST-01 | 10-01, 10-02, 10-03 | Minimal Phoenix host app exists as canonical dogfood app | ✓ SATISFIED | `examples/accrue_host` is a real Phoenix app with host-owned auth, repo, test harness, and green full suite. |
| HOST-02 | 10-04 | Host app uses public installer and package APIs rather than private shortcuts | ✓ SATISFIED | Generated billing facade and webhook handler are installer-marked; router uses `Accrue.Router` and `AccrueAdmin.Router`; install-boundary test locks those boundaries. |
| HOST-03 | 10-04 | Host app has a realistic billable schema and generated billing facade | ✓ SATISFIED | `AccrueHost.Accounts.User` is `use Accrue.Billable`; `AccrueHost.Billing` exposes generated facade functions; facade tests create real customers/subscriptions. |
| HOST-04 | 10-06 | Host app mounts scoped webhook endpoint and verifies signed webhook payloads end to end | ✓ SATISFIED | Router mounts `/webhooks/stripe`; webhook ingest test verifies signed success, tampered rejection, idempotency, dispatch, and ledger evidence. |
| HOST-05 | 10-07 | Host app mounts `accrue_admin` behind realistic auth/session boundary | ✓ SATISFIED | `AccrueHost.Auth` reads real host session tokens; admin mount test denies anonymous/non-admin users and allows billing admins. |
| HOST-06 | 10-05 | User-facing checkout/subscription flow works through host app against Fake processor | ✓ SATISFIED | Subscription LiveView plus flow test prove start and cancel behavior through `AccrueHost.Billing` with persisted fake-backed state. |
| HOST-07 | 10-07 | Admin flow can inspect billing state, history, and perform an audited action | ✓ SATISFIED | Admin replay test renders subscription/webhook/events pages, replays a webhook row, and verifies persisted admin audit event. |
| HOST-08 | 10-03, 10-07 | Host app can be rebuilt from clean checkout with documented commands and no hidden local state | ✓ SATISFIED | README documents rebuild path and the CI-equivalent `bash scripts/ci/accrue_host_uat.sh` command; the automation reruns install, creates/migrates databases, builds assets, runs focused and full host suites, boots Phoenix, and runs browser smoke against the live app. |

No orphaned Phase 10 requirements were found in [.planning/REQUIREMENTS.md](/Users/jon/projects/accrue/.planning/REQUIREMENTS.md); all required IDs `HOST-01` through `HOST-08` are claimed by Phase 10 plans and accounted for above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| - | - | No TODO/FIXME/placeholder or empty-implementation stub patterns found in scanned `examples/accrue_host/lib` and `examples/accrue_host/test` files. | ℹ️ Info | No blocker anti-patterns surfaced in the host harness implementation. |

### Automated UAT

The prior human-only checks are now automated by [scripts/ci/accrue_host_uat.sh](/Users/jon/projects/accrue/scripts/ci/accrue_host_uat.sh) and wired into [accrue_host_uat.yml](/Users/jon/projects/accrue/.github/workflows/accrue_host_uat.yml).

| Former Human Check | Automated Coverage | Status |
| --- | --- | --- |
| Clean-checkout local boot | Reruns documented setup, installer idempotence, compile, asset build, focused UAT suite, full host suite, DB create/migrate, and bounded `mix phx.server` boot smoke. | ✓ PASS |
| Browser billing/admin smoke | Seeds deterministic users/webhook fixture, starts Phoenix in test mode, and uses Playwright Chromium to verify normal-user billing start/cancel plus admin dashboard/webhook replay/audit evidence. | ✓ PASS |

### Gaps Summary

No code, wiring, or UAT gaps remain against the Phase 10 goal or the declared `HOST-01` through `HOST-08` requirements. Automated verification and security verification support phase completion.

---

_Verified: 2026-04-16T17:17:36Z_  
_Verifier: Claude (gsd-verifier)_
