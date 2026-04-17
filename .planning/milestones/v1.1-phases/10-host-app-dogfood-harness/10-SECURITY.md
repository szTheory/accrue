---
phase: 10
slug: host-app-dogfood-harness
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-16
verified: 2026-04-16
---

# Phase 10 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo root -> examples/accrue_host | Generated host app must remain a real user-visible Phoenix app, not a hidden fixture. | Source, config, migrations, tests |
| browser session -> host auth | Host session/auth state must remain host-owned and realistic. | Session cookies, user token, current user |
| browser user -> host billing UI | Untrusted user input must be routed through host session auth and public billing APIs. | Plan selection, cancel action |
| external webhook sender -> /webhooks/stripe | Untrusted signed payload crosses into the host app. | Raw request body, Stripe signature header |
| host browser session -> mounted /billing UI | Only authenticated host admins may cross into admin functionality. | Session token, admin authorization |
| mounted admin replay -> Accrue replay/audit APIs | Admin actions must leave durable audit evidence. | Webhook replay command, actor context, ledger event |
| clean checkout -> local boot | Docs must surface all prerequisites and avoid hidden state. | Local env, database, Fake webhook secret |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-10-01 | Tampering | scaffold/config | mitigate | Standalone Phoenix app with explicit path deps verified in `examples/accrue_host/mix.exs`. | closed |
| T-10-02 | Information Disclosure | runtime/test config | mitigate | Fake processor and env-driven webhook secret handling in `config/test.exs` and `config/runtime.exs`. | closed |
| T-10-03 | Denial of Service | hidden local state | mitigate | Host-owned `AccrueHost.Repo` and sandbox config avoid private fixture state. | closed |
| T-10-04 | Elevation of Privilege | private fixture reuse | mitigate | `examples/accrue_host` is a standalone app with its own repo and OTP app. | closed |
| T-10-21 | Elevation of Privilege | auth/session scaffold | mitigate | Host-owned auth modules and session token flow exist in `accounts/user.ex` and `user_auth.ex`. | closed |
| T-10-22 | Tampering | router/live_session wiring | mitigate | Router uses authenticated pipeline and `live_session` hooks. | closed |
| T-10-23 | Denial of Service | auth drift | mitigate | Auth scaffold compiles and is wired through the host router. | closed |
| T-10-24 | Tampering | Wave 0 test scaffold | mitigate | Install-boundary tests lock public installer, router macro, and facade expectations. | closed |
| T-10-25 | Denial of Service | hidden local test state | mitigate | Host-owned `DataCase`, `ConnCase`, and `AccrueCase` isolate test state. | closed |
| T-10-26 | Elevation of Privilege | private proof shortcut | mitigate | Public-boundary proof tests exercise facade, LiveView, webhook, and admin paths. | closed |
| T-10-05 | Elevation of Privilege | install boundary | mitigate | Installer invocation and generated artifacts are asserted in `install_boundary_test.exs`. | closed |
| T-10-06 | Tampering | router webhook patch | mitigate | Route-scoped `CachingBodyReader` is present and installer patcher preserves it. | closed |
| T-10-07 | Elevation of Privilege | billable schema ownership | mitigate | Host user schema owns `use Accrue.Billable, billable_type: "User"`. | closed |
| T-10-08 | Information Disclosure | runtime config | mitigate | Fake-only defaults are local; production webhook secret now requires `STRIPE_WEBHOOK_SECRET`. | closed |
| T-10-09 | Elevation of Privilege | subscription UI | mitigate | LiveView calls `AccrueHost.Billing` facade and tests signed-in browser path. | closed |
| T-10-10 | Tampering | Fake-only billing proof | mitigate | Deterministic plan IDs and `Accrue.Processor.Fake` are configured for host tests. | closed |
| T-10-11 | Information Disclosure | UI copy/state | mitigate | Billing UI renders bounded product copy, not debug/state blobs. | closed |
| T-10-12 | Repudiation | update action proof | mitigate | Subscription flow test asserts persisted start/cancel state, not flash-only behavior. | closed |
| T-10-13 | Spoofing | webhook endpoint | mitigate | Webhook test covers signed success and tampered/unsigned rejection. | closed |
| T-10-14 | Tampering | raw-body parsing | mitigate | Webhook route uses raw-body reader; ingest test exercises the mounted endpoint. | closed |
| T-10-15 | Repudiation | webhook/audit integrity | mitigate | Host handler and tests verify persisted webhook row and ledger evidence. | closed |
| T-10-16 | Information Disclosure | secret handling | mitigate | Test secret remains local; production requires env secret; no raw secret logging found. | closed |
| T-10-17 | Elevation of Privilege | /billing mount | mitigate | `AccrueHost.Auth` and admin mount tests enforce anonymous, non-admin, and admin outcomes. | closed |
| T-10-18 | Repudiation | admin replay/audit | mitigate | Admin replay test verifies durable `admin.webhook.replay.completed` ledger evidence. | closed |
| T-10-19 | Information Disclosure | secrets and local state docs | mitigate | README documents commands, prerequisites, and local Fake webhook secret default. | closed |
| T-10-20 | Tampering | public API boundary bypass in admin proof | mitigate | Admin replay proof drives mounted admin UI rather than direct internal replay shortcuts. | closed |

