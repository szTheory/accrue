---
phase: 232-bounded-hygiene-release-handoff
plan: 04
subsystem: infra
tags: [node, ci, window-dispositions, total-map, cartesian-product-test, node-test]

requires:
  - phase: 232-02
    provides: "the shared isMainModule guard convention every scripts/ci/*.mjs entrypoint uses"
  - phase: 232-03
    provides: "scripts/ci/verify_ci_script_contract.mjs -- the meta-verifier this plan's edits stay compliant with"
provides:
  - "A total (disposition, state) pair map (BUCKET_OF_PAIR) in render_window_dispositions.mjs that fails closed on an unmapped pair, replacing the prior fall-through if-chain whose unreachability was recorded only in a comment"
  - "ROW_STATES exported from collect_window_dispositions.mjs so the renderer and its tests enumerate the same closed state set the collector validates against"
  - "A derived-legality cartesian-product reachability test in verify_window_dispositions.mjs asserting, in both directions, that every legal pair renders under exactly one declared bucket and no declared bucket is unreachable"
  - "D-15's four outcome-named bucket headings (never a bare status word), always rendered even at zero rows"
  - "A rendered Evidence command column and two new header sentences: the file is a deterministic projection of the JSON evidence of record, and the row-join/evidence-freshness strict checks apply only to the current phase's own record (D-18)"
  - "A presentation-only re-render of 231-WINDOW-DISPOSITIONS.md under the new renderer, with zero bytes changed in 231-WINDOW-DISPOSITIONS.json"
affects: [232-05, 232-06, 232-07, 232-08, 232-09, 232-10, 232-11]

actuals:
  tokens: 14326
  tasks: 3
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Total (disposition, state) pair map keyed by a NUL-separated pairKey(), fail() on an unmapped pair -- generalizable to any future closed-tuple bucketing (D-13)"
    - "Cartesian-product reachability test: derive legality by calling the schema validator itself over the full disposition x state product, never a hand-listed table, so the test cannot drift from the schema (D-14)"
    - "Byte-level python replacement instead of the Edit tool when a JSON-string parameter's \\uXXXX escape would decode to the literal Unicode codepoint rather than the six-character source text -- discovered this plan, documented as a gotcha below"

key-files:
  created: []
  modified:
    - scripts/ci/collect_window_dispositions.mjs
    - scripts/ci/render_window_dispositions.mjs
    - scripts/ci/verify_window_dispositions.mjs
    - .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md

key-decisions:
  - "The four D-15 bucket headings are exactly: \"Waived — the gate ran and failed\", \"Waived — the gate never proved anything\", \"Waived — the gate passed anyway\", \"Fixed — proved at the candidate SHA\" -- none a bare status word, matching the maintainer decision recorded in 232-CONTEXT.md D-15."
  - "evidence_command (present in the JSON, rendered nowhere before this plan) is rendered as a shell-readable, space-joined argv string in a new 'Evidence command' table column, not as a separate block -- keeps the row-per-line table shape every other window-disposition column already uses."
  - "bucketOf()'s fail-closed branch on an unmapped pair is unreachable through the public renderWindowDispositions() entrypoint today (CR-01's validateWindowRow already restricts the legal pair space to exactly the six pairs the map declares) -- it is defensive fail-safety against a caller that renders an unvalidated record directly, and is exercised directly by calling bucketOf() in this plan's own test, not through renderWindowDispositions()."
  - "The D-14 cartesian-product test's probeRow() helper minimally satisfies validateWindowRow's own conditional requirements (exit_code when state is \"proved\", owner/rationale/release_impact when disposition is \"waived\") so that pair LEGALITY is decided purely by calling the validator, never a hand-listed legal-pair table -- this is the test's entire point per D-14."
  - "[Rule 1] Both collect_window_dispositions.mjs and render_window_dispositions.mjs previously called isMainModule(import.meta.url) unguarded at their entrypoint-detection site, crashing (not silently returning false) on a bare import() from an ambiguous entrypoint -- exactly the shape of Task 1's own --input-type=module verify command for ROW_STATES. Wrapped both in the same try/catch pattern already established in verify_window_dispositions.mjs."
  - "[Gotcha, documented for future plans] Writing a literal \\u0000 (six ASCII characters) into an Edit tool's old_string/new_string JSON parameter decodes to the actual U+0000 codepoint, not the six-character source text -- an Edit call intending to insert the SOURCE TEXT \"\\u0000\" into a file will instead insert a real NUL byte, silently turning the file into a git-perceived binary file (a 'Bin X -> Y bytes' diff instead of a text diff). Caught via the Task-1 commit's diffstat; fixed with a targeted python byte-level replacement rather than retrying the Edit tool. Confirmed zero null bytes in the final committed blob."

