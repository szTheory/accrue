# Phase 207: Orchestration + digest + one-command round/fix loop - Context

**Gathered:** 2026-07-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 207 delivers the **orchestration + digest + one-command round/fix loop** of the UI ratchet —
the maintainer-facing driver that wraps Phase 205's proposer and Phase 206's verifier/ledger/gate into
**two `mix accrue_admin.ui.*` commands** with a rendered HTML digest, minimal batch-approve checkpoints,
auto-minted deterministic guards, prompt-caching, a surface-subset filter, and **guaranteed termination**.

Requirements: **ORCH-01, ORCH-02, ORCH-03, ORCH-04, ORCH-05, ORCH-06, ORCH-07, ORCH-08** (8 of 8 for
this phase).

**In scope:**
- `mix accrue_admin.ui.round` — build → boot admin (4017) → seed → capture → fan-out evaluators → dedup →
  verify → rank → render digest → append machine-confirmed survivors as `open` → seal the round marker
  (ORCH-01).
- `mix accrue_admin.ui.fix` — apply approved batch → `assets.build` → commit CSS bundle + source →
  re-capture → re-score → advance `open→resolved→verified-closed` → auto-mint one deterministic guard per
  resolved finding (ORCH-04, ORCH-05).
- The rendered **HTML digest** (`ratchet-digest.mjs`, twins `phase192-gallery.mjs`): screenshots grouped by
  surface with region overlays, a ranked worklist, a separate "Decisions needed" queue, a summary banner
  (ORCH-02).
- The **batch-approve / reject-to-suppress checkpoint** via a pre-filled transient `decisions.json`
  (ORCH-03).
- The **auto-mint guard producer** (typed data-row into an existing home spec) (ORCH-05).
- **Convergence + hard-cap** orchestration: K=2 consecutive dry rounds → `CONVERGED`; 6-round cap escalates
  (ORCH-06), tracked in a new committed append-only `rounds.ndjson`.
- **Prompt caching** (`cache_control`) on the stable prefix of `ratchet-propose.mjs` + `ratchet-verify.mjs`
  (ORCH-07).
- The **surface/slice subset filter** (`--slice` / `--surface`) threading through capture + fan-out via a
  shared `RATCHET_SURFACES` env, with the slice list defined once in `baseline-manifest.js` (ORCH-08).

**Out of scope (later phases):**
- Running the loop to **convergence on the representative slice**, **FREEZING** the first non-empty
  `ledger.baseline.json` (the reducer refuses to write a frozen baseline without the `--freeze` flag —
  208-only), wiring the `admin-ui-ratchet-guardrails` deterministic CI job, and maintainer **ACCEPT** +
  runbook — all **Phase 208** (CONV-01..07).
- Full ~19-surface **sweep** — **Phase 209** (optional/scope-gated, SWEEP-01).

**Invariants (carried from 205/206, non-negotiable):** the LLM never gates CI and is never on the guard-mint
or gate path; identity (`claim_key`/`finding_id`) is always re-derived deterministically via
`region-tags.js`, never trusted from the LLM; convergence/dry-round is computed deterministically by the
self-tested node reducer, never by Elixir and never by the LLM; capture always follows
`mix accrue_admin.assets.build` (committed-CSS discipline); all tooling is dev/test-only and never leaks
into adopter runtime; no new billing primitives, no route/API changes, no Tailwind migration; core `accrue`
stays LiveView-runtime-free; `ax-*` stays the styling SSOT.

</domain>

<decisions>
## Implementation Decisions

All four discussed gray areas were researched by **parallel advisor subagents** (pros/cons/tradeoffs,
worked examples, Elixir/Phoenix/Mix idiom, lessons from comparable tools in and beyond the ecosystem, DX,
footguns, UI/UX + brand + a11y lenses where applicable) and synthesized into the cohesive package below.
Per the project's dev/test-only, fully-reversible, unpublished nature, the one flagged "impactful fork"
(guard-mint realness) was **resolved in-synthesis** rather than escalated — the research answer aligns with
the milestone's "minimal toil / batch-approve" north-star and its residual risk is documented.

