---
phase: 231-exact-sha-release-gate-proof
plan: 05
subsystem: infra
tags: [ci-evidence, ship-windows, release-gate, broken-windows-ledger]

requires:
  - phase: 231-exact-sha-release-gate-proof
    provides: "plan 231-02's collect/render/verify_window_dispositions.mjs triad; plan 231-03's 231-GATE-01-EVIDENCE.json (clean scratch-clone cohort proof); plan 231-04's 231-GATE-02-EVIDENCE.ndjson (real workflow_dispatch proof, conclusion failure)"
provides:
  - ".planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json and .md — owner/rationale/release-impact/current-evidence per ship-window row id, joined 1:1 to .planning/WINDOWS.md"
  - ".planning/WINDOWS.md at open_count 0 (8 fixed, 2 waived) — every ship window carries a re-derived disposition"
affects: [231-06]

actuals:
  tokens: 11610
  tasks: 2
  commits: 1

tech-stack:
  added: []
  patterns:
    - "Deviation-row disposition follows the change's fate, not its byte-presence: a still-present text change closes fixed (rows 2, 6, 9), while a change whose entire implementation was later deleted by a separately-reviewed phase closes waived with an independently-verified equivalent-mechanism rationale (row 3), never silently 'fixed' on a stale premise."
    - "unrun-verify rows close fixed only on a genuinely re-run, currently-passing clean-checkout command (not merely 'the config now looks right') -- rows 4/5/6/7/8 were each independently re-executed (mix test / mix format --check-formatted) in a fresh scratch clone at the candidate SHA, not inferred from GATE-01's aggregate pass alone."
    - "A gate that now runs but produces a real non-qualifying outcome (row 10: one workflow_dispatch, conclusion failure, not the required 3 successes) still counts as 'the original blocker reproduces' under D-22, not 'the gate now passes' -- disposition is waived, not fixed, even though something genuinely executed."

key-files:
  created:
    - .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json
    - .planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md
  modified:
    - .planning/WINDOWS.md

key-decisions:
  - "Row 3 (deviation, phase 215) waived rather than fixed: the Swift capability-report reducer it named was deleted, not edited, by Phase 223-04's package-facade redesign (commit a03634a2, -1080 lines from AccrueOfflineClient.swift); confirmed by re-checking scripts/ci/verify_ios_offline_client.sh's jq assertion against the checked-in capability-report.json at the candidate SHA still enforces the equivalent 'cannot report proven without genuine evidence' property."
  - "Row 10 (unrun-verify, phase 227) waived rather than fixed: GATE-02 recorded exactly one real workflow_dispatch observation and it concluded failure, not a qualifying success, so Phase 227's three-success bounded critical-path comparison still cannot run -- the original data-gap blocker reproduces in substance even though a dispatch now genuinely executes."
  - "Row 2's re-derivation surfaced an unrelated, pre-existing fact worth recording honestly rather than silently closing on the original description alone: its test file has been orphaned from the Swift Package Manager build graph since Phase 223-04 (Package.swift declares a different test-target name) and is never compiled or run -- flagged in the disposition artifact as a future housekeeping item, out of this plan's scope to fix."
  - "Row 5 (billing_facade_test.exs fake-subscription-uniqueness) investigated and fixed on its merits per D-24 -- never auto-waived -- via a genuine re-run in a fresh scratch clone at the candidate SHA (18 tests, 0 failures), not the research note's dirty-tree observation."

patterns-established:
  - "For deviation-kind ship windows, re-derivation (D-23) must check whether the named production code still exists at all before checking whether its content is unchanged -- an absent file with a present sibling test can look 'intact' from the test alone."

requirements-completed: []

