---
phase: 229-repository-truth-recovery-safety
reviewed: 2026-09-13T16:29:34Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - scripts/ci/README.md
  - scripts/ci/ci_monitor.cjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/phase229_gap_closure.test.mjs
  - scripts/ci/preserve_repository_state.sh
  - scripts/ci/render_repository_inventory.mjs
  - scripts/ci/verify_repository_inventory.mjs
  - scripts/ci/watch_ci.sh
findings:
  critical: 9
  warning: 3
  info: 0
  total: 12
status: issues_found
---

# Phase 229: Code Review Report

**Reviewed:** 2026-09-13T16:29:34Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

The gap-closure work fixes the original output-alias, physical-boundary, public-record, shell-restore, watcher-default, foreign-manifest, and rendered-restore failures. All advertised fixture commands are green. Adversarial probes still reproduced nine blocking gaps: artifact mutation can occur after the only snapshot while preservation reports success; valid symlink text can be hashed incorrectly; remote collection silently truncates paginated categories; and the strict verifier accepts fabricated or incomplete ref, planning, provenance, and privacy evidence. The CI watch timeout also does not impose an absolute deadline.

Of the prior report, CR-01 through CR-05, CR-07, CR-08, CR-10, and WR-01 through WR-03 are behaviorally closed. CR-06 is only partially closed because live reads are wired but not paginated, and CR-09 is only partially closed because private-manifest/bundle equality is now proven while several canonical inventory claims remain trusted rather than independently reconciled.

## Narrative Findings (AI reviewer)

The complete advertised regression chain passed. Separate probes then demonstrated: a concurrent artifact rewrite after manifest publication returns exit 0 with a stale digest; a symlink target ending in a newline receives the wrong SHA-256; removing every preservation ref row from `refs.all` still passes all strict flags; replacing the ten ship windows with an empty array still passes; replacing the active branch object with a nonexistent all-`f` SHA still passes; a same-repository `GET .../issues` request passes command-provenance verification; `/var/private/phase229-capsule.json` passes privacy verification and is rendered; the README's documented strict command exits 1 for missing private inputs; and a one-second watch completed successfully after 2.658 seconds because its two GitHub reads were outside the deadline.

## Critical Issues

### CR-01: Preservation never verifies the artifact snapshot again before success

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:144-171`

**Issue:** The script hashes untracked artifacts once, writes that snapshot into the manifest, publishes the outputs, and then rechecks only the bundle. It never takes the required post-snapshot. A probe waited for the published manifest, rewrote an untracked regular file, and observed exit 0 plus `preserve repository state: PASS`; the manifest retained the old digest. This makes the claimed pre/post invariant false and allows observation to proceed from stale user-artifact evidence.

**Fix:** Re-enumerate every untracked entry NUL-safely immediately before setting `published=true`, recompute type and digest/link-text digest, and compare the complete path/type/digest map plus empty-directory policy with the frozen snapshot. On any mismatch, fail while cleanup still owns the newly published outputs. Add a deterministic mutation hook fixture after the first snapshot.

### CR-02: Trailing newlines in valid symlink targets produce false recovery evidence

**Classification:** BLOCKER

**File:** `scripts/ci/preserve_repository_state.sh:147`

**Issue:** `artifact_hash="$(printf '%s' "$(readlink "$full")" | ...)"` uses command substitution around `readlink`, which strips every trailing newline from the link text. A valid link targeting `target\n` produced recorded SHA-256 `34a040...` while hashing `fs.readlinkSync` returned `c97ecf...`. Later exact artifact validation therefore rejects an unchanged repository, and the private recovery evidence is not the promised link-text digest.

**Fix:** Hash the link text without shell command substitution, for example with a small Node helper using `fs.readlinkSync(path)` and `crypto.createHash("sha256")`, passing the path as one argv element. Add fixtures for empty-looking, embedded-newline, and trailing-newline link text.

### CR-03: “All” PR and release-branch observations silently stop at the first API page

**Classification:** BLOCKER

**File:** `scripts/ci/collect_repository_inventory.mjs:194-247`

**Issue:** Each remote category performs exactly one `gh api` call. Pull requests request only `per_page=100`; matching release refs do not even request a page size and therefore use the API default. There is no page loop, Link-header inspection, or overflow probe. A full first page is accepted as complete `available:true` evidence even when later pages exist, contradicting the promised all-open-PR and all-release-branch inventory and the phase's bounded-pagination threat mitigation.

**Fix:** Implement a bounded page loop for plural endpoints, request an explicit page size and page number, stop only on an authoritative terminal page, and return `unavailable:overflow` if another page exists beyond the configured page/item cap. Preserve every producing request in provenance and add first-page-full/second-page and cap-exceeded fixtures.

### CR-04: Strict recovery accepts a fabricated active-branch object

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:60-70,138-143`

**Issue:** The active-branch exception checks only that the canonical `refs.all` row equals the inventory's `milestone_branch` value. It never resolves the live symbolic ref or even proves that the replacement object exists. Replacing both values with a nonexistent 40-character all-`f` SHA passed the full real-capsule command with `--require-recovery --require-all-ref-recovery --require-complete-categories`. This permits fabricated point-in-time branch truth under the exception added by Plan 229-09.

**Fix:** Resolve `${activeRef}^{object}` from `repositoryRoot` and require it to equal both the canonical row and `refs.milestone_branch`; also prove the object exists with `git cat-file -e`. Keep the frozen object independently recoverable through the manifest, bundle, and encoded ref.

