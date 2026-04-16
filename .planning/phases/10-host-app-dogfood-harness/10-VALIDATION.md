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
| 10-01-01 | 01 | 1 | HOST-01 | T-10-03 | Core Phoenix host app exists with explicit host-owned Repo/runtime config and sibling path deps | integration | `cd examples/accrue_host && mix deps.get && mix compile` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 2 | HOST-01 | T-10-21 | Host auth/session boundary uses normal Phoenix-generated modules, not a private shortcut | integration | `cd examples/accrue_host && mix compile` | ❌ W0 | ⬜ pending |
| 10-03-01 | 03 | 3 | HOST-01, HOST-08 | T-10-25 | Host-owned Repo/Conn/Accrue test support boots the suite without private fixture state | integration | `cd examples/accrue_host && mix test` | ❌ W0 | ⬜ pending |
| 10-03-02 | 03 | 3 | HOST-01, HOST-08 | T-10-24 | Wave 0 proof files exist and compile while later plans replace scaffolds with executable proofs | integration | `cd examples/accrue_host && mix test` | ❌ W0 | ⬜ pending |
| 10-04-01 | 04 | 4 | HOST-02 | T-10-05 | Public installer patches router/config/generated files instead of private hand wiring | integration | `cd examples/accrue_host && mix accrue.install --yes --billable AccrueHost.Accounts.User --billing-context AccrueHost.Billing --admin-mount /billing --webhook-path /webhooks/stripe && mix test test/install_boundary_test.exs` | ❌ W0 | ⬜ pending |
| 10-04-02 | 04 | 4 | HOST-03 | T-10-06 | Host-owned user schema becomes billable and generated billing facade remains the proof boundary | integration | `cd examples/accrue_host && mix test test/accrue_host/billing_facade_test.exs` | ❌ W0 | ⬜ pending |
| 10-05-01 | 05 | 5 | HOST-06 | T-10-09 | Signed-in billing flow routes through `AccrueHost.Billing` and deterministic Fake plan IDs | integration | `cd examples/accrue_host && mix compile --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 10-05-02 | 05 | 5 | HOST-06 | T-10-12 | End-to-end subscription proof persists state and exercises update behavior through the host session boundary | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/subscription_flow_test.exs` | ❌ W0 | ⬜ pending |
| 10-06-01 | 06 | 5 | HOST-04 | T-10-16 | Host-local webhook dispatch wiring stays Fake-backed and does not leak signing secrets | integration | `cd examples/accrue_host && mix compile --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 10-06-02 | 06 | 5 | HOST-04 | T-10-13 | Signed webhook POST is verified before ingest and duplicate delivery stays idempotent | integration | `cd examples/accrue_host && mix test test/accrue_host_web/webhook_ingest_test.exs` | ❌ W0 | ⬜ pending |
| 10-07-01 | 07 | 6 | HOST-05 | T-10-17 | Anonymous and non-admin users cannot mount `/billing`; host admin session can | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_mount_test.exs` | ❌ W0 | ⬜ pending |
| 10-07-02 | 07 | 6 | HOST-07 | T-10-18 | Admin replay/requeue produces persisted audit/event evidence through the mounted UI | live/integration | `cd examples/accrue_host && mix test test/accrue_host_web/admin_webhook_replay_test.exs` | ❌ W0 | ⬜ pending |
| 10-07-03 | 07 | 6 | HOST-08 | T-10-19 | Documented clean-checkout commands run from the host app without hidden local state or secrets | smoke/scripted | `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix test && LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/accrue-host-boot.XXXXXX.log")" && ( export MIX_ENV=dev; mix phx.server >"$LOG_FILE" 2>&1 & SERVER_PID=$!; cleanup() { kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; rm -f "$LOG_FILE"; }; trap cleanup EXIT; READY=0; for _ in $(seq 1 30); do if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$LOG_FILE"; exit 1; fi; if rg -q 'Running AccrueHostWeb\.Endpoint|http://localhost:4000' "$LOG_FILE"; then READY=1; break; fi; sleep 1; done; if [ "$READY" -ne 1 ]; then cat "$LOG_FILE"; exit 1; fi; if rg -q 'secret_key_base|STRIPE_WEBHOOK_SECRET|could not start.*Repo|failed to start child: .*Repo|database .* does not exist|pending migrations|tcp connect .* refused' "$LOG_FILE"; then cat "$LOG_FILE"; exit 1; fi )` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/accrue_host` — normal Phoenix host app scaffold with local `../../accrue` and `../../accrue_admin` path deps.
- [ ] `examples/accrue_host/test/support/data_case.ex` and `examples/accrue_host/test/support/conn_case.ex` — host Repo/Conn test support.
- [ ] `examples/accrue_host/test/install_boundary_test.exs` — assertions that public installer/facade/router boundaries exist and private shortcuts are absent.
- [ ] `examples/accrue_host/test/accrue_host/billing_facade_test.exs` — green scaffold now, executable billable user + generated facade proof after Plan 10-04.
- [ ] `examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs` — green scaffold now, executable signed-in user subscription/update proof after Plan 10-05.
- [ ] `examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs` — green scaffold now, executable signed POST through webhook route proof after Plan 10-06.
- [ ] `examples/accrue_host/test/accrue_host_web/admin_mount_test.exs` — green scaffold now, executable auth/session protection proof for `/billing` after Plan 10-07.
- [ ] `examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs` — green scaffold now, executable admin inspected state plus audited replay/requeue proof after Plan 10-07.
- [ ] Optional `examples/accrue_host/package.json` and `examples/accrue_host/playwright.config.js` if browser UAT is selected in Phase 10.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Clean-checkout boot with local PostgreSQL | HOST-08 | The local machine currently may not have PostgreSQL running on `localhost:5432`; automated tests can script the commands but cannot provision the user's database service. | Start PostgreSQL 14+, then run the bounded smoke check from Plan 10-07: `cd examples/accrue_host && mix ecto.create && mix ecto.migrate && mix test && LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/accrue-host-boot.XXXXXX.log")" && ( export MIX_ENV=dev; mix phx.server >"$LOG_FILE" 2>&1 & SERVER_PID=$!; cleanup() { kill "$SERVER_PID" 2>/dev/null || true; wait "$SERVER_PID" 2>/dev/null || true; rm -f "$LOG_FILE"; }; trap cleanup EXIT; READY=0; for _ in $(seq 1 30); do if ! kill -0 "$SERVER_PID" 2>/dev/null; then cat "$LOG_FILE"; exit 1; fi; if rg -q 'Running AccrueHostWeb\.Endpoint|http://localhost:4000' "$LOG_FILE"; then READY=1; break; fi; sleep 1; done; if [ "$READY" -ne 1 ]; then cat "$LOG_FILE"; exit 1; fi; if rg -q 'secret_key_base|STRIPE_WEBHOOK_SECRET|could not start.*Repo|failed to start child: .*Repo|database .* does not exist|pending migrations|tcp connect .* refused' "$LOG_FILE"; then cat "$LOG_FILE"; exit 1; fi )`; confirm the command returns 0 only after Phoenix reports the endpoint URL and no missing env/secret/repo errors are present. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify and remain green under `mix test`
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
