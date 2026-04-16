---
phase: 12
slug: first-user-dx-stabilization
status: draft
nyquist_compliant: false
wave_1_scaffolds_complete: false
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
| **Estimated runtime** | To be measured during Wave 1 scaffold execution |

---

## Sampling Rate

- **After every task commit:** Run `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host_web/webhook_ingest_test.exs`
- **After every plan wave:** Run `bash scripts/ci/accrue_host_uat.sh`
- **Before `$gsd-verify-work`:** Full suite, package docs verifier, and Hex smoke must be green
- **Max feedback latency:** To be established by Wave 1 scaffold timing

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | DX-03/DX-05 | T-12-docs-api | Public docs avoid private-module teaching | docs test | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs` | No - Wave 1 scaffold | pending |
| 12-01-02 | 01 | 1 | DX-04 | T-12-diagnostics | Troubleshooting has stable diagnostic codes and safe fix paths | docs test | `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs` | No - Wave 1 scaffold | pending |
| 12-01-03 | 01 | 1 | DX-06 | T-12-docs-drift | Package docs do not publish stale versions or broken guide links | script + docs test | `bash scripts/ci/verify_package_docs.sh` | No - Wave 1 scaffold | pending |
| 12-02-01 | 02 | 1 | DX-07 | T-12-deps | Hex-style dependency validation does not require a second committed host app | integration | `bash scripts/ci/accrue_host_hex_smoke.sh` | No - Wave 1 scaffold | pending |
| 12-02-02 | 02 | 1 | DX-01 | T-12-clobber | Installer reruns reserve exact conflict-artifact and summary contracts before implementation | unit + host proof | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs` | Partial - Wave 1 scaffold | pending |
| 12-03-01 | 03 | 2 | DX-01 | T-12-clobber | Installer reruns preserve user-owned files and emit conflict artifacts | unit + host proof | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs` | Yes after plan 03 | pending |
| 12-04-01 | 04 | 2 | DX-05 | T-12-docs-api | Host UI reads billing state through the generated facade instead of private tables | host proof | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs` | Yes after plan 04 | pending |
| 12-05-01 | 05 | 3 | DX-02 | T-12-secrets | Boot and runtime diagnostics share one redacted setup-diagnostic contract | unit + host proof | `cd accrue && mix test test/accrue/config_test.exs test/accrue/auth_test.exs test/accrue/webhook/plug_test.exs` | Yes after plan 05 task 1 | pending |
| 12-05-02 | 05 | 3 | DX-02 | T-12-secrets | Installer `--check` emits the same diagnostic codes for router, raw-body, admin-mount, and auth wiring mistakes | installer test | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs` | Yes after plan 05 task 2 | pending |
| 12-06-01 | 06 | 4 | DX-03/DX-04/DX-05 | T-12-docs-api | First Hour and troubleshooting docs follow the host-app order and public API boundary | docs test | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs` | Yes after plan 06 | pending |
| 12-07-01 | 07 | 5 | DX-06 | T-12-docs-drift | Package metadata, source refs, and guide links remain strict and version-correct | script + docs test | `bash scripts/ci/verify_package_docs.sh && cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs` | Yes after plan 07 | pending |
| 12-08-01 | 08 | 3 | DX-07 | T-12-deps | Host app validates both path dependency and Hex-style dependency modes | integration | `bash scripts/ci/accrue_host_uat.sh && bash scripts/ci/accrue_host_hex_smoke.sh` | Path yes / Hex yes after plan 08 | pending |

*Status: pending, green, red, flaky*

---

## Wave 1 Scaffold Requirements

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

- [ ] All tasks have `<automated>` verify or Wave 1 scaffold dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 1 scaffolds cover all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency measured and acceptable
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
