---
phase: 12
slug: first-user-dx-stabilization
status: verified
nyquist_compliant: true
wave_1_scaffolds_complete: true
created: 2026-04-16
updated: 2026-04-16
audited: 2026-04-16
---

# Phase 12 - Validation Strategy

> Nyquist audit refresh for the completed Phase 12 implementation. The original file was stale; this update reflects the shipped tests, scripts, and workflow wiring now present in the repo.

---

## Audit Outcome

- Phase 12 already ships executable coverage for DX-01 through DX-07.
- No missing behavioral gap required a new test file.
- `12-VERIFICATION.md` and `12-SECURITY.md` are consistent with the current automated surface.
- `status: verified` and `nyquist_compliant: true` are now accurate.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Mix task tests, repo shell scripts, Phoenix host proof tests |
| **Config files** | `accrue/test/test_helper.exs`, `examples/accrue_host/test/test_helper.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` |
| **Focused host command** | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs` |
| **Full phase command set** | `bash scripts/ci/verify_package_docs.sh`, installer diagnostics/tests, focused host proofs, and `bash scripts/ci/accrue_host_hex_smoke.sh` |
| **Observed local runtime** | Docs/package tests: ~0.1s; diagnostics tests: ~0.2s; installer tests: ~1.8s; focused host proofs: ~0.4s; Hex smoke: several seconds plus compile/deps |

## Sampling Rate

- After docs changes: run the three docs/package checks.
- After installer or setup-diagnostic changes: run `test/mix/tasks/accrue_install_test.exs`, `test/mix/tasks/accrue_install_uat_test.exs`, `test/accrue/config_test.exs`, `test/accrue/auth_test.exs`, and `test/accrue/webhook/plug_test.exs`.
- After host-boundary or dependency-mode changes: run the focused host proof command plus `bash scripts/ci/accrue_host_hex_smoke.sh`.
- Before re-running `$gsd-verify-work`: rerun the full Phase 12 command set and confirm the `host-integration` workflow still references both `accrue_host_uat.sh` and `accrue_host_hex_smoke.sh`.

## Per-Task Verification Map

| Task ID | Plan | Requirement | Test Type | Automated Command | Evidence | Status |
|---------|------|-------------|-----------|-------------------|----------|--------|
| 12-01-01 | 12-01 | DX-03, DX-05 | docs test | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` | Guide-order and public-boundary contract passes. | ✅ green |
| 12-01-02 | 12-01 | DX-04 | docs test | `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs --warnings-as-errors` | Stable code/anchor/matrix contract passes. | ✅ green |
| 12-01-03 | 12-01 | DX-06 | script + docs test | `bash scripts/ci/verify_package_docs.sh` and `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` | Strict package-doc verifier and ExUnit wrapper both pass. | ✅ green |
| 12-02-01 | 12-02 | DX-07 | smoke | `bash scripts/ci/accrue_host_hex_smoke.sh` | Hex-mode smoke is active, not scaffolded, and passed locally. | ✅ green |
| 12-02-02 | 12-02 | DX-01 | unit + integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors` | Installer summary/conflict-artifact contract passes. | ✅ green |
| 12-03-01 | 12-03 | DX-01 | unit + integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors` | No-clobber reruns, `.accrue/conflicts`, and summary taxonomy are active and green. | ✅ green |
| 12-03-02 | 12-03 | DX-01 | unit + integration | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors` | Conflict headers and `.new` / `.snippet` artifacts are enforced by tests. | ✅ green |
| 12-04-01 | 12-04 | DX-05 | integration | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs` | Host-facing `billing_state_for/1` coverage passes. | ✅ green |
| 12-04-02 | 12-04 | DX-05 | integration | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs` | Host UI proof stays on the host facade boundary and passes. | ✅ green |
| 12-05-01 | 12-05 | DX-02 | unit + integration | `cd accrue && mix test test/accrue/config_test.exs test/accrue/auth_test.exs test/accrue/webhook/plug_test.exs --warnings-as-errors` | Shared setup diagnostics, redaction, and generic webhook failures pass. | ✅ green |
| 12-05-02 | 12-05 | DX-02 | installer test | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors` | Installer `--check` diagnostics stay on the shared taxonomy. | ✅ green |
| 12-06-01 | 12-06 | DX-03, DX-05 | docs test | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs --warnings-as-errors` | First Hour guide remains host-order correct and public-boundary only. | ✅ green |
| 12-06-02 | 12-06 | DX-04 | docs test | `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs --warnings-as-errors` | Troubleshooting guide remains anchored and actionable. | ✅ green |
| 12-07-01 | 12-07 | DX-06 | script + docs test | `bash scripts/ci/verify_package_docs.sh` and `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` | Versions, `source_ref`, README links, and guide links stay strict. | ✅ green |
| 12-08-01 | 12-08 | DX-07 | integration + smoke | `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs` and `bash scripts/ci/accrue_host_hex_smoke.sh` | Same host app is proved in path-mode and Hex-mode. | ✅ green |
| 12-08-02 | 12-08 | DX-07 | workflow/config | `rg -n 'Run host integration gate|Run host Hex smoke|bash scripts/ci/accrue_host_uat.sh|bash scripts/ci/accrue_host_hex_smoke.sh' .github/workflows/ci.yml` | CI still wires both host scripts in the `host-integration` job. | ✅ green |
| 12-09-01 | 12-09 | DX-02 | installer regression | `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors` | Scope-aware webhook pipeline preflight regression passes. | ✅ green |
| 12-09-02 | 12-09 | DX-02 | unit | `cd accrue && mix test test/accrue/config_test.exs --warnings-as-errors` | Migration lookup failures now raise `ACCRUE-DX-MIGRATIONS-PENDING` and tests pass. | ✅ green |
| 12-10-01 | 12-10 | DX-03, DX-04 | docs test | `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs --warnings-as-errors` | Docs contract locks `:webhook_signing_secrets` and rejects singular drift. | ✅ green |
| 12-10-02 | 12-10 | DX-06 | script + docs test | `bash scripts/ci/verify_package_docs.sh` and `cd accrue && mix test test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors` | Package-doc verifier rejects singular webhook-secret regressions. | ✅ green |
| 12-11-01 | 12-11 | DX-02, DX-04 | docs test + grep proof | `rg -n 'accrue-dx-repo-config|accrue-dx-migrations-pending|accrue-dx-oban-not-configured|accrue-dx-oban-not-supervised|accrue-dx-webhook-secret-missing|accrue-dx-webhook-route-missing|accrue-dx-webhook-raw-body|accrue-dx-webhook-pipeline|accrue-dx-auth-adapter|accrue-dx-admin-mount-missing' accrue/guides/troubleshooting.md` and `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs --warnings-as-errors` | All ten emitted troubleshooting anchors exist and the guide contract passes. | ✅ green |
| 12-11-02 | 12-11 | DX-02, DX-04, DX-06 | docs test | `cd accrue && mix test test/accrue/docs/troubleshooting_guide_test.exs --warnings-as-errors` | Full ten-anchor authoritative troubleshooting contract passes. | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Requirement Coverage

| Requirement | Automated Coverage | Status |
|-------------|--------------------|--------|
| DX-01 | `test/mix/tasks/accrue_install_test.exs`, `test/mix/tasks/accrue_install_uat_test.exs` | ✅ covered |
| DX-02 | `test/accrue/config_test.exs`, `test/accrue/auth_test.exs`, `test/accrue/webhook/plug_test.exs`, installer `--check` tests, troubleshooting contract | ✅ covered |
| DX-03 | `test/accrue/docs/first_hour_guide_test.exs` | ✅ covered |
| DX-04 | `test/accrue/docs/troubleshooting_guide_test.exs` plus troubleshooting anchor grep proof | ✅ covered |
| DX-05 | `test/accrue/docs/first_hour_guide_test.exs`, `test/accrue_host/billing_facade_test.exs`, `test/accrue_host_web/subscription_flow_test.exs` | ✅ covered |
| DX-06 | `scripts/ci/verify_package_docs.sh`, `test/accrue/docs/package_docs_verifier_test.exs`, troubleshooting anchor contract | ✅ covered |
| DX-07 | `test/install_boundary_test.exs`, `test/accrue_host/billing_facade_test.exs`, `scripts/ci/accrue_host_hex_smoke.sh`, CI workflow wiring grep proof | ✅ covered |

## Manual-Only Verifications

None. Phase 12 requirements are fully covered by executable tests, scripts, or workflow-config checks.

## Commands Re-run During This Audit

- `cd accrue && mix test test/accrue/docs/first_hour_guide_test.exs test/accrue/docs/troubleshooting_guide_test.exs test/accrue/docs/package_docs_verifier_test.exs --warnings-as-errors`
- `cd accrue && mix test test/accrue/config_test.exs test/accrue/auth_test.exs test/accrue/webhook/plug_test.exs --warnings-as-errors`
- `bash scripts/ci/verify_package_docs.sh`
- `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs --warnings-as-errors`
- `cd examples/accrue_host && MIX_ENV=test mix test --warnings-as-errors test/install_boundary_test.exs test/accrue_host/billing_facade_test.exs test/accrue_host_web/subscription_flow_test.exs test/accrue_host_web/webhook_ingest_test.exs`
- `bash scripts/ci/accrue_host_hex_smoke.sh`
- `rg -n 'Run host integration gate|Run host Hex smoke|bash scripts/ci/accrue_host_uat.sh|bash scripts/ci/accrue_host_hex_smoke.sh' .github/workflows/ci.yml`
- `rg -n 'accrue-dx-repo-config|accrue-dx-migrations-pending|accrue-dx-oban-not-configured|accrue-dx-oban-not-supervised|accrue-dx-webhook-secret-missing|accrue-dx-webhook-route-missing|accrue-dx-webhook-raw-body|accrue-dx-webhook-pipeline|accrue-dx-auth-adapter|accrue-dx-admin-mount-missing' accrue/guides/troubleshooting.md`

## Audit Trail

| Date | Auditor | Result | Notes |
|------|---------|--------|-------|
| 2026-04-16 | Codex Nyquist auditor | verified | Existing `12-VALIDATION.md` was stale; all Phase 12 requirements already had executable coverage and no new tests were needed. |

### Supporting Script Note

`scripts/ci/accrue_host_uat.sh` remains the broader Phase 11 host wrapper and is still referenced by `.github/workflows/ci.yml`. During this audit, a local rerun in the current workspace hit non-Phase-12 issues in its clean-worktree/dev-boot portions after the focused Phase 12 checks were already green. That does not create a Phase 12 automation gap because DX-07 is already covered by focused path-mode host proofs plus the active Hex smoke entrypoint.

## Validation Sign-Off

- [x] Every Phase 12 plan/task maps to a current automated proof
- [x] No missing test file or missing automated command remains for DX-01 through DX-07
- [x] Wave 1 scaffolds were activated or superseded by active checks
- [x] Manual-only table is empty
- [x] Existing verification/security artifacts agree with this audit
- [x] `status: verified` and `nyquist_compliant: true` are accurate

**Approval:** verified 2026-04-16
