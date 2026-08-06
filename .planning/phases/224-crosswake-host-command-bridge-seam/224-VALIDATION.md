---
phase: 224
slug: crosswake-host-command-bridge-seam
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-06
---

# Phase 224 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|---|---|
| **Framework** | Swift Testing on Swift 6.3.3; the pinned Crosswake package/project test configuration is discovered in Wave 0. |
| **Config file** | Pinned Crosswake package/project configuration (not locally available yet). |
| **Quick run command** | The exact pinned-Crosswake host-command admission test filter, recorded by Wave 0. |
| **Full suite command** | The pinned Crosswake bridge suite plus `swift test --package-path examples/crosswake_tracer` and the capability-report `jq` assertion. |
| **Estimated runtime** | Unknown until the immutable Crosswake source and its test target are pinned. |

## Sampling Rate

- **After every task commit:** Run the affected pinned-Crosswake host-command tests.
- **After every plan wave:** Run the complete pinned-Crosswake bridge suite and the tracer/evidence assertion.
- **Before `$gsd-verify-work`:** All deterministic suites must be green and the capability report must remain `feasibility_blocked`.
- **Max feedback latency:** One task commit.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---|---|---|---|---|---|---|---|---|---|
| 224-01-01 | 01 | 1 | BRDG-01, BRDG-02 | T-224-01..04 | An authorized clean immutable base audit/lock passes before any Crosswake edit; the reviewed patch preserves that base and its tracer traverses the real admission/reply path while public status stays blocked. | source gate + Crosswake tracer | `bash scripts/ci/verify_crosswake_host_commands.sh source-gate && bash scripts/ci/verify_crosswake_host_commands.sh tracer && jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` | ❌ W0 | ⬜ pending |
| 224-02-01 | 02 | 2 | BRDG-01, BRDG-02 | T-224-05, T-224-08..09 | All four bounded schemas, exact manifest/registry/version admission, stable denial, narrow delegate, and privacy-safe telemetry contracts pass through the audit-recorded admission suite. | Crosswake admission/API/privacy | `bash scripts/ci/verify_crosswake_host_commands.sh admission` | ❌ W0 | ⬜ pending |
| 224-02-02 | 02 | 2 | BRDG-02 | T-224-06..08 | Navigation invalidation, route-binding recheck, cancellation, and one-shot terminalization pass the lifecycle suite without regressing admission. | Crosswake lifecycle/race | `bash scripts/ci/verify_crosswake_host_commands.sh lifecycle && bash scripts/ci/verify_crosswake_host_commands.sh admission` | ❌ W0 | ⬜ pending |
| 224-03-01 | 03 | 3 | BRDG-01, BRDG-02 | T-224-10, T-224-12..13 | Ordered zero-delegate negatives, fixed request/response bounds, delegate API isolation, and telemetry/evidence privacy pass the admission/API suite. | Crosswake admission/API/privacy negative | `bash scripts/ci/verify_crosswake_host_commands.sh admission` | ❌ W0 | ⬜ pending |
| 224-03-02 | 03 | 3 | BRDG-02 | T-224-11..12 | Handler failure, cancellation, duplicate completion, and origin/manifest/route/epoch races remain stale-reply-safe under lifecycle and combined exact-pin execution. | Crosswake lifecycle/race + full runner | `bash scripts/ci/verify_crosswake_host_commands.sh lifecycle && bash scripts/ci/verify_crosswake_host_commands.sh full` | ❌ W0 | ⬜ pending |
| 224-04-01 | 04 | 4 | BRDG-01, BRDG-02 | T-224-15 | Locked D-03 is asserted automatically: overall and every capability remain blocked before evidence publication, or execution halts without mutation. | checked-in status contract | `jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` | ✅ | ⬜ pending |
| 224-04-02 | 04 | 4 | BRDG-01, BRDG-02 | T-224-14..16 | Exact-revision evidence, complete native runner, tracer consumer, evidence location, and blocked-status assertions pass together without a runtime promotion. | full runner + tracer + blocked evidence contract | `bash scripts/ci/verify_crosswake_host_commands.sh full && swift test --package-path examples/crosswake_tracer && jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked") and all(.capabilities[] | .evidence[]; (.kind != "crosswake_bridge_compile_unit") or (.location | contains("224-BRIDGE-CONFORMANCE-EVIDENCE.md")))' examples/crosswake_tracer/capability-report.json` | ❌ W0 | ⬜ pending |

## Wave 0 Requirements

- [ ] Record and verify the authorized immutable base source lock/audit before any Crosswake edit, then preserve that base while adding the reviewed patch revision, exact module/test target, diff, and upstream/fork convergence status.
- [ ] Add pinned-source `HostCommandAdmissionTests` that prove every mandatory pre-dispatch validation layer.
- [ ] Add pinned-source `HostCommandDenialAndEpochTests` for failure, cancellation, duplicate completion, and navigation races.
- [ ] Add a static/API test showing the host delegate receives neither WebKit nor reply-transport types.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|---|---|---|---|
| Physical-iPhone runtime readiness | BRDG-01, BRDG-02 | Explicitly out of scope; deterministic compile/test evidence cannot promote runtime readiness. | Do not perform or claim this evidence in Phase 224. Keep the capability report blocked. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no three consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing pinned-source references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is one task commit.
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence is available.

**Approval:** pending
