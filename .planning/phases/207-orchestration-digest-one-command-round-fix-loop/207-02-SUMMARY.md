---
phase: 207-orchestration-digest-one-command-round-fix-loop
plan: 02
subsystem: testing
tags: [ratchet, admin-ui, playwright, anthropic, prompt-caching, cache_control, esm]

# Dependency graph
requires:
  - phase: 205-persona-design-lens-evaluator-harness
    provides: "ratchet-propose.mjs proposer, region-tags.js identity SSOT, admin-visuals.spec.js capture, baseline-manifest.js SURFACES census"
  - phase: 206-adversarial-verifier-finding-ledger
    provides: "ratchet-verify.mjs panel + findings.ledger.ndjson + medianClamp deterministic re-gate"
provides:
  - "Exported SLICES map in baseline-manifest.js (single source of truth for --slice name resolution)"
  - "Shared RATCHET_SURFACES CSV filter across capture (admin-visuals.spec.js) and proposal (ratchet-propose.mjs discoverPngs)"
  - "Pure exported filterPngsBySurfaces() proven by key-free --self-test"
  - "cache_control ephemeral breakpoints on the stable prefix of proposer (persona + design) and verifier (panel) requests"
  - "buildPersonaRequest / buildDesignRequestPayload / buildPanelRequest pure request builders with in-file request-shape self-tests"