patterns-established:
  - "Total pair map + fail() over an if-chain: any future disposition x state (or similarly closed-tuple) bucketing in this repo should copy BUCKET_OF_PAIR's shape, not bucketOf's old fall-through predicate chain."
  - "Cartesian-product reachability test: any future closed-vocabulary bucketing gains an anti-dead-code test in both directions by deriving legality from the schema validator over the full product space, asserting the derived set non-empty, then deepEqual-ing reached vs declared bucket sets."

requirements-completed: []

coverage:
  - id: D1
    description: "The bucketing if-chain in render_window_dispositions.mjs is replaced by a total (disposition, state) pair map (BUCKET_OF_PAIR) that fails closed by row id and both values on an unmapped pair; ROW_STATES is exported from the collector unchanged in membership"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/collect_window_dispositions.mjs scripts/ci/render_window_dispositions.mjs (43 tests, 0 fail)"
        status: pass
      - kind: integration
        ref: "node --input-type=module -e \"import('./scripts/ci/collect_window_dispositions.mjs').then(m => process.exit(m.ROW_STATES ? 0 : 1))\" -> exit 0"
        status: pass
      - kind: integration
        ref: "grep -v '^\\s*//' scripts/ci/render_window_dispositions.mjs | grep -cE 'return \"(waived|failed|not_run|fixed)\"' -> 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Four D-15 outcome-named bucket headings are declared and always render, including at zero rows; the header carries the deterministic-projection sentence, a rendered evidence_command per row, and the D-18 historical-record note; 'parked' never appears as a schema value"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "render_window_dispositions.mjs in-file tests: 'renders every D-15 bucket heading even when the record has zero rows', 'header states the file is a deterministic projection...renders evidence_command', 'header states the row-join strict check applies only to the current phase's own record' -- all pass"
        status: pass
      - kind: other
        ref: "grep -n parked scripts/ci/collect_window_dispositions.mjs scripts/ci/render_window_dispositions.mjs scripts/ci/verify_window_dispositions.mjs -> no matches"
        status: pass
    human_judgment: false
  - id: D3
    description: "A cartesian-product reachability test in verify_window_dispositions.mjs derives legality by calling validateWindowRow, asserts the derived set is non-empty, and asserts every legal pair maps to exactly one declared bucket with no declared bucket unreachable -- proved in both directions by two executed-and-reverted negative controls"
    requirement: HYG-02
    verification:
      - kind: unit
        ref: "node --test --test-reporter=tap scripts/ci/verify_window_dispositions.mjs (7 tests, 0 fail), including 'every legal (disposition, state) pair renders under exactly one declared bucket, and no declared bucket is unreachable by any legal pair'"
        status: pass
      - kind: other
        ref: "Negative control 1 (throwaway unreachable bucket added to BUCKET_OF_PAIR): reachability test fails with a deepEqual mismatch, non-zero exit. Negative control 2 (fixed/proved mapping removed): both the fixtures test and the reachability test fail with 'row 1 has an unmapped (disposition, state) pair: (fixed, proved)', non-zero exit. Both mutations applied to a backup copy, confirmed failing, then reverted; committed file has 0 null bytes and re-passes 7/7."
        status: pass
      - kind: integration
        ref: "node scripts/ci/verify_window_dispositions.mjs --fixtures --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism -> PASS"
        status: pass
    human_judgment: false
  - id: D4
    description: "231-WINDOW-DISPOSITIONS.md is re-rendered under the new renderer against the unchanged 231-WINDOW-DISPOSITIONS.json in a presentation-only commit; the JSON has zero byte diff across the task's base-to-HEAD range and the commit's file list contains only the .md"
    requirement: HYG-02
    verification:
      - kind: integration
        ref: "git diff --quiet <task base>..HEAD -- .../231-WINDOW-DISPOSITIONS.json -> exit 0 (zero bytes changed), re-confirmed after the commit landed"
        status: pass
      - kind: integration
        ref: "Double-render byte-identity: render twice to /tmp, cmp exit 0 both against each other and against the committed .md"
        status: pass
      - kind: other
        ref: "git show --stat 5d5bdcf7 lists only 231-WINDOW-DISPOSITIONS.md"
        status: pass
      - kind: other
        ref: "grep -nE '/Users/|/home/|\\$HOME' .../231-WINDOW-DISPOSITIONS.md; test $? -eq 1 -> leak sweep matches nothing"
        status: pass
    human_judgment: false

