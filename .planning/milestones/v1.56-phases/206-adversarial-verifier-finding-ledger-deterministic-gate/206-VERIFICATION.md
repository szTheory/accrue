---
phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
verified: 2026-07-04T21:45:03Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "The density-defender's actual voting bias against direction:air candidates lacking a task-completion justification is a live-Opus prompt-following behavior (VERIFY-02's live half)"
    addressed_in: "Phase 208"
    evidence: "Phase 206-02-PLAN.md's own must-have text states this truth 'is NOT provable by --self-test — it is a manual maintainer spot-check at Phase 208 convergence (Nyquist caveat, VERIFY-02; see 206-VALIDATION.md Manual-Only Verifications).' Phase 208's ROADMAP goal is 'Prove the ratchet converges the representative slice end-to-end' — the first point at which a live Opus panel run against real candidates occurs, making it the natural venue for this spot-check. Phase 206's own D-37 design principle requires zero live LLM calls to prove this phase's own success criteria, so this truth was never in Phase 206's own provable scope."
---

# Phase 206: Adversarial Verifier + Finding Ledger + Deterministic Gate Verification Report

**Phase Goal:** Candidates collapse, are adversarially confirmed (2-of-3 skeptic panel + mandatory
justification token), persist to a committed forward-only ledger, and are protected by a
deterministic sibling gate the LLM never touches (DEDUP-03, VERIFY-01..03, LEDGER-01..05)
**Verified:** 2026-07-04T21:45:03Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | DEDUP-03: Two candidate rows sharing `finding_id` collapse into one work item with correct `persona_frequency` | VERIFIED | `node accrue_admin/e2e/ratchet/ratchet-ledger.js` self-test group (c): "2 distinct work items", "persona_frequency === 3", "raised_by_lenses contains all 3 lenses" — exit 0 |
| 2 | `fold()` throws on out-of-order/duplicate `seq` (tamper-evidence prerequisite) | VERIFIED | self-test (b) "out-of-order seq throws" / "duplicate seq throws" |
| 3 | VERIFY-01: 3-role vote array `[real, minor, not-a-defect]` confirms at severity `minor`; `[not-a-defect, not-a-defect, real]` does not confirm | VERIFIED | `ratchet-verify.mjs --self-test` (ii-b)/(ii-c) both pass |
| 4 | VERIFY-01/D-13: `[real, real, minor]` against proposer severity `minor` clamps DOWN to `minor`, never upgrades | VERIFIED | self-test (ii-d) pass |
| 5 | VERIFY-03: a confirmed candidate whose `justification_token` is inadmissible is dropped before any ledger write | VERIFIED | self-test (iii) "inadmissible-token drop never creates a ledger file" |
| 6 | An unmatched LLM-returned `finding_id` is dropped before any ledger write | VERIFIED | self-test (iv) pass |
| 7 | VERIFY-02: operator-density-defender's deterministic aggregation math + prompt-level instruction present | VERIFIED | Prompt text present (`ratchet-verify.mjs:146-147`, the D-30 instruction); deterministic median-clamp half fully self-tested. The live-Opus prompt-following half is explicitly out of this phase's own provable scope (D-37) — see Deferred Items below, not a phase-206 gap |
| 8 | LEDGER-01: a confirmed finding is appended into `findings.ledger.ndjson` as `open` carrying `confirmed_by`/`panel_votes`/`justification_token`/`persona_frequency`/`raised_by_lenses` | VERIFIED | self-test (v) append-round-trip: "both rows are ratchet-finding-event/1 confirm/open", severity/clamp fields carried correctly |
| 9 | LEDGER-02/03: committed ledger/baseline/reopen-markers/regressions quadruple self-matches and is gate-green; count-increase/guard-missing/illegal-reopen each independently provable | VERIFIED | `finding-regressions.ndjson` is 0 bytes on disk; `phase-ratchet-ledger.mjs --self-test` fixtures (2)/(3)/(4) each fire exactly 1 regression of the right kind; idempotent re-run produces zero git diff |
| 10 | LEDGER-04: a hand-edited baseline disagreeing with the raw ledger fold causes `verify_ratchet_ledger.mjs` to fail | VERIFIED | self-test (2) "hand-edited baseline disagreement exits ok:false" |
| 11 | LEDGER-05: gate reducer + independent CI verifier both self-test all 3 regression kinds + a clean pass | VERIFIED | Both scripts' self-tests exit 0 covering count-increase/guard-missing/illegal-reopen/clean |

