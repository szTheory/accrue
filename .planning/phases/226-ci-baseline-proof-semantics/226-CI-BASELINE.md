# CI baseline — three comparable first-attempt dispatches

The JSON record is authoritative; this rendering retains reviewable cohort and proof facts only.

## Eligibility and exclusions

| Run | SHA | Event / attempt | Wall | Eligibility |
| --- | --- | --- | ---: | --- |
| 31322443304 | `ee940cf9…` | workflow_dispatch / 1 | 2,380s | eligible anchor |
| 31332551817 | `5da8e6b8…` | workflow_dispatch / 1 | 2,686s | eligible current-shape cohort |
| 31344524124 | `5da8e6b8…` | workflow_dispatch / 1 | 2,182s | eligible current-shape cohort |

The dedicated immutable branch is `phase-226-baseline-5da8e6b88735`; its remote SHA, workflow blob, and six critical-chain lockfile blobs exactly match the recorded snapshot and anchor. There are no rejected candidates. Both new runs retained the parked **Admin UI ratchet guardrails** failure as `advisory`, not required proof.

## Timing and critical path

| Metric | Per-run seconds | Min / median / max |
| --- | --- | --- |
| Wall time | 2380, 2686, 2182 | 2182 / 2380 / 2686 |
| Required critical chain | anchor approximately 39m36s | staged release → admin drift/docs → host integration → Playwright → annotation |

The anchor’s 2,380-second wall time and approximately 39m36s chain remain the baseline, not the obsolete 33–36 minute assumption. The new runs confirm that queueing is not the primary driver; provider timestamps preserve each job and step duration in JSON. Docker/browser setup (Node, npm, Chromium) repeats in host/browser jobs, but must not be selected as a critical-path optimization without the exact eligible-run job/step evidence.

## Proof state and setup observations

Required successful lanes are `proved`; skipped work is not proof; the parked ratchet remains `advisory`; event-excluded work is `not-applicable`. All three cohort members are first attempt—no rerun was used. Cache state is retained per job (`observed-hit`, `observed-miss`, or `unknown`); provider state and artifact metadata remain metadata-only and privacy-safe.

## Phase 227 selection gate

Phase 227 may choose only a candidate that cites eligible run IDs, exact JSON paths, the affected critical-path stage, and the baseline median/range. The ranked JSON candidates point first to release setup/cache investigation and then host integration; an advisory, skipped, not-applicable, or unmeasured candidate is ineligible.