duration: ~40min
completed: 2026-09-16
status: complete
---

# Phase 232 Plan 04: Total pair-map window-disposition renderer + reachability test Summary

**Replaced the window-disposition renderer's fall-through if-chain with a total, fail-closed `(disposition, state)` pair map carrying D-15's four outcome-named buckets, added a derived-legality cartesian-product reachability test in both directions, and re-rendered phase 231's committed artifact presentation-only with its JSON untouched.**

## Performance

- **Duration:** ~40 min
- **Started:** 2026-09-16 (session continuation from 232-03)
- **Completed:** 2026-09-16T20:23:51Z
- **Tasks:** 3/3 completed
- **Files modified:** 4 (3 scripts, 1 re-rendered artifact)

## Accomplishments

- `scripts/ci/render_window_dispositions.mjs`'s `bucketOf()` now looks up a module-level `BUCKET_OF_PAIR` map keyed on the literal `(disposition, state)` pair (NUL-separated `pairKey()`) and calls `fail()` naming the row id and both values on any pair the map does not declare -- the CR-01 dead-branch incident (unreachability recorded only in a comment) can no longer happen silently.
- `scripts/ci/collect_window_dispositions.mjs` now exports `ROW_STATES` (`{proved, failed, skipped, advisory, non_run}`, membership unchanged) alongside the existing `ROW_KINDS`/`ROW_DISPOSITIONS`, so the renderer and the verifier's cartesian-product test can enumerate the closed state set without a second, hand-transcribed copy.
- Four D-15 bucket headings are declared, none a bare status word, and always render even at zero rows: **"Waived — the gate ran and failed"**, **"Waived — the gate never proved anything"**, **"Waived — the gate passed anyway"**, **"Fixed — proved at the candidate SHA"**. The third bucket is a real, currently-legal case (a waived row whose gate passed anyway — a ledger/reality mismatch), not a hypothetical, so it is a declared bucket rather than a comment.
- The rendered document header now states this file is a deterministic re-render (projection) of the named JSON record and that the JSON is the evidence of record; a new "Evidence command" table column renders each row's `evidence_command` (present in the JSON, shown nowhere before this plan); and a D-18 sentence states the `--require-row-join`/`--require-evidence-freshness` strict checks apply only to the current phase's own record because the join is against the live `.planning/WINDOWS.md` ledger, while a historical, frozen record verifies schema and determinism only.
- `scripts/ci/verify_window_dispositions.mjs` gained one new `node:test` case: derive the legal `(disposition, state)` pair set by calling `validateWindowRow` over the cartesian product of `ROW_DISPOSITIONS` x `ROW_STATES` (catching rejections rather than hand-listing legality), assert the derived set is non-empty, then `assert.deepEqual` the sorted reached-bucket set against the sorted declared-bucket set — one assertion proves both directions: no legal pair renders unbucketed, no declared bucket is dead code.
- Two negative controls were executed and reverted during this task (not committed): adding a throwaway unreachable bucket made the new test fail with a `deepEqual` mismatch; removing the `(fixed, proved)` mapping made both the existing fixtures test and the new reachability test fail with `row 1 has an unmapped (disposition, state) pair: (fixed, proved)`. Both mutations were applied to a backup file copy, confirmed to fail, then reverted before committing — the committed diff excludes them.
- `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md` was re-rendered under the new renderer against the same, byte-unchanged `231-WINDOW-DISPOSITIONS.json` in a presentation-only commit (`5d5bdcf7`, file list contains only the `.md`). Proof: zero bytes of the JSON changed across the task's base-to-HEAD range (`git diff --quiet` exit 0), and the new renderer run twice over the same JSON produces byte-identical Markdown that byte-equals the committed file.

