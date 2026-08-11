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
| Full command | `bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh` |
| Sampling | Quick command after each task; full command before phase verification |

## Gap-Closure Coverage

| Gap / threat | Named adversarial control | Final positive gate |
| --- | --- | --- |
| Exact recursive canonical schema/privacy (T-226-27/28/29) | Named `canonical-*-unknown` mutations cover root, policy, privacy, snapshot, anchor, cohort, aggregates, selection, run/job/step/artifact/signature/lane/proof elements; empty rules/classic/exclusions mutations reject inserted objects; type, secret, raw-payload, and query-URL mutations all use public `--input`. | The unchanged three-run canonical document passes the exact recursive type/key tree before semantic aggregates. |
| Provider snapshot truth (T-226-23) | Rules and classic 401, 403, 429, and 500 fixture envelopes | Successful effective rules plus confirmed classic 404 is the sole `none-enforced` path. |
| Pagination completeness (T-226-22) | Fixture-only `next_page` rejection for live-shape coverage; contradictory/unknown fixture paths fail closed | Live list bodies use bounded `total_count` pagination; flattened ID count must equal total. |
| Record/canonical separation | One-run collector record through `--input` | Exact three-run v2 canonical cohort validates separately. |
| Eligible proof (T-226-22) | `ineligible-proved` mutation | Eligible required successes alone produce aggregate proof. |
| Timing semantics (T-226-22) | `queue-drift` mutation | Runner queue and staged chain are independently recomputed. |
| Normalized diagnosis (T-226-21/T-226-22) | `signature-pair` mutation | Versioned v2 signature contains sorted lane/conclusion pairs only. |
| Stable topology / Phase 192 (T-226-26) | Renamed host job and missing ownership-command mutations | Phase 192 verifier and protected-file empty-diff gate pass. |
| Candidate identity binding (T-226-32) | Fresh public `--input` collector and canonical mutations reject `Fabricated release lane`; the shared predicate requires exactly one workflow-policy regex match. | The unchanged collector fixture and checked-in canonical cohort validate after every candidate job is matched to exactly one policy lane. |
| Candidate policy/proof integrity (T-226-33/34) | Fresh public collector/canonical mutations independently forge `manifest_identity`, `policy`, `required_for_release_proof`, `initial_queue_root`, `staged_critical_chain_order`, and `proof_state`; positive/negative proof pairs cover eligible success, skipped, advisory, conditional, unsuccessful required, and ineligible runs. | The validator derives the complete tuple and proof state from the checked-in policy plus observed eligibility/conclusion before aggregate proof recomputation. |
| Derived staged-chain timing (T-226-44/46; CR-01) | Fresh public `collector-chain-duration-drift` and `canonical-coherent-chain-duration-forgery` mutations alter the asserted run duration; the canonical control recomputes every affected per-run/minimum/median/maximum aggregate value. | Policy-bound staged-chain timestamps independently reproduce every eligible run's chain seconds before canonical aggregate validation. |
| Derived root-failure signature (T-226-45/47; CR-02) | Fresh public `collector-all-success-category-forgery`, `canonical-all-success-category-forgery`, and `collector-diagnostic-category-forgery` controls recompute IDs from forged categories; `collector-all-success-category` and `collector-diagnostic-failed-lane` prove both derived category states. | Sorted unique policy-bound failing-lane pairs derive lane conclusions, affected identities, category, and `ci-root-v2-` ID without raw diagnostic content. |
| Preserved stable contracts (T-226-35/36) | Retain Plan 07 recursive schema/privacy cases plus repository and Phase 192 contract checks; protected evidence/topology files must have an empty diff. | `verify_ci_baseline_contract.sh`, `verify_phase192_ci_contract.sh`, the local no-external-API declaration, and the protected-file gate all pass. |

## Per-Task Verification Map

| Task ID | Plan | Requirement | Automated command | Status |
| --- | --- | --- | --- | --- |
| 226-05-01 | 05 | BASE-01, BASE-02 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | ✅ green |
| 226-05-02 | 05 | BASE-01, BASE-02 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test` | ✅ green |
| 226-05-03 | 05 | OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh` | ✅ green |
| 226-06-01 | 06 | BASE-01, BASE-02 | Full command above | ✅ green |
| 226-06-02 | 06 | BASE-01, BASE-02, OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_phase192_ci_contract.sh && git diff --check` | ✅ green |
| 226-07-01 | 07 | BASE-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_ci_baseline_contract.sh` | ✅ green |
| 226-07-02 | 07 | BASE-01, BASE-02, OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh && git diff --check` | ✅ green |
| 226-08-01 | 08 | BASE-01, BASE-02 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_ci_baseline_contract.sh --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json` | ✅ green |
| 226-08-02 | 08 | BASE-01, BASE-02, OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh && node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query check.api-coverage-verify-pre 226 | jq -e '.passed == true' && git diff --check` | ✅ green |
| 226-10-01 | 10 | BASE-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_ci_baseline_contract.sh --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json` | ✅ green — CR-01 collector and coherent-canonical duration mutations reject. |
| 226-10-02 | 10 | BASE-01, BASE-02, OWN-01 | `bash scripts/ci/verify_ci_baseline_contract.sh --self-test && bash scripts/ci/verify_ci_baseline_contract.sh && bash scripts/ci/verify_phase192_ci_contract.sh && node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs query check.api-coverage-verify-pre 226 | jq -e '.passed == true' && git diff --check` | ✅ green — CR-02 category/ID mutations reject; BASE-02 and OWN-01 remain regression-protected, not reopened. |

## Stable Contracts

- `docs-contracts-shift-left` retains exactly one baseline-contract invocation.
- This phase does not modify workflow topology, required-check identities, the
  release matrix, cache topology, setup-ownership documentation, or Phase 192
  artifact identities.
- Confirm before closeout with:

```bash
test -z "$(git diff -- scripts/ci/capture_ci_baseline.sh scripts/ci/ci_baseline_workflow_policy.json .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.json .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md .github/workflows/ci.yml scripts/ci/README.md .planning/phases/226-ci-baseline-proof-semantics/226-SETUP-OWNERSHIP.md scripts/ci/verify_phase192_ci_contract.sh)"
```

Plan 07 additionally protects the canonical JSON/Markdown, collector, policy manifest,
workflow, ownership docs, required identities, matrix/cache topology, and Phase 192 files
from change while the stored-document boundary is tightened.

## Validation Sign-Off

- [x] Record mode, canonical mode, deterministic self-test, and Phase 192 commands are executable.
- [x] Privacy, provider, proof, timing, and topology high-severity mitigations have automated negative controls.
- [x] No manual verification is required; external read access is the sole prerequisite.
