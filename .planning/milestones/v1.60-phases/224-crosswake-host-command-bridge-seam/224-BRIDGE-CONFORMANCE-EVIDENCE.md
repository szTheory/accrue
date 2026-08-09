# Phase 224 Crosswake Bridge Conformance Evidence

**Evidence class:** deterministic Crosswake bridge compile/unit conformance only.
**Readiness status:** `feasibility_blocked` — this record does not promote any runtime capability.

## Exact-revision conformance

| Field | Value |
| --- | --- |
| Sanitized remote | `https://github.com/szTheory/crosswake.git` |
| Delivery lane | Alpha-owned short-lived `chore/accrue-host-command-bridge` |
| Immutable upstream base | `932b4f32bf087b8e4c0c36c3e54b1031839e867d` |
| Reviewed patch revision | `789175f219de03047456e098fedf4a97891feff2` |
| Reviewed diff range | `932b4f32bf087b8e4c0c36c3e54b1031839e867d..789175f219de03047456e098fedf4a97891feff2` |
| Binary diff identity (SHA-256) | `d4380733c61521060cbb7c7c50b522a6c7b08234ddfd83757cb2cb993a8479d4` |
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

### Trusted sender-frame assertions

At the real WebKit entry point, only a page-world main frame whose WebKit security-origin components exactly match the active session is admitted before decoding or evaluation. The positive trusted tracer invokes the typed delegate once and emits one terminal reply. A forged allowlisted envelope from a subframe, cross-origin main frame, or non-page content world invokes the delegate zero times and delivers zero replies. The existing envelope-origin guard remains after this trusted metadata admission as defense in depth.

| Check | Result | Scope proved |
| --- | --- | --- |
| Exact source lock and native suite | pass | Reviewed Crosswake source compiles and its deterministic unit suite passes at the pinned revision. |
| Host-command admission/lifecycle coverage | pass | Trusted-frame positive plus subframe, cross-origin, and non-page-world reply-suppression regressions; literal descriptor intersection, fixed schemas, opaque handler failure, one-shot terminalization, and stale epoch suppression remain covered by the exact native target. |
| Accrue tracer consumer | pass | The local SwiftPM conformance consumer still resolves and tests without becoming a runtime authority. |
| Capability report assertions | pass | Overall and every capability remain `feasibility_blocked`; every Crosswake compile/unit evidence entry points here. |

No pass count is inferred beyond the test tools' own output. No raw test log, payload,
credential, account/device identifier, adopter identity, receipt, JWS, proof byte, or
correlation value is retained in this record.

### Plan 07 replay and setup assertions

At the real trusted-sender bridge entry, a fully admitted `(routeEpoch, correlationID)` is
claimed under the Crosswake lifecycle lock after protocol/version, trusted-frame/origin,
route, pack, manifest, descriptor/version, registration, and fixed-schema checks—and before
attempt telemetry or host dispatch. The same correlation therefore invokes the host once and
produces at most one terminal reply. A replacement session advances the epoch and retires the
old claim namespace, so the same correlation is admitted once on the replacement route while
an old captured outcome remains reply-expired.

The ordinary `CrosswakeShellConfig` initializer cannot accept host-command descriptors or a
delegate. The only public descriptor-bearing path is the throwing `validating` factory; it
rejects malformed semantic versions plus identical and conflicting same-command duplicates
with bounded diagnostics naming the affected command and error class before channel creation.
A valid factory result traverses the actual bridge and replacement-route test path. The
focused native target passed 17 tests and the complete native target passed 31 tests at the
reviewed revision, including deterministic 32-way duplicate contention.

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