affects: [207-05-ui-round-mix-task, 208-prove-convergence-on-slice, ratchet-orchestration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure, hoisted, param-injected request builders callable from the key-free --self-test path before module-level consts initialize (TDZ-safe)"
    - "Single shared RATCHET_SURFACES CSV vocabulary read identically by the Playwright capture spec and the Node proposer"

key-files:
  created: []
  modified:
    - accrue_admin/e2e/baseline-manifest.js
    - accrue_admin/e2e/admin-visuals.spec.js
    - accrue_admin/e2e/ratchet/ratchet-propose.mjs
    - accrue_admin/e2e/ratchet/ratchet-verify.mjs

key-decisions:
  - "Request builders take systemPreamble/toolSchema as explicit params (not closure) so the --self-test can call them before SYSTEM_PREAMBLE const initializes — keeps the mandated self-test-first guard order intact without a TDZ ReferenceError"
  - "Design-lens image breakpoint added non-mutatively via content.map (spread on index 0) rather than mutating the pre-built designContent array"

patterns-established:
  - "Pattern: cache_control ephemeral on exactly 3 stable-prefix positions (system text block, tools[0], first/image content block) and never on per-call variable text — asserted by an in-file request-shape self-test"
  - "Pattern: filterPngsBySurfaces returns the input array unchanged (identity) when the CSV is falsy/empty; unknown names silently match nothing (never expand scope)"

requirements-completed: [ORCH-07, ORCH-08]

coverage:
  - id: D1
    description: "SLICES map exported from baseline-manifest.js with the foundation slice = [component-kitchen, dashboard, subscription-detail, subscriptions]"
    requirement: "ORCH-08"
    verification:
      - kind: automated
        ref: "node -e \"console.log(JSON.stringify(require('./accrue_admin/e2e/baseline-manifest.js').SLICES))\""
        status: pass
    human_judgment: false
  - id: D2
    description: "RATCHET_SURFACES CSV filter narrows admin-visuals.spec.js capture and ratchet-propose.mjs discoverPngs to the listed surfaces; unset = full list unchanged"
    requirement: "ORCH-08"
    verification:
      - kind: unit
        ref: "accrue_admin/e2e/ratchet/ratchet-propose.mjs --self-test (A-a..A-d filterPngsBySurfaces)"
        status: pass
      - kind: automated_ui
        ref: "RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js (documented manual check — requires e2e server)"
        status: unknown
    human_judgment: false
  - id: D3
    description: "cache_control ephemeral breakpoints on proposer persona + design request stable prefixes (3 each), verifier panel request stable prefix (3), none on variable text"
    requirement: "ORCH-07"
    verification:
      - kind: unit
        ref: "ratchet-propose.mjs --self-test (B-persona, B-design) + ratchet-verify.mjs --self-test (viii)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Live cache-hit proof — usage.cache_read_input_tokens rises on the second identical proposer run"
    verification:
      - kind: manual_procedural
        ref: "ANTHROPIC_API_KEY=... npm run ratchet:propose twice against unchanged PNGs, diff usage.cache_read_input_tokens (documented smoke, never a CI gate per VALIDATION.md)"
        status: unknown
    human_judgment: true
    rationale: "Requires a live ANTHROPIC_API_KEY and real API round-trips; per VALIDATION.md this cache-hit claim stays a documented manual smoke, never a gate path. Not reproducible key-free."

# Metrics
duration: 3min
completed: 2026-07-05
status: complete
---

# Phase 207 Plan 02: RATCHET_SURFACES filter + cache_control breakpoints Summary

**Shared `RATCHET_SURFACES` CSV/slice filter threaded through capture + proposer PNG discovery (backed by an exported `SLICES` map), plus Anthropic prompt-caching `cache_control` breakpoints on the proposer and verifier stable request prefixes — both proven by key-free self-tests with zero reordering of request fields.**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-07-05T00:20:52Z
- **Completed:** 2026-07-05T00:24Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added an exported `SLICES` map to `baseline-manifest.js` (`foundation` slice) as the single source of truth 207-05's `ui.round` mirrors for `--slice` resolution.
- Threaded one shared `RATCHET_SURFACES` env-var CSV filter through both the Playwright capture spec (`admin-visuals.spec.js`, inline in the test body) and the proposer's `discoverPngs()` via a pure, exported, self-tested `filterPngsBySurfaces()` — eliminating the `test-results/` hand-pruning footgun.
- Added three `cache_control:{type:"ephemeral"}` breakpoints (system text block, `tools[0]`, image content block) to the proposer's persona and design requests and the verifier's panel request, refactored into pure builder functions, with no field or content-block reordering (RESEARCH confirmed the image is already first).
- Extended both scripts' key-free `--self-test` paths with request-shape assertions proving exactly 3 breakpoints and none on the per-call variable text; guard order (self-test → no-key → SDK import) unchanged.

## Task Commits

1. **Task 1: SLICES export + RATCHET_SURFACES filter in capture and proposer PNG discovery** - `9dfed722` (feat)
2. **Task 2: cache_control breakpoints on the proposer and verifier stable prefixes** - `9bdacbb1` (feat)

## Files Created/Modified
- `accrue_admin/e2e/baseline-manifest.js` - Added exported `SLICES` map (foundation slice) beside `SURFACES`.
- `accrue_admin/e2e/admin-visuals.spec.js` - Inline `RATCHET_SURFACES` CSV filter on `shots` in the capture test body (`selectedShots`), leaving `shots` untouched.
- `accrue_admin/e2e/ratchet/ratchet-propose.mjs` - Pure exported `filterPngsBySurfaces()` called in `discoverPngs()`; `buildPersonaRequest`/`buildDesignRequestPayload` builders with cache_control breakpoints; extended `runProposeSelfTest()` (blocks A + B).
- `accrue_admin/e2e/ratchet/ratchet-verify.mjs` - `buildPanelRequest()` builder with cache_control breakpoints; extended `runSelfTest()` (block viii).

## Decisions Made
- Request builders receive `systemPreamble`/`toolSchema` as explicit parameters rather than closing over module-level consts. This is required because the mandated `--self-test`-first guard runs before `const SYSTEM_PREAMBLE` initializes; a closure would hit a temporal-dead-zone `ReferenceError` when the self-test calls the builder. Passing params keeps the builders pure and TDZ-safe while preserving the exact guard ordering the plan requires. (The plan's `buildPersonaRequest(model, toolSchema, b64, persona)` signature is illustrative — "e.g." — so adding the preamble param is within scope.)
- The design-lens image breakpoint is applied via `content.map` (spread on index 0) so the pre-built `designContent` array is not mutated.

## Deviations from Plan
None - plan executed exactly as written. (The extra `systemPreamble` builder parameter is a param-shape choice under the plan's own "e.g." signature guidance, not a behavior deviation; identity, the no-key exit-0 path, and the `--self-test`/no-key/SDK-import guard order are all unchanged.)

## Issues Encountered
None. The initial SLICES export smoke printed a MODULE_NOT_FOUND only because it was run with a repo-root-relative `require` path from inside `accrue_admin/`; re-running from the repo root printed the expected `foundation` slice.

## Manual Live Smoke (ORCH-07, documented — NOT a CI gate)
Per VALIDATION.md, the cache-hit claim stays a documented manual smoke: run `ANTHROPIC_API_KEY=... npm run ratchet:propose` twice in a row against unchanged PNGs and diff `usage.cache_read_input_tokens` in the API response between runs — the second run should report a non-zero `cache_read_input_tokens` on the stable system+schema+image prefix. This was not executed here (no live key in the execution environment) and is recorded as the manual proof path, never a gate.

## User Setup Required
None - no external service configuration required. (The live cache-hit smoke above optionally needs a maintainer-supplied `ANTHROPIC_API_KEY`, local-only.)

## Next Phase Readiness
- `SLICES` + `RATCHET_SURFACES` are ready for 207-05's `ui.round` mix task to mirror for `--slice` name resolution.
- Prompt-caching breakpoints are live on both LLM planes with identity, no-key, and self-test paths provably unchanged.
- No blockers.

---
*Phase: 207-orchestration-digest-one-command-round-fix-loop*
*Completed: 2026-07-05*

## Self-Check: PASSED
- All 4 modified files present on disk.
- Both task commits (`9dfed722`, `9bdacbb1`) present in git history.
- Both `--self-test` suites green key-free (exit 0); grep cache_control counts 19 (propose) / 15 (verify), both above the 6/3 minimums.
