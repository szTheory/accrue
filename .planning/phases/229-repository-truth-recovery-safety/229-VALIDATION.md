---
phase: "229"
slug: "repository-truth-recovery-safety"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-13"
---

# Phase 229 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Dependency-free Node.js fixture/self-test commands and Bash integration self-test |
| **Config file** | none |
| **Quick run command** | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories --require-edge-cases --require-all-ref-recovery --require-typed-artifacts --require-privacy-controls --require-determinism && node scripts/ci/ci_monitor.cjs --self-test` (fixtures also prove a replacement manifest+bundle pair, wrong/missing independent manifest digest, broad manifest permissions, unavailable ownership validation, actual bundle, and timestamped final-capture attestation fail before remote observation) |
| **Full suite command** | `bash scripts/ci/preserve_repository_state.sh --self-test && node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md && node scripts/ci/verify_repository_inventory.mjs --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-command-provenance --require-privacy-controls --require-determinism` |
| **Estimated runtime** | < 1 second |

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|-------------|--------|
| 229-01-01 | 01 | 1 | REPO-01, REPO-02 | Freezes all `refs/**`, verifies encoded refs/bundle, and hashes supported artifacts without dereferencing symlinks. | integration | `bash scripts/ci/preserve_repository_state.sh --self-test && node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-all-ref-recovery --require-typed-artifacts` | ✅ | ✅ green |
| 229-01-02 | 01 | 1 | REPO-01, REPO-02 | Committed local inventory is recovery-backed, sanitized, and reproducible. | integration | `node scripts/ci/verify_repository_inventory.mjs --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-command-provenance --require-privacy-controls --require-determinism` | ✅ | ✅ green |
| 229-02-01 | 02 | 1 | REPO-03 | List/inspect/watch accept only repository-bound, exact-SHA read operations; failure details are sanitized and provider proof remains separate. | unit | `node scripts/ci/ci_monitor.cjs --self-test && node --test scripts/ci/ci_monitor.cjs` | ✅ | ✅ green |
| 229-02-02 | 02 | 1 | REPO-03 | Compatibility wrapper delegates once to the bounded monitor and makes no direct GitHub call. | smoke | `bash -n scripts/ci/watch_ci.sh && node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh` | ✅ | ✅ green |
| 229-03-01 | 03 | 2 | REPO-01, REPO-02 | Recovery gating rejects incomplete recovery; remote records are repository-bound or explicitly unavailable with no substituted value. | unit | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories --require-edge-cases --require-all-ref-recovery --require-typed-artifacts` | ✅ | ✅ green |
| 229-03-02 | 03 | 2 | REPO-01, REPO-02 | Validated JSON is a deterministic, privacy-safe Markdown projection with stable ordering. | unit | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-complete-categories --require-all-ref-recovery --require-typed-artifacts --require-privacy-controls --require-determinism` | ✅ | ✅ green |
| 229-04-01 | 04 | 3 | REPO-01, REPO-03 | Documentation pins the JSON authority, read-only fixed-repository list/inspect/watch path, bounded watch, and provider-proof distinction. | smoke | `node scripts/ci/ci_monitor.cjs --self-test --verify-docs scripts/ci/README.md && node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --verify-docs scripts/ci/README.md` | ✅ | ✅ green |
| 229-04-02 | 04 | 3 | REPO-01, REPO-02, REPO-03 | Final evidence revalidates recovery, typed artifacts, categories, provenance, privacy, and byte-identical rendering. | integration | `node scripts/ci/verify_repository_inventory.mjs --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-command-provenance --require-privacy-controls --require-determinism` | ✅ | ✅ green |
| 229-04-security-remediation | 04 | 3 | REPO-02 | The collector validates the actual bundle digest, bounded bundle verification, every listed frozen ref/object, encoded refs, and timestamped typed pre/post invariants before an adapter can observe a remote. | integration | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue` | ✅ | ✅ green |
| 229-04-manifest-integrity-remediation | 04 | 3 | REPO-02 | The committed canonical inventory anchors the original private-manifest SHA-256; collection requires that independent digest and current-user ownership/mode validation before parsing the manifest, bundle checks, attestations, artifact validation, or adapter observation. | integration | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue` | ✅ | ✅ green |

## Manual-Only Verifications

All Phase 229 behaviors have executable coverage. Live-provider availability is intentionally not required: the committed remote records are expected to remain explicit `unavailable` records when a read adapter is unavailable, and the final verifier proves they do not masquerade as observed remote facts.

## Validation Sign-Off

- [x] Every plan task has an automated command.
- [x] REPO-01, REPO-02, and REPO-03 have behavioral coverage.
- [x] Recovery, privacy, unavailable-remote honesty, deterministic rendering, exact-SHA monitoring, wrapper delegation, and documentation contracts ran green.
- [x] No watch-mode command was used.
- [x] No implementation files were modified during this audit.
- [x] `nyquist_compliant: true` is set.

**Approval:** validated 2026-09-13

## Validation Audit 2026-09-13

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved with new tests | 0 |
| Existing behavioral commands run | 11 |
| Escalated | 0 |

The historical Plan 01 local-only record command was exercised once against the later Phase 04 final inventory and failed with `local-only inventory is required`. This is expected because Phase 04 intentionally changes the final artifact to `live_remote` mode while retaining explicit unavailable remote facts. The applicable final-record command above passed; no test or implementation change was warranted.
