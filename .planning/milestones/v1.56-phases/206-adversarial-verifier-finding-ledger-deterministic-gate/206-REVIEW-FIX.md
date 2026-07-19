---
phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
fixed_at: 2026-07-04T22:10:00Z
review_path: .planning/phases/206-adversarial-verifier-finding-ledger-deterministic-gate/206-REVIEW.md
iteration: 1
findings_in_scope: 10
fixed: 10
skipped: 0
status: all_fixed
---

# Phase 206: Code Review Fix Report

**Fixed at:** 2026-07-04T22:10:00Z
**Source review:** .planning/phases/206-adversarial-verifier-finding-ledger-deterministic-gate/206-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 10 (fix_scope: all — 2 critical, 6 warning, 2 info)
- Fixed: 10
- Skipped: 0

Every fix added or extended `--self-test` fixture coverage proving the specific defect the
finding described, and every touched file's own `--self-test` (plus the aggregate
`npm run ratchet:verify:self-test` / `ratchet:ledger:self-test` from `accrue_admin`) was re-run
and confirmed exit 0 before each commit. The real committed `findings.ledger.ndjson` and
`finding-regressions.ndjson` were confirmed untouched (still 0 bytes) throughout.

## Fixed Issues

### CR-01: Unsanitized `png_ref` path used to read and exfiltrate arbitrary local files to the Anthropic API

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-verify.mjs`
**Commit:** `58cc9d62`
**Applied fix:** Added `resolveWithinResultsDir(pngRef)`, which resolves `png_ref` against
`RESULTS_DIR` via `path.resolve` and throws if the resolved absolute path does not start with
`RESULTS_DIR + path.sep` (rejecting both relative `../` escapes and absolute-path escapes).
`verifyImageGroup` now calls this before `fs.readFileSync`, catching the thrown error and
skipping the image with a warning rather than reading/embedding an out-of-bounds file. Added
self-test case (vii): rejects `"../../../../.env"`, rejects an absolute path pointing outside
`RESULTS_DIR`, and accepts an ordinary in-directory reference.

### CR-02: `medianClamp()` silently confirms findings with fewer than 2 panel role votes, writing `severity: undefined` into the forward-only ledger

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-verify.mjs`
**Commit:** `725f7d48`
**Applied fix:** `medianClamp` now rejects any input where `buckets` is not an array of exactly
3 recognized bucket strings (returning `{confirmed: false, severity: null}`) before computing
`ranks[1]`, closing the `undefined === 0 → false` fail-open path. `PANEL_TOOL`'s
`roles` schema now also declares `minItems: 3, maxItems: 3` so the cardinality gap is closed at
the schema level too. Added self-test cases (ii-e)/(ii-f)/(ii-g) for `medianClamp([])`,
`medianClamp([one])`, `medianClamp([two])`, plus an end-to-end case (iv-b) proving
`confirmAndWrite` drops a 2-role verdict with `reason: "not-confirmed"` and never creates a
ledger file.

### WR-01: `appendLifecycleEvent` performs no lifecycle state-machine transition validation

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`
**Commit:** `48410429`
**Applied fix:** Added `LEGAL_TRANSITIONS` (`open→[resolve,suppress]`,
`resolved→[verify-close,reopen]`, `verified-closed→[reopen]`, `suppressed→[reopen]`) and
validated `prior.status → event` against it inside `appendLifecycleEvent`, throwing a
descriptive error on an illegal transition before any row is appended. Added self-test case (e)
proving `open→verify-close`, a repeated `resolved→resolve`, and `resolved→suppress` all throw
without appending a row, while the legal `resolved→verify-close` still succeeds.

### WR-02: No `appendReopened()` helper — the declared "reopen" lifecycle event has no validated write path

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`
**Commit:** `0b47e999`
**Applied fix:** Added `appendReopened(finding_id, ledgerPath, extraFields)` (thin wrapper over
`appendLifecycleEvent(..., "reopen", ...)`, benefiting from WR-01's transition table) and
exported it from `module.exports`. Extended self-test case (f): `verified-closed → reopen`
succeeds and reopens to status `open`; a subsequent `open → reopen` correctly throws (a finding
that is already open cannot be reopened again).

### WR-03: `GUARD_HOME_SPECS`/`LENS_KEYS` closed-enum arrays are hand-duplicated with no cross-check that the two copies stay in sync

**Files modified:** `scripts/ci/verify_ratchet_ledger.mjs`
**Commit:** `7df8ee5f`
**Applied fix:** Added `extractArrayLiteral(sourceText, constName)`, which reads a sibling
file's source AS TEXT (never imports it, preserving the file's independence design) and
regex-extracts + `JSON.parse`s an array-literal constant declaration. Added self-test case (7):
reads `phase-ratchet-ledger.mjs`'s source and asserts its `GUARD_HOME_SPECS` is byte-identical
to this file's own copy, and reads `ratchet-ledger.js`'s source (the canonical `LENS_KEYS`
`phase-ratchet-ledger.mjs` actually imports) and asserts it matches this file's independently
duplicated `LENS_KEYS`.

