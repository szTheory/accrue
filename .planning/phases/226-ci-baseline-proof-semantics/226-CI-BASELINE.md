# CI baseline — corrected three-run comparable cohort

The version 2 JSON record is authoritative. This Markdown is derived only from
that checked-in metadata and must be regenerated whenever the JSON differs.
Raw provider logs, traces, payloads, artifact bodies, and server output remain
in GitHub Actions rather than this repository.

## Eligible cohort and normalized conclusions

| Run | SHA | Initial runner queue | Staged critical chain | Jobs / artifacts | Signature | Eligibility |
| --- | --- | ---: | ---: | ---: | --- | --- |
| 31322443304 | `ee940cf9…` | 2s | 2376s | 20 / 6 | `failed-lane`; `admin-ui-ratchet-guardrails:failure` | eligible anchor |
| 31332551817 | `5da8e6b8…` | 3s | 2683s | 20 / 6 | `failed-lane`; `admin-ui-ratchet-guardrails:failure` | eligible cohort |
| 31344524124 | `5da8e6b8…` | 5s | 2176s | 20 / 6 | `failed-lane`; `admin-ui-ratchet-guardrails:failure` | eligible cohort |

Every run is a successful `workflow_dispatch` attempt one. Initial runner queue
is the earliest manifest-marked root start minus the provider run creation
time. It is deliberately distinct from the staged release → admin → host →
Playwright chain, whose duration spans the ordered chain stages. Neither value
is estimated. The normalized signature contains only category and sorted
manifest lane/conclusion pairs.

## Provenance and setup/cache topology

| Source | Ref / SHA | Workflow blob | Six D-01 lockfiles |
| --- | --- | --- | --- |
| Anchor | `refs/heads/main` / `ee940cf9…` | `0d01e6da…` | exact equality |
| Immutable cohort snapshot | `refs/heads/phase-226-baseline-5da8e6b88735` / `5da8e6b8…` | `0d01e6da…` | exact equality |

The JSON retains the six named lockfile blob OIDs, stable job identities,
required/advisory policy, cache-state classification, and the D-09/D-10 setup
ownership links. Cache evidence remains conservative: an explicit cache action
output is required for `observed-hit`; a skipped setup creation step is
`inferred-setup-bypass`; otherwise it is `unknown`.

## Derived timing and eligible proof

| Metric | Per-run seconds | Min / median / max |
| --- | --- | --- |
| Initial runner queue | 2, 3, 5 | 2 / 3 / 5 |
| Staged critical chain | 2376, 2683, 2176 | 2176 / 2376 / 2683 |
| Wall time | 2380, 2686, 2182 | 2182 / 2380 / 2686 |

The policy manifest defines 15 required proof identities. Each eligible run
proves exactly those identities. Advisory, skipped, conditional, and
not-applicable lanes cannot satisfy release proof; aggregate proof is derived
only from eligible required successful lanes. Any inspected ineligible record
has zero proved lanes.

## Timestamp-scoped provider snapshot

At `2026-08-10T23:52:12Z`, the successful effective-rules response contained no
required-status-check rules and the classic required-status-check endpoint
returned confirmed HTTP 404. The canonical state is therefore
`none-enforced` at that capture instant only; it makes no claim about current
or future enforcement.

## Phase 227 selection gate

Phase 227 may select only candidates that cite the eligible run IDs, exact JSON
paths, affected critical-path stage, and a measured baseline range. The JSON
holds the selection candidates and required evidence fields.
