# CI baseline — run 31322443304

The JSON record is authoritative; this file is a review rendering of its allowlisted facts.

| Metric | Measured value | Interpretation |
| --- | ---: | --- |
| Run wall time | 2,380s / 39m40s | Replaces the old 33–36 minute assumption. |
| Required critical path | approximately 39m36s | Staged release gate → admin drift/docs → host integration → Playwright → annotation sweep. |
| Required-chain queue delay | 11s | Seconds-scale, not the bottleneck. |

The qualifying sample is workflow_dispatch, attempt 1, SHA `ee940cf9e1f86b4d7c551b15ce113feb7f2a2997`, and completed successfully. The OpenTelemetry required release cell took 1,334s; admin drift/docs 202s; host integration 544s; Playwright shard 3 239s; annotation sweep 13s.

## Proof semantics

Every observed job has distinct `policy`, provider `conclusion`, and derived `proof_state` fields in JSON. Only a required, successful job from this eligible first attempt is `proved`; skipped is not proof, advisory is not proof even when green, and event-excluded work is `not-applicable`. Artifact presence and overall workflow success do not manufacture release proof.

## Provider enforcement snapshot

GitHub effective rules for `main` returned `[]`; classic required-status-check protection returned 404. The canonical snapshot therefore explicitly records `none-enforced`. Workflow YAML is repository proof taxonomy, not inferred external enforcement.

## Privacy boundary

Committed facts are limited to run/job/step timestamps and conclusions, cache state, artifact name/size/expiry, and required-check context/app ID. No logs, artifact archives, environment values, raw payloads, traces, reports, screenshots, or server output are committed. Raw evidence remains Actions-owned.
