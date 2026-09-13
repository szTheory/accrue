---
phase: "229"
slug: "repository-truth-recovery-safety"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-13"
revalidated: "2026-09-13"
---

# Phase 229 — Validation Strategy

## Final Result

Phase 229 is Nyquist-compliant after Plans 229-05 through 229-09 and the final adversarial coverage pass. REPO-01, REPO-02, REPO-03, CR-01 through CR-10, and WR-01 through WR-03 all have executable behavioral coverage. The historical failures in `229-VERIFICATION.md` and `229-REVIEW.md` are retained as the gap source; the commands below exercise their remediated behavior.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Dependency-free Node.js `node:test` suites plus Bash integration self-test |
| **Config file** | none |
| **Test files** | `scripts/ci/preserve_repository_state.sh`, `scripts/ci/collect_repository_inventory.mjs`, `scripts/ci/verify_repository_inventory.mjs`, `scripts/ci/ci_monitor.cjs`, `scripts/ci/phase229_gap_closure.test.mjs` |
| **Quick run command** | `bash scripts/ci/preserve_repository_state.sh --self-test && node --test scripts/ci/phase229_gap_closure.test.mjs && node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md && node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-edge-cases --require-command-provenance --require-privacy-controls --require-determinism` |
| **Estimated runtime** | less than 10 seconds locally |

The real-capsule verification additionally requires the three private runtime variables below. Their values and locations must never be committed.

