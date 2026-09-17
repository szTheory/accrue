---
phase: 227
slug: measured-critical-path-improvement
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-12
validated: 2026-09-12
---

# Phase 227 — Validation Record

The Phase 227 validation is green only because the live kept gate revalidated
the exact-three, first-attempt candidate cohort at SHA
`0339f14d6badaa7d901c27a62379c86b666c5d62`. This record retains the earlier
draft's scope while replacing its pending rows with executed evidence.

## Executed full suite

All commands below exited zero on 2026-09-12. Read-only live verification was
used; no dispatch, rerun, replacement, ref creation, or other remote mutation
occurred.

| Gate | Executed command / result |
| --- | --- |
| Strict verifier | `node --check scripts/ci/verify_ci_critical_path.mjs`; `node --test scripts/ci/verify_ci_critical_path.test.mjs` — 7/7 passing |
| Exact-tree preflight | `--verify-preflight-evidence ... --candidate-sha 0339f14d6badaa7d901c27a62379c86b666c5d62 --expected-state candidate --require-no-remote-effects` |
| Immutable fixture | `--fixtures --workflow-fixture .../fixtures/ci-workflow-restored-v2.yml --contract .../227-ci-contract.json` |
| Kept live evidence | `--verify-live-actions ... --require-activation-evidence .../227-CANDIDATE-PREFLIGHT.json --require-kept` |
| Byte rendering | `--render-evidence --evidence .../227-CI-CRITICAL-PATH.ndjson --rendered .../227-CI-CRITICAL-PATH.md --contract .../227-ci-contract.json --expected-repository szTheory/accrue` |
| Candidate workflow | `--verify-workflow --workflow .github/workflows/ci.yml --contract .../227-ci-contract.json --expected-state candidate` |
| Frozen baseline | `node scripts/ci/verify_ci_baseline.mjs --records .../226-CI-BASELINE.ndjson --rendered .../226-CI-BASELINE.md --require-critical-path --expected-repository szTheory/accrue` |
| Provider and setup controls | `node scripts/ci/verify_provider_proof.mjs --fixtures`; `node scripts/ci/verify_stripe_webhook_boot_evidence.mjs --fixtures`; `bash scripts/ci/verify_ci_setup_diagnostics.sh`; `bash scripts/ci/verify_phase225_required_lane_evidence.sh` |
| CI-pinned application checks | `(cd accrue && ASDF_ERLANG_VERSION=28.4.1 ASDF_ELIXIR_VERSION=1.19.5-otp-28 mix format --check-formatted)`; focused `mix test ... --warnings-as-errors` — 10 tests, 0 failures |

## Per-task verification map

| Task | Requirements | Threats | Executed proof | Result |
| --- | --- | --- | --- | --- |
| 227-04 | PATH-01, SAFE-01, SAFE-02 | T-227-46, T-227-48, T-227-51 | Strict parser/test corpus, immutable restored fixture, recursive privacy and byte renderer | ✅ green |
| 227-05 | PATH-01, SAFE-01, SAFE-02 | T-227-47, T-227-49, T-227-50 | Preserved historical exclusions, negative control, inverse/accounting checks | ✅ green |
| 227-07 | PATH-01, PATH-02, SAFE-01, SAFE-02 | T-227-46, T-227-47, T-227-48, T-227-SC | Exact-SHA preflight evidence and no-remote-effects proof | ✅ green |
| 227-08 Task 1 | PATH-01, PATH-02, SAFE-01, SAFE-02 | T-227-46 through T-227-52 | Live repository-bound kept verification: reservations, immediate consumptions, three complete vectors, removed temporary ref | ✅ green |
| 227-08 Task 2 | PATH-02, SAFE-01, SAFE-02 | T-227-48, T-227-51, T-227-52 | Deterministic report byte check, candidate workflow check, privacy/provider separation | ✅ green |
| 227-08 Task 3 | PATH-01, PATH-02, SAFE-01, SAFE-02 | T-227-46 through T-227-52, T-227-SC | Full suite listed above; CI-pinned format and focused Accrue tests | ✅ green |

## Requirement and decision coverage

| Coverage | Evidence |
| --- | --- |
| PATH-01 / D-01–D-03 | Candidate graph has the one authorized host prerequisite removal; independent lanes and final fan-in remain verified by the candidate workflow gate. |
| PATH-02 / D-04–D-07 | Exactly three qualifying attempt-1 observations (1179s, 1125s, 1079s); 1125s median is below 1666s and 1179s maximum is below 2602s; baseline and generated report remain immutable. |
| SAFE-01 / D-08–D-11 | Deterministic negative-control/fixture, exact contract, required roles/artifacts, and literal unused inverse remain live- and locally verified. |
| SAFE-02 / D-12–D-23 | Historic exclusions remain visible; reservation/consumption budgets closed; advisory/provider states remain literal; no rerun/replacement authority exists; report begins with current fact and exact verifier. |

## Sign-off

- [x] Every additive task has executed automated evidence.
- [x] Wave 0 references are present and passing.
- [x] All applicable high/medium threat mitigations are covered by a live or local gate.
- [x] No pending, missing, or manual-only row remains.
- [x] `status: validated`, `wave_0_complete: true`, and `nyquist_compliant: true` are justified by the executed suite.

**Approval:** validated 2026-09-12.
