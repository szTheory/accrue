---
phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
plan: 01
subsystem: testing
tags: [nodejs, cjs, ndjson, event-sourcing, ratchet, admin-ui-eval]

# Dependency graph
requires:
  - phase: 205-persona-design-lens-evaluator-harness
    provides: "region-tags.js identity SSOT (claimKey/findingId/isAdmissibleToken/normalizeOverlays), the ratchet-candidate/1 row schema (ratchet-propose.mjs), and the 6-persona LENS_KEYS/PERSONAS vocabulary this plan mirrors"
provides:
  - "ratchet-ledger.js: LENS_KEYS/EVENT_TYPES/STATUS_VALUES/SUPPRESSED_REASONS closed enums + lensKeyFor()"
  - "appendOpen/appendResolved/appendVerifiedClosed/appendSuppressed — append-only NDJSON writers, each taking an explicit ledgerPath, re-validating claim_key/finding_id via region-tags.js before writing"
  - "fold(rows) — latest-event-wins reducer with seq-monotonic tamper-evidence assertion"
  - "collapseByFindingId(candidateRows) — DEDUP-03 multi-lens collapse (persona_frequency + raised_by_lenses)"
  - "runSelfTest()/assertSelfTest() proving all of the above with zero network calls"
affects: [206-02-ratchet-verify, 206-03-phase-ratchet-ledger, 206-04-verify-ratchet-ledger-ci, 207-orchestration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CJS module.exports + `if (require.main === module) { runSelfTest(); }` standalone runner (twin of region-tags.js), importable from ESM consumers via cjs-module-lexer interop"
    - "Append-only NDJSON event log with a single global monotonic seq counter (not per-finding_id) and fold()-time strict-increase assertion as tamper-evidence"
    - "Every append helper takes an explicit ledgerPath parameter (never hardcodes the committed file) so --self-test always targets an fs.mkdtempSync scratch directory"

key-files:
  created:
    - accrue_admin/e2e/ratchet/ratchet-ledger.js
  modified: []

key-decisions:
  - "appendResolved/appendVerifiedClosed/appendSuppressed take only finding_id (not a full row) — they look up the finding's latest existing row in the ledger itself (last-match-wins scan, in file order) to re-validate identity and carry every D-17 field forward; only appendOpen takes the full candidate/work-item row, since it's the first row for that finding_id"
  - "appendOpen additionally rejects a non-admissible justification_token via isAdmissibleToken before writing (Rule 2: the plan's required isAdmissibleToken import had no explicit call site spelled out in the action text, so this closes that gap defensively on the one write path that introduces a brand-new finding)"
  - "isValidSuppressedReason() treats bare 'duplicate-of' as invalid (must carry a ':<finding_id>' suffix per D-41); the other 5 SUPPRESSED_REASONS values must match exactly"
  - "fold()'s seq-monotonic assertion is a single GLOBAL counter across the whole ledger array (not per finding_id) — matches nextSeq()'s 'max existing seq + 1 across the whole file' semantics used by every append helper"

requirements-completed: [DEDUP-03]

coverage:
  - id: D1
    description: "Two synthetic candidate rows sharing the same finding_id collapse into one work item whose persona_frequency equals the count of distinct raised_by lenses (DEDUP-03)"
    requirement: "DEDUP-03"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-ledger.js — self-test (c) collapse-persona-frequency group (4 assertions)"
        status: pass
    human_judgment: false
  - id: D2
    description: "An out-of-order/duplicate seq row causes fold() to throw rather than silently accept it — the structural prerequisite for Wave-2's tamper-evidence"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-ledger.js — self-test (b) fold-seq-monotonic group (2 assertions)"
        status: pass
    human_judgment: false
  - id: D3
    description: "appendOpen/appendResolved/appendVerifiedClosed round-trip through a real fs.mkdtempSync ledger file, and fold() correctly reports the terminal status"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-ledger.js — self-test (d) append-round-trip group (3 assertions)"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-07-04
status: complete
---

# Phase 206 Plan 01: Ratchet Ledger Append/Fold Helper Summary

**Built `ratchet-ledger.js` — the CJS append-only NDJSON lifecycle event log + latest-event-wins fold reducer that both Wave-2 files (`ratchet-verify.mjs`, `phase-ratchet-ledger.mjs`) import instead of reimplementing.**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-07-04T20:36:36Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- `accrue_admin/e2e/ratchet/ratchet-ledger.js` created: CJS, SDK-free, zero network calls, importable from ESM consumers via cjs-module-lexer interop (twins `region-tags.js`'s module shape exactly).
- Closed-enum constants (`LENS_KEYS` 7-value PER-LENS gate key, `EVENT_TYPES`, `STATUS_VALUES`, `SUPPRESSED_REASONS`) plus `lensKeyFor()` mapping a candidate's `raised_by` to its lens key.
- Four append-only writers (`appendOpen`/`appendResolved`/`appendVerifiedClosed`/`appendSuppressed`), each taking an explicit `ledgerPath`, re-validating `claim_key`/`finding_id` via `region-tags.js` before writing a single NDJSON line — never rewriting or truncating existing lines.
- `fold(rows)`: latest-event-wins reducer over parsed `ratchet-finding-event/1` rows, throwing on any non-strictly-increasing `seq` (the tamper-evidence invariant Wave-2's reducer and the independent CI verifier both depend on).
- `collapseByFindingId(candidateRows)`: groups Phase-205 `ratchet-candidate/1` rows by `finding_id`, computing `raised_by_lenses`/`persona_frequency` from the group and carrying every other field from the first-encountered representative row (proves DEDUP-03).
- `runSelfTest()`/`assertSelfTest()` covering fold-lifecycle, fold-seq-monotonic, collapse-persona-frequency, and a real append-round-trip fixture (via `fs.mkdtempSync`, wrapped in `try/finally` so cleanup never skips) — 11 `self-test pass:` lines, exit 0, zero network calls.

## Task Commits

Each task was committed atomically:

1. **Task 1: Lifecycle schema constants + append helpers** - `be68d253` (feat)
2. **Task 2: fold() reducer + DEDUP-03 collapse + self-test** - `4d066bf7` (feat)

**Plan metadata:** committed separately (see below)

## Files Created/Modified
- `accrue_admin/e2e/ratchet/ratchet-ledger.js` - CJS append/fold helper: closed enums, `lensKeyFor`, `appendOpen`/`appendResolved`/`appendVerifiedClosed`/`appendSuppressed`, `fold`, `collapseByFindingId`, `assertSelfTest`/`runSelfTest`, standalone runner

## Decisions Made
- `appendResolved`/`appendVerifiedClosed`/`appendSuppressed` accept only `finding_id` (per the plan's signature spec); they locate the finding's latest existing row in the ledger itself (a simple last-match-in-file-order scan, not the asserted `fold()`) to re-validate identity and carry every D-17 identity/carry field forward onto the new lifecycle row. `appendOpen` is the only helper that takes a full candidate/work-item row, since it is the first row ever written for that `finding_id`.
- Added a defensive `isAdmissibleToken(justification_token)` check inside `appendOpen` (Rule 2 — missing critical validation): the plan explicitly required importing `isAdmissibleToken` from `region-tags.js` but the action text didn't spell out a call site; rejecting an inadmissible token on the one write path that introduces a brand-new finding is the natural enforcement point and matches the D-16 gate's intent.
- `isValidSuppressedReason()` treats the bare literal `"duplicate-of"` as invalid — per D-41 it must always carry a `:<finding_id>` suffix; the other 5 `SUPPRESSED_REASONS` values must match exactly.
- `fold()`'s seq-monotonic assertion checks a single **global** running maximum across the whole array (not per `finding_id`), matching `nextSeq()`'s "max existing `seq` + 1 across the whole file" semantics used by every append helper.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Doc-comment literal string tripped the plan's own `@anthropic-ai/sdk` absence check**
- **Found during:** Task 2 (running the plan's `<verification>` block after both tasks landed)
- **Issue:** The file's own header comment stated `no network calls, no `@anthropic-ai/sdk`` as documentation — but `grep -c "@anthropic-ai/sdk" ratchet-ledger.js` (the plan's verification command, meant to prove no SDK *import*) matched that comment text and returned `1` instead of the required `0`.
- **Fix:** Reworded the comment to "no Anthropic SDK import" (same meaning, no literal substring collision).
- **Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`
- **Verification:** `grep -c "@anthropic-ai/sdk" accrue_admin/e2e/ratchet/ratchet-ledger.js` now returns `0`; `node accrue_admin/e2e/ratchet/ratchet-ledger.js` and `node -e "require(...)"` both still exit 0.
- **Committed in:** `4d066bf7` (Task 2 commit — fixed before commit, no separate commit needed)

**2. [Plan-authoring note, non-blocking] Task 1's own `<verify>` block references `m.fold`, a Task 2 symbol**
- **Found during:** Task 1 (running Task 1's `<verify><automated>` command immediately after Task 1's commit)
- **Issue:** Task 1's `<verify>` command checks `typeof m.fold==='function'`, but `fold` is defined in Task 2, not Task 1. Task 1's own `<acceptance_criteria>` and `<done>` blocks do NOT mention `fold` — only the supplementary `<verify>` command does.
- **Resolution:** Validated Task 1 against its own `<acceptance_criteria>`/`<done>` text (which passed cleanly, no `fold` reference) and proceeded to Task 2 immediately per the plan's own two-task structure for a single file. Re-ran Task 1's `<verify>` command after Task 2 landed — it now passes (exit 0), confirming the plan's intent (the check was written for the whole-module state, incidentally placed on Task 1). No code change was needed; this is purely a plan-authoring artifact, noted for traceability.

---

**Total deviations:** 2 (1 auto-fixed bug in doc comment wording, 1 non-blocking plan-authoring note — no code impact)
**Impact on plan:** Both are cosmetic/documentation-adjacent. No scope creep; the module's actual lifecycle/fold/collapse logic matches the plan exactly.

## Issues Encountered
None beyond the two items documented above.

## User Setup Required
None - no external service configuration required. This module is dev/test-only tooling under `accrue_admin/e2e/ratchet/`, never referenced from `accrue_admin`'s `lib/` runtime or `mix.exs` application deps.

## Next Phase Readiness
- `ratchet-ledger.js` exports the full lifecycle/append/fold/collapse surface that Wave 2 depends on: `206-02-PLAN.md`'s `ratchet-verify.mjs` can import `collapseByFindingId`/`appendOpen`, and `206-03-PLAN.md`'s `phase-ratchet-ledger.mjs` can import `fold`/`LENS_KEYS` directly, with zero reimplementation.
- No blockers. The module is fully self-testable (`node accrue_admin/e2e/ratchet/ratchet-ledger.js` exits 0, 11 `self-test pass:` lines, no lingering `ratchet-ledger-*` temp dirs after repeated runs).

## Self-Check: PASSED

- FOUND: accrue_admin/e2e/ratchet/ratchet-ledger.js
- FOUND: be68d253 (Task 1 commit)
- FOUND: 4d066bf7 (Task 2 commit)

---
*Phase: 206-adversarial-verifier-finding-ledger-deterministic-gate*
*Completed: 2026-07-04*
