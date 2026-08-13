# Phase 227 critical-path rollback

## Current fact

The final authorized candidate cohort did not admit three complete first-attempt proof vectors. The exact D-11 inverse is present at `80f6019374107fa1086eafc701090234c5e1b31f`; its sole authorized normal-CI proof run completed with a live-Stripe configuration failure.

## Rollback

- state: `rollback_applied_unverified`
- owner: maintainer
- next command: `gh workflow run ci.yml --repo szTheory/accrue --ref 80f6019374107fa1086eafc701090234c5e1b31f -f run_live_stripe=true`

No additional candidate, rerun, replacement, or restoration sample was launched. The literal next command is recorded for the external owner; this execution did not invoke it.

## Recovery preflight (2026-08-13)

The recovery gate was diagnosed from the immutable provider-job log and repository configuration. The job received blank values for all three required inputs, and the repository has none of the required secret names configured:

- `STRIPE_TEST_SECRET_KEY`
- `ACCRUE_LIVE_BASIC_PRICE`
- `ACCRUE_LIVE_PRO_PRICE`

The task-scoped environment also contains none of these values. Their values were not read or printed. Because this executor cannot safely invent or obtain Stripe credentials, the authorized recovery dispatch remains unspent. Configure all three repository secrets with a Stripe test-mode key and price IDs that belong to that key, then run the unchanged literal command above once.

## Final candidate proof vectors

| Run | Raw conclusion | Classification | Evidence gap / failure |
| --- | --- | --- | --- |
| [31715606960](https://github.com/szTheory/accrue/actions/runs/31715606960) | failure | `deterministic_required_lane_failure` | Floor release gate failed; Admin drift was skipped and `annotation-sweep` failed. |
| [31715609742](https://github.com/szTheory/accrue/actions/runs/31715609742) | success | `candidate_regression` | Required `accrue-host-ci-setup-facts` artifact absent. |
| [31715612044](https://github.com/szTheory/accrue/actions/runs/31715612044) | success | `candidate_regression` | Required `accrue-host-ci-setup-facts` artifact absent. |

All three are immutable `workflow_dispatch`, attempt-1 records at candidate SHA `d1244ee5fe591ee18bb31e30df81143b3dd4512c` with `run_live_stripe: false` and provider state `non_run`. Their complete repository-bound job URLs, artifact presence, advisory outcomes, workflow revision, and exclusions are retained in the NDJSON ledger.

## Restoration proof

[31716216311](https://github.com/szTheory/accrue/actions/runs/31716216311) is the one normal, attempt-1 `workflow_dispatch` at restored SHA `80f6019374107fa1086eafc701090234c5e1b31f`, with `run_live_stripe: true`. Host integration, all three Playwright shards, and `annotation-sweep` succeeded; the `live-stripe` provider preflight failed and emitted its artifact, so the raw workflow conclusion is `failure`. This is immutable rollback evidence but does not meet the fresh-success requirement for `rollback_verified`.

## Preserved controls

- The admissible negative control [31660617339](https://github.com/szTheory/accrue/actions/runs/31660617339) remains visible.
- All nine older exclusions and the earlier inadmissible control remain byte-present in the NDJSON ledger.
- The inverse workflow contract, critical-path fixtures, frozen Phase 226 baseline, provider fixtures, setup diagnostics, and Phase 225 preservation controls passed locally.

PATH-02 is unmet: this report records a safe applied rollback with an explicit external proof gap, not a kept comparison.