## Task Commits

Each task was committed atomically (5 commits total for this plan, Task 1 as a TDD RED/GREEN/fix trio):

1. **Task 1 RED: assert the new bucketing/header contract** - `520a85b5` (test) — 6 assertions fail against the old if-chain
2. **Task 1 GREEN: total pair map + D-15 headings + header sentences** - `b3a7d326` (feat) — 43/43 pass
3. **Task 1 fix: literal NUL byte introduced by an Edit-tool escaping quirk** - `8158a9d2` (fix) — see Deviations
4. **Task 2: derived-legality cartesian-product reachability test** - `cb389856` (feat) — 7/7 pass, both negative controls confirmed and reverted
5. **Task 3: presentation-only re-render of 231-WINDOW-DISPOSITIONS.md** - `5d5bdcf7` (docs) — JSON untouched, double-render byte-identical

_Note: Task 1 is TDD (RED → GREEN), plus one Rule-1 fix commit discovered by the RED/GREEN cycle itself; Tasks 2-3 are `type="auto"` (no `tdd="true"` attribute), committed as single feat/docs commits after their own verification passed._

## Files Created/Modified

- `scripts/ci/collect_window_dispositions.mjs` - exports `ROW_STATES`; entrypoint guard wrapped in try/catch (Rule 1)
- `scripts/ci/render_window_dispositions.mjs` - total `BUCKET_OF_PAIR` map, D-15 headings, evidence_command column, header sentences, `bucketOf`/`BUCKET_OF_PAIR`/`pairKey` exported for the verifier; entrypoint guard wrapped in try/catch (Rule 1); one literal NUL byte fixed to its `\u0000` escape (Rule 1)
- `scripts/ci/verify_window_dispositions.mjs` - new cartesian-product reachability test, `probeRow`/`deriveLegalPairs` helpers, imports of `ROW_STATES`/`bucketOf`/`BUCKET_OF_PAIR`
- `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md` - presentation-only re-render (JSON untouched)

## Decisions Made

See `key-decisions` in frontmatter for full rationale on: the four exact D-15 heading strings; rendering `evidence_command` as a new table column; `bucketOf`'s fail-closed branch being defensive-only and tested directly rather than through the public entrypoint; the cartesian-product test's `probeRow()` deriving legality purely from the schema validator; the Rule-1 entrypoint-guard try/catch fix on both files; and the literal-NUL-byte Edit-tool gotcha.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `collect_window_dispositions.mjs`/`render_window_dispositions.mjs` entrypoint guards crashed on an ambiguous-entrypoint import**
- **Found during:** Task 1, running the plan's own `<verify>` command `node --input-type=module -e "import('./scripts/ci/collect_window_dispositions.mjs')..."`
- **Issue:** Both files called `isMainModule(import.meta.url)` directly (unguarded) at their entrypoint-detection site. `isMainModule()` throws (rather than returning a silent false) when `process.argv[1]` is empty — exactly the shape of a `node --input-type=module -e "import(...)"` inline-eval script — so the throw propagated uncaught and crashed the bare import instead of resolving to "not the entrypoint".
- **Fix:** Wrapped both in the same `try { invokedAsEntrypoint = isMainModule(...) } catch { invokedAsEntrypoint = false }` pattern already established in `verify_window_dispositions.mjs`.
- **Files modified:** `scripts/ci/collect_window_dispositions.mjs`, `scripts/ci/render_window_dispositions.mjs`.
- **Verification:** `node --input-type=module -e "import('./scripts/ci/collect_window_dispositions.mjs').then(m => process.exit(m.ROW_STATES ? 0 : 1))"` now exits 0.
- **Committed in:** `b3a7d326` (Task 1 GREEN commit)

