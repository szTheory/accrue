# Phase 207: Orchestration + digest + one-command round/fix loop - Research

**Researched:** 2026-07-04
**Domain:** Elixir Mix-task orchestration over existing Node/Playwright tooling; Anthropic prompt-caching; self-contained HTML artifact generation
**Confidence:** HIGH (every claim below is grounded in a direct file read of the actual repo state, not training knowledge, except the Anthropic `cache_control` API shape which is CITED from the bundled `claude-api` skill reference)

## Summary

Phase 207 is a pure integration phase: every piece it needs to orchestrate already exists and works (Phase 205/206 shipped and are fully tested). Nothing here requires new npm/hex packages. The job is: (1) write two thin Elixir Mix tasks that shell out to the existing node/npm/playwright commands in the right order, twinning `accrue_admin.assets.build.ex`'s `Runner` behaviour exactly; (2) add net-new logic to the existing node reducer (`phase-ratchet-ledger.mjs`) for round-seal + dry-round + convergence — **this logic does not exist yet, at all**, confirmed by reading the file in full; (3) write a brand-new `ratchet-digest.mjs` (no literal HTML precedent in-repo — twin `phase192-gallery.mjs`'s *structural* idiom only); (4) add `cache_control` breakpoints to two existing request-builder functions in `ratchet-propose.mjs`/`ratchet-verify.mjs` — the code shape already puts the image as the first content block and the system/tools already precede messages, so **no reordering is required**, matching D-57's explicit claim; (5) add a `RATCHET_SURFACES` filter to `admin-visuals.spec.js`'s inline `shots` array and to `ratchet-propose.mjs`'s `discoverPngs()`.

**Primary recommendation:** Do not re-derive any design decision from CONTEXT.md — every one of them is directly executable against the real code with no adaptation needed except for two genuine integration gaps this research surfaced: (a) the `test-results/ui-ratchet/round-NN/` artifact-directory convention CONTEXT.md/UI-SPEC assume does not exist anywhere in the codebase today — capture/candidates/verdicts currently live flat under `test-results/admin-visuals/`, and (b) the digest's overlay-scale math (`renderedWidth / project.viewport_width`) is specified against `baseline-manifest.js`'s declared `PROJECTS` widths (1440/390), which do **not** match the actual Playwright capture viewports (1280/393) — see Risks below.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Phase Boundary.** Phase 207 delivers the orchestration + digest + one-command round/fix loop of the UI ratchet — the maintainer-facing driver that wraps Phase 205's proposer and Phase 206's verifier/ledger/gate into **two `mix accrue_admin.ui.*` commands** with a rendered HTML digest, minimal batch-approve checkpoints, auto-minted deterministic guards, prompt-caching, a surface-subset filter, and **guaranteed termination**. Requirements: ORCH-01..08 (8 of 8 for this phase).

**In scope:** `mix accrue_admin.ui.round` (build→boot admin(4017)→seed→capture→fan-out evaluators→dedup→verify→rank→render digest→append machine-confirmed survivors as `open`→seal the round marker, ORCH-01); `mix accrue_admin.ui.fix` (apply approved batch→`assets.build`→commit CSS bundle+source→re-capture→re-score→advance `open→resolved→verified-closed`→auto-mint one deterministic guard per resolved finding, ORCH-04/ORCH-05); the rendered HTML digest (`ratchet-digest.mjs`, twins `phase192-gallery.mjs`): screenshots grouped by surface with region overlays, a ranked worklist, a separate "Decisions needed" queue, a summary banner (ORCH-02); the batch-approve/reject-to-suppress checkpoint via a pre-filled transient `decisions.json` (ORCH-03); the auto-mint guard producer (typed data-row into an existing home spec) (ORCH-05); convergence+hard-cap orchestration: K=2 consecutive dry rounds → `CONVERGED`; 6-round cap escalates (ORCH-06), tracked in a new committed append-only `rounds.ndjson`; prompt caching (`cache_control`) on the stable prefix of `ratchet-propose.mjs` + `ratchet-verify.mjs` (ORCH-07); the surface/slice subset filter (`--slice`/`--surface`) threading through capture + fan-out via a shared `RATCHET_SURFACES` env, with the slice list defined once in `baseline-manifest.js` (ORCH-08).

**Out of scope (later phases):** running the loop to convergence on the representative slice, FREEZING the first non-empty `ledger.baseline.json` (208-only, `--freeze` flag), wiring the `admin-ui-ratchet-guardrails` deterministic CI job, maintainer ACCEPT+runbook (Phase 208, CONV-01..07); full ~19-surface sweep (Phase 209, optional, SWEEP-01).

**Invariants (carried from 205/206, non-negotiable):** the LLM never gates CI and is never on the guard-mint or gate path; identity (`claim_key`/`finding_id`) is always re-derived deterministically via `region-tags.js`, never trusted from the LLM; convergence/dry-round is computed deterministically by the self-tested node reducer, never by Elixir and never by the LLM; capture always follows `mix accrue_admin.assets.build` (committed-CSS discipline); all tooling is dev/test-only and never leaks into adopter runtime; no new billing primitives, no route/API changes, no Tailwind migration; core `accrue` stays LiveView-runtime-free; `ax-*` stays the styling SSOT.

**D-42 — File-driven, pre-filled `decisions.json` (transient input; the committed ledger is the durable record).** `ui.round` writes `test-results/ui-ratchet/round-NN/decisions.json` — gitignored (already covered by `test-results/`), deliberately a transient input. Every auto-fixable confirmed finding is pre-filled `"decision": "approve"`, so batch-approve is the zero-edit path: just run `mix accrue_admin.ui.fix`. Format is JSON (matches `export_copy_strings` → Jason). Each row carries human-readable context (`surface`, one-line `summary`, `region_tag`) beside the opaque `finding_id`. The durable, PR-reviewable record is the `suppress`/`resolve` event appended to the committed `findings.ledger.ndjson` — no second drift-prone audit artifact. This is the repo idiom: `ui.round` writes, `ui.fix` reads, both pure `File`/`OptionParser`, TTY-free (twins the phase200 file-artifact handoff). Rejected as anti-idiom: interactive stdin prompts; HTML-form writeback.

**D-43 — Reject requires a closed-enum reason; `ui.fix` refuses silent/invalid bypass.** Flip a row to `"decision": "reject"` and set `"suppressed_reason"` (validated against the locked enum `wont-fix-intentional | duplicate-of:<id> | out-of-scope | false-positive | accepted-residual | wont-fix-cost`, D-41) + optional `"suppressed_note"`. `ui.fix` `Mix.raise`s on any missing/invalid reason. A loud pre-apply banner (`Applying N fixes, M suppressions:` with reason breakdown) + `--dry-run` guards the "silent mass-approve" footgun. Suppress rows fold into the dedup suppress-list so the next round's proposer drops them before they re-enter as `open`.

**D-44 — The generator emits a typed DATA ROW (not a code block); assertion LOGIC is a single human-written, once-reviewed loop.** `ui.fix` appends one typed row per resolved finding into a delimited marker region of the kind-appropriate existing home spec; a human-authored loop test iterates the table and applies the right computed-style helper. Values are derived from the freshly re-captured post-fix DOM/CSS, never guessed. Rejected: full free-form assertion synthesis per finding; per-finding hand-authoring.

**D-45 — Assert the invariant, not the pixel; route by defect kind.** design-token bypass → `computed == resolved(var(--ax-…))`; contrast → `contrastRatio(fg,bg) >= <WCAG floor the fix achieved>`; spacing/scale → computed value ∈ `ax-space-*` scale-step set (membership); microcopy → DOM text contains corrected string / not the old string; focus-ring/z-layer/reduced-motion → boolean/threshold. Real-synth kinds: design-token, contrast, spacing/scale, microcopy, focus/overlay/motion. `ledger-count` sentinel kinds (D-40): hierarchy/visual-weight, brand-tier gestalt, density-balance, responsive-composition, and anything `effort_class: ia-product-decision`.

**D-46 — Idempotent, append-only, existing-homes-only; two-layer CI reconciles safety.** Key by `finding_id`: grep the target spec for `@ratchet:f-<id>` before appending → no-op if present. Insert only inside a delimited region (e.g. `// >>> @ratchet:auto-guards >>> … // <<< @ratchet:auto-guards <<<`), rows sorted by `finding_id` → deterministic, merge-friendly diffs. The `@ratchet:f-<id>` token lives in the row so the static substring gate sees it. Never create a new file: `GUARD_HOME_SPECS` is a closed constant duplicated in `phase-ratchet-ledger.mjs` + `verify_ratchet_ledger.mjs` with a byte-identical drift self-test; extending it is a deliberate separate PR, not a mint side-effect. Two-layer CI: (1) the ratchet's own deterministic gate proves the guard token is present (fast, substring-only, no browser); (2) the guard-home specs already run in the existing admin e2e Playwright job, which executes the loop and gives assertions teeth. Accepted residual risk: the ratchet gate is substring-only.