Decision IDs continue from Phase 206 (D-24..D-41). These are **D-42..D-57**, binding for planning.

### Approve / reject checkpoint mechanism (ORCH-03)
- **D-42 — File-driven, pre-filled `decisions.json` (transient input; the committed ledger is the durable record).** `ui.round` writes `test-results/ui-ratchet/round-NN/decisions.json` — **gitignored** (already
  covered by `test-results/`), deliberately a transient input. Every auto-fixable confirmed finding is
  pre-filled `"decision": "approve"`, so **batch-approve is the zero-edit path: just run `mix
  accrue_admin.ui.fix`.** Format is JSON (matches `export_copy_strings` → Jason). Each row carries
  human-readable context (`surface`, one-line `summary`, `region_tag`) **beside** the opaque `finding_id`,
  so the maintainer edits by meaning, never touches the hash. The **durable, PR-reviewable record is the
  `suppress`/`resolve` event appended to the committed `findings.ledger.ndjson`** — no second drift-prone
  audit artifact. This is the repo idiom: `ui.round` writes, `ui.fix` reads, both pure `File`/`OptionParser`,
  TTY-free (twins the phase200 file-artifact handoff). Rejected as anti-idiom: interactive stdin prompts
  (no existing task prompts; breaks under non-TTY; not replayable) and HTML-form writeback (server lifecycle
  in a mix task).
- **D-43 — Reject requires a closed-enum reason; `ui.fix` refuses silent/invalid bypass.** Flip a row to
  `"decision": "reject"` and set `"suppressed_reason"` (validated against the locked enum
  `wont-fix-intentional | duplicate-of:<id> | out-of-scope | false-positive | accepted-residual |
  wont-fix-cost`, D-41) + optional `"suppressed_note"`. `ui.fix` `Mix.raise`s on any missing/invalid reason.
  A **loud pre-apply banner** (`Applying N fixes, M suppressions:` with reason breakdown) + `--dry-run`
  guards the "silent mass-approve" footgun without a per-finding TTY loop. Suppress rows fold into the dedup
  suppress-list so the next round's proposer drops them before they re-enter as `open`.

### Guard auto-mint producer (ORCH-05) — the flagged fork, resolved to the data-row shape
- **D-44 — The generator emits a typed DATA ROW (not a code block); assertion LOGIC is a single human-written, once-reviewed loop.** `ui.fix` appends one typed row per resolved finding into a delimited marker region of
  the kind-appropriate existing home spec; a human-authored loop test iterates the table and applies the
  right computed-style helper. Values are **derived from the freshly re-captured post-fix DOM/CSS, never
  guessed** — this inverts the jest/characterization-test footgun (never lock in the still-wrong current
  behavior; the captured value is the just-verified fix). Rejected: full free-form assertion synthesis per
  finding (HIGH wrong-assertion/false-CI/vacuous risk, breaks §49 taste routing) and per-finding
  hand-authoring (defeats "sign-off, not per-issue hunting"). **This is the accepted fork:** the mint emits
  *data*, the assertion *logic* is reviewed once, not per finding.
- **D-45 — Assert the invariant, not the pixel; route by defect kind.** design-token bypass → `computed ==
  resolved(var(--ax-…))`; contrast → `contrastRatio(fg,bg) >= <WCAG floor the fix achieved>`; spacing/scale
  → computed value ∈ `ax-space-*` scale-step set (membership); microcopy → DOM text contains corrected
  string / not the old string; focus-ring / z-layer / reduced-motion → boolean/threshold. **Real-synth
  kinds:** design-token, contrast, spacing/scale, microcopy, focus/overlay/motion. **`ledger-count` sentinel
  kinds (D-40):** hierarchy/visual-weight, brand-tier gestalt, density-balance, responsive-composition, and
  anything `effort_class: ia-product-decision`. Because the synthesizable set *is* the mechanically-fixable
  auto-fix lane, **most auto-fixed findings get a real guard**, and `ledger-count` stays "small and visible."
