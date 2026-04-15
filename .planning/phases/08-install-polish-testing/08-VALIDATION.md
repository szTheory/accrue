---
phase: 08
slug: install-polish-testing
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-15
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL Sandbox, Oban.Testing, Mox, StreamData |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `accrue/mix.exs` |
| **Quick run command** | `cd accrue && mix test test/accrue/test test/accrue/config_test.exs test/accrue/telemetry_test.exs` |
| **Full suite command** | `cd accrue && mix test.all && cd ../accrue_admin && mix test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd accrue && mix test test/accrue/test test/accrue/config_test.exs test/accrue/telemetry_test.exs`
- **After every plan wave:** Run `cd accrue && mix test.all` plus targeted `cd accrue_admin && mix test test/accrue_admin/router_test.exs` when installer/admin mount behavior changes
- **Before `$gsd-verify-work`:** Run fresh Phoenix install smoke, `cd accrue && mix test.all`, `cd accrue_admin && mix test`, and compile checks for with/without OTel and Sigra
- **Max feedback latency:** 120 seconds for targeted tests, full suite before wave completion

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 0 | INST-01..10 | T-08-01 / T-08-02 | Installer dry-run, idempotency, no-clobber, safe report | integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs` | no W0 | pending |
| 08-01-02 | 01 | 0 | INST-08 | T-08-01 | Handler generator never overwrites edited files | integration | `cd accrue && mix test test/mix/tasks/accrue_gen_handler_test.exs` | no W0 | pending |
| 08-01-03 | 01 | 0 | TEST-02 | N/A | Fake clock drives lifecycle without sleeps | integration | `cd accrue && mix test test/accrue/test/clock_test.exs` | no W0 | pending |
| 08-01-04 | 01 | 0 | TEST-03 | T-08-03 | Synthetic webhooks use normal verification/handler path | integration | `cd accrue && mix test test/accrue/test/webhooks_test.exs` | no W0 | pending |
| 08-01-05 | 01 | 0 | TEST-06 | N/A | Event assertions inspect persisted ledger rows | integration | `cd accrue && mix test test/accrue/test/event_assertions_test.exs` | no W0 | pending |
| 08-01-06 | 01 | 0 | TEST-07 | N/A | Public facade imports setup without copying internals | unit | `cd accrue && mix test test/accrue/test/facade_test.exs` | no W0 | pending |
| 08-01-07 | 01 | 0 | OBS-02 | T-08-04 | OTel attributes are allowlisted and optional dependency compiles both ways | unit/compile | `cd accrue && mix test test/accrue/telemetry/otel_test.exs` | no W0 | pending |
| 08-01-08 | 01 | 0 | OBS-02 | T-08-04 | Every public Billing function is spanned or explicitly audited | unit/audit | `cd accrue && mix test test/accrue/telemetry/billing_span_coverage_test.exs` | no W0 | pending |
| 08-01-09 | 01 | 0 | AUTH-05 | T-08-05 | Community auth docs contain required adapters and callbacks | docs/unit | `cd accrue && mix test test/accrue/docs/community_auth_test.exs` | no W0 | pending |
| 08-02-01 | 02 | 1 | INST-01, INST-02, INST-05, INST-07, INST-09, INST-10 | T-08-01 / T-08-02 | Generated files are fingerprinted and config validation fails loud | integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs` | W0 | pending |
| 08-03-01 | 03 | 1 | INST-03, INST-04, INST-06, AUTH-04, AUTH-05 | T-08-03 / T-08-05 | Router/webhook/admin/auth wiring is explicit, reviewable, and protected | integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/install/sigra_detection_test.exs` | no W0 | pending |
| 08-03-02 | 03 | 2 | INST-01..10 | T-08-01 / T-08-02 | Installer entrypoint orchestrates Options, Project, Templates, Fingerprints, Patches, config docs/validation, and final reporting | integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/accrue/install/sigra_detection_test.exs` | W0 | pending |
| 08-04-01 | 04 | 2 | TEST-02, TEST-03, TEST-07 | N/A | Clock and event helpers wrap Fake Processor behavior | integration | `cd accrue && mix test test/accrue/test/clock_test.exs test/accrue/test/webhooks_test.exs test/accrue/test/facade_test.exs` | W0 | pending |
| 08-05-01 | 05 | 2 | TEST-04, TEST-05, TEST-06 | N/A | Assertions fail with observed evidence and matcher details | unit/integration | `cd accrue && mix test test/accrue/test/mailer_assertions_test.exs test/accrue/test/pdf_assertions_test.exs test/accrue/test/event_assertions_test.exs` | partial | pending |
| 08-06-01 | 06 | 3 | OBS-02 | T-08-04 | OTel bridge records only sanitized business attributes and compiles with/without OTel | unit/compile | `cd accrue && mix test test/accrue/telemetry/otel_test.exs test/accrue/telemetry/billing_span_coverage_test.exs && MIX_ENV=test ACCRUE_OTEL_MATRIX=without_opentelemetry mix compile --warnings-as-errors --force && MIX_ENV=test ACCRUE_OTEL_MATRIX=with_opentelemetry mix compile --warnings-as-errors --force` | W0 | pending |
| 08-07-01 | 07 | 3 | TEST-10, AUTH-05 | N/A | Testing guide and auth adapter guide content is executable | docs/integration | `cd accrue && mix test test/accrue/docs/testing_guide_test.exs test/accrue/docs/community_auth_test.exs` | no W0 | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `accrue/test/mix/tasks/accrue_install_test.exs` — stubs for INST-01..10
- [ ] `accrue/test/mix/tasks/accrue_gen_handler_test.exs` — stubs for INST-08
- [ ] `accrue/test/accrue/install/sigra_detection_test.exs` — stubs for AUTH-04 and AUTH-05
- [ ] `accrue/test/accrue/test/clock_test.exs` — stubs for TEST-02
- [ ] `accrue/test/accrue/test/webhooks_test.exs` — stubs for TEST-03
- [ ] `accrue/test/accrue/test/event_assertions_test.exs` — stubs for TEST-06
- [ ] `accrue/test/accrue/test/facade_test.exs` — stubs for TEST-07
- [ ] `accrue/test/accrue/telemetry/otel_test.exs` — stubs for OBS-02
- [ ] `accrue/test/accrue/telemetry/billing_span_coverage_test.exs` — stubs for OBS-02 Billing span coverage
- [ ] `accrue/test/accrue/docs/testing_guide_test.exs` — stubs for TEST-10
- [ ] `accrue/test/accrue/docs/community_auth_test.exs` — stubs for AUTH-05
- [ ] Fresh Phoenix fixture/sandbox helper for install smoke

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Fresh Phoenix app subjective install DX under 30 seconds | Phase 8 goal | Wall-clock and prompt clarity require human smoke once automation passes | Create a new `phx.new` app, point deps at local Accrue packages, run `mix accrue.install --dry-run`, then `mix accrue.install --yes`, and confirm report, generated files, and app boot |
| Reviewable diff clarity for nonstandard router/application shapes | INST-03, INST-07 | Edge cases vary by host app structure | Run installer against a host app with multiple routers/repos and verify skipped/manual snippets are exact and non-destructive |

---

## Threat References

| Ref | Threat | Required Mitigation |
|-----|--------|---------------------|
| T-08-01 | User edits clobbered by reinstall | Generated-file fingerprints, diff review, skip modified files, `--force` only for pristine Accrue-owned files |
| T-08-02 | Secrets printed in install report | Redact Stripe keys, webhook secrets, raw bodies, env values, and config values in reports/errors |
| T-08-03 | Webhook raw body captured globally | Patch route-scoped webhook pipeline only; manual snippets must show route-scoped raw-body capture |
| T-08-04 | OTel trace PII leakage | Allowlist attributes and tests rejecting raw payloads, emails, addresses, API keys, signing secrets, and metadata blobs |
| T-08-05 | Admin mounted without auth | Use `AccrueAdmin.Router.accrue_admin/2` and include host protection notes instead of generating unprotected admin code |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 120s for targeted tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-15
