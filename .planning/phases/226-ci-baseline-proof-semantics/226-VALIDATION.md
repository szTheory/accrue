---
phase: 226
slug: ci-baseline-proof-semantics
status: draft
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
| **Full suite command** | `node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` |
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
| 226-01-01 | 01 | 1 | BASE-01 | T-226-01 | Only allowlisted, sanitized CI evidence is persisted | unit/fixture | `node --check scripts/ci/collect_ci_baseline.mjs && node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Planned: Plan 01 Wave 1 creates and exercises the verifier | ⬜ pending |
| 226-01-02 | 01 | 1 | BASE-01 | T-226-02 | Cohort, rerun, timing, cache/setup, and signature claims remain comparable and fail closed | unit/fixture | `node --check scripts/ci/collect_ci_baseline.mjs && node --check scripts/ci/render_ci_baseline.mjs && node --check scripts/ci/verify_ci_baseline.mjs && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Planned: Plan 01 Wave 1 exercises the created verifier | ⬜ pending |
| 226-02-01 | 02 | 2 | BASE-01 | T-226-05 | The frozen live snapshot is schema-valid, privacy-safe, and bound to immutable Actions evidence | live-record contract | `gh auth status && node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson` | Executed 2026-08-11 against the checked-in 90-day snapshot | ✅ green |
| 226-02-02 | 02 | 2 | BASE-01 | T-226-06 | The maintainer report is a byte-reproducible rendering of the validated frozen snapshot | render/record contract | `node scripts/ci/render_ci_baseline.mjs --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --out .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md && node scripts/ci/verify_ci_baseline.mjs --fixtures` | Executed 2026-08-11 with byte-identical checked-in render | ✅ green |
| 226-03-01 | 03 | 1 | BASE-02 | T-226-09 | Zero-selected, skipped, non-run, stale, blocked, and misconfigured provider states cannot be promoted to proof | unit/fixture | `node --check scripts/ci/provider_proof.mjs && node --check scripts/ci/render_provider_summary.mjs && node --check scripts/ci/verify_provider_proof.mjs && node scripts/ci/verify_provider_proof.mjs --fixtures` | Planned: Plan 03 Wave 1 creates and exercises the verifier | ⬜ pending |
| 226-03-02 | 03 | 1 | BASE-02 | T-226-11 | Live-suite counts and the evidence manifest are emitted by the real formatter and consumed by provider classification | ExUnit/fixture | `cd accrue && mix test test/accrue/live_proof_formatter_test.exs --warnings-as-errors && cd .. && node scripts/ci/verify_provider_proof.mjs --fixtures` | Planned: Plan 03 Wave 1 exercises the created verifier | ⬜ pending |
| 226-04-01 | 04 | 1 | OWN-01 | T-226-13 | A Node-version failure resolves to a stable owner, narrow repair command, and redacted setup fact | shell contract | `bash -n scripts/ci/ci_setup_diagnostic.sh && bash -n scripts/ci/verify_ci_setup_diagnostics.sh && bash -n scripts/ci/accrue_host_verify_browser.sh && bash scripts/ci/verify_ci_setup_diagnostics.sh` | Planned: Plan 04 Wave 1 creates and exercises the verifier | ⬜ pending |
| 226-04-02 | 04 | 1 | OWN-01 | T-226-16 | All setup codes preserve the host/CI ownership boundary and existing proof path | shell contract | `bash -n scripts/ci/ci_setup_diagnostic.sh && bash -n scripts/ci/verify_ci_setup_diagnostics.sh && bash -n scripts/ci/accrue_host_verify_browser.sh && bash -n scripts/ci/accrue_host_uat.sh && bash scripts/ci/verify_ci_setup_diagnostics.sh` | Planned: Plan 04 Wave 1 exercises the created verifier | ⬜ pending |
| 226-05-01 | 05 | 3 | BASE-02, OWN-01 | T-226-17, T-226-18, T-226-19 | Always-run workflow evidence remains privacy-safe, read-only, non-mutating, and bound to stable job topology | static workflow/fixture contract | `node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Planned: integrates the Wave 1 verifiers with the workflow contract | ⬜ pending |
| 226-05-02 | 05 | 3 | BASE-01, BASE-02, OWN-01 | T-226-20 | Maintainer docs and validation metadata agree with every executable baseline, provider, and ownership contract | phase contract | `node scripts/ci/verify_ci_baseline.mjs --fixtures && node scripts/ci/verify_provider_proof.mjs --fixtures && bash scripts/ci/verify_ci_setup_diagnostics.sh && bash scripts/ci/verify_phase225_required_lane_evidence.sh` | Planned: closes the integrated contract after all prior plan outputs exist | ⬜ pending |

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

---

## Validation Sign-Off

- [x] All ten tasks have a concrete `<automated>` verify command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] No `MISSING` automated references exist at planning time (`wave_0_complete: true`)
- [x] BASE-01 recorded assertion passes against checked-in evidence and deterministic fixtures; BASE-02 remains pending its provider-proof evidence
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter for the complete planning-time verification map

**Approval:** pending; mark complete only after both recorded assertion commands run successfully.