- **D-46 — Idempotent, append-only, existing-homes-only; two-layer CI reconciles safety.** Key by
  `finding_id`: grep the target spec for `@ratchet:f-<id>` before appending → no-op if present (re-running
  `ui.fix` never duplicates). Insert only inside a delimited region (e.g. `// >>> @ratchet:auto-guards >>>
  … // <<< @ratchet:auto-guards <<<`), rows sorted by `finding_id` → deterministic, merge-friendly diffs
  that never restructure neighbors (lint/prettier stable). The `@ratchet:f-<id>` token lives in the row so
  the static substring gate sees it. **Never create a new file:** `GUARD_HOME_SPECS` is a closed constant
  duplicated in `phase-ratchet-ledger.mjs` + `verify_ratchet_ledger.mjs` with a byte-identical drift
  self-test; extending it is a deliberate separate PR, not a mint side-effect (a kind with no home routes to
  `ledger-count`). **Two-layer CI:** (1) the ratchet's own deterministic gate proves the guard *token is
  present* (fast, substring-only, no browser); (2) the guard-home specs already run in the existing admin
  e2e Playwright job, which *executes* the loop and gives assertions teeth. **Accepted residual risk
  (maintainer-visible, not silent):** the ratchet gate is substring-only, so gutting the loop body while
  keeping the rows is a deliberate, review-visible edit — the same honest-residual trust class 206 already
  documented for `ledger-count`.

### Round/loop state, dry-round detection, convergence + hard cap (ORCH-01, ORCH-04, ORCH-06)
- **D-47 — Round state = a NEW committed, append-only `rounds.ndjson` (sibling to `reopen-markers.ndjson`).**
  One row per round: `{round, dry, epoch, scope, bundle_sha256, seq}`. Counter = `max(round)`;
  consecutive-dry = trailing run of `dry:true` **within the current baseline epoch** (mirrors the reopen-marker
  epoch-binding, D-41). Round artifacts (digest.html, candidates, verdicts, PNGs) stay gitignored under
  `test-results/ui-ratchet/round-NN/`. This new file is required because **dry-ness is genuinely underivable
  from the finding ledger** (a dry round appends zero finding events, leaving no trace) — and deriving from
  gitignored `round-NN` dirs would be non-reproducible on a fresh clone/CI. It is an event log, not a mutable
  state blob, so it preserves the append-only D-38 idiom and the single-source-of-truth discipline.
- **D-48 — A round is DRY iff a 4-clause conjunction holds (deterministic reducer, no LLM):** (1) `ui.round`
  appended **zero new `open`** rows for this round, AND (2) **zero `open` findings remain** in the ledger fold
  (this clause *subsumes* "no pending-approved fixes" — an approved-but-unapplied fix leaves the finding
  `open` until `ui.fix` advances it), AND (3) both `finding-regressions.ndjson` **and** `regressions.ndjson`
  are **0 bytes**, AND (4) **all slice cells ≥ 2** (coverage floor, scoped by the active subset filter). All
  four inputs are committed files diffed by the self-tested node reducer.
- **D-49 — K=2 consecutive dry → `CONVERGED`; 6th round without convergence → unmissable escalation.** The
  round counter increments **on each `ui.round`** (the measurement step seals the `rounds.ndjson` marker;
  `ui.fix` does not seal a round). `CONVERGED` exits 0 with a "run sign-off" message. At the **6th** round
  without convergence: (a) digest banner `CAP REACHED — 6 rounds, N open, not converged`, (b) a terminal
  message naming the exact next action, and (c) a **non-zero exit** (`System.halt(2)` / `Mix.raise`) so it
  cannot be silently scripted past.
