# CI baseline — three comparable first-attempt dispatches

The JSON record is authoritative. This rendering contains measured, privacy-safe cohort facts only; raw provider diagnostics remain in GitHub Actions.

## Eligible cohort and normalized failures

| Run | SHA | Queue seconds | Root-failure signature | Eligibility |
| --- | --- | ---: | --- | --- |
| 31322443304 | `ee940cf9…` | 2366 | `ci-root-v1-ZmFpbGVk…`; `failed-lane`; `admin-ui-ratchet-guardrails` | eligible anchor |
| 31332551817 | `5da8e6b8…` | 2670 | `ci-root-v1-ZmFpbGVk…`; `failed-lane`; `admin-ui-ratchet-guardrails` | eligible cohort |
| 31344524124 | `5da8e6b8…` | 2167 | `ci-root-v1-ZmFpbGVk…`; `failed-lane`; `admin-ui-ratchet-guardrails` | eligible cohort |

Every run is a successful `workflow_dispatch` attempt one. Queue derives from the latest observed start among the manifest-marked required critical roots minus the provider run creation time; it is never estimated. The signature is a versioned ID derived solely from its normalized category and sorted manifest lane identities.

## Provenance equality

| Source | Ref / SHA | Workflow blob | Six D-01 lockfiles |
| --- | --- | --- | --- |
| Anchor | `refs/heads/main` / `ee940cf9…` | `0d01e6da…` | exact equality |
| Immutable cohort snapshot | `refs/heads/phase-226-baseline-5da8e6b88735` / `5da8e6b8…` | `0d01e6da…` | exact equality |

The complete JSON objects hold the six named lockfile OIDs: `accrue/mix.lock`, `accrue_admin/mix.lock`, `accrue_admin/package-lock.json`, `examples/accrue_host/mix.lock`, `examples/accrue_host/package-lock.json`, and `examples/accrue_host/assets/package-lock.json`. No extra path substitutes for a missing required key.

## Derived aggregates and proof

| Metric | Per-run seconds | Min / median / max |
| --- | --- | --- |
| Wall time | 2380, 2686, 2182 | 2182 / 2380 / 2686 |
| Critical queue | 2366, 2670, 2167 | 2167 / 2366 / 2670 |

The versioned workflow-policy manifest defines 15 required proof identities. For each eligible run, exactly those 15 identities resolve to `proved`; the advisory ratchet lane and conditional live-Stripe lane cannot satisfy release proof. `aggregates.proof.all_required_lanes_proved` is mechanically derived from those three per-run identity sets, not copied from a boolean.

Cache evidence remains conservative: an explicit cache-action output is required for `observed-hit`; a skipped setup creation step is recorded as `inferred-setup-bypass` and insufficient evidence is `unknown`.

## Phase 227 selection gate

Phase 227 may choose only a candidate that cites the eligible run IDs, exact JSON paths, affected critical-path stage, and a measured baseline range. Provider enforcement stays a timestamp-scoped snapshot rather than an inference from workflow YAML.
