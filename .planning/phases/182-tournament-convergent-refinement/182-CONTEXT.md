# Phase 182: Tournament Convergent Refinement - Context

**Gathered:** 2026-06-13 (from the user's Round 1 verdict + approved Round 2 plan, delivered conversationally at the Phase 181 checkpoint)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 182 delivers the convergent refinement stage of the logo tournament (LOGO-03):

1. **Round 2 (and any further rounds) authored from the TOURNAMENT.md Round 1 ledger entry**: 6–9 variants of the ≤2 finalists (B4 primary, B1 runner-up), rendered in the same 8-tile context matrix plus increasingly real contexts.
2. **Real color treatments are the new exploration axis** (user request): brand-palette color (not monochrome-only), shown in light mode + dark mode + forced monochrome at multiple sizes. Every variant must remain monochrome-DERIVABLE (BRAND-DNA hard constraint).
3. **Monotonic ledger**: each round's verdict appends verbatim to `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/TOURNAMENT.md` at the `<!-- ROUND-2-APPEND-BELOW -->` marker. No R1-C constraint is re-litigated.
4. **✋ Looping checkpoint**: user judges each round's gallery; loop concludes when the user locks a single winner. If 3 rounds complete without a lock, surface an explicit "extend one more round or settle on [candidate]?" question.
5. **Final entry freezes the winner**: candidate ID + ratified mark and lockup geometry recorded for Phase 183.

Out of scope: production logo system in `brandbook/` (Phase 183). All exploration artifacts stay in `.planning/`.

</domain>

<decisions>
## Implementation Decisions

### Round 1 verdict — binding constraints (R1-C IDs, never re-litigate)
- **R1-C1:** Direction locked to B (stepped intervals). All Round 2 variants derive from Direction B; Directions A, C, D are dead.
- **R1-C2:** Preserve the "stepping up toward the type treatment" gesture — ascending steps oriented toward the logotype; the mark→type relationship is a feature to strengthen, not incidental.
- **R1-C3:** Logotype treatment locked — Geist, current weight/case ("the font choice seems fine with me").
- **R1-C4:** Round 2 must present real color treatments (light + dark + mono, multiple sizes), while every variant remains monochrome-DERIVABLE per BRAND-DNA. (User asked "is monochrome our style?" — answer: no, mono is a derivation requirement; Moss #5E9E84 is the brand's primary accent.)

### Round 2 variant axes (user-ratified direction from the verdict conversation)
- **D-182-01:** Anchors: **B4** (steps:6, stepHeight:0.18, stepWidth:0.18, curvature:0 — user's primary pick) and **B1** (steps:4, stepHeight:0.25, stepWidth:0.25, curvature:0.05 — user's runner-up).
- **D-182-02:** Structure sweep around B4: step count 4/5/6, step proportions, curvature on/off. Must include at least one variant addressing B4's known weakness (6 fine steps merge into a boxy shape at 16px favicon scale — self-review scored B4 legibility-16px = 2; e.g. a chunkier 5-step compromise between B1 and B4).
- **D-182-03:** Mark→type relationship variants (per R1-C2): e.g. final step rising to exactly cap height adjacent to the "a", tighter gapRatio, step rhythm echoing letter spacing.
- **D-182-04:** Color treatments (the new axis): Ink mono baseline, full-Moss mark (#5E9E84), two-tone Ink+Moss (e.g. final/top step in Moss). Every color variant passes the existing monochrome-derivable lint. Logotype stays Ink (#181818 greyscale fill for lint compliance) unless a variant has a cited reason.
- **D-182-05:** Total per round: 6–9 variants (ROADMAP cap) — likely ~3 structures × ~3 color treatments with overlap pruned to fit; combinatorics culled at planning time, not generation time.

### Harness reuse (from Phase 181 — committed, verified working post-coordinate-fix)
- **D-182-06:** Reuse `geist-spine.mjs` + `assemble-lockup.mjs` as-is; extend `assembleLockup` palette support to per-element fills for two-tone marks.
- **D-182-07:** Parameterize the hardcoded phase-dir paths in `lint.mjs`, `generate.mjs`, `render-matrix.mjs`, `build-gallery.mjs` so they run for the 182 phase dir (this was the known deferred item from 181). `b-step.mjs` is the single generator, extended with the new knobs.
- **D-182-08:** Keep the 8-tile render matrix (paper-light, ink-dark, 32/16px favicons, avatar-circle, readme-header, social-card, mono), the INK_DARK_COLOR_MAP fill-swap, and the blank-render guard. Extend the ink-dark color map for Moss-on-dark. Per ROADMAP SC-1, rounds add "increasingly real contexts" — actual README header text and actual social-card copy in those tiles.
- **D-182-09:** Gallery: `round-2-gallery.html` in the 182 phase dir, same verdict-block UX, verdict appends at `<!-- ROUND-2-APPEND-BELOW -->` in the 181 TOURNAMENT.md (single ledger file — 182 references it, never forks it).

### Lessons from 181 the planner MUST honor (from 181-REVIEW.md + fix history)
- **D-182-10:** Visual verification is mandatory before any user checkpoint: agent Reads the rendered PNGs (the 181 coordinate-space bug shipped a broken gallery because nobody looked). Blank-render guard stays in the pipeline.
- **D-182-11:** No unused rendering contracts: 181's Critical CR-01 was Direction C emitting a `markGroupSvg` stroke contract that `assembleLockup` never consumed (arcs rendered as filled domes). Any new generator output field must be consumed by the assembler or not exist; if color variants add fill/stroke structure, wire it end-to-end and verify in a rendered PNG.
- **D-182-12:** Lint thresholds are not tuned to explain away bad renders — 16px legibility CR stays at 3.0; investigate renders first if candidates fail.
- **D-182-13:** Triage 181-REVIEW.md warnings during harness-reuse work: fix what the Round 2 pipeline actually exercises (e.g. smoke-mode index.json clobber, tautological gap-ratio lint, avatar tile not actually circle-cropping) — do not blanket-fix all 18 findings; this phase's deliverable is the tournament, not a harness rewrite.

### Claude's Discretion
- Exact variant matrix (which structure × color combos make the 6–9 cut) and stable ID scheme for Round 2 candidates (e.g. R2-1..R2-9 or B4a/B4b/B1a...).
- How phase-dir parameterization is implemented (env var, CLI arg, or config import).
- Which "increasingly real context" copy goes in the readme-header and social-card tiles.
- Plan breakdown and wave structure.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/TOURNAMENT.md` — the ledger: Round 1 verdict (verbatim), R1-C1..C4, the `<!-- ROUND-2-APPEND-BELOW -->` marker this phase appends at.
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/harness/` — the working pipeline to reuse (geist-spine, assemble-lockup, dirs/b-step, lint, generate, render-matrix, build-gallery).
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/181-REVIEW.md` — 18 code-review findings; see D-182-11/D-182-13 for triage policy.
- `.planning/phases/181-svg-pipeline-tournament-round-1-divergent/181-06-SUMMARY.md` — pipeline invocations + the 4 post-completion fixes (coordinate-space contract documented in assemble-lockup.mjs header).
- `.planning/phases/180-brand-audit-dna-lock/BRAND-DNA.md` — locked palette with usage rules (Moss #5E9E84 primary accent; Ink/Slate/Fog/Paper neutrals; Cobalt interactive; Amber sparing) — the color-treatment tiebreaker.
- `.planning/phases/180-brand-audit-dna-lock/logo-brief.md` — the 4 hard constraints, still binding on every Round 2 variant.
- `.planning/ROADMAP.md` Phase 182 — goal + 4 success criteria (6–9 variants of ≤2 finalists; monotonic ledger; ≤3 rounds with settle-or-extend; final entry freezes winner geometry).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 181 harness (committed, post-fix verified): `node_modules` already installed in the 181 harness dir (opentype.js, wawoff2, playwright, pngjs, svgo, geist). Decide whether 182 symlinks/reuses that dir or installs its own — reuse is cheaper and version-identical.
- `assembleLockup(markPathD, glyphs, config)` — coordinate contract documented in module header: glyphs carry baked absolute X, baseline y=0; mark scaled `s = capHeight/markHeight` onto `BASELINE = capHeight*1.1`; single logotype `<g>`. `palette` config currently `{ink, paper}` single-fill.
- `b-step.mjs generate(config)` → `{markPathD, markWidth, markHeight}` with knobs steps/stepHeight/stepWidth/curvature, BASE_UNIT=40.
- Mark fills must be saturation ≤0.15 for `lintMonochromeDeriv` — Moss #5E9E84 has sat ≈ 0.40, so the monochrome-derivable lint semantics for COLOR variants need care: the lint's intent is "mark survives mono conversion" (structure not hue-dependent), not "mark is grey." Planner should specify how color variants satisfy the lint (e.g. lint the mono-derived rendering, or per-variant declared mono mapping) without weakening its intent.

### Integration Points
- Phase 183 consumes: locked winner's generator config + frozen geometry from the final TOURNAMENT.md entry.
- The checkpoint loop is per-round: gallery → user verdict → append ledger → either next round (new variants from verdict) or winner locked.
</code_context>

<specifics>
## Specific Ideas

- User's verbatim Round 2 request: "can we do another round of exploration like a tournament of main variations that might significantly improve things given our focused direction here, showing the colors dark and light mode + monocrhome at diff sizes etc etc so we can hone in on a final logo/brand"
- Round 2 verdict block schema mirrors Round 1 (D-11 from 181) with R2-C{n} constraint IDs.
- B4's 16px weakness is the most valuable structural problem to solve this round — the user's favorite must also work as a favicon.
</specifics>

<deferred>
## Deferred Ideas

- Full harness-warning cleanup (all 18 REVIEW findings) — only pipeline-exercised fixes happen in 182 (D-182-13); the rest can ride to Phase 183 production hardening if still relevant.
</deferred>

---

*Phase: 182-Tournament Convergent Refinement*
*Context gathered: 2026-06-13*