coverage:
  - id: D1
    description: "All ten .planning/WINDOWS.md rows re-derived at the candidate SHA and disposed fixed-or-waived via the ledger writer CLI (never hand-edited); open_count reaches 0 with the pinned 10-column schema unwidened"
    requirement: GATE-03
    verification:
      - kind: other
        ref: "node scripts/ci/verify_window_dispositions.mjs --repo . --records .../231-WINDOW-DISPOSITIONS.json --rendered .../231-WINDOW-DISPOSITIONS.md --candidate integration/v1.62-candidate --expected-repository szTheory/accrue --require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism"
        status: pass
      - kind: other
        ref: "grep -qE '^open_count: 0$' .planning/WINDOWS.md && header line unchanged && exactly 10 numbered rows"
        status: pass
    human_judgment: false
  - id: D2
    description: "Row 5's real pre-existing test failure investigated and fixed on its merits at a genuine clean-checkout run at the candidate SHA, never auto-waived (D-24)"
    requirement: GATE-03
    verification:
      - kind: integration
        ref: "examples/accrue_host/test/accrue_host/billing_facade_test.exs (18 tests, 0 failures, exit 0, fresh scratch clone at f524f2a6b16d3576829632ab6fa77d24b718e6f7)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Each unrun-verify row's originally-blocking gate re-run clean in a fresh scratch clone at the candidate SHA (rows 4, 7, 8: mix format --check-formatted; row 4 also mix test package_docs_verifier_test.exs; row 6: mix test snapshot_test.exs)"
    requirement: GATE-03
    verification:
      - kind: other
        ref: "mix format --check-formatted (accrue, accrue_host) and mix test test/accrue/docs/package_docs_verifier_test.exs / test/accrue/entitlements/snapshot_test.exs, all exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Frozen Phase 229/230 capsules verified byte-unchanged by the window-status flip (D-27, D-28) via an explicit-range diff against the pre-task commit"
    requirement: GATE-03
    verification:
      - kind: other
        ref: "git diff --quiet <pre-task-sha>..HEAD -- 229-REPOSITORY-INVENTORY.json 230-ROLLBACK-POINT.json 230-INTEGRATION-DISPOSITION.json"
        status: pass
    human_judgment: false

duration: 105min
completed: 2026-09-16
status: complete
---

# Phase 231 Plan 5: Exact-SHA Release Gate Proof — Ship-Window Dispositions Summary

Re-derived all ten `.planning/WINDOWS.md` rows at candidate SHA `f524f2a6b16d3576829632ab6fa77d24b718e6f7` in fresh scratch clones (never trusting the archived descriptions), closed 8 as `fixed` on genuinely re-run, currently-passing evidence and 2 as `waived` with owner/rationale/release-impact after confirming their original blockers still reproduce in substance — driving the ledger to `open_count: 0` entirely through the writer CLI.

## Performance

- **Duration:** ~105 min
- **Tasks:** 2
- **Files modified:** 3 (1 modified, 2 created)

## Accomplishments