## Evidence

| Threat ID | Evidence |
|-----------|----------|
| T-10-01 | `examples/accrue_host/mix.exs:65`, `examples/accrue_host/mix.exs:66` |
| T-10-02 | `examples/accrue_host/config/test.exs:22`, `examples/accrue_host/config/runtime.exs:33` |
| T-10-03 | `examples/accrue_host/lib/accrue_host/repo.ex:1`, `examples/accrue_host/config/test.exs:21` |
| T-10-04 | `examples/accrue_host/mix.exs:6`, `examples/accrue_host/lib/accrue_host/repo.ex:1` |
| T-10-21 | `examples/accrue_host/lib/accrue_host/accounts/user.ex:1`, `examples/accrue_host/lib/accrue_host_web/user_auth.ex:1` |
| T-10-22 | `examples/accrue_host/lib/accrue_host_web/router.ex:47`, `examples/accrue_host/lib/accrue_host_web/router.ex:49` |
| T-10-23 | `examples/accrue_host/lib/accrue_host_web/user_auth.ex:1`, `examples/accrue_host/lib/accrue_host_web/router.ex:47` |
| T-10-24 | `examples/accrue_host/test/install_boundary_test.exs:12`, `examples/accrue_host/test/install_boundary_test.exs:29` |
| T-10-25 | `examples/accrue_host/test/support/data_case.ex:1`, `examples/accrue_host/test/support/conn_case.ex:1`, `examples/accrue_host/test/support/accrue_case.ex:1` |
| T-10-26 | `examples/accrue_host/test/accrue_host/billing_facade_test.exs:47`, `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs:17`, `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:17` |
| T-10-05 | `examples/accrue_host/test/install_boundary_test.exs:16`, `examples/accrue_host/test/install_boundary_test.exs:37`, `examples/accrue_host/test/install_boundary_test.exs:38` |
| T-10-06 | `examples/accrue_host/lib/accrue_host_web/router.ex:71`, `examples/accrue_host/lib/accrue_host_web/router.ex:76`, `accrue/lib/accrue/install/patches.ex:81` |
| T-10-07 | `examples/accrue_host/lib/accrue_host/accounts/user.ex:3` |
| T-10-08 | `examples/accrue_host/config/runtime.exs:26`, `examples/accrue_host/config/runtime.exs:33`, `examples/accrue_host/config/test.exs:22` |
| T-10-09 | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:30`, `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:54`, `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs:33` |
| T-10-10 | `examples/accrue_host/lib/accrue_host/billing/plans.ex:6`, `examples/accrue_host/config/test.exs:22`, `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs:37` |
| T-10-11 | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:12`, `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:15`, `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:166` |
| T-10-12 | `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs:74`, `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs:83` |
| T-10-13 | `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:17`, `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:86` |
| T-10-14 | `examples/accrue_host/lib/accrue_host_web/router.ex:76`, `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:104` |
| T-10-15 | `examples/accrue_host/lib/accrue_host/billing_handler.ex:15`, `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:62`, `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs:71` |
| T-10-16 | `examples/accrue_host/config/test.exs:22`, `examples/accrue_host/config/test.exs:24`, `examples/accrue_host/config/runtime.exs:31` |
| T-10-17 | `examples/accrue_host/lib/accrue_host/auth.ex:22`, `examples/accrue_host/lib/accrue_host/auth.ex:45`, `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs:10`, `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs:21` |
| T-10-18 | `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:112`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:121`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:123` |
| T-10-19 | `examples/accrue_host/README.md:14`, `examples/accrue_host/README.md:16`, `examples/accrue_host/README.md:19`, `examples/accrue_host/README.md:25` |
| T-10-20 | `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:98`, `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs:110` |

## Accepted Risks Log

No accepted risks.

## Transfer Log

No transferred risks.

## Unregistered Flags

None. No `## Threat Flags` sections were present in `10-01-SUMMARY.md` through `10-07-SUMMARY.md`.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-16 | 26 | 26 | 0 | gsd-security-auditor |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-16
