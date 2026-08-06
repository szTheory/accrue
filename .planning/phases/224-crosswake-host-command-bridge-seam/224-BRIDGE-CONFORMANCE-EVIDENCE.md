# Phase 224 Crosswake Bridge Conformance Evidence

**Evidence class:** deterministic Crosswake bridge compile/unit conformance only.
**Readiness status:** `feasibility_blocked` — this record does not promote any runtime capability.

## Exact-revision conformance

| Field | Value |
| --- | --- |
| Sanitized remote | `https://github.com/szTheory/crosswake.git` |
| Delivery lane | Alpha-owned short-lived `chore/accrue-host-command-bridge` |
| Immutable upstream base | `932b4f32bf087b8e4c0c36c3e54b1031839e867d` |
| Reviewed patch revision | `57e03b61082b1f865bc31c5e8b6dcee444f56dad` |
| Reviewed diff range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..57e03b61082b1f865bc31c5e8b6dcee444f56dad` |
| Binary diff identity (SHA-256) | `9d5330a471d7446fb8657fa22c5c41ade458b4eb739c50cbf245a1457d954e31` |
| Audit digest | Bound through `crosswake-source-lock.json` |
| Review status | Local diff reviewed; deterministic suites passed |
| Upstream convergence | `alpha_fork_pending_upstream_review`; no upstream acceptance or PR is asserted |

The checked-in source lock is the machine-readable authority for the exact remote, base,
patch, diff identity, and audit digest. The final source audit contains the exhaustive
four-file production/test inventory for this reviewed diff.

## Environment and commands

| Fact | Observed value |
| --- | --- |
| Swift | Apple Swift 6.3.3 |
| Xcode | 26.6 (build 17F113) |
| Platform | macOS 26.5, arm64 |
| Exact native target | `swift test --package-path packages/crosswake-shell-core-ios` |
| Pinned complete gate | `CROSSWAKE_SOURCE_ROOT=/Users/jon/projects/crosswake-accrue-bridge bash scripts/ci/verify_crosswake_host_commands.sh full` |
| Accrue tracer consumer | `swift test --package-path examples/crosswake_tracer` |
| Blocked-status assertion | `jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` |

The complete gate first rejects a wrong remote, dirty checkout, non-matching revision,
broken ancestry, diff mismatch, or audit mismatch. It then runs the exact native suite,
the tracer consumer, the evidence digest assertion, and the report's blocked-status and
evidence-location assertion.

## Observed deterministic results

| Check | Result | Scope proved |
| --- | --- | --- |
| Exact source lock and native suite | pass | Reviewed Crosswake source compiles and its deterministic unit suite passes at the pinned revision. |
| Host-command admission/lifecycle coverage | pass | Literal descriptor intersection, fixed schemas, opaque handler failure, one-shot terminalization, and stale epoch suppression remain covered by the exact native target. |
| Accrue tracer consumer | pass | The local SwiftPM conformance consumer still resolves and tests without becoming a runtime authority. |
| Capability report assertions | pass | Overall and every capability remain `feasibility_blocked`; every Crosswake compile/unit evidence entry points here. |

No pass count is inferred beyond the test tools' own output. No raw test log, payload,
credential, account/device identifier, adopter identity, receipt, JWS, proof byte, or
correlation value is retained in this record.

## BRDG conformance matrix

| Requirement | Deterministic evidence | Boundary retained |
| --- | --- | --- |
| BRDG-01 | Exact pinned native suite and source audit cover protocol/version/route/origin/pack/manifest admission, four literal commands, and manifest-plus-registration/version intersection. | Crosswake remains the validated transport and reply owner; no Accrue-local bridge or generic plugin API exists. |
| BRDG-02 | Exact pinned native suite covers malformed and unregistered denial, throwing delegate normalization, one-shot terminalization, and route-epoch stale-reply suppression. | Success is a transport outcome only; no command or test grants an entitlement. |

## STRIDE mitigation matrix

| Threat | Evidence | Result |
| --- | --- | --- |
| T-224-14 information disclosure | Sanitized remote identity, structural facts only, no raw logs or payload material. | mitigated within checked-in evidence scope |
| T-224-15 readiness spoofing | Complete gate asserts the overall and every capability status stays `feasibility_blocked`; physical-device requirements stay present. | mitigated |
| T-224-16 repudiation | Lock binds base, patch, diff identity, audit, target, commands, environment, review, convergence, requirements, and limitations. | mitigated |
| T-224-SC evidence source tampering | Complete gate validates remote, clean revision, ancestry, diff, audit digest, and this evidence digest before accepting results. | mitigated |

## Limitations and unresolved assumptions

This evidence establishes deterministic Crosswake bridge compile/unit conformance only.
It includes no StoreKit behavior, Accrue integration, authenticated host transport proof,
simulator promotion, physical-iPhone run, UI, host authentication, or runtime-readiness
claim. The separate `physical-device-evidence.md` remains blocked and unchanged.

`SPEC-FALLBACK-BRDG-01` and `SPEC-FALLBACK-BRDG-02` remain FLAGGED-UNVERIFIED: the
specless probe did not classify them and supplied no explicit edge/prohibition verification
tier. The descriptor-less prohibitions against a generic commerce/plugin API, sensitive
adopter/billing/device material, and treating deterministic success as entitlement or
physical-device proof also remain unresolved and visible in the plan. Passing deterministic
evidence does not resolve any of those assumptions or prohibitions.