```bash
test -n "${PHASE229_PRIVATE_MANIFEST:-}" && \
test -n "${PHASE229_RECOVERY_BUNDLE:-}" && \
test -n "${PHASE229_MANIFEST_SHA256:-}" && \
node scripts/ci/verify_repository_inventory.mjs \
  --records .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.json \
  --rendered .planning/phases/229-repository-truth-recovery-safety/229-REPOSITORY-INVENTORY.md \
  --expected-repository szTheory/accrue \
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
| REPO-01 | Canonical schema-v2 JSON covers 218 refs, 109 recovery mappings, six typed artifacts, every current worktree, ten ship windows, and four bounded remote categories; Markdown is deterministic. | Inventory fixture suite, supplemental gap-closure tests, and real-capsule strict verification | green |
| REPO-02 | Capsule targets fail closed, publication is exclusive and atomic, original refs restore from real bundle heads without shell evaluation, strict verification proves exact set equality, and user artifacts remain typed/non-dereferenced. | Preservation self-test, strict verifier tests, rendered restore integration, and real-capsule strict verification | green |
| REPO-03 | One read-only monitor lists, inspects, and bounded-watches exact repository/SHA state; wrapper defaults to main/CI and all unsuccessful completions are non-zero. | Monitor self-test, executable wrapper subprocess tests, Node tests, and documentation verification | green |

## Per-Plan Verification Map

| Plan / task | Requirement | Test type | Automated command | Status |
|-------------|-------------|-----------|-------------------|--------|
| 229-01-01, 229-05-01, 229-05-02 | REPO-01, REPO-02 | integration | `bash -n scripts/ci/preserve_repository_state.sh && bash scripts/ci/preserve_repository_state.sh --self-test` | green |
| 229-01-02, 229-03-01, 229-03-02 | REPO-01, REPO-02 | integration | `node scripts/ci/verify_repository_inventory.mjs --fixtures --expected-repository szTheory/accrue --require-recovery --require-all-ref-recovery --require-typed-artifacts --require-complete-categories --require-edge-cases --require-command-provenance --require-privacy-controls --require-determinism` | green |
| 229-02-01, 229-02-02 | REPO-03 | integration | `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh && node --test scripts/ci/ci_monitor.cjs` | green |
| 229-04-01 | REPO-01, REPO-03 | smoke | `node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md` | green |
| 229-04-02, 229-09-01 | REPO-01, REPO-02, REPO-03 | integration | Real-capsule strict command above | green |
| 229-06-01 | REPO-01, REPO-03 | unit/integration | `node --test scripts/ci/collect_repository_inventory.mjs && node --test scripts/ci/phase229_gap_closure.test.mjs` | green |
| 229-06-02 | REPO-01, REPO-02 | integration | `node --test scripts/ci/phase229_gap_closure.test.mjs` | green |
| 229-07-01 | REPO-01, REPO-02 | integration | `node --test scripts/ci/verify_repository_inventory.mjs` | green |
| 229-07-02 | REPO-02 | integration | `node --test scripts/ci/verify_repository_inventory.mjs` | green |
| 229-08-01, 229-08-02 | REPO-03 | integration/smoke | `bash -n scripts/ci/watch_ci.sh && node scripts/ci/ci_monitor.cjs --self-test --verify-wrapper scripts/ci/watch_ci.sh --verify-docs scripts/ci/README.md && node --test scripts/ci/ci_monitor.cjs` | green |
| 229-09-02 | REPO-01, REPO-02, REPO-03 | regression | Quick run plus real-capsule strict command | green |

## Review Gap Closure Matrix

| ID | Required behavior | Executable evidence | Status |
|----|-------------------|---------------------|--------|
| CR-01 | Equal, aliased, same-inode, and touching output targets fail before publication/ref mutation. | `preserve_repository_state.sh --self-test` equal/alias/inode/nested probes | filled |
| CR-02 | A symlink-parent cannot place capsule output inside a worktree. | Preservation self-test physical-boundary rejection | filled |
| CR-03 | Public-record mode publishes a valid bundle/manifest/record triplet with matching digest/count. | Preservation self-test public-output success and injected post-manifest failure | filled |
| CR-04 | Metacharacter-bearing refs and stash restore through argv data without shell evaluation. | Preservation self-test fresh-repository restore fixture | filled |
| CR-05 | No-argument wrapper selects main/CI; exact SHA wins; non-success exits 69. | `ci_monitor.cjs` executable wrapper subprocess suite | filled |
| CR-06 | Four fixed GET-only observations retain zero/one/many values and six bounded unavailable reasons without substitution. | Collector embedded test plus `phase229_gap_closure.test.mjs` unavailable taxonomy | filled |
| CR-07 | Every real worktree is recorded without paths; empty/non-empty/malformed ship-window authorities are distinguished. | `phase229_gap_closure.test.mjs` real three-worktree integration and ledger tests | filled |
| CR-08 | Foreign recovery provenance fails before bundle, attestation, planning, worktree, or remote access. | `phase229_gap_closure.test.mjs` foreign-manifest ordering test with absent dependent files and zero adapter calls | filled |
| CR-09 | Strict recovery proves exact equality and rejects missing, extra, duplicate, wrong-object/encoded/head, foreign, null, and empty inputs. | `verify_repository_inventory.mjs` strict recovery and flag-specific tests | filled |
| CR-10 | The exact rendered commands verify the bundle and restore original ordinary/hostile heads in a fresh repository. | Rendered recovery procedure integration test | filled |
| WR-01 | `release..notes` is accepted; exact dot/dot-dot components are rejected. | Preservation self-test artifact-path probes | filled |
| WR-02 | Stash, public output, aliases, physical boundary, single-ref, and empty-ref modes are exercised. | Preservation self-test | filled |
| WR-03 | Scratch/unpublished outputs are removed on success and injected/empty failure. | Preservation self-test cleanup assertions | filled |

## Observed Final Evidence

- Preservation self-test: PASS.
- Collector tests: 2/2 PASS.
- Supplemental gap-closure tests: 4/4 PASS; importing the collector also executes its two embedded tests, for 6/6 total in that command.
- CI monitor tests: 2/2 PASS; executable wrapper and docs checks PASS.
- Strict inventory fixtures: PASS.
- Real canonical inventory against the unchanged anchored private manifest and bundle: PASS.
- Canonical evidence: schema v2, `live_remote`, 218 total refs, 109 recovery mappings, six typed artifacts, one current worktree matching `git worktree list`, ten ship windows matching `.planning/WINDOWS.md`; remote main observed, PRs/release branches observed empty, Actions explicitly unavailable with reason `network`.
- Original private manifest remained mode 0600, current-user owned, and SHA-256 matched its independent anchor. The original bundle digest also remained unchanged.

## Manual-Only Verifications

None. Live GitHub availability is not a completion prerequisite: an attempted bounded read may produce a typed unavailable fact, and automated checks prevent that state from masquerading as observed evidence or provider proof.

## Validation Sign-Off

- [x] Every Phase 229 plan task has an automated command.
- [x] REPO-01, REPO-02, and REPO-03 have executable behavioral coverage.
- [x] CR-01 through CR-10 and WR-01 through WR-03 are covered by tests that were run and passed.
- [x] Strict flags have independent negative controls.
- [x] Exact restore instructions execute against real fixture bundle heads.
- [x] No implementation file was modified during the final adversarial audit.
- [x] The supplemental test-only coverage was committed atomically.
- [x] No original recovery-capsule file or unrelated/untracked file was modified.

**Approval:** validated after gap closure on 2026-09-13