**D-47 — Round state = a NEW committed, append-only `rounds.ndjson` (sibling to `reopen-markers.ndjson`).** One row per round: `{round, dry, epoch, scope, bundle_sha256, seq}`. Counter = `max(round)`; consecutive-dry = trailing run of `dry:true` within the current baseline epoch. Round artifacts (digest.html, candidates, verdicts, PNGs) stay gitignored under `test-results/ui-ratchet/round-NN/`. This new file is required because dry-ness is genuinely underivable from the finding ledger, and deriving from gitignored `round-NN` dirs would be non-reproducible on a fresh clone/CI.

**D-48 — A round is DRY iff a 4-clause conjunction holds (deterministic reducer, no LLM):** (1) `ui.round` appended zero new `open` rows for this round, AND (2) zero `open` findings remain in the ledger fold (subsumes "no pending-approved fixes"), AND (3) both `finding-regressions.ndjson` and `regressions.ndjson` are 0 bytes, AND (4) all slice cells ≥ 2 (coverage floor, scoped by the active subset filter). All four inputs are committed files diffed by the self-tested node reducer.

**D-49 — K=2 consecutive dry → `CONVERGED`; 6th round without convergence → unmissable escalation.** The round counter increments on each `ui.round` (the measurement step seals the `rounds.ndjson` marker; `ui.fix` does not seal a round). `CONVERGED` exits 0 with a "run sign-off" message. At the 6th round without convergence: (a) digest banner `CAP REACHED — 6 rounds, N open, not converged`, (b) a terminal message naming the exact next action, and (c) a non-zero exit (`System.halt(2)`/`Mix.raise`).

**D-50 — `ui.round` and `ui.fix` stay TWO separate manual commands (Terraform plan/apply split).** `ui.round` (measurement, read-only w.r.t. source): the verifier is the sole writer of `open`; it does NOT apply fixes, edit CSS/source, mint guards, commit code, or move any baseline. `ui.fix` (mutation): applies the approved batch, rebuilds+commits CSS+source, re-captures/re-scores, advances `open→resolved→verified-closed`, mints guards; it does NOT propose net-new findings, seal a round marker, or write a frozen baseline.

**D-51 — Mix tasks are thin orchestrators; ALL file-reasoning lives in the node reducer.** Both tasks mirror `accrue_admin.assets.build.ex`: sequenced `System.cmd` steps via a swappable `Runner` behaviour (`Application.get_env(:accrue_admin, key, ShellRunner)`) for CI-safe testability, `Mix.raise` on non-zero, reimplement nothing in Elixir. Dry detection, the round counter, and the round-seal computation all live in the node reducer (`phase-ratchet-ledger.mjs`); Mix merely invokes `node`/`npm run`/`npx playwright`.

**D-52 — `--slice <name>` named preset + `--surface=a,b,c` CSV, resolved to a shared `RATCHET_SURFACES` env read by BOTH the capture spec and the proposer.** The mix task is the single resolution point: it expands `--slice foundation` (bare `--slice` = the default representative slice) or `--surface=dashboard` into `RATCHET_SURFACES=<csv>`; the capture spec (`admin-visuals.spec.js`) filters its `shots` array by name, and the proposer (`ratchet-propose.mjs`) filters discovered PNGs by `png.screen`. Unset = the full configured surface set. Capture only shoots the subset. The slice list is defined once as an exported `SLICES` map in `baseline-manifest.js` beside `SURFACES`. Rejected: Playwright `--grep`/`--project`; freeform glob/regex.

**D-53 — Digest = a new Node `ratchet-digest.mjs` twinning `phase192-gallery.mjs`.** Self-contained HTML, inline CSS, no external deps, row-builder + validator + `--self-test`; emits `test-results/ui-ratchet/round-NN/digest.html`; invoked by `ui.round`. Opens locally/offline, regenerable, CI-checkable via its self-test. Borrow the Playwright-reporter ideas (grouping, overlays, self-contained), not the tool.

**D-54 — "Decisions needed" predicate is deterministic: `effort_class === "ia-product-decision"` → decision queue; else (`"css"` | `null`) → auto-fixable worklist.** `effort_class` is set on the ledger row from `candidate.effort_hint` (`ratchet-ledger.js`/`ratchet-verify.mjs`), whose schema enum is `["css","ia-product-decision"]` (`ratchet-propose.mjs`), defaulting `null`. Pure equality on a closed enum — no model call.

**D-55 — Region overlay = draw from the Phase 205 `.bbox.json` sidecar.** For each confirmed finding, read `${surface}${theme==="dark"?"-dark":""}.bbox.json` in the capture dir, look up `bbox[region_tag]` (the D-09 capture-time `boundingBox()`), and draw an absolutely-positioned outline `<div>` over the embedded screenshot, scaling capture-viewport CSS px to the rendered `<img>` width (`scale = renderedWidth / project.viewport_width`; 1440 desktop / 390 mobile from `baseline-manifest.js` — **see Common Pitfalls Pitfall 2 for a verified discrepancy with the actual capture viewport**). A `null` box (selector absent on that surface) → no box; label the finding against the surface header instead.

**D-56 — Deterministic ranking + brand-aligned, accessible layout.** Worklist sort key: `severity` asc (real→0, minor→1), then `persona_frequency` desc, then `effort_class` asc (css→0, null→1; cheap wins first), then `finding_id` asc (stable tiebreak). Decisions-needed queue: `severity`, `persona_frequency` desc, `finding_id`. All fields on the ledger row — zero non-determinism. Layout: sticky summary banner → Worklist → Decisions needed (distinct accent, 0–2 forks) → gallery grouped by surface with region overlays. Brand tokens from the CURRENT `brandbook/index.html` (Geist sans; mono for `finding_id`/`claim_key`/`region_tag`; restrained neutral palette). Semantic HTML; honor `prefers-color-scheme`; encode severity with text + shape, not color alone; overlay = 2px accent outline + small label chip, never a fill.

**D-57 — Add `cache_control:{type:"ephemeral"}` breakpoints on the stable prefix; NO reorder required.** In `ratchet-propose.mjs` (mirrored in `ratchet-verify.mjs`): convert the `system` string → blocks with a cache breakpoint, add a breakpoint on the last `tools` entry, and add a breakpoint on the per-screenshot target-image block. The API caches the linear `tools → system → messages` prefix, so this caches schema + system + screenshot for all 7 calls with no reordering (the target image is already the first content block). Per-persona prompt + per-candidate content stay uncached after the breakpoint. Invariants preserved: identity is re-derived by `region-tags.js` and is order/cache-independent; the three guards (`--self-test` → no-key exit-0 → SDK import) run before any request is built.

### Claude's Discretion

