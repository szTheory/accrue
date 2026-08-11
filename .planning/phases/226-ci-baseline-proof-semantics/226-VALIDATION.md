---
phase: 226
slug: ci-baseline-proof-semantics
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-11
---

# Phase 226 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Node built-in assertions and shell contract checks; existing ExUnit and Playwright suites remain source proof |
| **Config file** | `examples/accrue_host/playwright.config.js`; `accrue_admin/playwright.config.js`; no root Node test config |
| **Quick run command** | `node scripts/ci/verify_ci_baseline.mjs --fixtures` |
| **Full suite command** | `node --check scripts/ci/collect_ci_baseline.mjs && node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node --check scripts/ci/verify_provider_proof.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path && node scripts/ci/verify_provider_proof.mjs --fixtures && (cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors) && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` |
| **Estimated runtime** | Under 120 seconds for fixture and contract checks |

---

## Sampling Rate

- **After every task commit:** Run the relevant fixture command plus `node --check` on changed `.mjs` files
- **After every plan wave:** Run all Phase 226 fixture and contract checks
- **Before `$gsd-verify-work`:** Full suite must be green and both recorded-assertion commands below must pass
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Automated Reference Lifecycle | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 226-01-01 | 01 | 1 | BASE-01 | T-226-01 | Only allowlisted, sanitized CI evidence is persisted | unit/fixture | `node --check scripts/ci/collect_ci_baseline.mjs && node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Executed 2026-08-11 against deterministic fixtures | ✅ green |
| 226-01-02 | 01 | 1 | BASE-01 | T-226-02 | Cohort, rerun, timing, cache/setup, and signature claims remain comparable and fail closed | unit/fixture | `node --check scripts/ci/collect_ci_baseline.mjs && node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Executed 2026-08-11 against deterministic fixtures | ✅ green |
| 226-02-01 | 02 | 2 | BASE-01 | T-226-05 | The frozen live snapshot is schema-valid, privacy-safe, and bound to immutable Actions evidence | live-record contract | `gh auth status && node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` | Executed 2026-08-11 against the checked-in 90-day snapshot | ✅ green |
| 226-02-02 | 02 | 2 | BASE-01 | T-226-06 | The maintainer report is a byte-reproducible rendering of the validated frozen snapshot | render/record contract | `node scripts/ci/render_ci_baseline.mjs --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --out .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Executed 2026-08-11 with byte-identical checked-in render | ✅ green |
| 226-03-01 | 03 | 1 | BASE-02 | T-226-09 | Zero-selected, skipped, non-run, stale, blocked, and misconfigured provider states cannot be promoted to proof | unit/fixture | `node --check scripts/ci/provider_proof.mjs && node --check scripts/ci/render_provider_summary.mjs && node --check scripts/ci/verify_provider_proof.mjs && node scripts/ci/verify_provider_proof.mjs --fixtures` | Executed 2026-08-11 against exhaustive state fixtures | ✅ green |
| 226-03-02 | 03 | 1 | BASE-02 | T-226-11 | Live-suite counts and the evidence manifest are emitted by the real formatter and consumed by provider classification | ExUnit/fixture | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors && cd .. && node scripts/ci/verify_provider_proof.mjs --fixtures` | Executed 2026-08-11 with formatter and provider fixtures | ✅ green |
| 226-04-01 | 04 | 1 | OWN-01 | T-226-13 | A Node-version failure resolves to a stable owner, narrow repair command, and redacted setup fact | shell contract | `bash -n scripts/ci/ci_setup_diagnostic.sh && bash -n scripts/ci/verify_ci_setup_diagnostics.sh && bash -n scripts/ci/accrue_host_verify_browser.sh && bash scripts/ci/verify_ci_setup_diagnostics.sh` | Executed 2026-08-11 against setup fixtures | ✅ green |
| 226-04-02 | 04 | 1 | OWN-01 | T-226-16 | All setup codes preserve the host/CI ownership boundary and existing proof path | shell contract | `bash -n scripts/ci/ci_setup_diagnostic.sh && bash -n scripts/ci/verify_ci_setup_diagnostics.sh && bash -n scripts/ci/accrue_host_verify_browser.sh && bash -n scripts/ci/accrue_host_uat.sh && bash scripts/ci/verify_ci_setup_diagnostics.sh` | Executed 2026-08-11 against setup fixtures | ✅ green |
| 226-05-01 | 05 | 3 | BASE-02, OWN-01 | T-226-17, T-226-18, T-226-19 | Always-run workflow evidence remains privacy-safe, read-only, non-mutating, and bound to stable job topology | static workflow/fixture contract | `node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Executed 2026-08-11 after CI evidence wiring | ✅ green |
| 226-05-02 | 05 | 3 | BASE-01, BASE-02, OWN-01 | T-226-20 | Maintainer docs and validation metadata agree with every executable baseline, provider, and ownership contract | phase contract | `node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Executed 2026-08-11 as the full Phase 226 contract | ✅ green |
| 226-06-01 | 06 | 4 | BASE-01, BASE-02 | T-226-21, T-226-23, T-226-24 | Full-CI `non_run` timing cohorts qualify independently of provider proof while schedule, failure, cancellation, and reruns stay excluded | unit/fixture | `node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_provider_proof.mjs --fixtures` | Executed 2026-08-11 against deterministic non_run cohort and provider-promotion controls | ✅ green |
| 226-06-02 | 06 | 4 | BASE-01, BASE-02 | T-226-22 | Impossible canonical-looking UTC dates are rejected before baseline or provider arithmetic | unit/fixture | `node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_provider_proof.mjs --fixtures` | Executed 2026-08-11 against timestamp rejection controls | ✅ green |
| 226-07-01 | 07 | 5 | BASE-01 | T-226-25, T-226-26 | Cohort-aligned staged paths require ordered release, host, and latest Playwright completion without summing parallel shards | unit/fixture | `node scripts/ci/verify_ci_baseline.mjs --fixtures` | Executed 2026-08-11 against staged-path boundary controls | ✅ green |
| 226-07-02 | 07 | 5 | BASE-01, BASE-02, OWN-01 | T-226-27, T-226-28, T-226-29 | Frozen evidence and all inherited provider, formatter, setup, and required-lane contracts remain byte-reproducible and green | phase contract | `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path && node scripts/ci/verify_provider_proof.mjs --fixtures && (cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors) && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Executed 2026-08-11 after the compatible-path refresh | ✅ green |
| 226-12-01 | 12 | 6 | BASE-01 | T-226-25, T-226-26 | Latest 20 compatible complete paths span visible fingerprint strata; GitHub matrix shard labels resolve to one unsummed Playwright stage | unit/fixture | `node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Executed 2026-08-11 with deterministic multi-fingerprint and shard-label controls | ✅ green |
| 226-12-02 | 12 | 6 | BASE-01, BASE-02, OWN-01 | T-226-27, T-226-28, T-226-29 | The 90-day read-only Actions snapshot has 20 compatible complete paths, explicit stratum sensitivity, byte-identical rendering, and unchanged inherited proof contracts | live-record contract | `node --check scripts/ci/collect_ci_baseline.mjs && node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node --check scripts/ci/verify_provider_proof.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path && node scripts/ci/verify_provider_proof.mjs --fixtures && (cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors) && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Executed 2026-08-11 after temporary collection, dual rendering, and atomic evidence replacement | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Automated Reference Coverage

There is no separate Wave 0 plan. Every task already has a concrete executable `<automated>` command, so there are no `MISSING` automated references at planning time and `wave_0_complete` is true. The verifier files are planned production artifacts, not files claimed to exist before execution: Plans 01, 03, and 04 create and exercise them in Wave 1, and later plans consume those proven commands.

---

## Automated Recorded Assertions

| Behavior | Requirement | Recorded Assertion | Automated Command |
|----------|-------------|--------------------|-------------------|
| Frozen comparable-run snapshot represents real workflow topology and exposes the measured critical path | BASE-01 | The checked-in NDJSON records the workflow/config revision, event/branch/runner/job-set cohort fingerprint inputs, qualifying and excluded run counts, queue/DAG/duration facts, immutable evidence links, and resulting critical-path claim; the verifier rejects missing or inconsistent fields and byte-compares the rendered Markdown. | `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md` |
| Provider freshness window matches the selected scheduled/manual cadence | BASE-02 | Provider fixtures and the rendered record assert the daily selected cadence, labeled 48-hour grace, SHA equality, and exact fresh/stale/skipped/misconfigured/blocked/non-run transitions; the verifier rejects a freshness claim with the wrong cadence, grace, or SHA. | `node scripts/ci/verify_provider_proof.mjs --fixtures` |
| Compatible staged timing retains topology evolution | BASE-01 | The latest 20 unique successful first-attempt full-CI paths each contain ordered release-gate, host-integration, and one or more Playwright shards. The verifier measures one release-start to latest-shard-completion span per run, reports p50/p95, discloses fingerprint count/range/percentile sensitivity, and rejects duplicate, rerun, provider-only, missing-stage, ordering, and under-sample controls. | `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --require-critical-path` |

---

## Validation Sign-Off

- [x] All sixteen tasks have a concrete `<automated>` verify command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No `MISSING` automated references exist at planning time (`wave_0_complete: true`)
- [x] BASE-01 recorded assertions pass against checked-in compatible-path evidence and deterministic fixtures; BASE-02 provider fixtures pass with cadence, grace, SHA, and state transitions
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter for the complete planning-time verification map

**Approval:** approved 2026-08-11 after all 16 task rows, the compatible-path/stratum-disclosure assertion, and the full Phase 226 command completed with zero behavior-unverified rows. Plan 12 is the collision-free successor to the retired Plan 08 alias.
