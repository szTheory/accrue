---
phase: 226
slug: ci-baseline-proof-semantics
status: complete
nyquist_compliant: true
wave_0_complete: true
updated: 2026-08-10
---

# Phase 226 — Validation Strategy

The canonical JSON is authoritative; Markdown is a derived privacy-safe
rendering. The commands below use only read-only Actions metadata GETs.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Bash contract tests plus authenticated read-only GitHub metadata collection |
| Quick command | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` |
| Full command | `tmp_file="$(mktemp)" && trap 'rm -f "$tmp_file"' EXIT && bash scripts/ci/capture_ci_baseline.sh --run-id 31322443304 --output "$tmp_file" && bash scripts/ci/verify_ci_baseline_contract.sh --input "$tmp_file" && bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh` |
| Sampling | Quick command after each task; full command before phase verification |

## Gap-Closure Coverage

| Gap / threat | Named adversarial control | Final positive gate |
| --- | --- | --- |
| Exact recursive privacy schema (T-226-21) | `unknown-root`, `unknown-nested`, `secret-like-unknown`, `invalid-run-type`, `query-url` mutations | Collector record and canonical contract both validate. |
| Provider snapshot truth (T-226-23) | Rules and classic 401, 403, 429, and 500 fixture envelopes | Successful effective rules plus confirmed classic 404 is the sole `none-enforced` path. |
| Pagination completeness (T-226-22) | Fixture-only `next_page` rejection for live-shape coverage; contradictory/unknown fixture paths fail closed | Live list bodies use bounded `total_count` pagination; flattened ID count must equal total. |
| Record/canonical separation | One-run collector record through `--input` | Exact three-run v2 canonical cohort validates separately. |
| Eligible proof (T-226-22) | `ineligible-proved` mutation | Eligible required successes alone produce aggregate proof. |
| Timing semantics (T-226-22) | `queue-drift` mutation | Runner queue and staged chain are independently recomputed. |
| Normalized diagnosis (T-226-21/T-226-22) | `signature-pair` mutation | Versioned v2 signature contains sorted lane/conclusion pairs only. |
| Stable topology / Phase 192 (T-226-26) | Renamed host job and missing ownership-command mutations | Phase 192 verifier and protected-file empty-diff gate pass. |

## Per-Task Verification Map

| Task ID | Plan | Requirement | Automated command | Status |
| --- | --- | --- | --- | --- |
| 226-05-01 | 05 | BASE-01, BASE-02 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | ✅ green |
| 226-05-02 | 05 | BASE-01, BASE-02 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | ✅ green |
| 226-05-03 | 05 | OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh` | ✅ green |
| 226-06-01 | 06 | BASE-01, BASE-02 | Full command above | ✅ green |
| 226-06-02 | 06 | BASE-01, BASE-02, OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_phase192_ci_contract.sh && git diff --check` | ✅ green |

## Stable Contracts

- `docs-contracts-shift-left` retains exactly one baseline-contract invocation.
- This phase does not modify workflow topology, required-check identities, the
  release matrix, cache topology, setup-ownership documentation, or Phase 192
  artifact identities.
- Confirm before closeout with:

```bash
test -z "$(git diff -- .github/workflows/ci.yml scripts/ci/README.md .planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md scripts/ci/verify_phase192_ci_contract.sh)"
```

## Validation Sign-Off

- [x] Record mode, canonical mode, deterministic self-test, and Phase 192 commands are executable.
- [x] Privacy, provider, proof, timing, and topology high-severity mitigations have automated negative controls.
- [x] No manual verification is required; external read access is the sole prerequisite.
