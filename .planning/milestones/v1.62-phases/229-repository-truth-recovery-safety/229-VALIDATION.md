---
phase: "229"
slug: "repository-truth-recovery-safety"
status: validated
nyquist_compliant: false
wave_0_complete: true
created: "2026-09-13"
revalidated: "2026-09-13"
---

# Phase 229 — Validation Strategy

## Final Result

Phase 229 is **partially validated** after the second gap-closure cycle. The preservation, pagination, strict-authority, privacy, CI-monitor, documentation, and handoff-comparator suites are green. Two adversarial checks exposed implementation defects that prevent a Nyquist-compliant final handoff:

1. Final collection decodes symlink link text as a string, so an unchanged invalid-UTF-8 symlink recorded byte-exactly by preservation is rejected as changed.
2. The committed canonical inventory cannot satisfy the strict verifier's exact-live-active-object rule after the plan, summary, validation, or hook commit advances the active branch.

The failures are implementation behavior, not test defects. They are escalated rather than hidden or weakened.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Dependency-free Node.js `node:test` suites plus Bash integration self-tests |
| **Config file** | none |
| **Behavioral test files** | `scripts/ci/preserve_repository_state.sh`, `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/verify_repository_inventory.mjs`, `scripts/ci/ci_monitor.cjs`, `scripts/ci/phase229_gap_closure.test.mjs`, `scripts/ci/verify_phase229_handoff_invariants.mjs` |
| **Quick command** | `node --test scripts/ci/phase229_gap_closure.test.mjs` |
| **Full local command** | `bash scripts/ci/preserve_repository_state.sh --self-test && node --test scripts/ci/collect_repository_inventory.mjs && node --test scripts/ci/verify_repository_inventory.mjs && node --test scripts/ci/phase229_gap_closure.test.mjs && node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md && node --test scripts/ci/ci_monitor.cjs && node scripts/ci/verify_phase229_handoff_invariants.mjs --self-test` |
| **Strict fixture command** | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-edge-cases --require-command-provenance --require-privacy-controls --require-determinism` |
| **Observed runtime** | about 30 seconds for the full local command |

The real-capsule verifier additionally requires private runtime inputs. Values and locations must never enter committed evidence.

```bash
test -n "${PHASE229_PRIVATE_MANIFEST:-}" && \
test -n "${PHASE229_RECOVERY_BUNDLE:-}" && \
test -n "${PHASE229_MANIFEST_SHA256:-}" && \
node scripts/ci/verify_repository_inventory.mjs \
  --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json \
  --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md \
  --expected-repository szTheory/accrue --repository-root . \
  --recovery-manifest "$PHASE229_PRIVATE_MANIFEST" \
  --expected-manifest-sha256 "$PHASE229_MANIFEST_SHA256" \
  --recovery-bundle "$PHASE229_RECOVERY_BUNDLE" \
  --require-recovery --require-all-ref-recovery --require-typed-artifacts \
  --require-complete-categories --require-edge-cases --require-command-provenance \
  --require-privacy-controls --require-determinism \
  --require-workflow-metadata-authorization
