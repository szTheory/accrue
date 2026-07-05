---
phase: 207-orchestration-digest-one-command-round-fix-loop
reviewed: 2026-07-04T12:00:00Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs
  - accrue_admin/e2e/ratchet/ratchet-ledger.js
  - accrue_admin/e2e/ratchet/ratchet-propose.mjs
  - accrue_admin/e2e/ratchet/ratchet-verify.mjs
  - accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs
  - accrue_admin/e2e/ratchet/ratchet-digest.mjs
  - accrue_admin/e2e/ratchet/ratchet-fix.mjs
  - accrue_admin/e2e/baseline-manifest.js
  - accrue_admin/e2e/admin-visuals.spec.js
  - accrue_admin/e2e/foundation-tokens.spec.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/reduced-motion.spec.js
  - accrue_admin/e2e/admin-page-flow-phase200.spec.js
  - accrue_admin/e2e/ratchet-fix-probe.spec.js
  - accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex
  - accrue_admin/test/mix/tasks/accrue_admin_ui_round_test.exs
  - accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs
findings:
  critical: 2
  warning: 3
  info: 3
  total: 8
status: issues_found
---

# Phase 207: Code Review Report

**Reviewed:** 2026-07-04T12:00:00Z
**Depth:** standard
**Files Reviewed:** 18
**Status:** issues_found

## Summary

Reviewed the Phase 207 UI-ratchet orchestration slice: the round-seal / next-round / convergence additions to `phase-ratchet-ledger.mjs`, the new `ratchet-digest.mjs` HTML digest, the `ratchet-fix.mjs` apply/finalize mutation half, the `ratchet-guard-mint.mjs` guard mint, the `ratchet-fix-probe.spec.js` DOM probe, and the two thin `mix accrue_admin.ui.round` / `ui.fix` orchestrators plus their tests.

Overall the isolation posture is good: the LLM stays off the gate path, `--self-test` paths target `mkdtemp` scratch dirs, path-traversal on `png_ref` is closed, and HTML output is escaped. However there are two defects that break the phase's own load-bearing guarantees end-to-end — the digest can abort the whole round on legitimate LLM output, and `finalize-fixes` writes structurally-incomplete guard rows into committed guard-home specs, breaking those specs in CI. Both are reachable on normal (non-adversarial) inputs.

## Critical Issues

### CR-01: Digest aborts the entire round when a confirmed finding has `suggested_fix: null`

**File:** `accrue_admin/e2e/ratchet/ratchet-digest.mjs:66-74, 281-293, 940-948`
**Issue:** `REQUIRED_ROW_FIELDS` includes `"suggested_fix"`, and `validateDigestRows` throws when any worklist/decisions-needed row has a `null`/empty value for it. But `suggested_fix` is *not* a required field anywhere upstream: the proposer's forced-tool schema requires only `["dimension","region_tag","severity","defect"]` (`ratchet-propose.mjs:387`), and `emitCandidates` explicitly stores `suggested_fix: typeof f.suggested_fix === "string" ? f.suggested_fix : null` (`ratchet-propose.mjs:852`). That `null` is carried verbatim onto the committed ledger row (`suggested_fix` is in `ratchet-ledger.js` `CARRY_FIELDS`, and `appendOpen` copies present keys, `null` included). So a genuinely-confirmed finding whose model output omitted a fix reaches `generateDigest`, `validateDigestRows(worklist, ...)` throws, `ratchet-digest.mjs` exits non-zero, and the `mix accrue_admin.ui.round` `digest` step `run_step!` calls `Mix.raise("digest step failed ...")` — aborting the round with **no digest produced**. This directly defeats the documented guarantee ("ALWAYS renders the digest before deciding whether to raise", `accrue_admin.ui.round.ex:20-22`). It fires on ordinary LLM output, not a crafted payload.
**Fix:** Either drop `suggested_fix` from the hard-required set and render a placeholder, or normalize it to a non-empty string at emit time. Minimal change in the digest:
```js
// ratchet-digest.mjs — treat suggested_fix as optional prose, not a gate field
const REQUIRED_ROW_FIELDS = [
  "finding_id", "surface", "region_tag", "severity", "persona_frequency", "defect",
]; // suggested_fix removed
// ...and in renderFindingRow, guard the optional fix line:
const fixLine = f.suggested_fix ? `<p class="fix muted">${escapeHtml(f.suggested_fix)}</p>` : "";
```
(If the fix must stay mandatory, instead default it at the proposer: `suggested_fix: typeof f.suggested_fix === "string" && f.suggested_fix.trim() ? f.suggested_fix : "(no fix suggested)"`, so no null ever reaches the committed ledger.)

### CR-02: `finalize-fixes` mints structurally-incomplete guards into committed guard-home specs for design-token / spacing-scale / microcopy findings

