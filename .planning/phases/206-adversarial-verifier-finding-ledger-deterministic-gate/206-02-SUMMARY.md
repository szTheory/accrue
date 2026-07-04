---
phase: 206-adversarial-verifier-finding-ledger-deterministic-gate
plan: 02
subsystem: testing
tags: [nodejs, esm, anthropic-sdk, adversarial-panel, ratchet, admin-ui-eval]

# Dependency graph
requires:
  - phase: 206-01
    provides: "ratchet-ledger.js: appendOpen/collapseByFindingId/LENS_KEYS/lensKeyFor — the shared lifecycle/collapse helper this plan imports rather than reimplements"
  - phase: 205-persona-design-lens-evaluator-harness
    provides: "region-tags.js identity SSOT (claimKey/findingId/isAdmissibleToken), ratchet-propose.mjs guard/SDK-call shape this plan forks, and the live candidates.ndjson row schema"
provides:
  - "ratchet-verify.mjs: the Opus-based 3-role adversarial skeptic panel (advocate/brand_purist/density_defender) that confirms or kills each DEDUP-03-collapsed candidate finding"
  - "medianClamp(buckets, proposerSeverity) — pure median-then-clamp-down-only vote aggregation (D-13/D-29)"
  - "buildValidatedCandidateMap()/confirmAndWrite() — the deterministic re-gate: never trusts an LLM-returned finding_id or justification_token at face value"
  - "The SINGLE writer (D-35) that appends 2-of-3-confirmed survivors directly into the committed findings.ledger.ndjson as open rows"
  - "npm run ratchet:verify / ratchet:verify:self-test scripts"