- Re-derived each row's condition at the candidate SHA via direct file inspection and, where an unrun-verify row named a specific test or format check, a genuine re-run in a fresh scratch clone (`mix test`, `mix format --check-formatted`) rather than inference from GATE-01/02's aggregate pass:
  - Row 1: confirmed `examples/accrue_host/playwright.config.js` already defines the `chromium-mobile` project the row recorded as missing (D-23's canonical "stale premise" case, preserved explicitly in the disposition artifact's rationale).
  - Row 4: `mix test test/accrue/docs/package_docs_verifier_test.exs` — 46 tests, 0 failures; `mix format --check-formatted` clean for `accrue`.
  - Row 5: `mix test test/accrue_host/billing_facade_test.exs` — 18 tests, 0 failures, including the previously-failing fake-subscription-uniqueness case at line 160 — investigated and fixed on its merits per D-24, never auto-waived.
  - Rows 6, 7, 8: `mix test test/accrue/entitlements/snapshot_test.exs` (4/4 pass) and `mix format --check-formatted` for `examples/accrue_host` (clean, no diff).
  - Rows 2, 9: confirmed the intentional Phase 215/225 text changes are still present and byte-intact at the candidate SHA (`mix.lock`'s `jose` entry unchanged after a fresh `mix deps.get`).
  - Row 3: discovered the named Swift reducer was deleted (not edited) by Phase 223-04's `a03634a2` (−1080 lines from `AccrueOfflineClient.swift`); independently verified the equivalent safety property is enforced today by `scripts/ci/verify_ios_offline_client.sh`'s `jq` assertion against the checked-in `capability-report.json`.
  - Row 10: read GATE-02's evidence — one real `workflow_dispatch` observation, conclusion `failure` — and determined this does not satisfy the "3 qualifying successes" the row originally needed.
- Flipped every row through `gsd-tools windows fixed <id>` / `windows waive <id> "<reason>"` — 8 fixed, 2 waived, `.planning/WINDOWS.md`'s frontmatter now reads `open_count: 0`, `waived_count: 2`, `fixed_count: 8`, `total_count: 10`, with its pinned 10-column header byte-unchanged.
- Emitted `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json` (mode `0600`) and `.md` via the Plan 02 triad, carrying owner/rationale/release-impact/current-evidence per row.
- Ran the full strict verification suite (`--require-row-join --require-evidence-freshness --require-waiver-completeness --require-determinism`): PASS. Confirmed `node --test scripts/ci/verify_repository_inventory.mjs` still passes (5/5) and the frozen Phase 229/230 capsules are byte-unchanged across an explicit pre-task-SHA diff range.

## Task Commits

1. **Task 1 + Task 2 (combined — Task 1 produced only a scratch input file, not a repository artifact):** `6c736b98` (feat) — re-derived evidence for all ten rows, flipped every `.planning/WINDOWS.md` status through the ledger writer, and committed the emitted `231-WINDOW-DISPOSITIONS.json`/`.md`.

**Plan metadata:** this commit (SUMMARY + STATE).

## Files Created/Modified

- `.planning/WINDOWS.md` — all ten rows flipped to `fixed`/`waived`; `open_count: 0`; pinned schema unchanged.
- `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json` (mode `0600`) — committed rich evidence, 10 rows.
- `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.md` — rendered diagnostic, byte-reproducible from the JSON.

## Decisions Made

- Row 3 waived, not fixed: the named production code no longer exists (deleted by an unrelated, separately-reviewed phase), and closing it "fixed" would misrepresent that the specific change was confirmed present. Waiving with a verified-equivalent-mechanism rationale is the honest disposition per D-22's "absent → escalate" branch, applied without a human checkpoint by actively investigating and resolving to a verified-safe waiver rather than leaving the row open.
- Row 10 waived, not fixed: a gate now genuinely executes (GATE-02's dispatch), but its outcome (one failure) is not the qualifying success the row required, so per D-22 the original blocker still reproduces in substance.
- Row 2's disposition records an honest, out-of-scope-to-fix side finding (SPM test-target orphaning since Phase 223-04) rather than silently closing on the original description alone — consistent with D-23's re-derivation discipline applied everywhere, not just to row 1.
- Row 5 investigated and fixed on its merits via a genuine clean-checkout re-run, never auto-waived, satisfying D-24 exactly as the row's own file/line pin requires.

## Deviations from Plan

None — plan executed exactly as written. The investigation into rows 2/3 surfaced facts (SPM orphaning, reducer deletion) beyond what the plan's `<read_first>` anticipated, but resolving them stayed within Task 1's own mandate to re-derive "current evidence" honestly (D-23) and Task 2's mandate to flip statuses through the writer CLI — no plan text was contradicted, no unplanned files were modified, and no architectural change was made to any production code.

## Issues Encountered

None blocking. Two genuinely new facts were investigated and disposed within this plan's own evidence-gathering task, documented above and in the committed disposition artifact:

- Row 2's test file is orphaned from `examples/crosswake_tracer/Package.swift`'s SPM test-target graph (unrelated to Phase 215, introduced by Phase 223-04) — recorded as a future housekeeping item, not fixed here.
- Row 3's named Swift reducer no longer exists — disposed as `waived` with an independently-verified equivalent-mechanism rationale, per D-22.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

`.planning/WINDOWS.md` is at `open_count: 0` with every row's disposition backed by re-derived, candidate-SHA evidence in the committed sibling artifact. `GATE-03` is not yet marked complete in `REQUIREMENTS.md` — the shared-ID gate (#2388) correctly holds it, since Plan 231-06 also declares `GATE-03` (alongside `GATE-01`/`GATE-02`) and has not yet produced its own SUMMARY; it will flip once 231-06 finishes. `roadmap update-plan-progress` for phase 231 failed with the known, pre-existing `missing_phase_details` `</details>`-placement defect in `ROADMAP.md` (already surfaced to the maintainer) — not fixed here, per explicit instruction. Plan 231-06 (minting a fresh `231-REPOSITORY-INVENTORY.json` capsule, per D-28, now that all window-status edits have landed) is the correct next step.

## Self-Check: PASSED

- `.planning/phases/231-exact-sha-release-gate-proof/231-WINDOW-DISPOSITIONS.json` and `.md` exist on disk.
- Commit `6c736b98` found in `git log --oneline --all`.
- Re-ran the plan-level `<verification>` block: `verify_window_dispositions.mjs` with all four strict flags PASS; `.planning/WINDOWS.md` reports `open_count: 0` with the pinned header intact and exactly ten numbered rows; `node --test scripts/ci/verify_repository_inventory.mjs` 5/5 pass; the frozen Phase 229/230 capsules are byte-unchanged across an explicit `<pre-task-sha>..HEAD` diff range and the working tree.

---
*Phase: 231-exact-sha-release-gate-proof*
*Completed: 2026-09-16*