- **D-50 — `ui.round` and `ui.fix` stay TWO separate manual commands (Terraform plan/apply split).** The
  human checkpoint belongs between measurement and mutation. `ui.round` (measurement, read-only w.r.t.
  source): the verifier is the sole writer of `open`; it **does NOT** apply fixes, edit CSS/source, mint
  guards, commit code, or move any baseline. `ui.fix` (mutation): applies the approved batch, rebuilds+commits
  CSS + source, re-captures/re-scores, advances `open→resolved→verified-closed`, mints guards; it **does NOT**
  propose net-new findings, seal a round marker, or write a **frozen** baseline (freezing is 208-only via
  `--freeze`; 207 only recomputes the *unfrozen* baseline during iteration).
- **D-51 — Mix tasks are thin orchestrators; ALL file-reasoning lives in the node reducer.** Both tasks
  mirror `accrue_admin.assets.build.ex`: sequenced `System.cmd` steps via a swappable `Runner` behaviour
  (`Application.get_env(:accrue_admin, key, ShellRunner)`) for CI-safe testability, `Mix.raise` on non-zero,
  **reimplement nothing in Elixir**. Dry detection, the round counter, and the round-seal computation all live
  in the node reducer (`phase-ratchet-ledger.mjs`, which already owns the ledger + `--self-test`); Mix merely
  invokes `node`/`npm run`/`npx playwright`. This keeps convergence deterministic + self-tested and the mix
  tasks trivially unit-testable via a fake `Runner`.

### Surface/slice subset filter (ORCH-08)
- **D-52 — `--slice <name>` named preset + `--surface=a,b,c` CSV, resolved to a shared `RATCHET_SURFACES` env read by BOTH the capture spec and the proposer.** The mix task is the single resolution point: it
  expands `--slice foundation` (bare `--slice` = the default representative slice) or `--surface=dashboard`
  into `RATCHET_SURFACES=<csv>`; the capture spec (`admin-visuals.spec.js`) filters its `shots` array by
  name, and the proposer (`ratchet-propose.mjs`) filters discovered PNGs by `png.screen`. **Unset = the full
  configured surface set.** Capture only shoots the subset (no shoot-all-then-prune). The slice list is
  defined **once** as an exported `SLICES` map in `baseline-manifest.js` beside `SURFACES` (single source of
  truth; the 208 representative slice = design-system foundation + a few component families + dashboard +
  subscription-detail + subscriptions-list; at capture granularity the component families ride inside the
  single `component-kitchen` shot). Rejected: Playwright `--grep`/`--project` (wrong granularity — all shots
  live in one looping `test()`); freeform glob/regex (config sprawl; CSV substring covers single-surface).

### HTML digest / gallery (ORCH-02)
- **D-53 — Digest = a new Node `ratchet-digest.mjs` twinning `phase192-gallery.mjs`.** Self-contained HTML,
  inline CSS, no external deps, row-builder + validator + `--self-test` (the repo's proven
  self-contained-artifact idiom); emits `test-results/ui-ratchet/round-NN/digest.html`; invoked by `ui.round`.
  Opens locally/offline, regenerable, CI-checkable via its self-test. Borrow the Playwright-reporter *ideas*
  (grouping, overlays, self-contained), not the tool.
- **D-54 — "Decisions needed" predicate is deterministic: `effort_class === "ia-product-decision"` → decision queue; else (`"css"` | `null`) → auto-fixable worklist.** `effort_class` is set on the ledger row from
  `candidate.effort_hint` (`ratchet-ledger.js`/`ratchet-verify.mjs`), whose schema enum is
  `["css","ia-product-decision"]` (`ratchet-propose.mjs`), defaulting `null`. Pure equality on a closed enum
  — no model call.
- **D-55 — Region overlay = draw from the Phase 205 `.bbox.json` sidecar.** For each confirmed finding, read
  `${surface}${theme==="dark"?"-dark":""}.bbox.json` in the capture dir, look up `bbox[region_tag]` (the D-09
  capture-time `boundingBox()`), and draw an absolutely-positioned outline `<div>` over the embedded
  screenshot, scaling capture-viewport CSS px to the rendered `<img>` width (`scale = renderedWidth /
  project.viewport_width`; 1440 desktop / 390 mobile from `baseline-manifest.js`). A `null` box (selector
  absent on that surface) → no box; label the finding against the surface header instead.
