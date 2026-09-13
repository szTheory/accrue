# Phase 227 critical-path kept comparison

## Current fact

- state: `kept`
- owner: maintainer
- PATH-02: `satisfied`
- exact verification: `node scripts/ci/verify_ci_critical_path.mjs --verify-live-actions --evidence .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.ndjson --rendered .planning/phases/227-measured-critical-path-improvement/227-CI-CRITICAL-PATH.md --contract .planning/phases/227-measured-critical-path-improvement/227-ci-contract.json --expected-repository szTheory/accrue --require-activation-evidence .planning/phases/227-measured-critical-path-improvement/227-CANDIDATE-PREFLIGHT.json --require-kept`

## Measured cohort

- frozen Phase 226 median: `2083s`; frozen p95: `2602s`; keep threshold: `1666s`
- exact sample count: `3`; durations: `[1179, 1125, 1079]` seconds; range: `100s`; median: `1125s`; maximum: `1179s`
- candidate SHA: `0339f14d6badaa7d901c27a62379c86b666c5d62`; tree: `0d96bf3a7f6927f43412c1c08de4b51aeba7c4eb`; workflow revision: `sha256:7edeebd139f653b45ba6cd81b7a1024c76fd3d988c8cb11ce552e695ac69be70`; fingerprint: `phase-227-gap-dispatch-false-v3`
- workflow context: attempt-1 `workflow_dispatch` at `phase-227-gap-dispatch-false-v3` with `run_live_stripe: false`; provider state is `non_run`, not provider proof. Separate provider evidence remains literal: `../228-repair-stripe-webhook-signing-ci-boot-contract-under-a-fresh/228-STRIPE-WEBHOOK-BOOT-EVIDENCE.md` / `failed/selected_assertions_failed`.

| Run | Duration | Host DAG wait | Conclusion | Required vector | Required artifact |
| --- | ---: | ---: | --- | --- | --- |
| [34665008225](https://github.com/szTheory/accrue/actions/runs/34665008225) | 1179s | 14s | success | all 12 required roles success | screenshots present |
| [34670140537](https://github.com/szTheory/accrue/actions/runs/34670140537) | 1125s | 2s | success | all 12 required roles success | screenshots present |
| [34700972204](https://github.com/szTheory/accrue/actions/runs/34700972204) | 1079s | 2s | success | all 12 required roles success | screenshots present |

Every required role and the required screenshot artifact is repository-bound and live-verified. Sigra is advisory success for all three runs; the parked Admin UI ratchet is advisory failure for all three and does not alter the required vector.

## Authority and safety accounting

- candidate budget `phase-227-gap-dispatch-false-v3`: 3/3 slots reserved and 3/3 consumed; no reruns, replacements, or concurrent dispatches.
- reservations and immediate bindings: `candidate-01-719a337d` → `34665008225`, `candidate-02-cb440a61` → `34670140537`, `candidate-03-bbe40295` → `34700972204`.
- candidate authority: `closed`; restoration authority: `closed_unspent`; no restoration record exists.
- temporary candidate ref `phase-227-gap-dispatch-false-v3` is removed. The exact unused inverse remains the restored workflow revision `sha256:2622f7d8cb3d20ae68cec19db9f57bf8b88151e712cdbb360e9db03642772fb0`; apply it only if the kept decision is formally superseded.
- predecessors `phase-227-dispatch-false-v1`, `phase-227-gap-dispatch-false-v2`, their runs, and all ledger bytes remain immutable and provide zero v3 observations.

## Retained controls and exclusions

| Negative control | Retained reason |
| --- | --- |
| [31660617339](https://github.com/szTheory/accrue/actions/runs/31660617339) | retained immutable negative control |

| Historical exclusion | Retained reason |
| --- | --- |
| [31659507827](https://github.com/szTheory/accrue/actions/runs/31659507827) | controlled negative run is inadmissible because aggregate annotation sweep did not execute |
| [31661675186](https://github.com/szTheory/accrue/actions/runs/31661675186) | run conclusion failure; PATH-01 requires successful first-attempt observations |
| [31661676716](https://github.com/szTheory/accrue/actions/runs/31661676716) | run conclusion failure; PATH-01 requires successful first-attempt observations |
| [31661678410](https://github.com/szTheory/accrue/actions/runs/31661678410) | run conclusion failure; PATH-01 requires successful first-attempt observations |
| [31662871264](https://github.com/szTheory/accrue/actions/runs/31662871264) | run conclusion failure; required release-gate test expects stale provider-parity guide literal continue-on-error: true |
| [31662872394](https://github.com/szTheory/accrue/actions/runs/31662872394) | run conclusion failure; required release-gate test expects stale provider-parity guide literal continue-on-error: true |
| [31662873551](https://github.com/szTheory/accrue/actions/runs/31662873551) | run conclusion failure; required release-gate test expects stale provider-parity guide literal continue-on-error: true |
| [31664055724](https://github.com/szTheory/accrue/actions/runs/31664055724) | run conclusion failure; selected live-stripe provider lane and parked ratchet lane failed |
| [31664057331](https://github.com/szTheory/accrue/actions/runs/31664057331) | run conclusion failure; selected live-stripe lane, host integration, and parked ratchet lane failed |
| [31664058949](https://github.com/szTheory/accrue/actions/runs/31664058949) | run conclusion failure; selected live-stripe provider lane and parked ratchet lane failed |

The ledger retains all reservation, consumption, required/advisory job URLs, full artifact inventories, activation preflight binding, and recursive privacy checks. Raw logs and artifact contents remain Actions-owned; a green workflow never implies provider proof.
