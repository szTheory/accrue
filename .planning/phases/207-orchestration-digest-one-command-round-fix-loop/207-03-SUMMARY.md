---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 03
subsystem: ui-ratchet
tags: [ratchet, guard-mint, e2e, playwright, ORCH-05, D-44, D-45, D-46]
requires:
  - "207-01: GUARD_HOME_SPECS/checkGuardRef/isSafeSpecPath exports from phase-ratchet-ledger.mjs"
provides:
  - "ratchet-guard-mint.mjs: mintGuardRow()/appendMintedRow()/kindForFinding()/homeSpecForKind()"
  - "@ratchet:auto-guards marker region + kind-dispatching loop test in all 4 GUARD_HOME_SPECS"
affects:
  - "207-06: ui.fix orchestration will call mintGuardRow()+appendMintedRow() per resolved finding"
tech-stack:
  added: []
  patterns:
    - "Typed DATA rows into a human-reviewed-once loop test (D-44) — no per-finding generated assertion code"
    - "Grep-before-append idempotency on the exact @ratchet:<finding_id> token (D-46)"
    - "Reuse imported token grammar (checkGuardRef/isSafeSpecPath) — never re-derive a second regex"
key-files:
  created:
    - accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs
  modified:
    - accrue_admin/e2e/foundation-tokens.spec.js
    - accrue_admin/e2e/reduced-motion.spec.js
    - accrue_admin/e2e/admin-page-flow-phase200.spec.js
    - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
decisions:
  - "Minted rows carry a trailing `// @ratchet:<finding_id>` token comment so the plain-JSON row stays the exact Task-1 shape while still satisfying checkGuardRef's substring-presence contract and grep-before-append idempotency"
  - "focus-ring loop honors an optional row.route, defaulting to /billing/dev/components (the focus-ring row shape is selector-only per D-45)"
metrics:
  duration: 18m
  completed: 2026-07-05
  tasks: 2
  files: 5
status: complete
---

# Phase 207 Plan 03: Guard-Mint Bootstrap + Reusable Mint Module Summary

Bootstrapped an empty, idempotent-append-ready `@ratchet:auto-guards` marker region plus one kind-dispatching loop test into each of the 4 `GUARD_HOME_SPECS`, and shipped `ratchet-guard-mint.mjs` — a pure, self-tested module that routes a resolved finding to its correct guard home (or the `ledger-count` sentinel) by dimension/defect_bucket, appends typed data rows idempotently and sorted, and mints a `guard_ref` that passes 207-01's own imported `checkGuardRef` with zero re-derived token grammar.

## What Was Built

### Task 1 — `@ratchet:auto-guards` bootstrap in the 4 guard-home specs (commit 3e9c53f2)
Each of the 4 files gained, appended after existing content (no edits inside any existing test):
- A delimited empty marker region: `// >>> @ratchet:auto-guards >>>` / `const RATCHET_AUTO_GUARDS = [];` / `// <<< @ratchet:auto-guards <<<`.
- ONE bare top-level `test(...)` that `test.skip`s on the empty array and otherwise iterates `RATCHET_AUTO_GUARDS`, dispatching on `row.kind` to that file's OWN existing helpers:
  - `foundation-tokens.spec.js`: `design-token` (styleOf vs rootToken), `contrast` (expectContrastAtLeast), `spacing-scale` (allowed_values contains computed value) — navigates once to `/billing/dev/components`.
  - `admin-page-flow-phase200.spec.js`: `microcopy` (openPhase200Route → #main-content innerText contains expected_text, not old_text).
  - `admin-interaction-overlay-phase199.spec.js`: `focus-ring` (login → focus selector → outlineStyle !== "none").
  - `reduced-motion.spec.js`: `motion` (login → parse transitionDuration comma-list → each segment ≤ max_ms).
- Every assertion message includes the literal `` `@ratchet:${row.finding_id}` `` so a failure names the finding.

### Task 2 — `ratchet-guard-mint.mjs` (commit 0a68f01b)
New ESM module importing `{ GUARD_HOME_SPECS, checkGuardRef, isSafeSpecPath }` from `phase-ratchet-ledger.mjs`:
- `kindForFinding({dimension, defect_bucket, effort_class})` — the closed D-45 table; `effort_class === "ia-product-decision"` always forces `ledger-count`.
- `homeSpecForKind(kind)` — maps to the 4 allowlisted specs or `null` (sentinel).
- `mintGuardRow(finding, probedFields)` — returns `{guard_ref, targetSpecPath, row}`; sentinel short-circuits to `{guard_ref:"ledger-count", targetSpecPath:null, row:null}`; otherwise sanity-asserts the home via `isSafeSpecPath` + `GUARD_HOME_SPECS`, builds the greppable `guard_ref`, and builds the exact per-kind row shape from `probedFields`.
- `appendMintedRow(targetSpecPath, row, repoRoot)` — grep-before-append idempotent; rewrites ONLY the delimited region; keeps rows sorted ascending by `finding_id`.
- `--self-test` CLI branch proves all of the above on `fs.mkdtempSync` COPIES of the real specs, never the committed files.

## Verification

- Task 1 automated: `env -u NO_COLOR npx playwright test e2e/foundation-tokens.spec.js e2e/reduced-motion.spec.js --timeout=60000 --workers=1` → **24 passed, 4 skipped** (the new loop tests no-op on the empty array; all pre-existing tests unaffected).
- `grep -c "@ratchet:auto-guards"` reports **2** for each of the 4 files; all 4 pass `node --check`.
- Task 2 automated: `node e2e/ratchet/ratchet-guard-mint.mjs --self-test` → **all pass** (12-dimension routing + effort override, homeSpec mapping, ledger-count sentinel, per-kind round-trip through the imported `checkGuardRef`, idempotent byte-identical double-append, sorted invariant over 3 out-of-order appends).
- `node -e "import(...).then(m => console.log(typeof m.mintGuardRow, typeof m.appendMintedRow))"` prints `function function`.
- `git status` confirms the self-test mutated **no** real committed spec file (only the new module was untracked pre-commit).

## Deviations from Plan

**None functional.** One design refinement worth recording: the plan describes idempotency as grep-before-append on the `@ratchet:<finding_id>` token, and `checkGuardRef` requires that token to be present as a substring in the spec file — but the per-kind rows are plain JSON (which never contains `@ratchet:`). Resolved by serializing each row as `  {json}, // @ratchet:<finding_id>` — the trailing token comment satisfies both `checkGuardRef`'s substring contract and grep-before-append idempotency, while the JSON object keeps the exact Task-1 row shape the loop tests read (comments are ignored by the live JS `const`). This is faithful to the plan's stated grammar, not a divergence from it.

## TDD Gate Compliance

Task 2 was authored `tdd="true"`. The module's test harness is its embedded `--self-test` (the canonical convention for every sibling `.mjs` in `e2e/ratchet/`), so the RED/GREEN cycle is contained within a single module + self-test rather than split across `test(...)`/`feat(...)` commits. The self-test asserts the full behavior contract (routing, override, round-trip, idempotency, sorting) and was run green before commit. MVP+TDD runtime gate did not apply (tdd_mode=false in phase config).

## Self-Check: PASSED

- FOUND: accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs
- FOUND: 4 modified guard-home specs (markers=2 each, node --check OK)
- FOUND commit 3e9c53f2 (Task 1)
- FOUND commit 0a68f01b (Task 2)
