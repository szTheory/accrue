# Phase 227 critical-path rollback

## Current fact

The corrected final candidate cohort admits only two of the three required first-attempt proof vectors. The exact D-11 inverse is present at `80f6019374107fa1086eafc701090234c5e1b31f`. The single post-correction restoration dispatch completed, but a missing Stripe webhook signing secret stopped the live suite during application boot.

## Rollback

- state: `rollback_applied_unverified`
- owner: maintainer
- restoration run budget: `exhausted`
- additional dispatch authorized: `false`
- next command: none

No candidate rerun or replacement was launched. Exactly one restoration run was created after the contract correction, and no further dispatch is authorized.

## Recovery preflight (2026-08-13)

The recovery gate was diagnosed from the immutable provider-job log and repository configuration. The job received blank values for all three required inputs, and the repository has none of the required secret names configured:

- `STRIPE_TEST_SECRET_KEY`
- `ACCRUE_LIVE_BASIC_PRICE`
- `ACCRUE_LIVE_PRO_PRICE`

The task-scoped environment also contained none of these values. Their values were not read or printed. This was the accurate preflight state on 2026-08-13; the 2026-08-28 outcome below supersedes its recovery instruction.

## Final candidate proof vectors

| Run | Raw conclusion | Classification | Evidence gap / failure |
| --- | --- | --- | --- |
| [31715606960](https://github.com/szTheory/accrue/actions/runs/31715606960) | failure | `deterministic_required_lane_failure` | Floor release gate failed; Admin drift was skipped and `annotation-sweep` failed. |
| [31715609742](https://github.com/szTheory/accrue/actions/runs/31715609742) | success | `candidate_regression` | Required `accrue-host-ci-setup-facts` artifact absent. |
| [31715612044](https://github.com/szTheory/accrue/actions/runs/31715612044) | success | `candidate_regression` | Required `accrue-host-ci-setup-facts` artifact absent. |

All three are immutable `workflow_dispatch`, attempt-1 records at candidate SHA `d1244ee5fe591ee18bb31e30df81143b3dd4512c` with `run_live_stripe: false` and provider state `non_run`. Their complete repository-bound job URLs, artifact presence, advisory outcomes, workflow revision, and exclusions are retained in the NDJSON ledger.

## Historical restoration proof

[31716216311](https://github.com/szTheory/accrue/actions/runs/31716216311) is the pre-correction attempt-1 `workflow_dispatch` at restored SHA `80f6019374107fa1086eafc701090234c5e1b31f`, with `run_live_stripe: true`. Host integration, all three Playwright shards, and `annotation-sweep` succeeded; the `live-stripe` provider preflight failed and emitted its artifact, so the raw workflow conclusion is `failure`. This immutable historical record is retained unchanged but did not meet the fresh-success requirement for `rollback_verified`.

## Preserved controls

- The admissible negative control [31660617339](https://github.com/szTheory/accrue/actions/runs/31660617339) remains visible.
- All nine older exclusions and the earlier inadmissible control remain byte-present in the NDJSON ledger.
- The inverse workflow contract, critical-path fixtures, frozen Phase 226 baseline, provider fixtures, setup diagnostics, and Phase 225 preservation controls passed locally.

PATH-02 is unmet: this report records a safe applied rollback with an explicit external proof gap, not a kept comparison.

## Post-recovery contract correction (2026-08-18)

The original proof vector mistakenly required `accrue-host-ci-setup-facts` while also requiring `host-integration` to succeed. That artifact is a failure-path diagnostic: the workflow and host UAT script emit it only when setup or `mix verify.full` fails, and the upload step ignores a missing file on successful runs. No run at any SHA could satisfy both predicates.

The contract now requires the success-path `accrue-host-phase15-screenshots` artifact and retains `accrue-host-ci-setup-facts` in the broader artifact inventory as a failure diagnostic. This is a transparent forward correction recorded after the failed recovery; no historical fingerprint, run record, or earlier classification was edited or backdated.

Read-only GitHub reconciliation revalidated the two successful candidate runs against every remaining predicate:

| Run | Prior classification | Corrected classification | Required path | Success artifact |
| --- | --- | --- | --- | --- |
| [31715609742](https://github.com/szTheory/accrue/actions/runs/31715609742) | `candidate_regression` | `admitted_observation` | passed | `accrue-host-phase15-screenshots` present |
| [31715612044](https://github.com/szTheory/accrue/actions/runs/31715612044) | `candidate_regression` | `admitted_observation` | passed | `accrue-host-phase15-screenshots` present |

These append-only reclassifications supersede the artifact-only exclusions in the historical table above. Run `31715606960` remains excluded for its deterministic required-lane failure. The corrected cohort therefore has only two admitted observations, fewer than the three required by the bounded measurement contract; rollback remains the honest decision. At the time of this correction the single authorized restoration dispatch was still unspent, and the correction itself made no Stripe configuration or workflow mutation.

## Authorized restoration outcome (2026-08-28)

The three repository Stripe inputs were configured without exposing their values. A literal SHA dispatch was rejected by GitHub with HTTP 422 and created no run, so it did not consume the budget. A temporary ref pointing exactly to restored SHA `80f6019374107fa1086eafc701090234c5e1b31f` was then used for the one authorized dispatch and removed immediately after run identity was bound.

[33188858334](https://github.com/szTheory/accrue/actions/runs/33188858334) is that sole attempt-1 `workflow_dispatch`, with `run_live_stripe: true`. Host integration, all three Playwright shards, and `annotation-sweep` succeeded. `accrue-host-phase15-screenshots` and `live-stripe-proof` are present; the failure-only setup-facts artifact is correctly absent.

The three key/price preflight inputs passed. The provider job then failed before selecting any live test because application boot raised `ACCRUE-DX-WEBHOOK-SECRET-MISSING`: the Stripe processor webhook signing secret was absent. The emitted proof classifies this as `misconfigured` / `manifest_invalid`, with zero selected tests and no manifest written. Therefore the run cannot establish `rollback_verified`.

The restoration budget is exhausted. No rerun or replacement is authorized. Phase 227 remains terminally blocked at `rollback_applied_unverified`; Task 3 stays skipped and PATH-02 remains unmet.