**File:** `accrue_admin/e2e/ratchet/ratchet-fix.mjs:239-266`, `accrue_admin/e2e/ratchet-fix-probe.spec.js:198-213`, `accrue_admin/e2e/ratchet/ratchet-guard-mint.mjs:119-138`
**Issue:** `ratchet-fix-probe.spec.js`'s `default` branch (every rubric dimension except contrast/6 and motion/9) unconditionally sets `present = false` and writes `probed = { selector, route, region_present, text }` — it never captures kind-specific fields. But `finalizeFixes` then routes those `present:false` findings through `mintGuardRow` → `buildRow`, and `buildRow` needs fields the probe never supplied:
- `design-token` (dim 1) needs `property` + `expected_token` — probe supplies neither.
- `spacing-scale` (dim 3 + `inconsistent-rhythm`) needs `property` + `allowed_values` — neither supplied.
- `microcopy` (dim 12) needs `expected_text` + `old_text` — neither supplied.

`buildRow` reads them off the empty map as `undefined`; `JSON.stringify` drops them; `appendMintedRow` writes an incomplete row into the committed guard-home spec (`foundation-tokens.spec.js` / `admin-page-flow-phase200.spec.js`) and flips `RATCHET_AUTO_GUARDS.length > 0`, so the previously-skipped auto-guard test now runs. It then executes e.g. `styleOf(locator, undefined)` / `rootToken(page, undefined)` (design-token) or `expect(text).toContain(undefined)` (microcopy) and **fails in CI** — corrupting a committed spec. `checkGuardRef`'s gate can't catch this: it only verifies the `@ratchet:<finding_id>` token substring exists, not that the row's kind-fields are populated. The probe's own comment even claims it produces "concrete [guards] for design-token/microcopy/focus-ring", but only `focus-ring` (needs just `selector`), `contrast`, and `motion` actually get complete data. This is reachable for any resolved dim-1/dim-3-rhythm/dim-12 finding — all common.
**Fix:** Make `mintGuardRow`/`buildRow` refuse to mint a concrete guard when a required kind-field is missing, and have `finalizeFixes` fall back to the `ledger-count` sentinel (or leave the finding `resolved`) in that case. Concretely, in `ratchet-guard-mint.mjs`:
```js
const REQUIRED_FIELDS_BY_KIND = {
  "design-token": ["selector", "property", "expected_token"],
  contrast: ["selector", "min_ratio"],
  "spacing-scale": ["selector", "property", "allowed_values"],
  microcopy: ["route", "expected_text", "old_text"],
  "focus-ring": ["selector"],
  motion: ["route", "selector", "max_ms"],
};
function mintGuardRow(finding, probedFields = {}) {
  const kind = kindForFinding(finding);
  if (kind === "ledger-count") return { guard_ref: "ledger-count", targetSpecPath: null, row: null };
  const missing = REQUIRED_FIELDS_BY_KIND[kind].filter((k) => probedFields[k] == null);
  if (missing.length) {
    // degrade to the ledger-count sentinel rather than mint a broken concrete guard
    return { guard_ref: "ledger-count", targetSpecPath: null, row: null };
  }
  // ...existing allowlist + guard_ref build...
}
```
Alternatively, extend the probe's `default` branch to actually capture the design-token/spacing/microcopy fields before it is allowed to report `present:false` for those kinds.

## Warnings

### WR-01: `ratchet-verify.mjs` ledger-isolation self-test (vi) is vacuous — it can never fail

**File:** `accrue_admin/e2e/ratchet/ratchet-verify.mjs:826-834`
**Issue:** The test claims to prove "real committed findings.ledger.ndjson untouched by --self-test", but it reads the file twice consecutively with **no operation in between**:
```js
const beforeBytes = existedBefore ? fs.readFileSync(LEDGER_PATH) : null;
const afterBytes  = existedBefore ? fs.readFileSync(LEDGER_PATH) : null;
```
`beforeBytes` and `afterBytes` are identical by construction, so `Buffer.compare(...) === 0` is always true regardless of whether earlier fixtures mutated the ledger. It provides false confidence in exactly the invariant this file most needs to guarantee (it is the *single writer* to the committed ledger). Compare with `phase-ratchet-ledger.mjs:812-830`, which correctly snapshots *before* the mutating call and re-reads *after*.
**Fix:** Snapshot the bytes at the very top of `runSelfTest()` (before any fixture runs) and compare against a fresh read here:
```js
// top of runSelfTest():
const _ledgerSnapshot = fs.existsSync(LEDGER_PATH) ? fs.readFileSync(LEDGER_PATH) : null;
// (vi):
const after = _ledgerSnapshot ? fs.readFileSync(LEDGER_PATH) : null;
assertSelfTest("(vi) ...", !_ledgerSnapshot || Buffer.compare(_ledgerSnapshot, after) === 0);
```

