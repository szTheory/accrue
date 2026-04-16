---
phase: 10
slug: host-app-dogfood-harness
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-16
updated: 2026-04-16
---

# Phase 10 - Validation Strategy

Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.ConnTest + Phoenix.LiveViewTest; shell UAT script; Playwright Test through the host UAT path |
| **Config file** | `examples/accrue_host/mix.exs`, `examples/accrue_host/config/test.exs`, `examples/accrue_host/playwright.config.js`, `scripts/ci/accrue_host_uat.sh` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix ecto.drop --quiet || true && MIX_ENV=test mix ecto.create --quiet && MIX_ENV=test mix ecto.migrate --quiet && mix test --max-cases 1` |
| **Focused proof command** | `cd examples/accrue_host && MIX_ENV=test mix ecto.drop --quiet || true && MIX_ENV=test mix ecto.create --quiet && MIX_ENV=test mix ecto.migrate --quiet && mix test --max-cases 1 test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs test/accrue_host_web/admin_mount_test.exs test/accrue_host_web/admin_webhook_replay_test.exs` |
| **Full suite command** | `bash scripts/ci/accrue_host_uat.sh` |
| **Estimated runtime** | ~30 seconds for full host UAT on a warm machine |

---

## Sampling Rate

- **After every task commit:** Run the narrow command listed in that task's `<verification>` block.
- **After every plan wave:** Run `cd examples/accrue_host && mix test` after a clean test DB reset.
- **Before `$gsd-verify-work`:** Run `bash scripts/ci/accrue_host_uat.sh` so installer rerun, generated-drift check, compile, focused tests, full suite, boot smoke, and browser smoke all execute in the same path CI uses.
- **Max feedback latency:** 120 seconds for ExUnit-only checks; 20 minutes for cold full UAT.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 10-01 | 1 | HOST-01 | T-10-03 | Core Phoenix host app exists with explicit host-owned Repo/runtime config and sibling path deps | integration | `cd examples/accrue_host && mix compile --warnings-as-errors` | `examples/accrue_host/mix.exs`, `examples/accrue_host/config/test.exs`, `examples/accrue_host/lib/accrue_host/repo.ex` | ✅ green |
| 10-02-01 | 10-02 | 2 | HOST-01 | T-10-21 | Host auth/session boundary uses normal Phoenix-generated modules, not a private shortcut | integration | `cd examples/accrue_host && mix compile --warnings-as-errors` | `examples/accrue_host/lib/accrue_host_web/user_auth.ex`, `examples/accrue_host/lib/accrue_host/accounts/user.ex` | ✅ green |
| 10-03-01 | 10-03 | 3 | HOST-01, HOST-08 | T-10-25 | Host-owned Repo/Conn/Accrue test support boots the suite without private fixture state | integration | `cd examples/accrue_host && mix test --max-cases 1` | `examples/accrue_host/test/support/data_case.ex`, `examples/accrue_host/test/support/conn_case.ex`, `examples/accrue_host/test/support/accrue_case.ex` | ✅ green |
| 10-03-02 | 10-03 | 3 | HOST-01, HOST-08 | T-10-24 | Wave 0 proof files exist and compile while later plans replace scaffolds with executable proofs | integration | `cd examples/accrue_host && mix test --max-cases 1` | `examples/accrue_host/test/install_boundary_test.exs`, host proof test files under `examples/accrue_host/test/accrue_host*` | ✅ green |
| 10-04-01 | 10-04 | 4 | HOST-02 | T-10-05 | Public installer patches router/config/generated files instead of private hand wiring | integration | `bash scripts/ci/accrue_host_uat.sh` and `cd examples/accrue_host && mix test --max-cases 1 test/install_boundary_test.exs` | `examples/accrue_host/lib/accrue_host/billing.ex`, `examples/accrue_host/lib/accrue_host/billing_handler.ex`, `examples/accrue_host/lib/accrue_host_web/router.ex` | ✅ green |
| 10-04-02 | 10-04 | 4 | HOST-03 | T-10-06 | Host-owned user schema becomes billable and generated billing facade remains the proof boundary | integration | `cd examples/accrue_host && mix test --max-cases 1 test/accrue_host/billing_facade_test.exs` | `examples/accrue_host/lib/accrue_host/accounts/user.ex`, `examples/accrue_host/lib/accrue_host/billing.ex`, `examples/accrue_host/test/accrue_host/billing_facade_test.exs` | ✅ green |
| 10-05-01 | 10-05 | 5 | HOST-06 | T-10-09 | Signed-in billing flow routes through `AccrueHost.Billing` and deterministic Fake plan IDs | integration | `cd examples/accrue_host && mix compile --warnings-as-errors` | `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex`, `examples/accrue_host/lib/accrue_host/billing.ex` | ✅ green |
| 10-05-02 | 10-05 | 5 | HOST-06 | T-10-12 | End-to-end subscription proof persists state and exercises update behavior through the host session boundary | live/integration | `cd examples/accrue_host && mix test --max-cases 1 test/accrue_host_web/subscription_flow_test.exs` | `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` | ✅ green |
| 10-06-01 | 10-06 | 5 | HOST-04 | T-10-16 | Host-local webhook dispatch wiring stays Fake-backed and does not leak signing secrets | integration | `cd examples/accrue_host && mix compile --warnings-as-errors` | `examples/accrue_host/lib/accrue_host/billing_handler.ex`, `examples/accrue_host/lib/accrue_host_web/router.ex` | ✅ green |
| 10-06-02 | 10-06 | 5 | HOST-04 | T-10-13 | Signed webhook POST is verified before ingest and duplicate delivery stays idempotent | integration | `cd examples/accrue_host && mix test --max-cases 1 test/accrue_host_web/webhook_ingest_test.exs` | `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` | ✅ green |
| 10-07-01 | 10-07 | 6 | HOST-05 | T-10-17 | Anonymous and non-admin users cannot mount `/billing`; host admin session can | live/integration | `cd examples/accrue_host && mix test --max-cases 1 test/accrue_host_web/admin_mount_test.exs` | `examples/accrue_host/lib/accrue_host/auth.ex`, `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` | ✅ green |
| 10-07-02 | 10-07 | 6 | HOST-07 | T-10-18 | Admin inspects billing state, webhook history, and event activity before replay; replay produces persisted `admin.webhook.replay.completed` audit/event evidence | live/integration | `cd examples/accrue_host && mix test --max-cases 1 test/accrue_host_web/admin_webhook_replay_test.exs` | `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` | ✅ green |
| 10-07-03 | 10-07 | 6 | HOST-08 | T-10-19 | Documented clean-checkout commands run from the host app without hidden local state or secrets | smoke/scripted | `bash scripts/ci/accrue_host_uat.sh` | `examples/accrue_host/README.md`, `scripts/ci/accrue_host_uat.sh` | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `examples/accrue_host` is a normal Phoenix host app scaffold with local `../../accrue` and `../../accrue_admin` path deps.
- [x] `examples/accrue_host/test/support/data_case.ex` and `examples/accrue_host/test/support/conn_case.ex` provide host Repo/Conn test support.
- [x] `examples/accrue_host/test/install_boundary_test.exs` asserts public installer/facade/router boundaries exist and private shortcuts are absent.
- [x] `examples/accrue_host/test/accrue_host/billing_facade_test.exs` proves billable user + generated facade behavior.
- [x] `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` proves signed-in user subscription/cancel behavior.
- [x] `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` proves signed POST through webhook route behavior.
- [x] `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` proves auth/session protection for `/billing`.
- [x] `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` proves admin inspected state plus audited replay/requeue behavior.
- [x] Browser UAT is covered through the Phase 11 host-local Playwright package and `scripts/ci/accrue_host_uat.sh`.

---

## Manual-Only Verifications

No manual-only validation remains for Phase 10. The clean-checkout boot path is covered by `bash scripts/ci/accrue_host_uat.sh`, which reruns setup, resets/migrates the database, runs focused and full host suites, performs a bounded `mix phx.server` boot smoke, and executes the browser billing/admin smoke.

---

## Validation Audit 2026-04-16

| Metric | Count |
|--------|-------|
| Gaps found | 13 stale pending rows |
| Resolved | 13 |
| Escalated | 0 |

Commands run during this audit:

- `cd examples/accrue_host && MIX_ENV=test mix ecto.drop --quiet || true && MIX_ENV=test mix ecto.create --quiet && MIX_ENV=test mix ecto.migrate --quiet && mix compile --warnings-as-errors && mix test --max-cases 1 test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs test/accrue_host_web/admin_mount_test.exs test/accrue_host_web/admin_webhook_replay_test.exs && mix test --max-cases 1`
- `bash scripts/ci/accrue_host_uat.sh`

Note: an earlier attempt to run multiple Mix test commands in parallel was invalid because concurrent BEAM/Postgres clients exhausted local Postgres connections and contaminated the shared test database. The recorded validation result is based on the clean sequential rerun above.

---

## Validation Sign-Off

- [x] All tasks have automated verify and remain green under focused/full host checks
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency defined
- [x] `nyquist_compliant: true` set in frontmatter
- [x] `wave_0_complete: true` set in frontmatter

**Approval:** approved 2026-04-16