- **D-56 — Deterministic ranking + brand-aligned, accessible layout.** Worklist sort key: `severity` asc
  (real→0, minor→1), then `persona_frequency` desc, then `effort_class` asc (css→0, null→1; cheap wins
  first), then `finding_id` asc (stable tiebreak). Decisions-needed queue: `severity`, `persona_frequency`
  desc, `finding_id`. All fields on the ledger row — zero non-determinism. Layout: sticky **summary banner**
  (`Round 3 — 14 confirmed, 9 root-cause, 0 IA decisions`, plus a `CONVERGED (2 dry rounds)` badge when dry)
  → **Worklist** → **Decisions needed** (distinct accent, 0–2 forks) → **gallery grouped by surface** with
  region overlays. Brand tokens from the CURRENT `brandbook/index.html` (Geist sans; mono for
  `finding_id`/`claim_key`/`region_tag`; restrained neutral palette — "quiet, well-made dev tooling, not
  fintech"). Semantic HTML (`<section>`/`<table>`/`<details>`); honor `prefers-color-scheme` (standalone
  artifact, not the admin's `data-theme` chrome); encode severity with **text + shape, not color alone**;
  overlay = 2px accent outline + small label chip, never a fill that hides the defect.

### Prompt caching (ORCH-07)
- **D-57 — Add `cache_control:{type:"ephemeral"}` breakpoints on the stable prefix; NO reorder required.** In
  `ratchet-propose.mjs` (mirrored in `ratchet-verify.mjs`): convert the `system` string → blocks with a
  cache breakpoint, add a breakpoint on the last `tools` entry, and add a breakpoint on the per-screenshot
  **target-image block** (identical across the 7 calls/screenshot — the dominant repeated payload). The API
  caches the linear `tools → system → messages` prefix, so this caches schema + system + screenshot for all
  7 calls with no reordering (the target image is already the first content block). Per-persona prompt +
  per-candidate content stay **uncached** after the breakpoint. **Invariants preserved:** identity is
  re-derived by `region-tags.js` and is order/cache-independent; the three guards (`--self-test` → no-key
  exit-0 → SDK import) run *before* any request is built, so caching never touches the no-key/`--self-test`
  paths; `cache_control` is request-shape only.

### Claude's Discretion (safe to leave to research/planning)
- **`rounds.ndjson` as a separate sibling file vs folded into `findings.ledger.ndjson` as `round_sealed`
  events** — chose SEPARATE (keeps the finding reducer's `latest-event-wins per finding_id` fold pure;
  mirrors the `reopen-markers.ndjson` precedent). This is the single mildly-hard-to-reverse committed-schema
  choice — worth a nod at plan time, but not escalated.
- **ORCH-07 exemplar-first reorder (max savings)** — deferred as a cheap, reversible **same-phase follow-on
  toggle**: additionally move the two design-lens exemplar images ahead of the target image in
  `buildDesignContent` + breakpoint after them, so the exemplar pair caches across every screenshot of a
  `surface_type` within the 5-min ephemeral window. Ship D-57's "no-reorder" baseline first; needs only a
  small prompt-copy reword ("attached AFTER this prompt"). Planner may fold it in if cheap.
- Exact `decisions.json` field ordering; whether `ui.fix` adds an optional aggregate TTY `yes?` (skipped
  non-TTY) on top of the file-edit consent; exact delimited-marker syntax for the auto-guard region; exact
  `bundle_sha256` capture point in `rounds.ndjson`; whether the digest embeds screenshots as `data:` URIs or
  relative `round-NN/` paths; precise banner copy.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone design & requirements (READ FIRST)
- `~/.claude/plans/ui-ratchet-txt-i-agile-honey.md` — the full v1.56 milestone design. For 207: lines
  55–62 (the two-command `mix accrue_admin.ui.round`/`ui.fix` maintainer loop + the ONLY-3-interactions),
  line 57 (digest description), §49 (guard homes routed by defect kind), §51 (finite-lattice termination /
  K=2 dry rounds / 6-round cap), §99–108 (footguns, esp. committed-CSS-drift + non-convergence).
- `.planning/REQUIREMENTS.md` — ORCH-01..08 are lines 48–55 (this phase); CONV-02/03 (freeze + wire CI) are
  208-handoff awareness.
- `.planning/ROADMAP.md` §"Phase 207" (SC 1–7 are the binding contract) + §"Phase 208" (to place the
  207/208 seam — convergence DETECTION is 207; FREEZING the baseline + wiring CI + ACCEPT are 208).

### Locked upstream decisions (Phases 205 & 206 — do NOT re-litigate)
- `.planning/phases/206-adversarial-verifier-finding-ledger-deterministic-gate/206-CONTEXT.md` — D-35
  (verifier is the sole writer of `open`; 207 only removes/advances), D-36 (207 is a pure superset-layer:
  ZERO new writers of `open`), D-37 (baseline non-empty-but-UNFROZEN in 206, FROZEN 208-only via `--freeze`),
  D-38 (append-only NDJSON event log + monotonic `seq`), D-39 (inline `@ratchet:<finding_id>` guard token +
  `GUARD_HOME_SPECS` allowlist + static-substring gate), D-40 (`ledger-count` sentinel = honest residual),
  D-41 (`reopen-markers.ndjson` epoch-binding + closed `suppressed_reason` enum + suppress-list feeds dedup).
- `.planning/phases/205-persona-design-lens-evaluator-harness/205-CONTEXT.md` — D-01 (coarse 4-axis claim-key
  + `finding_id`), D-09 (`.bbox.json` capture-time region-selector coords for THIS overlay), D-10 (region
  SSOT), D-12 (`cell_refs` FK into the 30,348-cell census), D-13 (severity 2-level), D-14 (`job_blocking`),
  D-16 (deterministic justification-token gate), D-17 (`ratchet-candidate/1` row schema incl. `effort_hint`).

### Reuse / twin targets (promote + twin, don't reinvent)
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — the mix-task orchestration idiom to mirror:
  `Runner` behaviour + `System.cmd` + `Application.get_env` runner-swap + `Mix.raise` on non-zero (D-51).
- `accrue_admin/lib/mix/tasks/accrue_admin.e2e.server.ex` — the `MIX_ENV=test mix accrue_admin.e2e.server`
  boot on `ACCRUE_ADMIN_E2E_PORT` (default 4017) that `ui.round` must start before capture.
- `accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex` — the non-interactive `OptionParser` +
  `File.read!/write!` + `Jason` idiom for the `decisions.json` reader/writer (D-42).
- `accrue_admin/e2e/phase192-gallery.mjs` — the self-contained HTML gallery to TWIN for `ratchet-digest.mjs`:
  row builders + field validators + `runSelfTest()` (D-53).
- `accrue_admin/e2e/phase200-scorecard.mjs` — the deterministic reducer idiom + `regressions.ndjson`-0-bytes
  contract the dry-round detector reuses (D-48).
- `accrue_admin/e2e/ratchet/phase-ratchet-ledger.mjs` — the reducer that OWNS the ledger; gains the
  round-seal + dry computation (D-48/D-51). Read how it validates `guard_ref` presence so the mint satisfies
  it exactly (D-46).
- `scripts/ci/verify_ratchet_ledger.mjs` — the independent re-verifier holding the second copy of the
  `GUARD_HOME_SPECS` allowlist + drift self-test (D-46).
- `accrue_admin/e2e/ratchet/ratchet-propose.mjs` — the message-builder to add `cache_control` to (D-57) and
  the `discoverPngs()` seam to filter by `RATCHET_SURFACES` (D-52); also the `effort_hint` enum source (D-54).
- `accrue_admin/e2e/ratchet/ratchet-verify.mjs` — mirror the `cache_control` change here (D-57).
- `accrue_admin/e2e/ratchet/ratchet-ledger.js` — where `effort_class` is set from `effort_hint` (D-54) and
  the typed append helpers the guard-mint + lifecycle advances reuse.
- `accrue_admin/e2e/ratchet/region-tags.js` — the SDK-free identity SSOT; identity is ALWAYS re-derived here,
  never from the LLM (invariant behind D-57 cache-safety).

### Capture / surface grammar (the filter + overlay seams)
- `accrue_admin/e2e/admin-visuals.spec.js` — the single looping `test()` whose `shots` array `ui.round`
  filters by `RATCHET_SURFACES` (D-52); the capture-time `boundingBox()` that emits `.bbox.json` (D-55).
- `accrue_admin/e2e/baseline-manifest.js` — `SURFACES`, `DIMENSIONS`, `THEMES`, `PROJECTS`, viewport widths;
  gains the exported `SLICES` map (D-52) as the single source of truth for the representative slice.
- `accrue_admin/playwright.config.js` — the `webServer` boot contract (4017, `/__e2e__/health`).

### Guard homes (real spec files the mint appends into — never a new file)
- `accrue_admin/e2e/foundation-tokens.spec.js` (token/contrast/spacing), `accrue_admin/e2e/
  admin-interaction-overlay-phase199.spec.js` (focus/overlay; greppable `@phase199 @overlay` title tags),
  `accrue_admin/e2e/reduced-motion.spec.js` (motion), `accrue_admin/e2e/admin-page-flow-phase200.spec.js`
  (microcopy DOM-text) — the `GUARD_HOME_SPECS` allowlist (D-45/D-46).

### Brand & JTBD (the digest is a maintainer-facing UI)
- `brandbook/index.html` — CURRENT brand book (prefer over the older `prompts/accrue-brand-book.md`): "quiet
  polish, well-made dev tooling, not fintech"; Geist sans + mono; restrained neutral palette (D-56).
- `prompts/accrue-brand-book.md` — older brand DNA (defer to `brandbook/index.html` where they differ).
- `prompts/accrue_admin_operator_ui_journey_blueprint.md`, `.planning/research/JTBD-FRONTIER.md` — operator
  JTBD framing; NOTE the digest serves the **maintainer** persona (triage a round, decide fast), NOT the
  adopter operator personas the evaluator emulates.

### Ecosystem idiom (gate/baseline/suppression conventions)
- `../lattice_stripe/prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`,
  `elixir-best-practices-deep-research.md`, `phoenix-best-practices-deep-research.md` — Elixir OSS
  mix-task/gate/baseline conventions; cross-language analogs cited by research: PHPStan/RuboCop-todo
  baselines, changesets file-driven approval, Terraform plan/apply, jest/characterization-test guard
  footguns, Playwright/Chromatic visual-review galleries, pytest `-k` / Playwright `--project` filters.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `accrue_admin.assets.build.ex`: the exact mix-orchestrator template — `Runner` behaviour, `System.cmd`,
  runner-swap via `Application.get_env`, `Mix.raise`. `ui.round`/`ui.fix` are near-mechanical twins that
  shell out to `node`/`npm run ratchet:*`/`npx playwright` and reimplement no logic in Elixir.
- `phase192-gallery.mjs`: the self-contained HTML gallery to twin for `ratchet-digest.mjs` (row builder +
  validator + `--self-test`, no deps, brand-voiced).
- `phase200-scorecard.mjs` + `phase-ratchet-ledger.mjs`: the deterministic-reducer + `regressions.ndjson`-
  0-bytes pattern the dry-round detector reuses; the ledger reducer gains round-seal + dry computation.
- `ratchet-propose.mjs` / `ratchet-verify.mjs` / `ratchet-ledger.js` / `region-tags.js`: the proposer message
  builder (cache_control + surface filter), verifier (mirror cache_control), ledger append helpers +
  `effort_class`, and identity SSOT.
- `admin-visuals.spec.js` + `baseline-manifest.js`: the capture `shots` loop + surface SSOT — the filter and
  `.bbox.json` overlay seams.

### Established Patterns
- **Thin-mix-task-over-node-scripts:** Elixir orchestrates via `System.cmd`; all ledger/reducer/identity
  reasoning stays in the self-tested node layer so the LLM and Elixir are both off the deterministic path.
- **Detector-then-baseline forward-only ratchet (205/206):** machine detects → verifier auto-persists `open`
  → human batch-approves or suppresses → `ui.fix` advances + mints a guard → baseline moves only in the
  fewer-findings direction; FREEZING into CI is a separate deliberate act (208).
- **Self-contained-artifact convention:** deterministic HTML/JSON artifacts with a `--self-test`, no external
  deps, committed-or-gitignored deliberately, opens/replays locally.
- **Committed-CSS-bundle discipline:** `ui.fix` must run `mix accrue_admin.assets.build` and commit
  `priv/static` before re-capture; the round marker records `bundle_sha256`.
- **Append-only NDJSON event logs + epoch-binding:** `findings.ledger.ndjson`, `reopen-markers.ndjson`, and
  the new `rounds.ndjson` all share monotonic `seq` + latest-event-wins folds + current-epoch scoping.

### Integration Points
- New files under `accrue_admin/e2e/ratchet/`: `ratchet-digest.mjs`, `rounds.ndjson`; new mix tasks
  `accrue_admin/lib/mix/tasks/accrue_admin.ui.round.ex` + `accrue_admin.ui.fix.ex`; `SLICES` added to
  `baseline-manifest.js`; `RATCHET_SURFACES` filter added to `admin-visuals.spec.js` + `ratchet-propose.mjs`;
  `cache_control` added to `ratchet-propose.mjs` + `ratchet-verify.mjs`; auto-guard marker regions added to
  the `GUARD_HOME_SPECS`. Wire `ui:round`/`ui:fix`/`ratchet:digest` npm scripts in `accrue_admin/package.json`
  beside `ratchet:*`.
- `phase-ratchet-ledger.mjs` gains the round-seal + dry-round computation (+ `--self-test` coverage).
- The `admin-ui-ratchet-guardrails` deterministic CI job stays DEFERRED to Phase 208 (207 wires no CI).
- All new tooling is dev/test-only; nothing enters adopter runtime.

</code_context>

<specifics>
## Specific Ideas

- Batch-approve is the **zero-edit path**: pre-filled `decisions.json` defaults every auto-fixable finding to
  `approve`, so the maintainer's happy path is literally "run `mix accrue_admin.ui.fix`."
- The maintainer's total interaction surface across a round is exactly three actions (design line 58):
  batch-approve (or edit rejects), answer 0–2 IA/product forks, sign off once the digest shows
  `CONVERGED (2 dry rounds)`.
- Digest summary-banner copy target: `Round 3 — 14 confirmed, 9 root-cause, 0 IA decisions` + a `CONVERGED`
  / `CAP REACHED` badge.
- The guard-mint emits **data, not code** — the assertion logic is one human-reviewed loop; this is the
  deliberate cut that keeps "sign-off, not per-issue hunting" true while still giving real CI teeth via the
  existing admin e2e Playwright job.
- Keep the `ledger-count` (honest-residual) set small and visible — most auto-fixed findings should carry a
  real minted guard.

</specifics>

<deferred>
## Deferred Ideas

- **Run the loop to CONVERGENCE on the representative slice; FREEZE the first non-empty
  `ledger.baseline.json` (via `--freeze`); wire the `admin-ui-ratchet-guardrails` deterministic CI job;
  maintainer ACCEPT + runbook** — Phase 208 (CONV-01..07). 207 delivers the machinery + convergence
  DETECTION; 208 proves + freezes + gates.
- **Full ~19-surface sweep** — Phase 209 (optional/scope-gated, SWEEP-01).
- **ORCH-07 exemplar-first reorder for cross-screenshot exemplar caching** — a cheap, reversible same-phase
  follow-on toggle on top of D-57's no-reorder baseline; planner may fold it in.

No scope creep surfaced — discussion stayed within the phase boundary.

</deferred>

---

*Phase: 207-orchestration-digest-one-command-round-fix-loop*
*Context gathered: 2026-07-04*