**2. [Rule 1 - Bug] A literal NUL byte was written into the source file instead of its six-character `\u0000` escape**
- **Found during:** Task 1 GREEN commit's own diffstat, which reported `render_window_dispositions.mjs | Bin 16572 -> 19324 bytes` (a binary diff) for a ~14-line text change
- **Issue:** Passing the literal text `\u0000` inside an Edit-tool `old_string`/`new_string` JSON parameter decodes, via standard JSON string escaping, to the actual U+0000 codepoint (a real NUL byte) rather than the six ASCII characters `\`, `u`, `0`, `0`, `0`, `0` intended as source text. The Edit tool inserted a literal NUL byte into `PAIR_SEPARATOR = "\u0000"`, making the whole file appear binary to git.
- **Fix:** Confirmed via a byte-level Python read (`data.count(b'\x00')` -> 1), then replaced the exact byte sequence `"\x00"` with the literal six-character text `"\u0000"` using a direct Python byte-level write (not the Edit tool, to avoid the same escaping mangling on retry). Re-verified `node --check` and the full 43-test suite still pass, and applied the identical prevention when adding `export`s to the same map in Task 2 (used direct Python string replacement instead of the Edit tool for the line containing `PAIR_SEPARATOR`, since the Edit tool's internal string match against the byte-correct file continued to disagree with a `\u0000`-containing parameter).
- **Files modified:** `scripts/ci/render_window_dispositions.mjs`.
- **Verification:** `python3 -c "print(open(path,'rb').read().count(b'\x00'))"` -> 0 in the committed blob; `node --check` clean; 43/43 tests pass.
- **Committed in:** `8158a9d2` (dedicated fix commit, since it was discovered after `b3a7d326` landed)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — real bugs found via the task's own mandated verification, not scope creep).
**Impact on plan:** Both fixes were necessary for Task 1's own `<verify>` commands to pass and for the committed artifact to be a genuine text file rather than an accidental binary blob. No behavior change to any CLI invocation's documented contract.

## Issues Encountered

None beyond the two auto-fixed deviations above. The Edit tool's `\uXXXX`-in-JSON-parameter escaping behavior (deviation 2) is worth flagging for future plans that construct source text containing a literal backslash-u escape sequence: prefer a direct file read/replace (e.g. Python) over the Edit tool for that specific character class, or verify with a byte-level read immediately after any such edit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The window-disposition renderer now tells the truth about which gate outcomes it describes: bucketing is total and fails closed, reachability is asserted in both directions by a test that cannot drift from the schema, and phase 231's projection is regenerated with its evidence of record untouched. `HYG-02` remains `Pending` in REQUIREMENTS.md because it is a shared ID declared by other not-yet-executed plans in this phase (per the shared-ID gate) and only flips complete when every declaring plan finishes. No blockers for 232-05 or later plans.

## Self-Check: PASSED

- FOUND: `520a85b5`, `b3a7d326`, `8158a9d2`, `cb389856`, `5d5bdcf7` (all five commits) in `git log --oneline`
- FOUND: `scripts/ci/collect_window_dispositions.mjs`, `scripts/ci/render_window_dispositions.mjs`, `scripts/ci/verify_window_dispositions.mjs` (verified via `node --check`, all clean)
- FOUND: `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md` re-rendered, JSON sibling byte-unchanged (confirmed live)
- Re-ran all plan-level `<verification>` commands: `node --test --test-reporter=tap` over the three window-disposition files -> 50/50 pass; `--fixtures` + all four strict flags -> PASS; double-render byte-identity against the committed 231 artifact -> confirmed; zero null bytes in the final committed `render_window_dispositions.mjs` blob (confirmed live)
- `node scripts/ci/verify_ci_script_contract.mjs --repo . --expected-repository szTheory/accrue --require-guard-coverage --require-non-vacuity --require-cohort-floor` -> `PASS (verified: require-cohort-floor, require-guard-coverage, require-non-vacuity)` (confirmed live, sibling-plan contract still satisfied)

---
*Phase: 232-bounded-hygiene-release-handoff*
*Completed: 2026-09-16*
