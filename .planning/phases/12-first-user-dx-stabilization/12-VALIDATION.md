---
phase: 12
slug: first-user-dx-stabilization
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 12 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 local runtime, with Oban test mode and Phoenix host proofs |
| **Config file** | `accrue/test/test_helper.exs`, `accrue_admin/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs` |
| **Quick run command** | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host_web/webhook_ingest_test.exs` |
| **Full suite command** | `bash scripts/ci/accrue_host_uat.sh` plus `cd accrue && mix test.all` and `cd accrue_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | To be measured during Wave 0 |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host_web/webhook_ingest_test.exs`
- **After every plan wave:** Run `bash scripts/ci/accrue_host_uat.sh`
- **Before `$gsd-verify-work`:** Full suite, package docs verifier, and Hex smoke must be green
- **Max feedback latency:** To be established by Wave 0 timing

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 0 | DX-03/DX-05 | T-12-docs-api | Public docs avoid private-module teaching | docs test | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs` | No - W0 | pending |
| 12-01-02 | 01 | 0 | DX-04 | T-12-diagnostics | Troubleshooting has stable diagnostic codes and safe fix paths | docs test | `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs` | No - W0 | pending |
| 12-01-03 | 01 | 0 | DX-06 | T-12-docs-drift | Package docs do not publish stale versions or broken guide links | script + docs test | `bash scripts/ci/verify_package_docs.sh` | No - W0 | pending |
| 12-01-04 | 01 | 0 | DX-07 | T-12-deps | Hex-style dependency validation does not require a second committed host app | integration | `bash scripts/ci/accrue_host_hex_smoke.sh` | No - W0 | pending |
| 12-02-01 | 02 | 1 | DX-01 | T-12-clobber | Installer reruns preserve user-owned files and emit conflict artifacts | unit + host proof | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs` | Partial | pending |
| 12-03-01 | 03 | 1 | DX-02 | T-12-secrets | Diagnostics name keys and fixes without leaking secrets | unit + host proof | `cd accrue && mix test test/accrue/auth_test.exs test/accrue/config_test.exs test/accrue/webhook/plug_test.exs` | Partial | pending |
| 12-04-01 | 04 | 2 | DX-03/DX-04/DX-05/DX-06 | T-12-docs-api | Quickstart and troubleshooting docs follow host-app order and public APIs | docs + script | `cd accrue && mix test test/accrue/docs/*.exs && bash scripts/ci/verify_package_docs.sh` | Partial | pending |
| 12-05-01 | 05 | 2 | DX-07 | T-12-deps | Host app validates path dependency and Hex-style dependency modes | integration | `bash scripts/ci/accrue_host_uat.sh && bash scripts/ci/accrue_host_hex_smoke.sh` | Path yes / Hex no - W0 | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `accrue/test/accrue/docs/first_hour_guide_test.exs` - asserts host-path order, public API mentions, and no private-module teaching for DX-03/DX-05.
- [ ] `accrue/test/accrue/docs/troubleshooting_guide_test.exs` - asserts stable diagnostic code anchors, columns, and symptom coverage for DX-04.
- [ ] `scripts/ci/verify_package_docs.sh` with a corresponding test - verifies package versions, `source_ref`, README snippets, and guide links for DX-06.
- [ ] `scripts/ci/accrue_host_hex_smoke.sh` - switches the host app to Hex-style deps and runs the narrow smoke for DX-07.
- [ ] Installer tests expanded for real `--write-conflicts` artifacts and categorized summaries; current tests prove idempotence and redaction but not the locked conflict-artifact contract.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None expected | DX-01 through DX-07 | Phase 12 behaviors should be covered by ExUnit, docs tests, CI scripts, and host-app smoke commands | N/A |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency measured and acceptable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
