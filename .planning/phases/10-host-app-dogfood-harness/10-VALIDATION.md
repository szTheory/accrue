---
phase: 10
slug: host-app-dogfood-harness
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-16
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.ConnTest + Phoenix.LiveViewTest; optional Playwright local UAT if the planner chooses browser automation in Phase 10 |
| **Config file** | `examples/accrue_host/mix.exs`; optional `examples/accrue_host/playwright.config.js` if browser UAT is added |
| **Quick run command** | `cd examples/accrue_host && mix test` |
| **Full suite command** | `cd examples/accrue_host && mix test` or `cd examples/accrue_host && mix test && npm exec playwright test` if Playwright is added |
| **Estimated runtime** | ~60 seconds after dependencies are fetched |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && mix test`
- **After every plan wave:** Run `cd examples/accrue_host && mix test`
- **Before `$gsd-verify-work`:** Host app full suite must be green, plus any optional Playwright command if added
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | HOST-01, HOST-08 | — | N/A | integration | `cd examples/accrue_host && mix test` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | HOST-02 | T-10-03 | Proof path uses public installer/facade, not private inserts | integration | `cd examples/accrue_host && mix test test/install_boundary_test.exs` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | HOST-03 | — | Host owns billable user schema and generated billing facade | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` | ❌ W0 | ⬜ pending |
| 10-03-01 | 03 | 3 | HOST-06 | T-10-03 | User subscription flow routes through `AccrueHost.Billing` and `Accrue.Processor.Fake` | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/subscription_flow_test.exs` | ❌ W0 | ⬜ pending |
| 10-04-01 | 04 | 3 | HOST-04 | T-10-01 | Signed webhook POST is verified before ingest | integration | `cd examples/accrue_host && mix test test/accrue_host_web/webhook_ingest_test.exs` | ❌ W0 | ⬜ pending |
| 10-05-01 | 05 | 4 | HOST-05 | T-10-02 | Anonymous users cannot access `/billing`; admin access uses host session boundary | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs` | ❌ W0 | ⬜ pending |
| 10-05-02 | 05 | 4 | HOST-07 | T-10-02 | Admin replay/requeue produces persisted audit/event evidence | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs` | ❌ W0 | ⬜ pending |
| 10-05-03 | 05 | 4 | HOST-08 | T-10-04 | Documented clean-checkout commands run from the host app without hidden local state or secrets | smoke/scripted | `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/accrue_host` — normal Phoenix host app scaffold with local `../../accrue` and `../../accrue_admin` path deps.
- [ ] `examples/accrue_host/test/support/data_case.ex` and `examples/accrue_host/test/support/conn_case.ex` — host Repo/Conn test support.
- [ ] `examples/accrue_host/test/install_boundary_test.exs` — assertions that public installer/facade/router boundaries exist and private shortcuts are absent.
- [ ] `examples/accrue_host/test/accrue_host/billing_facade_test.exs` — green scaffold now, executable billable user + generated facade proof after Plan 10-02.
- [ ] `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` — green scaffold now, executable signed-in user subscription/update proof after Plan 10-03.
- [ ] `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` — green scaffold now, executable signed POST through webhook route proof after Plan 10-04.
- [ ] `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` — green scaffold now, executable auth/session protection proof for `/billing` after Plan 10-05.
- [ ] `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` — green scaffold now, executable admin inspected state plus audited replay/requeue proof after Plan 10-05.
- [ ] Optional `examples/accrue_host/package.json` and `examples/accrue_host/playwright.config.js` if browser UAT is selected in Phase 10.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clean-checkout boot with local PostgreSQL | HOST-08 | The local machine currently may not have PostgreSQL running on `localhost:5432`; automated tests can script the commands but cannot provision the user's database service. | Start PostgreSQL 14+, then run `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix phx.server`; confirm boot output includes the Phoenix endpoint URL and no missing env/secret errors. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify and remain green under `mix test`
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