### CR-05: All-ref verification ignores preservation rows in the committed all-ref inventory

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:127-143`

**Issue:** Strict verification reconciles live encoded refs separately, then filters every preservation row out of `checked.refs.all`. Removing all 109 `refs/accrue-preserve/phase-229/*` rows from the canonical inventory and freshly rendering it still passed every strict flag. The verifier therefore certifies an inventory that does not contain all local refs even though REPO-01 and the final summary claim all 218 rows.

**Fix:** Split canonical `refs.all` into preservation and non-preservation maps. Compare its preservation map exactly with the independently resolved `encodedMap`, including missing, extra, duplicate, and changed rows, before applying the narrowly defined active-branch continuity rule to the non-preservation map.

### CR-06: Complete-category verification accepts an empty ship-window snapshot

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:173-179`

**Issue:** `assertCompleteCategories` checks only that `ship_windows` is an array and `worktrees` is non-empty. Replacing all ten committed windows with `[]` passed the full strict verifier. The same design cannot detect a missing secondary worktree or invented worktree row. This reintroduces the core completeness failure from the prior verification report at the independent-verifier boundary.

**Fix:** Reconcile ship-window IDs/states against the bounded `.planning/WINDOWS.md` authority and reconcile worktree branch/detached/SHA/dirty rows against `git worktree list --porcelain` plus per-worktree status. If point-in-time verification must survive later drift, require independently anchored snapshot inputs rather than treating non-empty arrays as proof.

### CR-07: Provenance verification accepts arbitrary same-repository API requests

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:148-153`

**Issue:** The command-provenance gate requires only a `GET /repos/szTheory/accrue/` prefix. Changing `remote_main.request` to `GET /repos/szTheory/accrue/issues` passed `--require-command-provenance` and the full strict chain. A request that cannot produce the claimed ref SHA is therefore accepted as its provenance.

**Fix:** Define the exact allowed request contract per category and require exact normalized matches: main ref, open PRs with bounded pagination, matching `release/*` refs, and bounded Actions runs. For paginated categories, validate the complete ordered request sequence and bounds.

### CR-08: Privacy verification misses most absolute filesystem paths

**Classification:** BLOCKER

**File:** `scripts/ci/verify_repository_inventory.mjs:192-203`

**Issue:** The privacy scan recognizes only `/Users/`, `/home/`, `/tmp/`, and drive-letter prefixes. Setting a rendered planning field to `/var/private/phase229-capsule.json` passed `--require-privacy-controls`; `/root`, `/opt`, `/private/tmp`, UNC paths, and URI-form file locations have the same gap. This contradicts the no-absolute-path/no-external-capsule-location security contract.

**Fix:** Apply field-specific schemas and reject every absolute/path-like value with `path.isAbsolute`, Windows/UNC checks, and `file:` URI checks wherever paths are forbidden. Reject all control characters, not only NUL, and add negative fixtures for `/var`, `/root`, `/private`, UNC, and file-URI forms.

### CR-09: The requested watch timeout is not an absolute deadline

**Classification:** BLOCKER

**File:** `scripts/ci/ci_monitor.cjs:104-109,147-154`

**Issue:** Timeout is checked only after a complete list-plus-view polling cycle, while each GitHub subprocess independently permits 30 seconds. A controlled adapter that took 1.2 seconds for each read returned completed success after 2.658 seconds under `--timeout-seconds 1`, with exit 0. A stalled cycle can exceed the caller's advertised deadline by roughly 60 seconds, and sleep can overshoot it further.

**Fix:** Compute one monotonic absolute deadline, check it before and after every remote read, pass the remaining budget into each subprocess timeout, and cap each sleep to the remaining duration. Add a real subprocess-delay fixture that asserts wall-clock timeout behavior, not only an injected logical clock.

## Warnings

### WR-01: The documented strict verification command cannot run

**Classification:** WARNING

**File:** `scripts/ci/README.md:35-42`

**Issue:** The README says this command verifies recovery, then supplies `--require-recovery --require-all-ref-recovery` without `--recovery-manifest`, `--expected-manifest-sha256`, or `--recovery-bundle`. Executing it exits 1 with `--recovery-manifest requires a non-empty private manifest path`. The docs checker validates only keywords and does not execute the command.

**Fix:** Show the required runtime-only variables and all three private-input flags in the verification command, using the same variable names as the collection and validation documentation. Add a docs subprocess fixture against a generated private capsule.

### WR-02: Run inspection does not bind the viewed result to the selected run

**Classification:** WARNING

**File:** `scripts/ci/ci_monitor.cjs:126-134`

**Issue:** After selecting one run ID, `inspectSha` verifies only that the viewed response retains the requested SHA. A response with a different run ID or workflow but the same SHA is accepted, so jobs and conclusions can be attributed to the wrong run despite the preceding uniqueness check.

**Fix:** Require `run.run_id === matching[0].run_id` and, when workflow selection is present, require the viewed workflow to match as well. Add mismatched-ID and mismatched-workflow response fixtures.

### WR-03: Gap-closure tests omit the remaining adversarial boundaries

**Classification:** WARNING

**File:** `scripts/ci/phase229_gap_closure.test.mjs:30-139`

**Issue:** The supplemental suite covers unavailable-reason mapping, multi-worktree collection, window count parsing, and foreign-manifest ordering, but not page truncation, post-snapshot artifact mutation, raw symlink text, active-branch fabrication, missing canonical preservation rows, category-authority equality, endpoint provenance, privacy path variants, or real deadline enforcement. The embedded suites likewise use one-page API fixtures and self-consistent inventories, allowing all nine blockers above to remain green.

**Fix:** Add the exact reproduced probes as regression tests, with each test first asserting the current failure and then pinning the corrected behavior. Exercise CLI/process boundaries where timing, documentation, and publication semantics matter.

---

_Reviewed: 2026-09-13T16:29:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
