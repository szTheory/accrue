---
phase: 226
slug: ci-baseline-proof-semantics
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-09
---

# Phase 226 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Bash contract test plus read-only GitHub Actions metadata smoke check |
| **Config file** | none — Phase 226 adds its dedicated contract script |
| **Quick run command** | `bash scripts/ci/verify_ci_baseline_contract.sh` |
| **Full suite command** | `tmp_file="$(mktemp)" && trap 'rm -f "$tmp_file"' EXIT && bash scripts/ci/capture_ci_baseline.sh --run-id 31322443304 --output "$tmp_file" && bash scripts/ci/verify_ci_baseline_contract.sh --input "$tmp_file"` |
| **Estimated runtime** | ~30 seconds locally; live API time excluded |

## Sampling Rate

- **After every task commit:** Run `bash scripts/ci/verify_ci_baseline_contract.sh`
- **After every plan wave:** Run the full suite command
- **Before `$gsd-verify-work`:** Contract and live read-only collection must be green
- **Max feedback latency:** 30 seconds for fixture/contract checks

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 226-01-01 | 01 | 1 | BASE-01 | T-226-01 | Collector emits only allowlisted Actions metadata, never log or secret-bearing content. | contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | ❌ W0 | ⬜ pending |
| 226-02-01 | 02 | 2 | BASE-01, BASE-02 | T-226-02 | Baseline records comparable/excluded runs and typed proof states. | contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | ❌ W0 | ⬜ pending |
| 226-03-01 | 03 | 3 | OWN-01 | T-226-03 | Ownership runbook links CI and host diagnostics without changing release topology. | contract | `bash scripts/ci/verify_ci_baseline_contract.sh` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

## Wave 0 Requirements

- [ ] `scripts/ci/capture_ci_baseline.sh` — API-only collector with fixture mode
- [ ] `scripts/ci/verify_ci_baseline_contract.sh` — privacy, schema, taxonomy, and ownership checks
- [ ] `.planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.{md,json}` — measured baseline fixture

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Two additional current-shape first-attempt dispatches | BASE-01 | Requires authenticated GitHub Actions dispatches and real provider timing. | Dispatch twice, capture metadata only, then verify eligible cohort and recorded exclusions. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification
- [ ] Wave 0 covers all missing references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30 seconds for local checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
