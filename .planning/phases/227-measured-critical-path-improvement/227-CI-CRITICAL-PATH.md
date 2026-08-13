# Phase 227 critical-path comparison

## Current fact

No eligible post-change observations exist. Every retained `workflow_dispatch` candidate run concluded `failure`, so the locked requirement for three successful first-attempt observations is unmet.

## Decision

- state: `rollback_required`
- owner: maintainer
- next command: `replan after selecting a compatible event class that does not require unavailable provider proof`

## Immutable controls and exclusions

- Admissible negative control: [31660617339](https://github.com/szTheory/accrue/actions/runs/31660617339) — host integration and all Playwright shards succeeded; `annotation-sweep` failed on the recorded test annotation.
- First candidate cohort exclusions: [31661675186](https://github.com/szTheory/accrue/actions/runs/31661675186), [31661676716](https://github.com/szTheory/accrue/actions/runs/31661676716), [31661678410](https://github.com/szTheory/accrue/actions/runs/31661678410).
- Second candidate cohort exclusions: [31662871264](https://github.com/szTheory/accrue/actions/runs/31662871264), [31662872394](https://github.com/szTheory/accrue/actions/runs/31662872394), [31662873551](https://github.com/szTheory/accrue/actions/runs/31662873551).
- Final permitted cohort exclusions: [31664055724](https://github.com/szTheory/accrue/actions/runs/31664055724), [31664057331](https://github.com/szTheory/accrue/actions/runs/31664057331), [31664058949](https://github.com/szTheory/accrue/actions/runs/31664058949).

The Phase 226 before evidence remains frozen. This report is intentionally an insufficient-evidence account, not a comparison or keep decision.
