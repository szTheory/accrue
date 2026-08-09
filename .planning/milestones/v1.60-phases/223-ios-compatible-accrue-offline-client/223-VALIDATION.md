---
phase: 223
slug: ios-compatible-accrue-offline-client
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-06
---

# Phase 223 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (Swift 6 toolchain) |
| **Config file** | `packages/accrue-offline-client/Package.swift` (created in Wave 1) |
| **Quick run command** | `swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests` |
| **Full suite command** | `bash scripts/ci/verify_ios_offline_client.sh && bash scripts/ci/verify_reference_scenario_contract.sh` |
| **Estimated runtime** | ~180 seconds |

---

## Sampling Rate

- **After every task commit:** Run the affected Swift Testing filter, then the package test suite when the task changes core, cache, or package targets.
- **After every plan wave:** Run `swift test --package-path packages/accrue-offline-client`; after Wave 4 run the full suite command.
- **Before `$gsd-verify-work`:** Full suite must be green and `capability-report.json` must remain `feasibility_blocked`.
- **Max feedback latency:** 180 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 223-01-00 | 01 | 1 | IOS-02 | T-223-01..04 | Blocking D-02 publication checkpoint. Automated diagnostic confirms any pre-existing package remains describable. Manual confirmation: record explicit acceptance of exactly fresh/stale_offline/denied/invalid before publication. Resume signal: `confirm-locked-contract`; `halt-phase` stops execution. | Blocking decision checkpoint + package diagnostic | `test ! -e packages/accrue-offline-client/Package.swift \|\| swift package --package-path packages/accrue-offline-client describe >/dev/null` | Conditional pre-Wave 1 | ⬜ pending |
| 223-01-01 | 01 | 1 | IOS-01, IOS-02 | T-223-01..04 | Canonical ES256 proof reaches the private verifier, opaque admission, authenticated cache, and four-state facade; a fresh client loads only authenticated canonical cached state; absent/tampered/recovery-failed cache and malformed proof remain bounded non-grants. | Swift unit/tracer + package graph | `swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests.tracerAcceptsCanonicalAllowAndRecoversIt && swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests.freshClientLoadsAuthenticatedCachedStateWithoutGrantingFromPresence && swift package --package-path packages/accrue-offline-client dump-package \| jq -e '([.products[] \| select(.type.library != null) \| .name] \| sort) == ["AccrueOfflineClientCore"]'` | ❌ Wave 1 | ⬜ pending |
| 223-02-01 | 02 | 2 | IOS-01, IOS-02 | T-223-05, T-223-06, T-223-09 | Corpus, malformed/profile/binding/time/key rotation, high-water, signed-deny, idempotency, and concurrent admission never manufacture authority. | Swift unit/mutation | `swift test --package-path packages/accrue-offline-client --filter OfflineEntitlementClientTests` | ❌ Wave 2 | ⬜ pending |
| 223-02-02 | 02 | 2 | IOS-01, IOS-03 | T-223-06..08 | Interrupted and concurrent replacement retains one complete authenticated envelope and does not permit stale allow over signed denial. | Process/fault | `swift test --package-path packages/accrue-offline-client --filter AtomicOfflineCacheProcessTests` | ❌ Wave 2 | ⬜ pending |
| 223-03-01 | 03 | 3 | IOS-02, IOS-03 | T-223-03, T-223-10..12 | Host reconnect supplies compact bytes only; direct and reconnect paths share verified admission; transport/cache failure is a bounded non-grant. | Swift unit/concurrency | `swift test --package-path packages/accrue-offline-client --filter OfflineReconnectTests` | ❌ Wave 3 | ⬜ pending |
| 223-03-02 | 03 | 3 | IOS-03 | T-223-13, T-223-14 | Apple helper requires explicit ThisDeviceOnly policy and reports pre-first-unlock/keychain failure without weaker fallback; the package graph exposes exactly core plus the optional Apple library. | Swift unit + package graph | `swift test --package-path packages/accrue-offline-client --filter KeychainCacheKeyTests && swift package --package-path packages/accrue-offline-client dump-package \| jq -e '([.products[] \| select(.type.library != null) \| .name] \| sort) == ["AccrueOfflineClientApple", "AccrueOfflineClientCore"]'` | ❌ Wave 3 | ⬜ pending |
| 223-04-00 | 04 | 4 | IOS-01, IOS-02, IOS-03 | T-223-16, T-223-19 | Blocking D-12 evidence checkpoint. Automated diagnostic confirms overall and every capability remain feasibility_blocked. Manual confirmation: record that package test/build/consumer success cannot establish device proof. Resume signal: `confirm-evidence-boundary`; `halt-phase` stops execution. | Blocking decision checkpoint + evidence diagnostic | `jq -e '.overall_status == "feasibility_blocked" and all(.capabilities[]; .status == "feasibility_blocked")' examples/crosswake_tracer/capability-report.json` | ✅ Existing | ⬜ pending |
| 223-04-01 | 04 | 4 | IOS-01, IOS-02, IOS-03 | T-223-15..19 | Tracer is a path-dependent consumer and public docs preserve host ownership and feasibility-only language. | Package/contract | `swift test --package-path examples/crosswake_tracer && swift package --package-path examples/crosswake_tracer describe \| grep -F 'accrue-offline-client' && jq -e '.overall_status == "feasibility_blocked"' examples/crosswake_tracer/capability-report.json` | Existing tracer / ❌ package | ⬜ pending |
| 223-04-02 | 04 | 4 | IOS-01, IOS-02, IOS-03 | T-223-16..19 | CI runs public-package tests, core-only arm64 iOS 16 compilation, runtime/test-surface checks, and read-only feasibility assertions. | CI / SDK compile | `bash scripts/ci/verify_ios_offline_client.sh && bash scripts/ci/verify_reference_scenario_contract.sh` | ❌ Wave 4 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `packages/accrue-offline-client/Package.swift` — SwiftPM manifest and library/test target graph.
- [ ] `Tests/AccrueOfflineClientCoreTests/GoldenVectorFixtureSupport.swift` — test-only canonical corpus/key loader.
- [ ] `Tests/AccrueOfflineClientCoreTests/OfflineEntitlementClientTests.swift` — tracer and mutation suite.
- [ ] `Tests/AccrueOfflineClientProcessTests/AtomicOfflineCacheProcessTests.swift` — process/fault recovery suite.
- [ ] `scripts/ci/verify_ios_offline_client.sh` — merge-blocking package and iOS compilation lane.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Physical-device/Crosswake bridge proof | IOS-01..03 scope boundary | Package test and generic iOS SDK compile are explicitly insufficient evidence. | Do not promote `capability-report.json`; use only the separately authorized physical-device evidence artifact and external gate. |
| One-way public-state contract | IOS-02 | First-adopter public API decision requires human confirmation before publication. | Resolve Plan 223-01 Task 0 with `confirm-locked-contract` or halt. |
| Deterministic-evidence boundary | IOS-01..03 | Readiness/evidence semantics require human confirmation. | Resolve Plan 223-04 Task 0 with `confirm-evidence-boundary` or halt. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or a Wave 0 dependency.
- [ ] Sampling continuity: no three consecutive tasks lack an automated verification command.
- [ ] Wave 0 creates the package, test-support, fault-test, and CI foundations.
- [ ] No watch-mode flags are used.
- [ ] Feedback latency is bounded to 180 seconds.
- [ ] `nyquist_compliant: true` is set only after validate-phase confirms the completed execution evidence.

**Approval:** pending