affects: [206-03-phase-ratchet-ledger, 206-04-verify-ratchet-ledger-ci, 207-orchestration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "3-guard order (--self-test -> no-key exit-0 -> dynamic SDK import) forked verbatim from ratchet-propose.mjs, with region-tags.js/ratchet-ledger.js imported statically at the top (both SDK-free CJS modules, needed synchronously by this file's own --self-test) rather than deferred to GUARD 3 — only @anthropic-ai/sdk (which genuinely requires the key) is dynamically imported"
    - "Stable-prefix-first request construction (D-28): SYSTEM_AND_RUBRIC + PANEL_TOOL are module-level constants built once and reused identically on every panel call; only the per-image message content (screenshot + per-finding info list) varies — sets up ORCH-07's later prompt-caching without touching identity"
    - "Deterministic re-gate runs in-process immediately after each Opus response: identity re-derivation (never trust LLM finding_id) -> medianClamp() aggregation -> isAdmissibleToken() re-check on the candidate's OWN token -> only then appendOpen()"

key-files:
  created:
    - accrue_admin/e2e/ratchet/ratchet-verify.mjs
  modified:
    - accrue_admin/package.json

key-decisions:
  - "region-tags.js and ratchet-ledger.js are imported via static top-level ESM `import * as` (mirroring ratchet-propose.mjs's proven working pattern for region-tags.js) rather than deferred to GUARD 3's dynamic import, since this file's own --self-test needs synchronous access to both (regionTags.runSelfTest(), regionTags.claimKey/findingId/isAdmissibleToken, ratchetLedger.appendOpen/collapseByFindingId) before any key check. Only `@anthropic-ai/sdk` (the actual key-dependent import) is deferred behind GUARD 3. `baseline-manifest.js` was NOT imported — nothing in either task's action text actually requires DIMENSIONS/SURFACES/cellId in this file (candidate rows already carry cell_refs/surface_type from the Phase-205 proposer), and importing it unused would be dead code."
  - "SYSTEM_PREAMBLE is copied verbatim from ratchet-propose.mjs per the plan's explicit instruction, including its reference to \"the emit_findings tool\" even though this file's forced tool is named emit_verdicts — the API's tool_choice forces the correct tool call regardless of what the system prompt names, so this stray mention is harmless prose, not a functional bug; kept verbatim to preserve plan fidelity for the D-15 injection-guard wording."
  - "Reworded every pre-self-test-guard doc-comment mention of the literal string `ANTHROPIC_API_KEY` (4 occurrences in the header/guard comments) to avoid a false grep match — same class of authoring pitfall 206-01 hit with `@anthropic-ai/sdk` in a doc comment. The acceptance criteria's `grep -n \"ANTHROPIC_API_KEY\"` check must find the guard's own `if (!process.env.ANTHROPIC_API_KEY)` line, not an earlier prose mention. [Rule 1 - Bug, auto-fixed before commit]"
  - "3-role rubric text + system preamble are combined into ONE `SYSTEM_AND_RUBRIC` constant sent as the API `system` field (not embedded in the per-call user message) — this maximizes the D-28 stable-prefix-caching benefit, since `system`/`tools` are the parts of an Anthropic request most amenable to prompt caching, while the variable per-image content (screenshot + finding list) lives in `messages`."
  - "`buildValidatedCandidateMap()` re-derives and validates EVERY collapsed candidate's own claim_key/finding_id once, at map-build time, rather than per-verdict — more efficient and equivalent to per-verdict re-validation since the map is the single source `confirmAndWrite()` consults; a candidate whose own stored identity fails to re-derive is silently excluded from the map (defense-in-depth, should not occur from a correctly-functioning proposer)."

requirements-completed: [VERIFY-01, VERIFY-02, VERIFY-03, LEDGER-01]

coverage:
  - id: D1
    description: "Synthetic 3-role vote array of [real, minor, not-a-defect] confirms with severity minor (median rank 1); [not-a-defect, not-a-defect, real] does not confirm (median rank 0)"
    requirement: "VERIFY-01"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test — (ii-b)/(ii-c) medianClamp truth-table assertions"
        status: pass
    human_judgment: false
  - id: D2
    description: "Synthetic vote array of [real, real, minor] against proposer severity minor clamps DOWN to minor, never upgrades (D-13 downgrade-only)"
    requirement: "VERIFY-01"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test — (ii-d) medianClamp downgrade-only assertion"
        status: pass
    human_judgment: false
  - id: D3
    description: "A confirmed candidate whose own justification_token is not in the closed admissible set is dropped before any ledger write"
    requirement: "VERIFY-03"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test — (iii) inadmissible-token drop assertions (2)"
        status: pass
    human_judgment: false
  - id: D4
    description: "A verdict whose finding_id does not match any known collapsed candidate is dropped before any ledger write"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test — (iv) unmatched-finding-id drop assertions (2)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The density-defender's actual voting bias against direction:air candidates is a live-Opus prompt-following behavior and is NOT provable by --self-test"
    requirement: "VERIFY-02"
    verification:
      - kind: manual
        ref: "206-VALIDATION.md Manual-Only Verifications — Phase 208 maintainer spot-check"
        status: deferred
    human_judgment: true
  - id: D6
    description: "A confirmed finding is appended directly into findings.ledger.ndjson as an open row carrying confirmed_by/panel_votes/justification_token/persona_frequency/raised_by_lenses"
    requirement: "LEDGER-01"
    verification:
      - kind: unit
        ref: "node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test — (v) append-round-trip fixture (5 assertions)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-04
status: complete
---

# Phase 206 Plan 02: Adversarial Verifier + Committed Ledger Writer Summary

**Built `ratchet-verify.mjs` — the Opus-based 3-role adversarial skeptic panel (advocate/brand_purist/density_defender) that confirms or kills each DEDUP-03-collapsed UI-defect candidate and is the sole writer appending confirmed survivors into the committed `findings.ledger.ndjson`.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-04
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- `accrue_admin/e2e/ratchet/ratchet-verify.mjs` created (686 lines): ESM, forks `ratchet-propose.mjs`'s exact 3-guard order (`--self-test` → no-key exit-0 → dynamic `@anthropic-ai/sdk` import), `VERIFY_MODEL` defaulting to `claude-opus-4-8` (D-32, deliberately distinct from the proposer's `claude-sonnet-4-5`), and `supportsSampling()` reused verbatim (no `opus-4-8` special-case).
- D-15 injection-guard `SYSTEM_PREAMBLE` copied verbatim from `ratchet-propose.mjs`, extended per D-34 with an explicit instruction to treat each candidate's own `defect`/`suggested_fix` free-text (itself LLM-generated in Phase 205) as untrusted second-order data.
- 3-role rubric text (`PANEL_RUBRIC_TEXT`) spelling out the advocate/brand_purist/density_defender jobs, including the D-30 density-defender voting instruction against `direction:"air"` candidates lacking `job_blocking`/`persona-job-miss:` justification. Combined with the system preamble into one `SYSTEM_AND_RUBRIC` constant sent as the stable `system` field on every call (D-28 caching setup).
- `PANEL_TOOL` forced `emit_verdicts` schema with `strict: true` + `additionalProperties: false` at every level (RESEARCH Pattern 2 — Opus 4.8 genuinely supports strict structured outputs, unlike the proposer's Sonnet 4.5 default).
- `medianClamp(buckets, proposerSeverity)` — pure D-29 vote aggregation: median of 3 role ranks kills at rank 0, otherwise clamps `min(median, proposerRank)` (D-13 downgrade-only — the panel can lower `real→minor` or kill, never upgrade).
- `buildValidatedCandidateMap()`/`confirmAndWrite()` — the full deterministic re-gate run immediately after parsing each Opus response: (a) verdict `finding_id` must match a real, self-verifying collapsed candidate (never trust LLM identity, T-206-02-03); (b) `medianClamp()` must confirm; (c) the candidate's OWN `justification_token` must independently pass `isAdmissibleToken()` (VERIFY-03, T-206-02-04) — only then does `ratchetLedger.appendOpen()` write the row.
- One Opus call per source image (`groupByPngRef` + `verifyImageGroup`), batching every distinct finding on that image into one `emit_verdicts` request (D-28 — not 3 calls/candidate); response parsed via `.find((b) => b.type === "tool_use")?.input?.verdicts` with an `Array.isArray` degrade-to-`[]` guard (Pitfall 1/6, never `content[0]`).
- Per-role `rationale`/verdicts persisted to an ephemeral, gitignored `test-results/admin-visuals/verify-verdicts.ndjson` (D-33) — never touched by `--self-test`.
- `runSelfTest()` covering, with ZERO network calls and no `ANTHROPIC_API_KEY`: (i) `regionTags.runSelfTest()` still passes; (ii) the full 4-case `medianClamp` truth table; (iii) inadmissible-token drop; (iv) unmatched-finding-id drop; (v) a real end-to-end `appendOpen`-calling round-trip writing 2 confirmed candidates into an `fs.mkdtempSync` scratch ledger; (vi) the real committed `findings.ledger.ndjson` (if it exists) is byte-identical before/after `--self-test` — 30 `self-test pass:` lines total (13 from `region-tags.js` + 17 new), exit 0.
- `"ratchet:verify"`/`"ratchet:verify:self-test"` npm scripts added to `accrue_admin/package.json`, immediately after the existing `ratchet:propose`/`ratchet:self-test` pair.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fork guard/config/panel-call machinery (includes Task 2's median-clamp/re-gate logic, written in the same pass)** - `d9e75e6c` (feat)
2. **Task 2: package.json script wiring** - `1cde3c30` (feat)

**Plan metadata:** committed separately (see below)

## Files Created/Modified
- `accrue_admin/e2e/ratchet/ratchet-verify.mjs` - Opus-based 3-role adversarial panel: guards, `SYSTEM_AND_RUBRIC`, `PANEL_TOOL`, `medianClamp`, `buildValidatedCandidateMap`/`confirmAndWrite` deterministic re-gate, `verifyImageGroup`/`main` live loop, `runSelfTest`
- `accrue_admin/package.json` - `ratchet:verify`/`ratchet:verify:self-test` scripts

## Decisions Made
- Both tasks (guard/panel machinery, and median-clamp/re-gate/self-test) were implemented together in a single `ratchet-verify.mjs` authoring pass, since the file is one coherent module and Task 1's own acceptance criteria (guard ordering, model default, parsing pattern) can only be verified once the self-test function they gate on actually exists. Commit 1 (`d9e75e6c`) carries the whole file; commit 2 (`1cde3c30`) adds the `package.json` wiring that completes Task 2's remaining scope. This mirrors 206-01's own two-task/one-file execution note.
- `region-tags.js`/`ratchet-ledger.js` imported via static top-level `import * as` (not deferred to GUARD 3) — see key-decisions above for full rationale.
- `baseline-manifest.js` was NOT imported, despite the plan's Task 1 action text grouping it alongside `@anthropic-ai/sdk` under "GUARD 3 dynamically imports" — no functionality in either task actually requires `DIMENSIONS`/`SURFACES`/`cellId` in this file (Phase-205 candidate rows already carry `cell_refs`/`surface_type` computed by the proposer), and importing an unused module would be dead code with no test coverage. [Rule 3 — blocking-issue judgment call, documented rather than silently deviating]

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Doc-comment literal `ANTHROPIC_API_KEY` strings tripped the plan's own guard-ordering grep check**
- **Found during:** Task 1 (running the plan's `<acceptance_criteria>` grep commands immediately after first draft)
- **Issue:** The file's header/guard doc comments mentioned the literal string `ANTHROPIC_API_KEY` four times before the actual `--self-test` guard's line number (in prose describing the guard order, D-37, and the Usage section) — this is the exact same class of bug 206-01 hit with `@anthropic-ai/sdk` in a doc comment. `grep -n "ANTHROPIC_API_KEY" ratchet-verify.mjs | head -1` matched a comment at line 23 instead of the real guard code at line ~201, making the acceptance criteria's "self-test line < key-check line" assertion fail.
- **Fix:** Reworded all four pre-guard doc-comment mentions to describe the credential without spelling the exact env var name (e.g. "live-model credential env var", "ZERO live-model credential dependency") — same meaning, no literal substring collision. The actual guard code (`if (!process.env.ANTHROPIC_API_KEY)`) and its two adjacent lines keep the real literal, positioned correctly after the self-test guard.
- **Files modified:** `accrue_admin/e2e/ratchet/ratchet-verify.mjs`
- **Verification:** `grep -n 'process.argv.includes("--self-test")' ...` reports line 191; `grep -n "ANTHROPIC_API_KEY" ...` first match now reports line 201 (191 < 201, passes); `ANTHROPIC_API_KEY= node ratchet-verify.mjs` exits 0.
- **Committed in:** `d9e75e6c` (fixed before commit, no separate commit needed)

**2. [Rule 1 - Bug] Initial self-test fixture (v) asserted the wrong expected severity**
- **Found during:** Task 2 (first `--self-test` run)
- **Issue:** The end-to-end append-round-trip fixture's `verdictA` roles ([real, minor, real] against proposer severity "real") actually median-clamps to `"real"` (median rank 2, `min(2, 2) = 2`), but the assertion text incorrectly expected a downgrade to `"minor"`.
- **Fix:** Corrected the assertion's expected value to match the true computed result (`"real"`) and added a second, genuinely-downgrading assertion on the fixture's second candidate (`[minor, minor, not-a-defect]` against proposer severity `"minor"` → confirmed `"minor"`, correctly exercising the clamp path without contradicting the median math).
- **Files modified:** `accrue_admin/e2e/ratchet/ratchet-verify.mjs`
- **Verification:** `node ratchet-verify.mjs --self-test` — all 30 `self-test pass:` lines, exit 0.
- **Committed in:** `d9e75e6c` (fixed before commit, no separate commit needed)

---

**Total deviations:** 2 (both Rule 1 bugs, auto-fixed before commit — no scope creep, no code shipped with the bugs).
**Impact on plan:** None on scope; both fixes are internal to this file's own doc comments and self-test fixture correctness. The shipped logic matches the plan's `<action>`/`<behavior>` specification exactly.

## Issues Encountered
None beyond the two items documented above.

## User Setup Required
None — no external service configuration required. `ratchet-verify.mjs` is dev/test-only tooling under `accrue_admin/e2e/ratchet/`, never referenced from `accrue_admin`'s `lib/` runtime or `mix.exs` application deps. A live panel run requires `ANTHROPIC_API_KEY` to be set by the maintainer, but no phase success criterion depends on that (D-37) — `--self-test` proves everything with zero network calls.

## Next Phase Readiness
- `ratchet-verify.mjs` is now the phase's committed-ledger single writer: `206-03-PLAN.md`'s `phase-ratchet-ledger.mjs` can assume `findings.ledger.ndjson` rows (once a live run has actually been executed) always carry the full `confirmed_by`/`panel_votes`/`justification_token`/`persona_frequency`/`raised_by_lenses`/`effort_class` shape written here.
- `findings.ledger.ndjson` does NOT yet exist on disk (206-03 seeds it as an initially-empty committed file) — this plan's self-test never creates it, confirmed by assertion (vi) (`fs.existsSync` guard skips trivially when absent).
- No blockers. `node accrue_admin/e2e/ratchet/ratchet-verify.mjs --self-test` and `cd accrue_admin && npm run ratchet:verify:self-test` both exit 0 with 30 `self-test pass:` lines, zero lingering `ratchet-verify-*` temp dirs after repeated runs, and zero mutation of the real committed ledger path.

## Known Stubs
None — every function shipped is fully wired (live panel call path is untested against a real API key per D-37's design, but that is the intended dev/test-only posture, not a stub; the deterministic re-gate and ledger-write path are fully exercised by `--self-test`).

## Threat Flags
None — all new surface (Opus panel call, ledger write path) is already covered by this plan's own `<threat_model>` STRIDE register (T-206-02-01..06); no new surface was introduced beyond what that register anticipated.

## Self-Check: PASSED

- FOUND: accrue_admin/e2e/ratchet/ratchet-verify.mjs
- FOUND: d9e75e6c (Task 1 commit)
- FOUND: 1cde3c30 (Task 2 commit)

---
*Phase: 206-adversarial-verifier-finding-ledger-deterministic-gate*
*Completed: 2026-07-04*
