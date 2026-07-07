---
phase: 207-orchestration-digest-one-command-round-fix-loop
reviewed: 2026-07-07T12:35:13Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase200.spec.js
  - accrue_admin/e2e/admin-visuals.spec.js
  - accrue_admin/e2e/baseline-manifest.js
  - accrue_admin/e2e/foundation-tokens.spec.js
  - accrue_admin/e2e/ratchet-fix-probe.spec.js
  - accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs
  - accrue_admin/e2e/ratchet/ratchet-digest.mjs
  - accrue_admin/e2e/ratchet/ratchet-fix.mjs
  - accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs
  - accrue_admin/e2e/ratchet/ratchet-ledger.js
  - accrue_admin/e2e/ratchet/ratchet-propose.mjs
  - accrue_admin/e2e/ratchet/ratchet-verify.mjs
  - accrue_admin/e2e/ratchet/rounds.ndjson
  - accrue_admin/e2e/reduced-motion.spec.js
  - accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex
  - accrue_admin/package.json
  - accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs
  - accrue_admin/test/mix/tasks/accrue_admin_ui_round_test.exs
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 207: Code Review Report

**Reviewed:** 2026-07-07T12:35:13Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Reviewed the 20-file Phase 207 source scope from the plan summaries, then re-reviewed the relevant ledger/fix-loop files after post-review fix commit `b1551e6f`.

The previous CR-01 is fixed in current HEAD. `ratchet-fix.mjs` now reads the ledger and calls `validateDecisionsBatch(rows, ledgerRows)` before any append (`accrue_admin/e2e/ratchet/ratchet-fix.mjs:211`), and that pure preflight rejects non-open or missing targets plus dangling `duplicate-of:<finding_id>` suppressions before `applyDecisions()` can append rows (`accrue_admin/e2e/ratchet/ratchet-fix.mjs:136`). The new self-test fixture `(b2) dangling duplicate-of aborts during preflight` asserts the ledger remains byte-identical (`accrue_admin/e2e/ratchet/ratchet-fix.mjs:512`). I also ran `node accrue_admin/e2e/ratchet/ratchet-fix.mjs --self-test`; it passed.

No critical findings remain. Four previously reported warnings are still valid.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: [WARNING] `ratchet-verify.mjs` ledger-isolation self-test is still vacuous

**File:** `accrue_admin/e2e/ratchet/ratchet-verify.mjs:823`

**Issue:** The self-test claims to prove the real committed `findings.ledger.ndjson` is untouched by `--self-test`, but it reads `beforeBytes` and `afterBytes` consecutively after all fixtures have already run. There is no operation between the two reads, so the assertion cannot fail even if an earlier fixture mutated the committed ledger.

**Fix:** Snapshot the real ledger at the top of `runSelfTest()` before any fixture code runs, then compare against a fresh read in this check.

```js
function runSelfTest() {
  const realLedgerSnapshot = fs.existsSync(LEDGER_PATH) ? fs.readFileSync(LEDGER_PATH) : null;

  // ...all fixture checks...

  const after = realLedgerSnapshot ? fs.readFileSync(LEDGER_PATH) : null;
  assertSelfTest(
    "(vi) real committed findings.ledger.ndjson untouched by --self-test",
    !realLedgerSnapshot || Buffer.compare(realLedgerSnapshot, after) === 0
  );
}
```

### WR-02: [WARNING] `appendOpen` still has no idempotency or lifecycle guard

**File:** `accrue_admin/e2e/ratchet/ratchet-ledger.js:303`; interaction with `accrue_admin/e2e/ratchet/ratchet-verify.mjs:307`, `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex:100`, and `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs:988`

**Issue:** `appendOpen` re-reads existing rows only to compute `seq`; it never checks whether the same `finding_id` is already open or was previously closed. `ui.round` computes the next round from `rounds.ndjson` before `verify`, but `verify` appends open findings before `seal-round` appends the round seal. If the process fails in that window, a rerun uses the same round number and can append duplicate `confirm/open` rows. If a candidate matches a previously resolved or verified-closed finding, `appendOpen` effectively reopens it with a raw `confirm` event instead of the transition-checked `appendReopened` path.

**Fix:** Make `appendOpen` preflight the latest row for the `finding_id` before appending. It should no-op or return the existing row for same-round duplicate opens, reject already-open duplicates from a different round, and route legitimate reopens through `appendReopened` plus the required reopen-marker flow.

### WR-03: [WARNING] `ratchet-propose.mjs` exports a helper but still exits or runs the live proposer on import

**File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs:51`, `accrue_admin/e2e/ratchet/ratchet-propose.mjs:157`, `accrue_admin/e2e/ratchet/ratchet-propose.mjs:165`, `accrue_admin/e2e/ratchet/ratchet-propose.mjs:873`

**Issue:** `filterPngsBySurfaces` is exported and documented as pure/unit-testable, but the module has top-level `process.exit(0)` guards and an unguarded `await main()`. Importing the helper without `ANTHROPIC_API_KEY` terminates the importing process; importing it with a key can start reading screenshots and calling the Anthropic API. That makes the export unsafe for tests and creates a surprising side-effect boundary for a file that now exposes a public helper.

**Fix:** Move CLI-only guards into `main()` and wrap execution in an import-meta entrypoint guard. Keep helper exports side-effect-free.

```js
import { pathToFileURL } from "node:url";

async function main(argv = process.argv.slice(2)) {
  if (argv.includes("--self-test")) {
    regionTags.runSelfTest();
    runProposeSelfTest();
    return;
  }
  if (!process.env.ANTHROPIC_API_KEY) {
    console.log("[ratchet-propose] ANTHROPIC_API_KEY not set - skipping (human/CI gate only)");
    return;
  }
  // import SDK/manifest here, then run live proposer
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    await main();
  } catch (error) {
    console.error(`ratchet-propose.mjs crashed: ${error.message}`);
    process.exitCode = 1;
  }
}
```

### WR-04: [WARNING] `ratchet-fix` can resolve malformed rounds into `round-NaN` or non-integer artifact paths

**File:** `accrue_admin/e2e/ratchet/ratchet-fix.mjs:72`, `accrue_admin/e2e/ratchet/ratchet-fix.mjs:102`, `accrue_admin/e2e/ratchet/ratchet-fix.mjs:304`, `accrue_admin/e2e/ratchet/ratchet-fix.mjs:320`, `accrue_admin/e2e/ratchet/ratchet-fix.mjs:340`

**Issue:** `resolveRound` returns `Math.max(...roundsRows.map((r) => r.round))` without filtering finite integers, and `parseRoundArg` accepts any finite number even though its error says an integer is required. A malformed `rounds.ndjson` row with a missing `round`, or a direct CLI call like `--round 1.5`, flows into `resolveRoundDir()` and produces paths such as `round-NaN` or `round-1.5`, followed by opaque file errors.

**Fix:** Require positive integers for both explicit and discovered rounds, and fail with a clear error when no valid round exists.

```js
function assertRound(value, source) {
  const num = Number(value);
  if (!Number.isInteger(num) || num < 1) {
    throw new Error(`${source} must be a positive integer, got ${JSON.stringify(value)}`);
  }
  return num;
}

function resolveRound(explicitRound, roundsRows) {
  if (explicitRound != null) return assertRound(explicitRound, "--round");
  const rounds = roundsRows.map((r) => r.round).filter((r) => Number.isInteger(r) && r >= 1);
  if (rounds.length === 0) {
    throw new Error("resolveRound: no valid round recorded in rounds.ndjson and no --round given");
  }
  return Math.max(...rounds);
}
```

---

_Reviewed: 2026-07-07T12:35:13Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