- `rounds.ndjson` as a separate sibling file vs folded into `findings.ledger.ndjson` as `round_sealed` events — chose SEPARATE (keeps the finding reducer's fold pure; mirrors the `reopen-markers.ndjson` precedent). Single mildly-hard-to-reverse committed-schema choice.
- ORCH-07 exemplar-first reorder (max savings) — deferred as a cheap, reversible same-phase follow-on toggle: additionally move the two design-lens exemplar images ahead of the target image in `buildDesignContent` + breakpoint after them, so the exemplar pair caches across every screenshot of a `surface_type` within the 5-min ephemeral window. Ship D-57's "no-reorder" baseline first; planner may fold it in if cheap.
- Exact `decisions.json` field ordering; whether `ui.fix` adds an optional aggregate TTY `yes?` (skipped non-TTY) on top of the file-edit consent; exact delimited-marker syntax for the auto-guard region; exact `bundle_sha256` capture point in `rounds.ndjson`; whether the digest embeds screenshots as `data:` URIs or relative `round-NN/` paths (UI-SPEC resolves this: relative paths, not `data:` URIs); precise banner copy.

### Deferred Ideas (OUT OF SCOPE)

- Run the loop to CONVERGENCE on the representative slice; FREEZE the first non-empty `ledger.baseline.json` (via `--freeze`); wire the `admin-ui-ratchet-guardrails` deterministic CI job; maintainer ACCEPT + runbook — Phase 208 (CONV-01..07). 207 delivers the machinery + convergence DETECTION; 208 proves + freezes + gates.
- Full ~19-surface sweep — Phase 209 (optional/scope-gated, SWEEP-01).
- ORCH-07 exemplar-first reorder for cross-screenshot exemplar caching — a cheap, reversible same-phase follow-on toggle on top of D-57's no-reorder baseline; planner may fold it in.

No scope creep surfaced — discussion stayed within the phase boundary.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ORCH-01 | Single `mix accrue_admin.ui.round` command drives build→boot→seed→capture→fan-out→dedup→verify→rank→digest | `accrue_admin.assets.build.ex` Runner idiom to twin; Playwright's own `webServer` contract already boots+seeds — no separate System.cmd server-boot step needed (see Architecture Patterns) |
| ORCH-02 | Rendered HTML digest, grouped by surface, region overlays, worklist + decisions-needed queue | `phase192-gallery.mjs` structural idiom (row-builder + validator + `--self-test`); `.bbox.json` shape confirmed from `admin-visuals.spec.js`; UI-SPEC is the executor's binding visual reference |
| ORCH-03 | Batch-approve / reject-with-reason checkpoint via `decisions.json` | `accrue_admin.export_copy_strings.ex`'s `OptionParser` + `File`/`Jason` idiom to twin; `ratchet-ledger.js`'s `appendSuppressed`/`SUPPRESSED_REASONS` already enforce the closed reason enum |
| ORCH-04 | `mix accrue_admin.ui.fix` applies batch, rebuilds+commits CSS, re-captures/re-scores, updates ledger | `accrue_admin.assets.build.ex` reused directly as a sub-step; `ratchetLedger.appendResolved`/`appendVerifiedClosed` already exist and are legal-transition-checked |
| ORCH-05 | Auto-mint deterministic guard per resolved finding | `checkGuardRef`/`GUARD_HOME_SPECS`/token grammar already fully implemented in `phase-ratchet-ledger.mjs` and duplicated in `scripts/ci/verify_ratchet_ledger.mjs`; **no delimited marker region exists yet in any of the 4 guard-home spec files** — genuine new-territory bootstrap (see Risks) |
| ORCH-06 | K=2 dry-round convergence + 6-round hard cap | **Net-new logic** — `phase-ratchet-ledger.mjs` has zero round/dry/convergence concept today; must be added alongside a new `rounds.ndjson` |
| ORCH-07 | `cache_control` prompt caching, no reorder | Confirmed: `ratchet-propose.mjs`/`ratchet-verify.mjs` already put the image as the first message-content block, and `system`/`tools` are already request-level fields preceding `messages` — the D-57 no-reorder claim holds exactly |
| ORCH-08 | `RATCHET_SURFACES` filter | `discoverPngs()` in `ratchet-propose.mjs` and the inline `shots` array in `admin-visuals.spec.js` are the two (and only two) insertion points; `ratchet-verify.mjs` needs no filter (naturally scoped by `candidates.ndjson` content) |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Round/fix orchestration (`mix accrue_admin.ui.*`) | Backend (Mix task, thin) | — | Elixir only sequences `System.cmd`; owns zero business logic (D-51) |
| Asset build, admin boot, capture, seed | Backend (Mix task) / Browser (Playwright) | — | `mix accrue_admin.assets.build` + `npx playwright test` — Playwright's own `webServer` config boots the Phoenix admin server, no separate manual boot step |
| Proposer/verifier LLM calls | External service (Anthropic API) via Node script | — | `ratchet-propose.mjs`/`ratchet-verify.mjs` — never invoked from Elixir, never in CI |
| Ledger fold, dry-round/convergence computation, guard-ref check | Backend (Node reducer, deterministic) | — | `phase-ratchet-ledger.mjs` — explicitly the ONLY place file-reasoning/convergence logic lives (D-51); Elixir never re-implements |
| Digest rendering | Backend (Node script → static HTML artifact) | Browser (the artifact itself, opened locally) | `ratchet-digest.mjs` generates; a human opens the resulting static file in a browser — no server involved |
| Batch-approve/reject checkpoint | Backend (Node/Elixir via flat JSON file) | — | `decisions.json` — file-driven, TTY-free; `ui.round` writes, `ui.fix` reads |
| Guard-mint (auto-generated assertion data rows) | Backend (Node script writes) / Test tier (Playwright executes) | — | Data row minted by `ui.fix`; assertion *logic* lives in the 4 existing `.spec.js` guard-home files, executed by the existing Playwright job |

## Standard Stack

No new external dependencies are required for this phase. All required libraries are already present and pinned:

| Library | Version (verified) | Purpose | Where used |
|---------|---------------------|---------|------------|
| `@anthropic-ai/sdk` | `^0.100.1` (in `accrue_admin/package.json`) [VERIFIED: repo file read] | Cache-control-capable Anthropic client, already imported dynamically in `ratchet-propose.mjs`/`ratchet-verify.mjs` | Node scripts (unchanged import) |
| `@playwright/test` | `^1.57.0` [VERIFIED: repo file read] | Capture spec + `webServer` boot | `admin-visuals.spec.js`, `playwright.config.js` |
| Elixir `Mix.Task` / `System.cmd` | project floor (Elixir 1.17+) | Orchestration | new `accrue_admin.ui.round.ex` / `.ui.fix.ex` |
| `Jason` | already a core dep (CLAUDE.md) | `decisions.json` read/write | new mix tasks, mirroring `accrue_admin.export_copy_strings.ex` |

**Version verification:** `npm view @anthropic-ai/sdk version` was not run live (offline research), but the installed `package.json` pin (`^0.100.1`) is well past the version that introduced `cache_control` (a long-GA, non-beta feature per the bundled Anthropic API reference) — no upgrade needed. [ASSUMED: no live `npm view` was executed this session; the installed pin is read directly from the committed `package.json`, which is authoritative for "what this repo currently has," so this is `[VERIFIED: repo file]` for the version itself, but the claim "this version supports cache_control" is `[CITED: bundled claude-api skill reference]`, not independently confirmed against the npm registry changelog.]

### Alternatives Considered

Not applicable — this phase adds zero new packages. Every "alternative" is a design-pattern choice already locked in CONTEXT.md (D-42..D-57).

**Installation:** none required.

## Package Legitimacy Audit

Not applicable — no external packages are added, upgraded, or newly declared in this phase. `GUARD_HOME_SPECS`, `RATCHET_SURFACES`, and `rounds.ndjson` are code/data additions to already-vetted, already-committed files.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────────────────────┐
                         │  mix accrue_admin.ui.round  (Elixir, thin)   │
                         └───────────────────┬───────────────────────────┘
                                             │ System.cmd, sequenced, Runner-swappable
              ┌──────────────────────────────┼──────────────────────────────────────┐
              ▼                              ▼                                      ▼
  mix accrue_admin.assets.build   npx playwright test admin-visuals.spec.js   node phase-ratchet-ledger.mjs
  (rebuild CSS/JS bundle)         (webServer boots MIX_ENV=test admin,        (NEW: round-seal + dry/converge
                                   seeds via /__e2e__/*, captures PNGs        computation, appended here)
                                   + .bbox.json, honors RATCHET_SURFACES)
                                             │
                                             ▼
                          RATCHET_ROUND=<N> node ratchet-propose.mjs
                          (discoverPngs() filtered by RATCHET_SURFACES;
                           7 calls/screenshot: 6 persona + 1 design lens;
                           cache_control on system/tools/image block;
                           writes candidates.ndjson)
                                             │
                                             ▼
                          node ratchet-verify.mjs
                          (1 call/image, batches all candidates on that
                           image; cache_control mirrored; median-clamp
                           2-of-3 confirm; appendOpen() → open rows)
                                             │
                                             ▼
                     accrue_admin/e2e/ratchet/findings.ledger.ndjson
                     (committed, append-only — the durable identity/lifecycle store)
                                             │
                              ┌──────────────┴───────────────┐
                              ▼                               ▼
              phase-ratchet-ledger.mjs (existing)     node ratchet-digest.mjs (NEW)
              recompute confirmed_open, regressions,   reads ledger + rounds.ndjson + .bbox.json;
              guard_ref checks, NEW round-seal/dry     ranks (D-56); renders worklist +
              → writes finding-regressions.ndjson,      decisions-needed + gallery-with-overlays;
                ledger.baseline.json (unfrozen),        writes digest.html + pre-filled decisions.json
                rounds.ndjson (NEW)
                                             │
                                             ▼
                              maintainer opens digest.html, edits
                              decisions.json (approve/reject+reason)
                                             │
                                             ▼
                         mix accrue_admin.ui.fix  (Elixir, thin)
              apply approved batch → mix accrue_admin.assets.build →
              git commit CSS+source → re-capture (playwright) → re-verify/rescore →
              ratchetLedger.appendResolved/appendVerifiedClosed →
              mint guard-token data rows into the 4 GUARD_HOME_SPECS files
```

### Recommended Project Structure

```
accrue_admin/
├── lib/mix/tasks/
│   ├── accrue_admin.ui.round.ex     # NEW — twin of assets.build.ex's Runner idiom
│   └── accrue_admin.ui.fix.ex       # NEW — same idiom, mutation phase
├── e2e/
│   ├── admin-visuals.spec.js         # MODIFIED — add RATCHET_SURFACES filter to `shots`
│   ├── baseline-manifest.js          # MODIFIED — add exported `SLICES` map
│   └── ratchet/
│       ├── ratchet-propose.mjs       # MODIFIED — cache_control + RATCHET_SURFACES filter in discoverPngs()
│       ├── ratchet-verify.mjs        # MODIFIED — cache_control only (no surface filter needed)
│       ├── ratchet-ledger.js         # UNCHANGED (already has everything ui.fix needs)
│       ├── region-tags.js            # UNCHANGED
│       ├── phase-ratchet-ledger.mjs  # MODIFIED — add round-seal + dry/converge computation
│       ├── ratchet-digest.mjs        # NEW — twins phase192-gallery.mjs structurally
│       └── rounds.ndjson             # NEW — committed, sibling to reopen-markers.ndjson
├── test/mix/tasks/
│   ├── accrue_admin_ui_round_test.exs  # NEW — twin of accrue_admin_assets_build_test.exs's FakeRunner pattern
│   └── accrue_admin_ui_fix_test.exs    # NEW — same pattern
scripts/ci/
└── verify_ratchet_ledger.mjs          # MODIFIED ONLY IF round-seal fields need independent re-verification (Claude's discretion — likely yes for consistency with the "independent re-verifier" discipline already established)
```

### Pattern 1: Mix-task Runner behaviour (twin exactly)

**What:** `accrue_admin.assets.build.ex` defines a `Runner` behaviour (`@callback run/3`), a `ShellRunner` default implementation using `System.cmd/3`, and swaps the implementation via `Application.get_env(:accrue_admin, <task_runner_key>, ShellRunner)`. Every step calls a private `run_step!/5` that raises via `Mix.raise` on non-zero exit.

**When to use:** `ui.round.ex` and `ui.fix.ex` — every single subprocess invocation (`mix accrue_admin.assets.build`, `npx playwright test ...`, `node e2e/ratchet/ratchet-propose.mjs`, `node e2e/ratchet/ratchet-verify.mjs`, `node e2e/ratchet/phase-ratchet-ledger.mjs`, `node e2e/ratchet/ratchet-digest.mjs`) goes through the SAME swappable `Runner`.

**Example (verbatim from the real file, `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex`):**
```elixir
defmodule Mix.Tasks.AccrueAdmin.Assets.Build do
  use Mix.Task
  @runner_env_key :accrue_admin_assets_build_runner

  defmodule Runner do
    @callback run(String.t(), [String.t()], keyword()) :: {:ok, integer()} | {:error, term()}
  end

  defmodule ShellRunner do
    @behaviour Runner
    @impl true
    def run(command, args, opts) do
      {_, status} = System.cmd(command, args, cd: Keyword.fetch!(opts, :cd),
        env: [{"BROWSERSLIST_IGNORE_OLD_DATA", "1"}], stderr_to_stdout: true,
        into: IO.stream(:stdio, :line))
      {:ok, status}
    rescue
      error -> {:error, error}
    end
  end

  @impl Mix.Task
  def run(_argv) do
    root = File.cwd!()
    runner = Application.get_env(:accrue_admin, @runner_env_key, ShellRunner)
    run_step!(runner, "tailwind", "npx", tailwind_args(root), cd: root)
    run_step!(runner, "esbuild", "npx", esbuild_args(root), cd: root)
  end

  defp run_step!(runner, label, command, args, opts) do
    case runner.run(command, args, opts) do
      {:ok, 0} -> :ok
      {:ok, status} -> Mix.raise("#{label} build failed with exit status #{status}")
      {:error, reason} -> Mix.raise("#{label} build failed: #{Exception.message(reason)}")
    end
  end
end
```

The unit test that proves this (`accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs`) defines a `FakeRunner` implementing `@behaviour Build.Runner`, sends `{:runner_call, tool, args, cwd}` messages via `send(self(), ...)`, swaps it in via `Application.put_env(:accrue_admin, :accrue_admin_assets_build_runner, FakeRunner)` in `setup`, restores in `on_exit`, and asserts on `assert_received`. **This exact test pattern is the one to twin for `ui.round`/`ui.fix` unit tests** — the planner should assert the precise `System.cmd` sequence (assets.build → playwright test → node propose → node verify → node ledger → node digest) via `assert_received` ordering, never a live subprocess.

### Pattern 2: Playwright's `webServer` already satisfies "boot the admin"

**What:** `accrue_admin/playwright.config.js` already declares:
```js
webServer: {
  command: `MIX_ENV=test ACCRUE_ADMIN_E2E_PORT=${port} mix accrue_admin.e2e.server`,
  url: `${baseURL}/__e2e__/health`,
  reuseExistingServer: !process.env.CI,
  timeout: 120_000
}
```
**Implication for `ui.round`:** invoking `npx playwright test e2e/admin-visuals.spec.js` from within `accrue_admin/` **already** boots the admin server (`MIX_ENV=test mix accrue_admin.e2e.server`), health-checks it, and tears it down on completion. `ui.round`'s "boots the admin" (ROADMAP SC 1) requirement is satisfied automatically by the capture step — there is no separate manual System.cmd for booting a server, and no separate manual `reset`/`seed` System.cmd either (both happen inside `admin-visuals.spec.js`'s `test.beforeEach`/test body via `POST /__e2e__/reset` and `POST /__e2e__/seed/<fixture>`). This materially simplifies the `ui.round` pipeline: it is `assets.build` → `playwright test admin-visuals.spec.js` → `node ratchet-propose.mjs` → `node ratchet-verify.mjs` → `node phase-ratchet-ledger.mjs` → `node ratchet-digest.mjs`, six sequential `Runner.run` calls, nothing more.

### Pattern 3: Self-contained-artifact idiom (`phase192-gallery.mjs`) to twin for `ratchet-digest.mjs`

**What:** `accrue_admin/e2e/phase192-gallery.mjs` is the closest in-repo idiom for a self-contained generated document with a `--self-test`. Its shape:
- `parseArgs(argv)` supporting `--self-test`, `--dry-run`, `--output <path>`
- Pure row-builder functions (`generateEvidenceRows`) + `REQUIRED_GALLERY_FIELDS`-style field validators (`validateGalleryRows`, `validateTraceRefs`, `validateChecklistRows`) that `throw` with a joined failure list
- `markdownTable(headers, rows)` helper (digest needs an HTML-table equivalent instead)
- `runSelfTest()` builds a complete fixture under `fs.mkdtempSync`, asserts ACCEPT/BLOCK outcomes, asserts each validator individually throws on a malformed row
- `main(argv)` guard: `if (import.meta.url === pathToFileURL(process.argv[1]).href) { main().catch(...) }`

**Caveat (UI-SPEC explicitly notes this):** `phase192-gallery.mjs` renders **Markdown**; `ratchet-digest.mjs` must render **HTML with inline `<style>`**. Twin the *structural* idiom (parseArgs/row-builder/validator/self-test/main-guard), not the literal markdown-table renderer — there is no prior literal HTML gallery in this repo to copy; `207-UI-SPEC.md` is the executor's primary visual reference for the new renderer.

### Pattern 4: `cache_control` placement — no reorder needed (confirmed against real request-builder code)

**What (CITED: bundled `claude-api` skill / Anthropic docs, applied to the verified real code shape):**
- Request-level render order is `tools` → `system` → `messages` (CITED: `shared/prompt-caching.md`, bundled skill reference).
- Max **4** `cache_control` breakpoints per request.
- Minimum cacheable prefix is **model-dependent**: **4096 tokens** for `claude-opus-4-8`/Opus 4.7/4.6/4.5/Haiku 4.5; **2048 tokens** for `claude-sonnet-4-6`/Haiku 3.5/3; **1024 tokens** for `claude-sonnet-4-5`/Sonnet-4-1/4/3.7. `ratchet-propose.mjs`'s `SCORE_MODEL` default is `claude-sonnet-4-5` (1024-token minimum); `ratchet-verify.mjs`'s `VERIFY_MODEL` default is `claude-opus-4-8` (4096-token minimum) — see Risk 3 below.
- `usage.cache_creation_input_tokens` / `usage.cache_read_input_tokens` on the response are the measurement signal for ORCH-07's "measurably reducing per-run input tokens/cost" requirement.

**Confirmed in the real `ratchet-propose.mjs` request builder (`proposeForImage`, persona loop, lines ~426–444):**
```js
const request = {
  model,
  max_tokens: 2048,
  system: SYSTEM_PREAMBLE,           // currently a bare string — must become an array of text blocks
  tools: [toolSchema],               // one tool entry — cache_control goes on THIS entry (it is also "the last")
  tool_choice: { type: "tool", name: "emit_findings" },
  messages: [{
    role: "user",
    content: [
      { type: "image", source: { type: "base64", media_type: "image/png", data: b64 } },  // FIRST content block — image already precedes text
      { type: "text", text: buildLensPrompt(persona) }
    ]
  }]
};
```
Because the image block is already the FIRST element of `messages[0].content`, and `tools`/`system` are already request-level fields preceding `messages`, the D-57 claim holds without any reordering: add `cache_control: {type: "ephemeral"}` to (a) the `system` array's single text block (converting `system` from a string to `[{type:"text", text: SYSTEM_PREAMBLE, cache_control: {...}}]`), (b) the last (only) `tools` entry (`toolSchema`), and (c) the image content block. This is **3 breakpoints** (within the 4-max limit), matching D-57 exactly.

The SAME shape and conclusion holds for `ratchet-verify.mjs`'s `verifyImageGroup` (line ~415): `system: SYSTEM_AND_RUBRIC`, `tools: [PANEL_TOOL]`, `messages: [{role:"user", content:[{type:"image",...}, {type:"text", text: findingsText}]}]`. The file's own comment at lines 410–413 already states: *"Stable-prefix-first (D-28): system + rubric + PANEL_TOOL schema are IDENTICAL on every call... this ordering is what makes ORCH-07's Phase-207 prompt-caching a drop-in later without touching identity."* — this is a direct in-repo confirmation written by the Phase 206 team, not an inference.

**One nuance for the proposer specifically:** `buildToolSchema(surface)` embeds `region_tag: {enum: regionTags.allowedSubsetFor(surface)}`, which is constant PER SURFACE but differs ACROSS surfaces. This means the `tools`+`system` cache prefix is reusable across the 7 calls made on ONE screenshot (6 personas + 1 design lens — all share the same `surface`), but does NOT carry over to the next screenshot (different surface → different tool schema → cache miss on tools/system, fresh write). This matches D-57's stated scope exactly ("caches schema + system + screenshot for all 7 calls" — per-screenshot, not cross-screenshot) and explains why the CONTEXT.md "Claude's Discretion" section defers the cross-screenshot exemplar-first reorder as a separate follow-on toggle.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Ledger fold / lifecycle transitions | A new state machine in Elixir or in `ratchet-digest.mjs` | `ratchetLedger.fold()`, `appendResolved`, `appendVerifiedClosed`, `LEGAL_TRANSITIONS` (all in `ratchet-ledger.js`) | Already exists, already self-tested, already imported by both `ratchet-verify.mjs` and `phase-ratchet-ledger.mjs`; re-implementing risks silent divergence from the tamper-evidence `seq`-monotonic check |
| Identity re-derivation (`claim_key`/`finding_id`) | Any new hashing/normalization logic in the digest or the round-seal computation | `region-tags.js`'s `claimKey()`/`findingId()`/`normalizeRegion()` | SDK-free, pure, self-tested; the whole DEDUP-01/02 guarantee depends on NEVER re-deriving identity a second, possibly-diverging way |
| Guard-ref presence/token-grammar check | A new regex/grep in the digest or in `ui.fix.ex` | `checkGuardRef()` in `phase-ratchet-ledger.mjs` (already implements the exact `@ratchet:f-[0-9a-f]{16}` grammar + `GUARD_HOME_SPECS` allowlist + path-safety) | Duplicating this risks a subtly different regex that silently diverges from the independent CI re-verifier |
| Round counter / dry detection | Ad-hoc directory-listing of `test-results/round-NN/` dirs | A NEW committed `rounds.ndjson` event log (D-47), computed by `phase-ratchet-ledger.mjs` | `test-results/` is gitignored — deriving round state from it is non-reproducible on a fresh clone/CI, exactly the failure mode D-47 documents |
| Suppression-reason validation | A new closed-enum check in `ui.fix.ex` | `isValidSuppressedReason()` / `SUPPRESSED_REASONS` in `ratchet-ledger.js` | Already handles the `duplicate-of:<finding_id>` grammar-plus-existence-check (IN-02 fix); Elixir should call this indirectly by shelling to a node validator, never reimplement the enum in Elixir |

**Key insight:** every deterministic computation this phase needs (fold, identity, guard-check, suppression validation) is a pure function that ALREADY EXISTS in `ratchet-ledger.js`/`region-tags.js`/`phase-ratchet-ledger.mjs` and is already covered by `--self-test`. The ENTIRE net-new logic surface for this phase is: (1) round-seal + dry/converge computation (genuinely absent today), (2) the HTML digest renderer (genuinely absent today), (3) the guard-mint data-row appender (genuinely absent today, though it reuses `checkGuardRef`'s validation contract), and (4) two `cache_control` additions + one `RATCHET_SURFACES` filter (small, mechanical diffs to existing files).

## Common Pitfalls

### Pitfall 1: Assuming a `round-NN/` artifact directory convention already exists
**What goes wrong:** CONTEXT.md/UI-SPEC/ROADMAP all reference `test-results/ui-ratchet/round-NN/digest.html`, `round-NN/candidates`, `round-NN/verdicts`, `round-NN/decisions.json`, and screenshots living in that same directory. **None of this exists today.** `ratchet-propose.mjs`'s `RESULTS_DIR` is hardcoded to `path.join(__dirname, "../../test-results/admin-visuals")` (flat, not round-scoped); `CANDIDATES_PATH` is `RESULTS_DIR/candidates.ndjson` (also flat); `ratchet-verify.mjs`'s `VERDICTS_PATH` is likewise flat under `test-results/admin-visuals/verify-verdicts.ndjson`; `admin-visuals.spec.js` writes PNGs to `test-results/admin-visuals/${project}/` (also flat, unconditionally).
**Why it happens:** CONTEXT.md's canonical-refs section was written assuming the round-NN convention as if it were already load-bearing infrastructure; it is actually new plumbing this phase must introduce.
**How to avoid:** The planner must explicitly decide (this is a genuine, not-yet-resolved integration seam) between: (a) leave PNG capture/candidates/verdicts paths exactly as they are (flat, `test-results/admin-visuals/`) since `admin-visuals.spec.js` and the existing `phase192`/`phase200` tooling all assume that path, and have `ratchet-digest.mjs` (at digest-render time) COPY the current round's PNGs + `.bbox.json` sidecars into a NEW `test-results/ui-ratchet/round-NN/` directory alongside `digest.html` (a cheap `fs.cpSync` step, zero risk to existing consumers); or (b) parameterize the capture/candidate/verdict paths themselves to be round-scoped (touches `admin-visuals.spec.js`, `ratchet-propose.mjs`, `ratchet-verify.mjs` — higher risk, more surface area, and risks breaking the existing `npm run e2e:visuals:png-only` / `ratchet:propose` / `ratchet:verify` scripts which assume the flat path). **Recommend (a)** — smallest correct footprint, consistent with D-51's "reimplement nothing, touch as little as possible" spirit.
**Warning signs:** if the planner's tasks reference `test-results/ui-ratchet/round-NN/candidates.ndjson` as an INPUT to `ratchet-verify.mjs` without a corresponding task that changes `ratchet-verify.mjs`'s hardcoded `CANDIDATES_PATH`, the plan will not actually work as written.

### Pitfall 2: Overlay-scale math references a viewport width that does not match the real capture viewport
**What goes wrong:** UI-SPEC's D-55 overlay spec says: `scale = renderedWidth / project.viewport_width` where `project.viewport_width` is "1440 (desktop project) or 390 (mobile project) from `baseline-manifest.js` `PROJECTS`." Reading `baseline-manifest.js` confirms `PROJECTS = [{name:"chromium-desktop", viewport_width: 1440}, {name:"chromium-mobile", viewport_width: 390}]`. **But** `playwright.config.js`'s `chromium-desktop` project explicitly overrides `viewport: {width: 1280, height: 900}` (NOT 1440), and its `chromium-mobile` project uses `devices["Pixel 5"]` whose actual viewport is `{width: 393, height: 727}` (NOT 390) — verified directly via `node -e "require('@playwright/test').devices['Pixel 5']"`. This is also independently confirmed by `exemplars/PROVENANCE.json`'s capture recipe note: *"Captured at a fixed 1280px-wide desktop viewport."*
**Why it happens:** `baseline-manifest.js`'s `PROJECTS.viewport_width` values were set (in an earlier phase) as documentation/grammar values for the census cell-ID scheme, not kept in sync with the actual Playwright device/viewport config.
**How to avoid:** `ratchet-digest.mjs` should NOT blindly trust `baseline-manifest.js`'s `PROJECTS[...].viewport_width` for the overlay scale calculation — it will silently misalign every overlay box by a `1280/1440 ≈ 0.889` factor on desktop and a `393/390 ≈ 1.008` factor on mobile. Either hardcode the actual known capture widths (1280/393) in `ratchet-digest.mjs` with a comment explaining the divergence, or (safer, more future-proof) read them from `playwright.config.js`'s `devices`/explicit-viewport config at digest-render time. This is a real, verified discrepancy in the existing codebase, not a Phase-207 regression — flag it to the planner as a decision point rather than silently propagating the (wrong) baseline-manifest numbers into new code.
**Warning signs:** overlay boxes visibly offset from their true screen position in the rendered digest, worse on desktop than mobile.

### Pitfall 3: `cache_control`'s minimum-cacheable-prefix floor differs between the proposer's and verifier's default models
**What goes wrong:** `ratchet-propose.mjs`'s `SCORE_MODEL` defaults to `claude-sonnet-4-5` (1024-token cacheable minimum per the Anthropic API reference); `ratchet-verify.mjs`'s `VERIFY_MODEL` defaults to `claude-opus-4-8` (4096-token cacheable minimum). If the verifier's `SYSTEM_AND_RUBRIC + PANEL_TOOL` combined prefix is under ~4096 tokens, `cache_control` will silently no-op (no error, `cache_creation_input_tokens: 0` forever) even though the code is "correct."
**Why it happens:** the two scripts intentionally use different default models (Opus for the higher-stakes adversarial verify panel per D-32); the cache-floor difference is a consequence of that choice, not a bug, but it's easy to miss when validating ORCH-07's "measurably reducing... cost" requirement.
**How to avoid:** the phase's validation step for ORCH-07 (see Validation Architecture) must assert `cache_read_input_tokens > 0` on a SECOND identical-prefix call for BOTH scripts independently, not just one — and if the verifier's rubric text is thin, may need to be padded/left as a documented residual (Claude Fable/Opus-tier prefixes are usually large enough given `SYSTEM_AND_RUBRIC` embeds a full rubric + panel instructions, but this must be measured, not assumed).
**Warning signs:** `usage.cache_read_input_tokens === 0` on the verifier across repeated runs while the proposer shows non-zero reads.

### Pitfall 4: No delimited guard-marker region exists yet in any of the 4 guard-home spec files
**What goes wrong:** D-46 describes appending rows "only inside a delimited region (e.g. `// >>> @ratchet:auto-guards >>> ... // <<< @ratchet:auto-guards <<<`)" of an EXISTING guard-home spec file. Grepping all 4 files (`foundation-tokens.spec.js`, `admin-interaction-overlay-phase199.spec.js`, `reduced-motion.spec.js`, `admin-page-flow-phase200.spec.js`) for `@ratchet` confirms **zero existing occurrences** — because the ledger is currently empty (0 rows in `findings.ledger.ndjson`; no live proposer/verifier run has ever happened, confirmed by `wc -l`), no finding has ever been resolved, so no guard has ever been minted.
**Why it happens:** this is genuinely virgin territory — Phase 206 built the CHECK (`checkGuardRef`) but never the MINT, and no live run has occurred yet to exercise it.
**How to avoid:** `ui.fix`'s guard-mint code must handle the "delimited region does not yet exist in this file" bootstrap case explicitly — either (a) each of the 4 guard-home spec files gets an EMPTY, pre-seeded `// >>> @ratchet:auto-guards >>> ... // <<< @ratchet:auto-guards <<<` block added as part of THIS phase's implementation (a small, safe, additive diff to 4 files, done once), or (b) the mint code creates the block on first append if absent (more code, more edge cases, but no upfront file changes). **Recommend (a)** — simpler, one-time, reviewable diff; the mint logic then only ever needs to handle "insert a row into an existing delimited region," never "create the region."
**Warning signs:** the mint code crashes or silently no-ops on the very first `ui.fix` run because it assumed the marker region pre-exists.

### Pitfall 5: The round-number source of truth is not yet defined
**What goes wrong:** `ratchet-propose.mjs` already reads `RATCHET_ROUND` from env (`Number(process.env.RATCHET_ROUND || "1")`) and stamps it onto every candidate row (which flows into `CARRY_FIELDS` on the ledger row). But nothing today COMPUTES what the next round number should be — D-49 says "the round counter increments on each `ui.round`," but the actual increment logic (read `rounds.ndjson`, find `max(round)`, add 1, feed back as `RATCHET_ROUND` to the node scripts) does not exist anywhere yet.
**Why it happens:** this is exactly the kind of "all file-reasoning lives in the node reducer" (D-51) computation that must be added to `phase-ratchet-ledger.mjs`, but it's easy to accidentally put in the Elixir mix task instead (violates D-51) or to invent an ad-hoc convention.
**How to avoid:** add a small new CLI mode to `phase-ratchet-ledger.mjs`, e.g. `node phase-ratchet-ledger.mjs --next-round` that prints the next round integer to stdout (reading `rounds.ndjson`'s `max(round) + 1`, or `1` if absent) and exits 0 with no other side effects. `ui.round.ex`'s `Runner` calls this FIRST, captures stdout via `System.cmd`, parses the integer, and sets `RATCHET_ROUND=<n>` in the env passed to every subsequent `Runner.run` call (propose/verify/digest all need to know the current round).
**Warning signs:** every round silently reports `round: 1` because nothing ever increments it, or the round number is computed inconsistently in two different places (Elixir vs. Node).

### Pitfall 6: `admin-visuals.spec.js`'s `shots` array is not currently a named, filterable export
**What goes wrong:** the D-52 filter design assumes the capture spec can be filtered "by name" — but `shots` is a local `const` INSIDE the single `test(...)` callback, not a module-level export. Filtering it by `RATCHET_SURFACES` means adding a filter step directly inside that test body (e.g. `const filtered = RATCHET_SURFACES ? shots.filter(([name]) => surfaceSet.has(name)) : shots;` before the `for (const [name, path] of shots)` loop), not importing/filtering it from outside the spec file.
**Why it happens:** the spec was written (Phase 187-era) as a single monolithic capture test, before any filtering need existed.
**How to avoid:** the filter logic must live INSIDE `admin-visuals.spec.js`'s test body, reading `process.env.RATCHET_SURFACES` (CSV) directly — there is no clean external hook. This is a small, contained change but the planner should not describe it as "import and filter `shots`" since that array is not importable as-is.
**Warning signs:** a plan task that says "export `shots` from `admin-visuals.spec.js`" — unnecessary; simpler to filter in place.

## Code Examples

### `cache_control` — converting `ratchet-propose.mjs`'s persona request (Source: bundled Anthropic API skill reference + verified current code shape)
```js
// BEFORE (current code, ratchet-propose.mjs proposeForImage(), persona loop):
const request = {
  model,
  max_tokens: 2048,
  system: SYSTEM_PREAMBLE,
  tools: [toolSchema],
  tool_choice: { type: "tool", name: "emit_findings" },
  messages: [{
    role: "user",
    content: [
      { type: "image", source: { type: "base64", media_type: "image/png", data: b64 } },
      { type: "text", text: buildLensPrompt(persona) }
    ]
  }]
};

// AFTER (adds 3 cache_control breakpoints; ZERO reordering):
const request = {
  model,
  max_tokens: 2048,
  system: [
    { type: "text", text: SYSTEM_PREAMBLE, cache_control: { type: "ephemeral" } }
  ],
  tools: [
    { ...toolSchema, cache_control: { type: "ephemeral" } }
  ],
  tool_choice: { type: "tool", name: "emit_findings" },
  messages: [{
    role: "user",
    content: [
      {
        type: "image",
        source: { type: "base64", media_type: "image/png", data: b64 },
        cache_control: { type: "ephemeral" }
      },
      { type: "text", text: buildLensPrompt(persona) }  // uncached — per-persona, varies every call
    ]
  }]
};
// Same 3-breakpoint pattern applies verbatim to designRequest (the 7th/design-lens call)
// and to ratchet-verify.mjs's `request` object (system: SYSTEM_AND_RUBRIC, tools: [PANEL_TOOL]).
```

### Fake-Runner Mix task test (Source: verified real file, `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` — twin exactly for `ui.round`/`ui.fix`)
```elixir
defmodule Mix.Tasks.AccrueAdmin.Ui.RoundTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO
  alias Mix.Tasks.AccrueAdmin.Ui.Round

  defmodule FakeRunner do
    @behaviour Round.Runner
    @impl true
    def run(command, args, opts) do
      send(self(), {:runner_call, command, args, opts[:cd]})
      {:ok, 0}
    end
  end

  setup do
    Mix.Task.reenable("accrue_admin.ui.round")
    prior = Application.get_env(:accrue_admin, :accrue_admin_ui_round_runner)
    Application.put_env(:accrue_admin, :accrue_admin_ui_round_runner, FakeRunner)
    on_exit(fn ->
      Mix.Task.reenable("accrue_admin.ui.round")
      if prior, do: Application.put_env(:accrue_admin, :accrue_admin_ui_round_runner, prior),
        else: Application.delete_env(:accrue_admin, :accrue_admin_ui_round_runner)
    end)
    :ok
  end

  test "sequences build, capture, propose, verify, ledger, digest in order" do
    capture_io(fn -> Round.run([]) end)
    assert_received {:runner_call, "mix", ["accrue_admin.assets.build"], _}
    assert_received {:runner_call, "npx", ["playwright", "test", "e2e/admin-visuals.spec.js"], _}
    assert_received {:runner_call, "node", ["e2e/ratchet/ratchet-propose.mjs"], _}
    assert_received {:runner_call, "node", ["e2e/ratchet/ratchet-verify.mjs"], _}
    assert_received {:runner_call, "node", ["e2e/ratchet/phase-ratchet-ledger.mjs"], _}
    assert_received {:runner_call, "node", ["e2e/ratchet/ratchet-digest.mjs"], _}
  end
end
```

### `--next-round` addition to `phase-ratchet-ledger.mjs` (net-new; sketch, not yet in repo)
```js
// New CLI mode, added alongside the existing --self-test / --freeze checks in main():
if (process.argv.includes("--next-round")) {
  const rows = readNdjsonRows(ROUNDS_PATH); // new sibling path, e.g. path.join(__dirname, "rounds.ndjson")
  const maxRound = rows.reduce((m, r) => Math.max(m, r.round || 0), 0);
  console.log(String(maxRound + 1));
  process.exit(0);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Phase 205/206: proposer/verifier make 7 uncached calls/screenshot, re-sending system+tools+image every time | Phase 207 adds `cache_control` breakpoints on the stable prefix | This phase (2026-07-04) | Per the file's own D-28 comment, this was ALWAYS the intended design (the request shape was built cache-ready in Phase 206) — Phase 207 is the "flip the switch" phase, not a redesign |
| No subset/slice filter — a slice run required hand-pruning `test-results/` PNGs | `RATCHET_SURFACES` env-based filter in `discoverPngs()` + `admin-visuals.spec.js`'s inline `shots` | This phase | Removes the manual-pruning footgun documented as a "live smoke" finding in Phase 205 |
| No round/convergence concept in the ledger reducer | New round-seal + dry-round + K=2-convergence + 6-round-cap computation in `phase-ratchet-ledger.mjs` | This phase | First time the loop can terminate deterministically instead of running indefinitely |

**Deprecated/outdated:** nothing in this phase deprecates prior-phase code — everything from 205/206 is additive-compatible (D-36: "207 is a pure superset-layer: ZERO new writers of `open`").

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `@anthropic-ai/sdk@^0.100.1` fully supports `cache_control` on system/tools/image blocks with no upgrade needed | Standard Stack | Low — `cache_control` has been a stable, non-beta Messages API field for a long time; if somehow unsupported, the SDK would need a `npm view @anthropic-ai/sdk versions` check before implementation, but this is a mechanical fix, not a design change |
| A2 | Recommendation (a) in Pitfall 1 (copy PNGs into round-NN/ at digest-render time rather than moving the whole capture pipeline) is the right integration seam | Common Pitfalls / Architecture | Medium — if the planner instead chooses to round-scope the capture path itself, more files change (`admin-visuals.spec.js`, `ratchet-propose.mjs`, `ratchet-verify.mjs`) and existing npm scripts (`e2e:visuals:png-only`, `ratchet:propose`, `ratchet:verify`) may need dual-path support; this is a genuine open design question, not a locked decision, and is flagged as such |
| A3 | Recommendation (a) in Pitfall 4 (pre-seed empty delimited marker blocks in all 4 guard-home specs as part of this phase) is preferred over "mint code creates the block on first use" | Common Pitfalls | Low — either approach is workable; pre-seeding is simpler and lower-risk but is a judgment call the planner should confirm |
| A4 | `phase-ratchet-ledger.mjs --next-round` (new CLI mode) is the right shape for round-number determination, keeping ALL file-reasoning in Node per D-51 | Common Pitfalls / Code Examples | Low-Medium — the exact CLI flag name/shape is Claude's Discretion; the core requirement (round number must be computed by the node reducer, not Elixir, per D-51) is locked and non-negotiable |

**If this table is empty:** not applicable — all four items above are architecture-adjacent judgment calls flagged for planner confirmation, not verified-external facts; none touches a CONTEXT.md-locked decision.

## Open Questions (RESOLVED)

1. **Where do round-scoped digest/decisions/candidate artifacts physically live relative to the existing flat `test-results/admin-visuals/` capture path?**
   - What we know: CONTEXT.md/UI-SPEC assume a `test-results/ui-ratchet/round-NN/` directory holding digest.html + screenshots + bbox.json + candidates + verdicts together; none of this exists today; the existing capture/candidate/verdict paths are flat and hardcoded in 3 different files.
   - What's unclear: whether the planner should round-scope the capture pipeline itself or just copy artifacts into a round-NN home at digest time.
   - Recommendation: copy-at-digest-time (Pitfall 1, recommendation (a)) — smallest footprint, zero risk to existing consumers of the flat path (`score-visuals.mjs`, `phase192-gallery.mjs`, `phase200-scorecard.mjs` all read PNGs from the flat `test-results/admin-visuals/` structure and must keep working unmodified).
   - **RESOLVED:** implemented by the executed `207-04` copy-at-digest-time approach. The digest owns the round-scoped artifact home without forcing the existing flat capture/proposer/verifier paths to change.

2. **Does the digest's overlay-scale math get corrected to the real capture viewport (1280/393) or does it stay pinned to `baseline-manifest.js`'s declared values (1440/390)?**
   - What we know: the two numbers genuinely diverge, confirmed three ways (playwright.config.js explicit override, `devices["Pixel 5"]` actual viewport, and `exemplars/PROVENANCE.json`'s own capture-recipe note of "1280px-wide").
   - What's unclear: whether this is an already-known, accepted discrepancy from an earlier phase (in which case UI-SPEC's numbers may be intentional-but-wrong and should be corrected in this phase) or a genuinely new finding.
   - Recommendation: hardcode the real captured widths (1280/393) directly in `ratchet-digest.mjs` rather than trusting `baseline-manifest.js`'s `PROJECTS[...].viewport_width`, and leave a code comment documenting the divergence for a future baseline-manifest cleanup (out of this phase's scope to fix the manifest itself, since that's a frozen grammar file touched by many other phases).
   - **RESOLVED:** implemented by executed `207-04` with the real capture widths `1280/393`, preserving correct overlay placement while leaving baseline-manifest cleanup out of scope.

3. **Does `scripts/ci/verify_ratchet_ledger.mjs` need its own round-seal recomputation for independence, mirroring its existing GUARD_HOME_SPECS/LENS_KEYS duplication discipline?**
   - What we know: the file's own doc comment states an explicit "independence discipline" — it deliberately re-implements fold/guard-check/lens-enum rather than importing them, specifically so a shared bug wouldn't pass both checks.
   - What's unclear: whether the ORCH-06 convergence/dry computation is gate-relevant enough to warrant the same independent-reimplementation treatment, or whether it's purely advisory (digest-display-only, no CI consequence this phase, since 207 wires no CI per CONTEXT.md).
   - Recommendation: skip independent reimplementation this phase — CONTEXT.md is explicit that "207 wires no CI" and the round-seal/dry-round computation only feeds the digest banner + the maintainer's local terminal message, not a CI gate (that's Phase 208's `admin-ui-ratchet-guardrails` job). The independence discipline should be revisited in Phase 208 once convergence becomes CI-gated.
   - **RESOLVED:** deferred to Phase 208, where convergence becomes CI-gated. Phase 207 keeps round-seal/dry-round logic local to the deterministic reducer and digest/terminal reporting path.

## Environment Availability

Skipped in the literal per-dependency-table sense — this phase adds no new external tool/service dependencies. All required tools (`node`, `npm`, `npx playwright`, `mix`) are already required by Phases 205/206 and confirmed present via their existing, working `package.json` scripts (`ratchet:propose`, `ratchet:verify`, `ratchet:ledger`, `e2e:visuals:png-only`). The one true external dependency — the Anthropic API (`ANTHROPIC_API_KEY`) — is already handled by the existing 3-guard ordering (`--self-test` → no-key exit-0 → SDK import) in both `ratchet-propose.mjs` and `ratchet-verify.mjs`, and this phase's `cache_control` change sits entirely inside guard 3 (post-key-check), so it never touches the no-key/CI-safe path.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Node built-in assertion idiom (`assertSelfTest`/`runSelfTest`, no external test runner) for all `.mjs` reducers; ExUnit for Mix tasks |
| Config file | none — each `.mjs` file is directly executable (`node e2e/ratchet/phase-ratchet-ledger.mjs --self-test`) |
| Quick run command | `cd accrue_admin && npm run ratchet:ledger:self-test` (existing script — extend once `--next-round`/round-seal logic is added) |
| Full suite command | `cd accrue_admin && npm run ratchet:ledger && node ../scripts/ci/verify_ratchet_ledger.mjs` (real committed-file run) + `mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ORCH-01 | `ui.round` sequences build→capture→propose→verify→ledger→digest in the right order | unit (fake Runner) | `mix test test/mix/tasks/accrue_admin_ui_round_test.exs` | ❌ Wave 0 |
| ORCH-02 | Digest row-builder + validator produce well-formed worklist/decisions-needed/gallery rows; `--self-test` fixture covers empty/normal/converged/cap-reached states | unit (`--self-test`) | `node e2e/ratchet/ratchet-digest.mjs --self-test` | ❌ Wave 0 |
| ORCH-03 | `ui.fix` refuses a missing/invalid `suppressed_reason`; batch-approve applies all pre-filled `approve` rows with zero edits | unit (fake Runner + fixture `decisions.json`) | `mix test test/mix/tasks/accrue_admin_ui_fix_test.exs` | ❌ Wave 0 |
| ORCH-04 | `ui.fix` sequences apply→build→commit→re-capture→re-score→ledger-advance→mint in order | unit (fake Runner) | `mix test test/mix/tasks/accrue_admin_ui_fix_test.exs` | ❌ Wave 0 |
| ORCH-05 | Guard-mint appends idempotently (re-running never duplicates a row for the same `finding_id`); minted `guard_ref` passes `checkGuardRef()` | unit (`--self-test` on the mint function, using `fs.mkdtempSync` fixture specs) | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` (extend existing suite) | ❌ Wave 0 (extend existing file) |
| ORCH-06 | Dry-round 4-clause conjunction fires correctly; K=2 consecutive dry → CONVERGED; 6th non-converged round → non-zero exit | unit (`--self-test` fixtures: 0 open+0 new+both-regressions-empty+coverage-met vs. each clause individually false) | `node e2e/ratchet/phase-ratchet-ledger.mjs --self-test` (extend existing suite) | ❌ Wave 0 (extend existing file) |
| ORCH-07 | Cache hit on a second identical-prefix call — `cache_read_input_tokens > 0` | manual/live smoke (requires `ANTHROPIC_API_KEY`; NOT part of the deterministic gate) | run `ratchet:propose` twice in a row against unchanged PNGs, diff `usage.cache_read_input_tokens` in a debug log line | N/A — live-model smoke, not a CI-gated automated test |
| ORCH-08 | `RATCHET_SURFACES=dashboard` captures/proposes ONLY the dashboard surface; unset covers the full set | integration (Playwright test asserting filtered `shots.length`) + unit (`discoverPngs()` filter logic) | `RATCHET_SURFACES=dashboard npx playwright test e2e/admin-visuals.spec.js` (manual verification: assert only `dashboard*.png` written) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the relevant `--self-test` (node) or `mix test <specific file>` (Elixir) for whichever file the task touched.
- **Per wave merge:** `npm run ratchet:ledger:self-test` + `node e2e/ratchet/ratchet-digest.mjs --self-test` + `mix test test/mix/tasks/accrue_admin_ui_round_test.exs test/mix/tasks/accrue_admin_ui_fix_test.exs`.
- **Phase gate:** all of the above green, plus a documented (not necessarily automated-in-CI, since this phase wires no CI per CONTEXT.md) manual live-smoke pass proving ORCH-07's cache-hit measurement, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `accrue_admin/test/mix/tasks/accrue_admin_ui_round_test.exs` — covers ORCH-01
- [ ] `accrue_admin/test/mix/tasks/accrue_admin_ui_fix_test.exs` — covers ORCH-03/ORCH-04
- [ ] Extend `phase-ratchet-ledger.mjs`'s existing `runSelfTest()` with new fixtures for round-seal, dry-round 4-clause conjunction, and the K=2/6-cap convergence logic — covers ORCH-05/ORCH-06
- [ ] `ratchet-digest.mjs` (net-new file) with its own `runSelfTest()` — covers ORCH-02
- [ ] Framework install: none — all frameworks (ExUnit, node built-in self-test idiom) are already present project-wide.

## Security Domain

`security_enforcement` is absent from `.planning/config.json` — treated as enabled per the mandatory protocol, though this phase's actual attack surface is minimal: all new/modified code is dev/test-only tooling (`e2e/ratchet/`, `lib/mix/tasks/accrue_admin.ui.*.ex`) that never ships to adopter runtime (CONTEXT.md invariant, re-confirmed).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No new auth surface — the digest is a static local HTML file, `decisions.json` is a local file edit |
| V3 Session Management | no | N/A |
| V4 Access Control | no | Maintainer-local tooling only; no new endpoints |
| V5 Input Validation | yes | `decisions.json`'s `suppressed_reason` must be validated against the closed enum before `ui.fix` acts on it (reuse `isValidSuppressedReason()` from `ratchet-ledger.js`, do not re-implement); the guard-mint's `guard_ref` must pass `checkGuardRef()`'s existing path-safety allowlist check (`isSafeSpecPath()` — already rejects absolute paths, `..` traversal, non-allowlisted files) |
| V6 Cryptography | no | No new crypto — `findingId()`'s sha256 usage is unchanged, existing code |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via a maintainer-edited or corrupted `decisions.json`/`rounds.ndjson` referencing an arbitrary file path as a "guard home" | Tampering | Reuse the EXISTING `isSafeSpecPath()`/`GUARD_HOME_SPECS` closed-allowlist check verbatim in the new mint code — never accept a free-form path from any file input |
| A hand-edited `decisions.json` silently mass-approving suppressions with a missing/invalid reason | Tampering / Repudiation | `ui.fix` must `Mix.raise` on any row lacking a valid `suppressed_reason` (per D-43) — never silently default to "approve" |
| Overlay/digest HTML rendering untrusted `defect`/`suggested_fix` free-text (originally LLM-generated, already treated as untrusted per D-15's prompt-injection guard) directly into HTML without escaping | Tampering (stored XSS in a locally-opened file, low severity since it's a local-only maintainer artifact, but still worth doing correctly) | `ratchet-digest.mjs` must HTML-escape every ledger-row string field (`defect`, `suggested_fix`, `surface`, etc.) before interpolating into the rendered HTML — this is a NEW code-writing concern since no prior HTML-emitting script in this repo needs this treatment (phase192-gallery.mjs emits Markdown, not HTML) |

## Sources

### Primary (HIGH confidence — direct repo file reads)
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — Runner/ShellRunner/run_step! idiom
- `accrue_admin/test/mix/tasks/accrue_admin_assets_build_test.exs` — FakeRunner test pattern
- `accrue_admin/lib/mix/tasks/accrue_admin.e2e.server.ex`, `accrue_admin/playwright.config.js` — webServer boot contract
- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` (full file, 637 lines) — confirmed NO round/dry/convergence logic exists
- `accrue_admin/e2e/ratchet/ratchet-ledger.js` (full file, 1101 lines) — IDENTITY_FIELDS/CARRY_FIELDS/lifecycle/fold/append helpers
- `accrue_admin/e2e/ratchet/region-tags.js` (full file) — claim_key/finding_id/REGION_TAGS/OVERLAY_TAGS
- `accrue_admin/e2e/ratchet/ratchet-propose.mjs` (full file, 733 lines) — request shape, discoverPngs(), guard order
- `accrue_admin/e2e/ratchet/ratchet-verify.mjs` (relevant sections) — request shape, D-28 caching comment
- `accrue_admin/e2e/admin-visuals.spec.js` (full file) — shots array, captureBBoxes, .bbox.json shape
- `accrue_admin/e2e/baseline-manifest.js` (full file) — PROJECTS/DIMENSIONS/SURFACES
- `accrue_admin/e2e/phase192-gallery.mjs` (full file, 731 lines) — self-contained-artifact idiom to twin
- `scripts/ci/verify_ratchet_ledger.mjs` (header + GUARD_HOME_SPECS section) — independence discipline, duplicate allowlist
- `accrue_admin/e2e/ratchet/{findings.ledger,finding-regressions,reopen-markers}.ndjson`, `ledger.baseline.json` — confirmed 0-byte/empty state today
- `accrue_admin/e2e/{foundation-tokens,admin-interaction-overlay-phase199,reduced-motion,admin-page-flow-phase200}.spec.js` — confirmed no `@ratchet:` markers exist yet
- `accrue_admin/e2e/ratchet/exemplars/PROVENANCE.json` — confirms actual capture viewport was 1280px
- `accrue_admin/package.json` — `@anthropic-ai/sdk@^0.100.1`, existing `ratchet:*` npm scripts
- `node -e "require('@playwright/test').devices['Pixel 5']"` — confirmed actual mobile viewport `{width:393, height:727}`, desktop default `{width:1280, height:720}`
- `.planning/phases/207-.../207-CONTEXT.md`, `207-UI-SPEC.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/config.json`

### Secondary (MEDIUM confidence — CITED from bundled reference material)
- Anthropic `cache_control` API shape (breakpoint placement, 4-max limit, minimum cacheable prefix per model, `usage.cache_creation_input_tokens`/`usage.cache_read_input_tokens`) — bundled `claude-api` skill's `shared/prompt-caching.md` and per-language `README.md` §Prompt Caching sections. Not independently re-verified against a live platform.claude.com fetch this session (offline research), but this reference material is maintained specifically to be authoritative and current.

### Tertiary (LOW confidence)
- none — every claim in this research is either a direct file read or a cited bundled-reference fact; no bare training-knowledge guesses were used for factual claims about this repo's code.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; existing pins read directly from `package.json`
- Architecture: HIGH — every pattern is copied from a real, currently-working file in this exact repo
- Pitfalls: HIGH — every pitfall is a verified, reproducible discrepancy (grep counts, `wc -l`, `node -e` device dumps), not speculation

**Research date:** 2026-07-04
**Valid until:** 30 days (stable — this is a mechanical integration phase over already-shipped, already-tested Phase 205/206 code; the only fast-moving element, the Anthropic API's `cache_control` shape, is a long-GA feature unlikely to change)
