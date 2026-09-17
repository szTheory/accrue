---
phase: 230-reviewable-history-integration
reviewed: 2026-09-15T00:00:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - .github/workflows/ci.yml
  - scripts/ci/README.md
  - scripts/ci/collect_integration_disposition.mjs
  - scripts/ci/collect_repository_inventory.mjs
  - scripts/ci/preserve_repository_state.sh
  - scripts/ci/render_integration_disposition.mjs
  - scripts/ci/verify_admin_ui_ratchet_ci_contract.sh
  - scripts/ci/verify_crosswake_host_commands.sh
  - scripts/ci/verify_integration_disposition.mjs
  - scripts/ci/verify_phase230_archive_invariants.mjs
  - scripts/ci/verify_repository_inventory.mjs
  - scripts/ci/verify_ui_ratchet_signoff.mjs
  - .tool-versions
  - accrue/test/accrue/config_test.exs
  - accrue_admin/mix.lock
  - accrue_portal/mix.lock
  - examples/accrue_host/mix.lock
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: passed_with_warnings
---

# Phase 230: Code Review Report (round 3 — final pass)

**Reviewed:** 2026-09-15
**Depth:** standard
**Files Reviewed:** 16 (17 paths listed; `examples/accrue_host/mix.lock` and its siblings counted individually)
**Status:** passed_with_warnings

## Summary

This is the third and final review pass. Round 1 found 2 Critical / 3 Warning / 1 Info. Round 2 (after commits `12dbb7d0`, `da5d3dbf`, `1235100e`, `a5a74034`) confirmed CR-01/WR-01/WR-02 fixed but found the CR-02 fix (`da5d3dbf`) had introduced a new Critical: the two exemption mechanisms it added (`computeYamlSoftUploadExemptLines`, `computeBashContentMatchExemptLines`) were broader than their own doc comments claimed — the YAML exemption never checked for `uses: actions/upload-artifact`, and the bash exemption never verified the loop variable was used exclusively in content-match calls.

Two further commits landed since round 2:

- `8f1ca293` tightened both predicates to match their doc comments and rewrote the comments to describe the tightened behavior.
- `1f48b5ad` fixed `extractYamlPathLines`, which previously only extracted a literal when the **trimmed line started with** `.planning/phases/` — a literal appearing mid-line (e.g. inside a quoted `grep` alternation in a `run:` step) was never extracted, never counted, never checked. It also moved the `literalCount += 1` increment to fire before exemption filtering (changing the reported metric from 17 to 43, a pure counting-semantics change with no effect on `failures`), and added a same-line `archive-sweep-exempt:` marker to the one real mid-line literal this surfaced, `.github/workflows/ci.yml:611`.

**Round 3 findings, verified live against the current source (not from the diff alone):**