### WR-04: A single malformed `raised_by` value in `candidates.ndjson` aborts verification of the entire batch

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`
**Commit:** `c22e105b`
**Applied fix:** `collapseByFindingId` now wraps each row's `lensKeyFor(row.raised_by)` call in
its own try/catch, skipping and logging (via `console.warn`) an offending row rather than
letting the exception propagate and abort the whole batch. If every row in a `finding_id`
group is malformed, that group is dropped (and logged) rather than emitted with an empty
`raised_by_lenses`. Added self-test case (c2): a batch containing one malformed row mixed into
an otherwise-valid 3-row shared group, plus a second finding_id whose entire group is malformed,
proves the function never throws, the fully-malformed group is dropped, the shared group's
valid rows still collapse correctly (`persona_frequency === 3`, unaffected by the bad 4th row),
and an unrelated distinct finding_id's group is untouched.

### WR-05: Inconsistent top-level error handling across the three CLI entry points

**Files modified:** `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs`,
`accrue_admin/e2e/ratchet/ratchet-verify.mjs`
**Commit:** `cf4887ef`
**Applied fix:** Wrapped both files' CLI entry points in the same clean-crash-message
try/catch already present in `scripts/ci/verify_ratchet_ledger.mjs`
(`console.error("<file> crashed: ${error.message}"); process.exitCode = 1;`).
`ratchet-verify.mjs`'s wrapper is placed around the bare `await main()` at end-of-file, which is
only ever reached past both the `--self-test` and no-API-key guards (both already
`process.exit(0)`), so it never affects self-test behavior. Verified functionally (not via the
self-test fixture, since this is an entry-point-level concern) by temporarily writing a
malformed row to the real (empty) `findings.ledger.ndjson`, confirming
`phase-ratchet-ledger.mjs` prints the clean `"phase-ratchet-ledger.mjs crashed: seq not
monotonic..."` message and exits 1 instead of a raw stack trace, then restoring the real ledger
via `git checkout --`.

### WR-06: `assertDimension()` (the closed 12-value dimension enum guard) is never invoked anywhere in the ledger/verify/gate chain

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`,
`accrue_admin/e2e/ratchet/ratchet-verify.mjs`
**Commit:** `856ba227`
**Applied fix:** `assertIdentity` (in `ratchet-ledger.js`) now calls
`assertDimension(row.dimension)` first, before deriving `claim_key`, so `appendOpen`/
`appendLifecycleEvent` reject a row with an out-of-range dimension even if its `claim_key`/
`finding_id` are internally self-consistent. `buildValidatedCandidateMap` (in
`ratchet-verify.mjs`) similarly calls `regionTags.assertDimension(candidate.dimension)` inside a
try/catch and drops (rather than indexes) a candidate whose dimension fails, matching that
function's existing "drop on identity defect" contract. Added self-test case (c3) in
`ratchet-ledger.js` (a self-consistent `dimension: 13` row is rejected by both `assertIdentity`
and `appendOpen`) and case (iv-a) in `ratchet-verify.mjs` (a self-consistent `dimension: 13`
candidate is dropped from `buildValidatedCandidateMap`'s index).

### IN-01: No file locking around ledger append — safe only under the current strictly-sequential single-process usage

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`
**Commit:** `4c01d7e4`
**Applied fix:** Documentation-only — added an explicit code comment above `nextSeq` stating
the load-bearing single-writer invariant (`ratchet-verify.mjs`'s sequential `for...of` loop,
never `Promise.all`), why it is currently race-free with no code-level lock, and what would need
to change (an `O_EXCL` lockfile) before parallel verification could be safely introduced.

### IN-02: `duplicate-of:<finding_id>` suppressed-reason suffix is never checked to reference a real, existing finding

**Files modified:** `accrue_admin/e2e/ratchet/ratchet-ledger.js`
**Commit:** `46cac320`
**Applied fix:** `isValidSuppressedReason` now validates the `duplicate-of:<suffix>` grammar
against `FINDING_ID_RE` (`/^f-[0-9a-f]{16}$/`) rather than accepting any non-empty suffix.
`appendSuppressed` additionally cross-checks, when the reason is `duplicate-of:`-shaped, that
the referenced `finding_id` actually exists among prior rows in the target `ledgerPath`,
throwing before appending if it does not (a dangling reference). Added self-test case (c4):
grammar rejects a free-text suffix and accepts a well-formed one; `appendSuppressed` rejects a
syntactically-valid-but-dangling reference (no row appended) and accepts a reference to a
finding_id that does exist in the same ledger.

## Skipped Issues

None — all findings were fixed.

---

_Fixed: 2026-07-04T22:10:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