### WR-02: `ui.fix` git-commit step commits the whole staged index, not "only priv/static"

**File:** `accrue_admin/lib/mix/tasks/accrue_admin.ui.fix.ex:107-116`
**Issue:** The moduledoc and inline comment assert it "commits ONLY `priv/static`", and the test asserts `git add priv/static` stages exactly that path. But the subsequent `git commit -m ... --allow-empty` commits the **entire index**, not just the path that was just added. Any files a maintainer had already staged before running `ui.fix` are swept into the `chore(ui-ratchet): rebuild CSS bundle` commit. The test only checks the `add` args, so it can't catch this.
**Fix:** Scope the commit to the pathspec so unrelated staged changes are excluded:
```elixir
run_step!(runner, "git-commit", "git",
  ["commit", "-m", "chore(ui-ratchet): rebuild CSS bundle for round #{round}",
   "--allow-empty", "--", "priv/static"],
  cd: root)
```
(A trailing `-- priv/static` limits the commit to that pathspec.)

### WR-03: `appendOpen` is the one lifecycle writer with no status/transition guard — the non-atomic round pipeline can append `confirm/open` rows onto non-open findings

**File:** `accrue_admin/e2e/ratchet/ratchet-ledger.js:303-346`; interaction with `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex:100-133`
**Issue:** Every other lifecycle writer (`appendResolved`/`appendVerifiedClosed`/`appendSuppressed`/`appendReopened`) funnels through `appendLifecycleEvent`, which enforces `LEGAL_TRANSITIONS` and refuses illegal appends. `appendOpen` does not: it appends a fresh `confirm/open` row for a `finding_id` regardless of that finding's current folded status, and performs no de-duplication. The `ui.round` pipeline is not atomic — if a run fails after `verify` writes to the committed ledger but before `seal-round` records the round in `rounds.ndjson`, a re-run computes the *same* `--next-round` integer, re-proposes, and `verify` re-appends `confirm/open` rows for still-present findings (and, if a candidate matches a previously `resolved`/`verified-closed` finding, "reopens" it by raw append, bypassing the `appendReopened` transition path). The deterministic reopen-marker gate (`checkReopenMarkers`) does eventually flag the cross-round case as `illegal-reopen`, so it is not silent, but the committed tamper-evident ledger still accumulates duplicate/illegitimate rows that require manual cleanup.
**Fix:** Have `appendOpen` (or `confirmAndWrite`) refuse to append when the folded finding already exists in a non-terminal-appropriate state — e.g. skip if a prior `open` row exists for that `finding_id`, and route genuine reopens through `appendReopened`. At minimum, make the `ui.round` re-run path idempotent so a failed-then-retried round does not double-append.

## Info

### IN-01: Dead constant `EFFORT_ORDER` in the digest

**File:** `accrue_admin/e2e/ratchet/ratchet-digest.mjs:200`
**Issue:** `const EFFORT_ORDER = { css: 0, null: 1 };` is never referenced — `effortRank` (line 208) hardcodes its own logic. Dead code that implies a coupling that does not exist.
**Fix:** Remove the constant, or drive `effortRank` from it.

### IN-02: `ratchet-propose.mjs` lacks the clean-crash wrapper its sibling `ratchet-verify.mjs` has

**File:** `accrue_admin/e2e/ratchet/ratchet-propose.mjs:873`
**Issue:** `ratchet-verify.mjs:913-918` and `phase-ratchet-ledger.mjs:1018-1025` wrap their entry point in `try/catch` that prints an actionable one-liner on an unexpected throw; `ratchet-propose.mjs` calls `await main();` bare, so an unexpected error outside `main`'s inner try surfaces as a raw Node unhandled-rejection stack trace, inconsistent with the deliberately-twinned siblings.
**Fix:** Wrap `await main()` in the same `try { ... } catch (error) { console.error(\`ratchet-propose.mjs crashed: ${error.message}\`); process.exitCode = 1; }`.

### IN-03: `resolveRound` / rounds parsing can yield `round-NaN` paths on a malformed `rounds.ndjson`

**File:** `accrue_admin/e2e/ratchet/ratchet-fix.mjs:102-108, 288-289`
**Issue:** `resolveRound` returns `Math.max(...roundsRows.map((r) => r.round))`; a row missing `round` makes the result `NaN`, which flows into `resolveRoundDir(NaN)` → `round-NaN`, then `readJson(decisionsPath)` throws an opaque `ENOENT`. Not reachable through the normal pipeline (seal always writes a numeric `round`), but there is no validation guarding a hand-edited/partial file.
**Fix:** Filter to finite `round` values (`.map(r => r.round).filter(Number.isFinite)`) and raise a clear error if none remain.

---

_Reviewed: 2026-07-04T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