1. **Round-2 Critical is closed.** `computeYamlSoftUploadExemptLines` (`verify_phase230_archive_invariants.mjs:254-287`) now walks to the literal's enclosing step via real `- <key>:` boundary scanning, and requires `uses:\s*actions/upload-artifact` to appear within that same step body (`YAML_UPLOAD_ARTIFACT_RE` check at line 281) in addition to `if-no-files-found: ignore` (line 282) — both conditions scoped to the same step, matching the doc comment at lines 240-250 exactly. `computeBashContentMatchExemptLines` (lines 203-238) now tracks `sawOtherUse` across every body line that references the loop variable and only exempts when `sawContentMatchUse && !sawOtherUse` (line 233), matching the doc comment at lines 187-198. I constructed both round-2 proof-of-concept inputs (a `run:` step performing a real `cat` of an archived literal followed by a coincidental `if-no-files-found: ignore`; a bash loop mixing `require_fixed "$needle"` with `cat "$needle"`) against the current source and both now correctly fail the sweep — this matches the orchestrator's own independent confirmation. Both scenarios are also now covered by permanent regression fixtures (Defect-1/Defect-2 regression + counter-regression pairs, `verify_phase230_archive_invariants.mjs:485-603`), so a future regression of either predicate would be caught automatically, unlike the round-2 gap which shipped with no fixture coverage.
2. **`extractYamlPathLines` rework (`1f48b5ad`) is sound.** `YAML_LITERAL_SCAN_RE` now scans the whole line (not just a trimmed-line-start anchor) and captures `before` context per occurrence for the (currently JS/bash-only) predicate-exemption plumbing, which is inert for YAML since the predicate check is gated on `!isYaml` (line 332) — so `before` is stored but not consulted for YAML occurrences, which is correct: the intent is only to preserve per-occurrence line numbers for the marker and soft-upload exemption checks, both of which key off `occurrence.line`, not `before`. `computeYamlSoftUploadExemptLines` itself still gates on `lines[i].trim().startsWith(".planning/phases/")` (line 258) — i.e., it only ever exempts genuine `path:` block-scalar lines, never a mid-line occurrence inside a `run:` script — which is the correct scope for a "soft-upload artifact path" exemption; a mid-line literal inside a shell script is categorically a different (potential-read) construct and must not inherit the upload-only exemption. Verified this is not merely asserted: constructed a mid-line literal for an archived, unrouted slug and confirmed it fails; confirmed the two round-3 regression fixtures (`Defect-3 regression` / `Defect-3 counter-regression`, lines 605-666) exercise exactly this pair.
3. **The `literalCount` reorder is a pure counting-semantics change.** The `literalCount += 1` statement (line 330) now executes unconditionally for every literal that passes the `PATH_LITERAL_RE` match, before any of the four `continue`-on-exempt checks (lines 332-335). None of those checks, nor the subsequent `failures.push(...)` calls (lines 347, 353), read or depend on `literalCount` — the two are entirely independent variables updated at different points in the same loop body, and moving the increment earlier changes only what `literalCount` reports, not which occurrences reach the `failures` array. Ran the sweep live: `verify_phase230_archive_invariants: PASS (scanned_files=97, literals=43)` — consistent with the stated 17→43 jump, all previously-passing occurrences (now counted, still exempt) remain in `failures.length === 0`.
4. **The `ci.yml:611` exemption marker is justified.** Read the annotated line in context (`.github/workflows/ci.yml:595-619`): the regex `grep -Eq '^(accrue/|accrue_admin/|...|\.planning/phases/190-navigation-data-display-meta-component-cohesion/)'` is matched against `/tmp/phase190-changed-files.txt`, which is populated by `git diff --name-only "$from_sha" "$GITHUB_SHA" > /tmp/phase190-changed-files.txt` two lines above — a changed-file-path listing, not a filesystem read of the literal itself. This is exactly the class of occurrence the `archive-sweep-exempt:` marker exists for (a literal used as pattern text against unrelated content, never dereferenced as a path), and the annotation states that reason inline. The stale phase-190 fragment inside that same regex (per `<known_intentional>`) is a genuine pre-existing staleness issue but is out of scope for Phase 230 and is not re-litigated here.

**WR-03 and IN-01 remain open, unchanged, by design** — re-verified against current source (see below); neither was touched by `8f1ca293` or `1f48b5ad`.

**Live verification run for this pass:**
- `node --test scripts/ci/verify_phase230_archive_invariants.mjs` → 2/2 pass (fixtures self-test + non-zero-scan test).
- `node scripts/ci/verify_phase230_archive_invariants.mjs` → `PASS (scanned_files=97, literals=43)`.
- `node --test` across the integration-disposition triad (`verify_integration_disposition.mjs`, `verify_repository_inventory.mjs`, `collect_integration_disposition.mjs`, `collect_repository_inventory.mjs`, `render_integration_disposition.mjs`) → 43/43 pass.
- `bash scripts/ci/verify_phase200_ci_contract.sh` → `verify_phase200_ci_contract: ok`.
- `bash scripts/ci/test_verify_crosswake_host_commands.sh` → all regression assertions pass (`Crosswake trusted-frame verification passed (reviewed_patch)`; `Crosswake host-command runner target rejection regression passed`).

No new Critical or Warning was found in this pass. Status is `passed_with_warnings` — the two open items are both pre-existing, deliberately-scoped-out Warnings/Info from round 1, not new defects.

## Fix Disposition Summary (all three rounds)