```

## Requirement Coverage

| Requirement | Observable behavior | Automated evidence | Status |
|-------------|---------------------|--------------------|--------|
| REPO-01 | Complete bounded repository/remote truth, exact live/planning authority reconciliation, privacy rejection, and deterministic rendering. | Collector/verifier suites and CR-03 through CR-08 matrix pass; committed real-capsule verification is stale after later commits. | partial |
| REPO-02 | Exact all-ref capsule recovery, byte-exact artifact identity, and final capsule/workspace invariants. | Preservation and handoff suites pass; raw non-UTF-8 symlink final collection fails. | partial |
| REPO-03 | One fixed-repository, exact-SHA, read-only monitor with an absolute deadline and selected/viewed run binding. | Monitor self-test, wrapper/docs check, four Node tests, CR-09, and WR-02 pass. | green |

## Second-Cycle Per-Plan Verification Map

| Plan / task | Requirement | Test type | Automated command | Status |
|-------------|-------------|-----------|-------------------|--------|
| 229-10-01 | REPO-02 | integration | `bash scripts/ci/preserve_repository_state.sh --self-test` | green |
| 229-10-02 | REPO-02 | integration | `bash scripts/ci/preserve_repository_state.sh --self-test` | green |
| 229-11-01, 229-11-02 | REPO-01 | unit/integration | `node --test scripts/ci/collect_repository_inventory.mjs && node --test scripts/ci/phase229_gap_closure.test.mjs` | green |
| 229-12-01, 229-12-02 | REPO-03 | integration/smoke | `node --test scripts/ci/ci_monitor.cjs && node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md` | green |
| 229-13-01, 229-13-02 | REPO-01, REPO-02, REPO-03 | integration | `node --test scripts/ci/phase229_gap_closure.test.mjs` plus the strict fixture command | green |
| 229-14-01 | REPO-02 | integration | `node --test --test-name-pattern='WR-01 documented strict command' scripts/ci/phase229_gap_closure.test.mjs` | green |
| 229-14-02 | REPO-01, REPO-02, REPO-03 | integration | handoff self-test and real-capsule strict command | blocked |

## Second-Cycle Adversarial Matrix

| Behavior | Executable evidence | Result |
|----------|---------------------|--------|
| Final artifact mutation blocks preservation PASS and removes only invocation-owned outputs. | CR-01 preservation subprocess fixture | filled |
| Symlink preservation hashes exact raw link bytes, including invalid UTF-8 and newline endings. | CR-02 preservation subprocess fixture | filled |
| PR, release-ref, and Actions plural facts require terminal pages and discard partial values on overflow/failure. | Collector embedded tests plus CR-03 | filled |
| Fabricated active object and altered preservation rows fail independent strict recovery. | CR-04 and CR-05 generated-repository fixtures | filled |
| Worktree/window missing, extra, duplicate, and changed rows fail direct authority reconciliation. | CR-06 plus real filesystem/Git snapshot additions | filled |
| Category provenance rejects unrelated, missing, duplicate, skipped, reordered, foreign, and over-bound requests. | CR-07 | filled |
| Privacy controls reject POSIX, Windows, UNC, drive-relative, file-URI, C0, and DEL values. | CR-08 | filled |
| CI watch obeys one wall-clock deadline; viewed results cannot switch run ID or workflow. | CR-09 and WR-02 isolated monitor processes | filled |
| README strict command accepts generated valid authority and rejects missing, empty, wrong, or broad-permission inputs. | WR-01 generated-capsule subprocess fixture | filled |
| Real capsule add/delete/rename/content/link/type/mode and attestation deltas are detected. | `final handoff capsule snapshots reject real filesystem identity drift` | filled |
| Real untracked content, tag movement, and worktree identity changes are detected. | `final handoff workspace snapshots reject real untracked ref and worktree drift` | filled |
| An unchanged invalid-UTF-8 symlink survives preservation, attestation, and final collection with one raw digest. | Temporary generated-capsule adversarial test run during this audit | escalated |
| The committed canonical inventory passes strict real-capsule verification after execution commits finish. | Real-capsule strict command above | escalated |

## Escalated Implementation Gaps

### NYQ-229-01 — Raw symlink bytes are decoded during final collection

- **Requirement:** REPO-02 / D-05 / Plans 229-10 and 229-14.
- **Expected:** An unchanged symlink whose link text is raw bytes `ff fe 0a` retains the SHA-256 recorded by preservation and passes final artifact reconciliation.
- **Actual:** A generated repository and private capsule passed preservation, then `collectRepositoryInventory` threw `artifact changed without exact authorization: raw-link`.
- **Cause:** `currentArtifact()` in `scripts/ci/collect_repository_inventory.mjs` calls `fs.readlinkSync(full)` without `{ encoding: "buffer" }`, while preservation and final attestation hash a Buffer.
- **Iterations:** 1/3; the assertion reached the implementation contract directly, so weakening or retrying the test was not appropriate.
- **Required fix:** Hash the Buffer returned by `fs.readlinkSync(full, { encoding: "buffer" })`, fail closed on non-Buffer/read failure, and retain the generated-capsule regression.

### NYQ-229-02 — Committed canonical active-ref evidence is immediately stale

- **Requirement:** REPO-01 / Plans 229-13 and 229-14.
- **Expected:** The committed final JSON/Markdown pair passes strict real-capsule verification on the completed phase tree.
- **Actual:** The read-only real-capsule command exited 1 with `recorded milestone branch object differs from the live active object` after normal plan/summary/hook commits advanced the branch.
- **Cause:** Strict verification requires the canonical active SHA to equal live `HEAD`, but committing the canonical pair and subsequent phase artifacts necessarily advances that same ref. The captured record cannot describe its own later commit by exact SHA.
- **Iterations:** 1/3; the failure is deterministic on the completed tree.
- **Required fix:** Define a non-self-referential capture authority (for example, a captured-at commit plus verified ancestry/recovery continuity) and add a post-commit strict regression. Do not weaken frozen-ref or bundle equality.

## Validation Audit 2026-09-13 — Second Gap-Closure Cycle

| Metric | Count |
|--------|-------|
| Gaps found | 4 |
| Resolved with behavioral tests | 2 |
| Escalated implementation blockers | 2 |
| Existing gap-closure tests passing | 24/24 |
| Collector tests passing | 6/6 |
| Inventory verifier tests passing | 8/8 |
| CI monitor tests passing | 4/4 |

## Observed Evidence

- Preservation Bash self-test: PASS.
- Collector Node suite: 6/6 PASS.
- Inventory verifier Node suite: 8/8 PASS.
- Gap-closure suite after test additions: 24/24 PASS.
- CI monitor Node suite: 4/4 PASS; wrapper and documentation verification PASS.
- Handoff invariant self-test: PASS for its named capsule/workspace/attestation comparisons.
- Full strict synthetic fixture command: PASS.
- Real-capsule strict command on the completed branch: FAIL with the active-object mismatch above.
- Generated raw-symlink final-collection probe: FAIL with the artifact-authorization mismatch above.

## Manual-Only Verifications

None. The two unresolved items are not manual checks; they are deterministic implementation failures with automated reproduction evidence.

## Validation Sign-Off

- [x] All Plans 229-10 through 229-14 and their summaries were audited.
- [x] Every existing test command was run in this audit.
- [x] Two synthetic-only invariant claims gained real filesystem/Git behavioral tests.
- [x] Implementation files remained read-only during this audit.
- [x] No original recovery-capsule or unrelated user-owned file was modified.
- [ ] Raw-byte symlink evidence survives final collection.
- [ ] The committed canonical inventory passes strict verification on the completed tree.

**Approval:** partial — implementation blockers NYQ-229-01 and NYQ-229-02 must be closed before Phase 229 is Nyquist-compliant.
