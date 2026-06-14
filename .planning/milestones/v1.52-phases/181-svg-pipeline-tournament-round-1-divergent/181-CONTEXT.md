# Phase 181: SVG Pipeline + Tournament Round 1 — Divergent - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 181 delivers the divergent ideation stage of the logo tournament (LOGO-01, LOGO-02):

1. A **reproducible Node harness** that uses opentype.js to emit exact Geist letterform outlines (one `<path>` per glyph, with IDs) and runs **automated pre-gate lints**: valid SVG parse, no-rect-background, lockup gap ratio within spec, 16px legibility screenshot, monochrome derivable, no subtitle in main lockup. No candidate that fails a lint reaches the user.
2. **12–16 candidates across 4 fixed conceptual directions**: (A) accumulation strata, (B) stepped interval / timeline tick, (C) layered arcs / state transition, (D) fully-integrated typemarks (path surgery on Geist outlines).
3. A **self-contained `round-1-gallery.html`** (file://-openable, SVGs inlined) rendering every candidate in a fixed context matrix: paper-light, ink-dark, 32px favicon, 16px favicon, GitHub avatar circle-crop, README header mock, social card mock, monochrome row. Stable IDs (A1…D4) + one-line rationale each.
4. **✋ User checkpoint**: pick 1–3 winners with per-winner keep/change notes, recorded verbatim as the round-1 entry in `TOURNAMENT.md`.

Out of scope: refinement rounds (Phase 182), the production logo system in `brandbook/` (Phase 183). Nothing this phase produces lands in `brandbook/` — all exploration artifacts stay in `.planning/`.

</domain>

<decisions>
## Implementation Decisions

### Generation approach
- **D-01:** **Per-direction mini-generators (hybrid parametric).** Each of the 4 directions gets its own small Node geometry module with 3–4 knobs (e.g., motif amplitude, stroke weight, spacing, layer count); each candidate is a config of knobs. Shared once across directions: opentype.js Geist spine, lockup assembly, lint suite, renderer.
- **D-02:** Direction D (integrated typemarks) additionally gets bespoke glyph-outline surgery on the extracted Geist paths (e.g., the `cc` pair as echoed layers, stepped `e` crossbar, `u` as filling interval) — its generator is thinner, hand-work is expected there.
- **D-03:** Rationale on record: Phase 182's variation rounds sweep exactly the dimensions the parametric model exposes (weight, motif amplitude, lockup spacing/kerning, terminals) — variations become parameter re-renders, not path surgery. Hand-authoring everything was rejected as it makes Phase 182 manual coordinate math and weakens the reproducibility story.

### Gate-failure & curation policy
- **D-04:** **Overgenerate and cull.** Generate ~20–24 raw candidates, run pre-gate lints + agent self-scoring as one deterministic pass, cull to the best 12–16 that pass. Lint failures are culled, never repaired in-loop (fix-until-pass was rejected — repair loops homogenize a divergent round).
- **D-05:** **Per-direction floor: ≥3 candidates per direction** in the final gallery. If a direction drops below the floor after culling, do capped targeted regeneration for that direction only (no unbounded retries).
- **D-06:** **Rejected/culled candidates are preserved** with their failure/score reasons in a `rejected/` area within the phase artifacts (evidence-on-record convention) — not shown in the main gallery flow.

### Legibility & self-review judging
- **D-07:** **Split judge.** The 16px legibility pre-gate lint is a **deterministic pixel heuristic**: decode the 16px Playwright PNG (pngjs) and fail on measurable proxies — fg/bg contrast ratio below threshold, connected-component/distinct-feature count outside band, edge-density collapse vs the 32px render. No API key, reproducible, CI-safe. Same SVG → same verdict.
- **D-08:** The pre-checkpoint **self-review is agent vision against a fixed rubric**: the executing agent Reads every context-matrix screenshot and scores each candidate on legibility, monochrome survival, avatar-crop integrity, brand fit — using the 0–3 score / pass-≥2 / NDJSON conventions from `accrue_admin/e2e/score-visuals.mjs` (Phase 179 precedent) but WITHOUT the API dependency (no @anthropic-ai/sdk call; the agent already has vision).
- **D-09:** Uniform LLM judging of the gate was rejected: a nondeterministic hard gate breaks the "reproducible harness" contract and silently degrades when ANTHROPIC_API_KEY is absent. Principle on record: **lint = deterministic, review = judged.**

### Verdict capture mechanics
- **D-10:** **Interactive gallery.** `round-1-gallery.html` includes lightweight vanilla JS (~60 lines, no deps, still file://-openable): per-candidate winner checkbox + keep/change note textareas + a "copy verdict block" button that emits a structured markdown block. Clipboard via `navigator.clipboard.writeText()` (file:// is a secure context) with a visible select-on-click `<pre>` fallback.
- **D-11:** The emitted verdict block and the `TOURNAMENT.md` round-1 entry **share one schema** so the agent appends the pasted block unmodified (verbatim by construction). Schema: round heading + date; `**Winners:**` ID list; explicit `**Killed:**` ID list; per-winner `### {ID}` sections with verbatim `keep:` / `change:` quotes; then a separate `### Constraints` section with stable `R1-C{n}` IDs, extracted by the agent from the verbatim notes and user-confirmed — normalization never overwrites the user's prose.
- **D-12:** The constraint IDs (`R{round}-C{n}`) are the handles Phase 182 uses for the monotonic never-re-litigate invariant.

### Claude's Discretion
- Exact knob set per direction generator and module layout of the harness.
- Pixel-heuristic thresholds for the 16px lint (tune to avoid false-fails on intentionally minimal marks); exact lockup gap-ratio spec value.
- Geist sourcing: fetch TTF from `vercel/geist` (SIL OFL 1.1) as primary; fallback converting in-repo `accrue_admin/priv/static/fonts/geist-sans-vf.woff2` → TTF via fonttools/wawoff2 (per design source).
- Exact location of the harness, gallery, screenshots, and `TOURNAMENT.md` within `.planning/` (design source convention: exploration artifacts in `.planning/milestones/v1.52-phases/`; active-phase artifacts conventionally live in the phase dir — planner picks one and keeps `TOURNAMENT.md` somewhere stable across Phases 181–183, since 182/183 append to and read it).
- Plan breakdown (~5 plans per design source: Wave 1 pipeline; Waves 2–3 generation; gallery + checkpoint).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Binding brand constraints (Phase 180 outputs — ratified)
- `.planning/phases/180-brand-audit-dna-lock/logo-brief.md` — **binding logo design brief**: the 4 hard constraints (no rect background/container, logotype optically close, no subtitle in main lockup, integrated typemark options required) that become this phase's pre-gate lints; design posture (Prisma/Vercel exemplar family, state/lifecycle imagery, never finance clichés).
- `.planning/phases/180-brand-audit-dna-lock/BRAND-DNA.md` — locked palette (Ink #111418, Slate #24303B, Fog #E9EEF2, Paper #FAFBFC, Moss #5E9E84, Cobalt #5D79F6, Amber #C8923B with usage rules), Geist/Geist Mono, voice, visual personality (accumulation/timelines/state transitions/layered records; avoid coins/cards/carts/gradient blobs). The tiebreaker document.
- `.planning/phases/180-brand-audit-dna-lock/BRAND-AUDIT.md` §8 (logo-system spec) and §9 (visual-example guidance) — the argument behind the brief; consult when a candidate decision needs rationale.
- `.planning/phases/180-brand-audit-dna-lock/quality-gate-checklist.md` — Phase-186 quality dimensions; candidates should not obviously fail these.

### Milestone design source
- `.planning/research/v1.52-brand-system-design.md` — authoritative Phase 181 spec: opentype.js `font.getPath().toPathData()` approach, Geist TTF sourcing + fallback, the 4 directions with motif examples, pre-gate lint list, context matrix contents, ID scheme, checkpoint protocol, exploration-artifact location convention.

### Milestone bookkeeping
- `.planning/ROADMAP.md` — Phase 181 goal + 4 success criteria.
- `.planning/REQUIREMENTS.md` — LOGO-01, LOGO-02 (this phase); LOGO-03 (Phase 182 consumes this phase's `TOURNAMENT.md` entry — schema must serve it).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `accrue_admin/e2e/score-visuals.mjs` — Phase 179 LLM visual-scoring script (Playwright screenshots + 0–3 rubric + NDJSON output + key-guard skip). **Reuse its rubric/output conventions for the agent self-review (D-08); do NOT reuse its API call for the gate (D-09).**
- `accrue_admin/playwright.config.js` + `@playwright/test` ^1.57 + chromium already installed in `accrue_admin/package.json` — the screenshot infrastructure for the 16px legibility lint and context-matrix QA.
- `accrue_admin/priv/static/fonts/geist-sans-vf.woff2`, `geist-mono-vf.woff2` — in-repo Geist variable fonts (TTF-conversion fallback source for opentype.js).

### Established Patterns
- Evidence-gated churn (milestone rule): every cull/score decision should carry a recorded reason (D-06 rejected/ area).
- Exploration artifacts never land in `brandbook/` — committed `brandbook/` arrives in Phase 183.
- The repo commits planning docs on main; the harness should be committed (reproducibility requirement).

### Integration Points
- Phase 182 consumes: the `TOURNAMENT.md` round-1 entry (D-11 schema, D-12 constraint IDs), the per-direction generators (variation rounds = parameter re-renders), and the lint suite + context-matrix renderer (same gates every round).
- Phase 183 consumes: the locked winner's generator config + the outline/optimization pipeline.
- The 4 hard constraints from `logo-brief.md` map 1:1 to pre-gate lints — the brief is the lint spec.

</code_context>

<specifics>
## Specific Ideas

- Design-source motif examples for direction D path surgery: the `cc` pair as echoed layers, stepped `e` crossbar, the `u` as a filling interval (lowercase "accrue" letterforms).
- Verdict block example shape (D-11):

  ```markdown
  ## Round 1 — {date}
  **Winners:** B2, C4
  **Killed:** A1 A2 A3 A4 B1 B3 B4 C1 C2 C3 D1 D2 D3 D4
  ### B2
  - keep: "<verbatim>"
  - change: "<verbatim>"
  ### Constraints (extracted by agent, user-confirmed)
  - R1-C1: <normalized constraint>
  ```
- Self-review rubric dimensions: 16px legibility, monochrome survival, avatar-crop integrity, brand fit (DNA visual personality as the rubric anchor).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 181-SVG Pipeline + Tournament Round 1 — Divergent*
*Context gathered: 2026-06-11*