**Score:** 10/10 truths verified (VERIFY-02's live-Opus voting-bias half is a self-deferred item to
Phase 208, per the plan's own must-have text — see Deferred Items; it was never part of Phase 206's
own provable scope and is not counted against this phase's score)

### Deferred Items

Items not yet met but explicitly addressed in a later milestone phase (Step 9b).

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | VERIFY-02's live-Opus density-defender voting-bias behavior (does the model actually honor the `direction:"air"` voting instruction) | Phase 208 | 206-02-PLAN.md must-have: "...is NOT provable by --self-test — it is a manual maintainer spot-check at Phase 208 convergence (Nyquist caveat...)"; Phase 208's ROADMAP goal is the first point a live panel run against real candidates occurs |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `accrue_admin/e2e/ratchet/ratchet-ledger.js` | Lifecycle/append/fold/collapse CJS module | VERIFIED | Exports `LENS_KEYS`/`EVENT_TYPES`/`STATUS_VALUES`/`SUPPRESSED_REASONS`/`lensKeyFor`/`appendOpen`/`appendResolved`/`appendVerifiedClosed`/`appendSuppressed`/`appendReopened`/`fold`/`collapseByFindingId`. `node ratchet-ledger.js` exits 0, 34 `self-test pass:` lines |
| `accrue_admin/e2e/ratchet/ratchet-verify.mjs` | Opus 3-role panel + committed ledger writer | VERIFIED | 3-guard order confirmed (`--self-test` precedes `ANTHROPIC_API_KEY` check); `VERIFY_MODEL` default `claude-opus-4-8`; `--self-test` exits 0, 30 self-test-pass lines (13 from region-tags + 17 own) |
| `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` | Deterministic sibling gate | VERIFIED | `grep -c "@anthropic-ai/sdk"` = 0; `--self-test` exits 0, 9 pass lines across 5 fixtures |
| `scripts/ci/verify_ratchet_ledger.mjs` | Independent CI re-verifier | VERIFIED | Zero import of `phase-ratchet-ledger`/`ratchet-ledger.js` (grep = 0); zero `@anthropic-ai/sdk`; `region-tags` reused (deliberate exception); `--self-test` exits 0, 12 pass lines across 7 fixtures |
| `accrue_admin/e2e/ratchet/findings.ledger.ndjson` | Committed, initially 0 bytes | VERIFIED | 0 bytes on disk, unmodified by full test suite run |
| `accrue_admin/e2e/ratchet/ledger.baseline.json` | Committed, all-7-lens zero, `frozen:false`, `epoch:1` | VERIFIED | Confirmed via direct file read — matches spec exactly |
| `accrue_admin/e2e/ratchet/reopen-markers.ndjson` | Committed, 0 bytes | VERIFIED | 0 bytes |
| `accrue_admin/e2e/ratchet/finding-regressions.ndjson` | Committed, 0 bytes (gate-green) | VERIFIED | 0 bytes |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `ratchet-verify.mjs` | `ratchet-ledger.js` | `collapseByFindingId`/`appendOpen` import | WIRED | `import * as ratchetLedger from "./ratchet-ledger.js"` confirmed at top of file, both functions called in `confirmAndWrite` |
| `phase-ratchet-ledger.mjs` | `ratchet-ledger.js` | `fold`/`LENS_KEYS` import | WIRED | Static `import * as ratchetLedger` confirmed; `fold(` grep ≥1 |
| `verify_ratchet_ledger.mjs` | (deliberately NOT) `phase-ratchet-ledger.mjs`/`ratchet-ledger.js` | independence | WIRED (verified as absent) | `grep -c "phase-ratchet-ledger\|ratchet-ledger.js"` returns 0; `region-tags` reuse count ≥1 |
| `accrue_admin/package.json` | 4 ratchet scripts | `ratchet:verify`/`ratchet:verify:self-test`/`ratchet:ledger`/`ratchet:ledger:self-test` | WIRED | All 4 present, `npm run ratchet:ledger` and `ratchet:ledger:self-test` both exit 0 live |

### Anti-Patterns Found

No blocking anti-patterns. The code-review cycle (206-REVIEW.md, standard depth, 5 files) found and
the fix cycle (206-REVIEW-FIX.md) closed all 10 findings. Every fix below was independently
re-confirmed present in the current working tree during this verification pass (not just trusted from
REVIEW-FIX.md's prose):

| ID | Severity | Description | Fix Verified In Codebase |
|----|----------|--------------|---------------------------|
| CR-01 | Critical | Unsanitized `png_ref` → path traversal / exfiltration to Anthropic API | `resolveWithinResultsDir()` present at `ratchet-verify.mjs:373`, called at `:393`, self-test (vii) proves `../` and absolute-path rejection |
| CR-02 | Critical | `medianClamp` silently confirms with <3 votes, writes `severity:undefined` | `buckets.length !== 3` guard present at `ratchet-verify.mjs:91`; `minItems:3`/`maxItems:3` added to `PANEL_TOOL` schema (`:182-183`); self-test (ii-e)/(ii-f)/(ii-g)/(iv-b) all pass |
| WR-01 | Warning | No lifecycle transition-legality check | `LEGAL_TRANSITIONS` table present (`ratchet-ledger.js:100`), enforced at `:370`; self-test group (e) proves illegal transitions throw |
| WR-02 | Warning | No `appendReopened()` write path | `appendReopened` defined (`:454`) and exported (`:1089`); self-test (f) proves it |
| WR-03 | Warning | Hand-duplicated enum arrays with no cross-check | `verify_ratchet_ledger.mjs` self-test (7) confirms `GUARD_HOME_SPECS`/`LENS_KEYS` byte-identical across files |
| WR-04 | Warning | One malformed `raised_by` row aborts whole batch | try/catch added in `collapseByFindingId`; self-test (c2) proves isolation |
| WR-05 | Warning | Inconsistent CLI error handling | Both `phase-ratchet-ledger.mjs` and `ratchet-verify.mjs` wrapped in clean try/catch (verified functionally per REVIEW-FIX; not re-exercised live here since doing so requires deliberately corrupting the real committed ledger — the fix report documents this was done and reverted via `git checkout --` at fix time) |
| WR-06 | Warning | `assertDimension` never invoked | Called in `assertIdentity` (`ratchet-ledger.js`) and `buildValidatedCandidateMap` (`ratchet-verify.mjs`); self-test (c3)/(iv-a) prove rejection of dimension 13 |
| IN-01 | Info | No file-lock, single-writer invariant undocumented | Doc comment added above `nextSeq` (documentation-only fix, confirmed present) |
| IN-02 | Info | `duplicate-of:<id>` suffix never validated/existence-checked | `FINDING_ID_RE` validation + existence cross-check added; self-test (c4) proves both grammar rejection and dangling-reference rejection |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|--------------|------------|-------------|--------|----------|
| DEDUP-03 | 206-01 | Multi-lens collapse with `persona_frequency` | SATISFIED | `collapseByFindingId` + self-test group (c) |
| VERIFY-01 | 206-02 | 3-role panel, 2-of-3 confirm threshold | SATISFIED | `medianClamp` + self-test (ii-*) |
| VERIFY-02 | 206-02 | Density-defender anti-over-whitespacing guard | SATISFIED (deterministic half); live-Opus half explicitly self-deferred to Phase 208 | Prompt text present; documented Nyquist caveat, not a gap (see Deferred Items) |
| VERIFY-03 | 206-02 | Admissible-justification-token gate | SATISFIED | `isAdmissibleToken` re-gate + self-test (iii) |
| LEDGER-01 | 206-02 | Confirmed findings persist with explicit lifecycle | SATISFIED | `appendOpen` + self-test (v) |
| LEDGER-02 | 206-03 | Committed baseline: `confirmed_open` per lens + `resolved_locked` | SATISFIED | `ledger.baseline.json` committed, all-zero, `frozen:false` |
| LEDGER-03 | 206-03 | Deterministic gate: count-increase / guard-missing / illegal-reopen | SATISFIED | 3 self-test fixtures (2)/(3)/(4) |
| LEDGER-04 | 206-04 | Gate-green only when regressions 0 bytes; independent CI re-verify | SATISFIED | `verify_ratchet_ledger.mjs` self-test (2) hand-edited-baseline-disagreement |
| LEDGER-05 | 206-03/04 | Both reducer + CI verifier self-test all 3 regression kinds + clean pass | SATISFIED | Both scripts' self-tests cover all kinds |

No orphaned requirements — REQUIREMENTS.md maps exactly these 9 IDs to Phase 206 (line 107-115), and
all 9 appear across the 4 plans' `requirements:` frontmatter with no gaps.

## Behavioral Spot-Checks / Live Verification

All 4 self-test entry points were run live in this verification pass (not merely cited from the
SUMMARY files) and all exited 0:

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| ratchet-ledger self-test | `node accrue_admin/e2e/ratchet/ratchet-ledger.js` | 34 pass lines, exit 0 | PASS |
| ratchet-verify self-test | `node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test` | 30 pass lines, exit 0 | PASS |
| phase-ratchet-ledger self-test | `node accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs --self-test` | 9 pass lines, exit 0 | PASS |
| verify_ratchet_ledger self-test | `node scripts/ci/verify_ratchet_ledger.mjs --self-test` | 12 pass lines, exit 0 | PASS |
| Live committed-artifact chain | `cd accrue_admin && npm run ratchet:ledger` | `[phase-ratchet-ledger] regressions=0` / `[verify-ratchet-ledger] ok=true` | PASS |
| Idempotency | `git status --porcelain accrue_admin/e2e/ratchet/ scripts/ci/` after the above run | empty (no diff) | PASS |
| Sole-writer / no-runtime-leak invariant | `grep -rn "ratchet-ledger\|ratchet-verify\|phase-ratchet-ledger\|verify_ratchet_ledger" accrue_admin/lib/ accrue_admin/mix.exs` | no matches | PASS |
| SDK-off-the-gate-path invariant | `grep -c "@anthropic-ai/sdk"` on `ratchet-ledger.js`/`phase-ratchet-ledger.mjs`/`verify_ratchet_ledger.mjs` | all 0 | PASS |

## Human Verification Required

None. The only item that would otherwise route to human verification (VERIFY-02's live-Opus
voting-bias behavior) is a self-deferred item explicitly scoped by the plan's own must-have text to a
Phase-208 maintainer spot-check, not an open question in Phase 206's own deliverable — see Deferred
Items above.

## Gaps Summary

No gaps. All 9 requirement IDs (DEDUP-03, VERIFY-01/02/03, LEDGER-01..05) are satisfied in the
codebase, not merely claimed in SUMMARY.md. The 2 critical + 6 warning + 2 info findings from the
code-review cycle were independently confirmed present as full fixes (not just documented as fixed)
via direct source inspection and passing self-test assertions specific to each finding ID. The
committed ledger/baseline/reopen-markers/regressions quadruple is confirmed gate-green and idempotent
by a live re-run in this verification pass, not by trusting the SUMMARY's prior claim. One item
(VERIFY-02's live-Opus behavior) is filed as an explicitly-deferred item to Phase 208 per the plan's
own wording, not an unaccounted-for gap, and does not block phase completion — Phase 206's own D-37
design principle requires zero live LLM calls to prove this phase's own success criteria.

---

_Verified: 2026-07-04T21:45:03Z_
_Verifier: Claude (gsd-verifier)_
