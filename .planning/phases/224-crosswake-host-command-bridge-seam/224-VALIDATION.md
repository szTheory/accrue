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
| 224-01-01 | 01 | 1 | BRDG-01, BRDG-02 | T-224-01 | Source pin, source audit, base/diff, and convergence evidence exist before a Crosswake change is attempted. | source/evidence | Pinned-source discovery command plus capability-report assertion | ❌ W0 | ⬜ pending |
| 224-02-01 | 02 | 2 | BRDG-01 | T-224-02 | Protocol, version, origin, pack, manifest, route, and epoch checks complete before a matching manifest capability and registry delegate can dispatch. | Crosswake unit/integration | `<pinned-crosswake-test-command> HostCommandAdmissionTests` | ❌ W0 | ⬜ pending |
| 224-02-02 | 02 | 2 | BRDG-02 | T-224-03 | Invalid input, undeclared or unregistered commands, bad origin/route/version, failures, duplicate completion, cancellation, and navigation races never reach transport control or yield a stale reply. | Crosswake negative/concurrency | `<pinned-crosswake-test-command> HostCommandDenialAndEpochTests` | ❌ W0 | ⬜ pending |
| 224-03-01 | 03 | 3 | BRDG-01, BRDG-02 | T-224-04 | Deterministic bridge evidence remains non-runtime evidence and all capability statuses remain blocked. | consumer/contract | `swift test --package-path examples/crosswake_tracer && jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` | ✅ | ⬜ pending |

## Wave 0 Requirements

- [ ] Record the immutable Crosswake source revision, exact module/test target, base/diff, and upstream/fork convergence status.
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