| ID | Original Severity | Disposition | Verified How |
|----|-------------------|--------------|---------------|
| CR-01 (round 1) | Critical | **Fixed** (round 2, unchanged since) | `--review-ref` content comparison now byte-identical-checks against the candidate ref's live tip; re-confirmed in round 2 with a fresh tampered branch of identical file count. Not re-litigated in round 3 per scope. |
| CR-02 (round 1) | Critical | **Fixed** (round 2 partial → fully closed round 3) | Per-file archive-routing safety proof (not corpus-wide) confirmed correct in round 2, with regression Fixture 5. The two new exemption mechanisms this fix introduced were themselves over-broad in round 2 (promoted to a new CR-01); both now tightened and fixture-covered as of `8f1ca293` — see finding 1 above. |
| WR-01 (round 1) | Warning | **Fixed** (round 2, unchanged since) | New CI step wired into `docs-contracts-shift-left`, no `continue-on-error`, runs the full triad + `--fixtures --require-hazard-universe`. Not re-litigated in round 3 per scope. |
| WR-02 (round 1) | Warning | **Fixed** (round 2, unchanged since) | Schema-only PASS message now names which `--require-*` flags ran; visually distinct from the full-flags PASS message. Not re-litigated in round 3 per scope. |
| CR-01 (round 2, new) | Critical | **Fixed** (round 3) | Both `computeYamlSoftUploadExemptLines` and `computeBashContentMatchExemptLines` tightened in `8f1ca293` to check exactly what their doc comments claim; both round-2 PoC inputs re-constructed against current source and now correctly fail; both now covered by permanent regression fixtures. See finding 1 above. |
| — (round 3, new) | — | **`extractYamlPathLines` line-start gap — fixed in `1f48b5ad`, reviewed clean** | Confirmed the rework extracts mid-line literals correctly, the soft-upload exemption still scopes correctly to bare `path:` lines only, `literalCount` reorder is counting-semantics-only, and the one real surfaced occurrence (`ci.yml:611`) is a legitimate exemption. See findings 2-4 above. No new defect found. |
| WR-03 | Warning | **Open (unchanged, as intended)** | Re-read `render_integration_disposition.mjs:162` (`renderExcludedLedger`) — `const sharedEvidence = value.rows[0]?.supersession_evidence ?? null;` still renders only the first row's `supersession_evidence`; `validateDispositionLedger` still has no deep-equality assertion across rows. |
| IN-01 | Info | **Open (unchanged, as intended)** | Re-read `verify_crosswake_host_commands.sh:14-29` — the 0-or->1-candidate ambiguity case still falls through to the generic `"source lock and audit are required"` message with no mention of archive-resolution ambiguity. |

## Warnings

### WR-03: The excluded-commit-ledger renderer's "shared evidence" assumption is not enforced by the schema (unchanged, still open)

**File:** `scripts/ci/render_integration_disposition.mjs:162` (`renderExcludedLedger`)
**Issue:** `const sharedEvidence = value.rows[0]?.supersession_evidence ?? null;` still renders only the first row's `supersession_evidence` as representative of every row's "Shared supersession evidence" section. `validateExcludedRow`/`validateDispositionLedger` still assert no deep-equality across rows. Holds today only because `collectExcludedCommitLedger` happens to assign the same object reference to every row — not because the schema requires it.
**Fix:** Add a schema-level assertion in `validateDispositionLedger` that every row's `supersession_evidence` is deep-equal, or hoist the field to the ledger level so the invariant is structural.

## Info

### IN-01: `verify_crosswake_host_commands.sh`'s archive fallback degrades silently to a generic error on ambiguity (unchanged, still open)

**File:** `scripts/ci/verify_crosswake_host_commands.sh:14-29`
**Issue:** When zero or more than one archived candidate directory matches `.planning/milestones/*-phases/224-crosswake-host-command-bridge-seam`, `phase224_dir` still falls back to the generic `"source lock and audit are required"` failure, with no message naming the ambiguity/miss as the real cause.
**Fix:** When the fallback search yields 0 or >1 candidates, name the ambiguity explicitly (e.g. "224-crosswake-host-command-bridge-seam resolves to N archived candidates, expected exactly 1") before falling through to the generic check.

---

_Reviewed: 2026-09-15_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
