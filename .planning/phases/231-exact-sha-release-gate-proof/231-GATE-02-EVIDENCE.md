# CI Baseline

## Current fact

**State:** insufficient_sample — no critical-path percentile claim. **Owner:** CI maintainers. **Next command:** `node scripts/ci/verify_ci_baseline.mjs --records .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --rendered .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md --expected-repository szTheory/accrue`. Evidence is the immutable Actions links below. This is a `workflow_dispatch`-class proof; a future pull-request-class proof for the same SHA produces a second, distinct check-run set (see Phase 232).

Privacy-safe, schema-v1 evidence. Raw logs, actors, branches, secrets, payloads, and artifact contents are not persisted.

## Comparable cohort

Snapshot metadata unavailable.
Phase 225 repair boundary is unavailable from this snapshot.

### Comparable timing

| Run | Cohort | State | Wall time | Evidence |
| --- | --- | --- | --- | --- |
| 35100620086 | cohort-v1-4b2927f29228e543 | failure | 622s | [run](https://github.com/szTheory/accrue/actions/runs/35100620086) |

## Measured critical path

Expected staged release → host integration → Playwright path (33–36 minutes): **insufficient_sample — no critical-path percentile claim**. No aggregate named-path total is a critical-path percentile.






| Cohort | Qualifying successes | Status | p50 | p95 |
| --- | --- | --- | --- | --- |

## Setup and cache costs

| Job | Setup costs | Cache facts | Evidence |
| --- | --- | --- | --- |
| admin-phase-200-deterministic-guardrails | {"docker_ms":23000,"node_ms":3000,"npm_ms":3000,"phoenix_ms":190000,"browser_ms":28000,"playwright_ms":1000} | {"hit":true,"restore_ms":1000,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808826938) |
| admin-group-contracts | {"docker_ms":21000,"browser_ms":93000,"node_ms":5000,"npm_ms":3000,"phoenix_ms":197000,"playwright_ms":0} | {"hit":true,"restore_ms":2000,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808826984) |
| docs-and-bash-contracts-shift-left | {"docker_ms":0,"node_ms":0,"fixture_ms":0} | {"hit":false,"restore_ms":0,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827021) |
| release-gate | {"docker_ms":23000} | {"hit":true,"restore_ms":1000,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827092) |
| phase-18-stripe-tax-gate | {"docker_ms":29000} | {"hit":true,"restore_ms":0,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827108) |
| admin-hardening-guardrails | {"docker_ms":33000,"node_ms":4000,"npm_ms":3000,"phoenix_ms":143000,"browser_ms":42000,"playwright_ms":1000} | {"hit":true,"restore_ms":2000,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827165) |
| release-gate | {"docker_ms":22000} | {"hit":true,"restore_ms":0,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827179) |
| release-gate | {"docker_ms":22000} | {"hit":true,"restore_ms":0,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827202) |
| release-gate-advisory | {"docker_ms":33000} | {"hit":true,"restore_ms":0,"save_ms":0,"size_bytes":0} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827250) |
| admin-ui-ratchet-guardrails | {"node_ms":1000} | {} | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104812360164) |

## Provider state

All full-CI timing runs are recorded as `non_run` for provider proof; a successful workflow is not live-provider proof. See the Phase 226 provider-proof evidence for the independent provider state.

For `workflow_dispatch` run [35100620086](https://github.com/szTheory/accrue/actions/runs/35100620086), the mandatory Stripe test-mode parity job (`live-stripe`) did not run: `provider_state: skipped`, because the dispatch's `run_live_stripe` input was explicitly set to `false`. A green Actions conclusion is not provider proof, and neither is this deliberate skip.

## Reliability

Root-job runner queue observations: 12. Dependent DAG-wait observations: 1.

| Job | State | Runner queue | DAG wait | Duration | Evidence |
| --- | --- | --- | --- | --- |
| ios-offline-client-package-compatibility | success | 7s | — | 47s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808826781) |
| admin-phase-200-deterministic-guardrails | success | 3s | — | 589s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808826938) |
| admin-group-contracts | success | 4s | — | 337s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808826984) |
| docs-and-bash-contracts-shift-left | failure | 4s | — | 19s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827021) |
| release-gate | failure | 4s | — | 276s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827092) |
| stripe-provider-proof-trigger-classifier | success | 3s | — | 10s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827094) |
| phase-18-stripe-tax-gate | failure | 4s | — | 186s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827108) |
| admin-hardening-guardrails | success | 4s | — | 519s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827165) |
| release-manifest-ssot | success | 4s | — | 116s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827167) |
| release-gate | failure | 3s | — | 262s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827179) |
| release-gate | failure | 4s | — | 260s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827202) |
| release-gate-advisory | failure | 4s | — | 216s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104808827250) |
| admin-ui-ratchet-guardrails | failure | — | 2s | 11s | [job](https://github.com/szTheory/accrue/actions/runs/35100620086/job/104812360164) |

## Exclusions

Failed, cancelled, skipped, and rerun attempts remain reliability evidence and never fill percentile samples. Scheduled/provider-only topologies remain outside full-CI timing cohorts. Raw logs, artifact contents, actors, raw branch names, payloads, and secrets are excluded.

## Reproduce

```sh
gh auth status
node scripts/ci/collect_ci_baseline.mjs --repo szTheory/accrue --workflow ci.yml --window-days 90 --sample-size 20 --out .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson
node scripts/ci/render_ci_baseline.mjs --input .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.ndjson --out /tmp/226-CI-BASELINE.md --expected-repository szTheory/accrue
cmp /tmp/226-CI-BASELINE.md .planning/phases/226-ci-baseline-proof-semantics/226-CI-BASELINE.md
node scripts/ci/verify_ci_baseline.mjs --fixtures --expected-repository acme/accrue
```
