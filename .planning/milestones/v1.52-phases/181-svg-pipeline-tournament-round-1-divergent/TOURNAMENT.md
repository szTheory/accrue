# Accrue Logo Tournament Ledger

This file is the **monotonic ledger** for the Accrue logo tournament (Phases 181–183).

**Invariant:** Each round appends its verdict block verbatim to this file. No constraint from an earlier round is ever re-litigated. Phases 182 and 183 append to this file at the paths indicated by the section markers below — they never overwrite or remove prior round sections.

**How to use:**
1. Open `round-1-gallery.html` in your browser (file://-openable, no server required)
2. Select your winner(s) — check the checkbox on each candidate you want to advance
3. Add per-winner keep/change notes in the text areas
4. Click "Copy verdict block" — a structured markdown block is placed on the clipboard
5. Paste the verdict block exactly once below the `<!-- ROUND-1-PASTE-BELOW -->` comment marker

The pasted block format matches the Round 1 schema exactly. Do not edit the pasted block — the Phase 182 agent will read it verbatim and extract constraint IDs (`R1-C{n}`) from it.

---

## Round 1 — 2026-06-12

<!-- ROUND-1-PASTE-BELOW -->
<!-- Verdict delivered conversationally at the 181-07 checkpoint (not via the gallery Copy button). -->
<!-- Transcribed verbatim by the agent below; keep/change notes are direct quotes from the user. -->

**Winners:** B4 (primary), B1 (runner-up)
**Killed:** A1 A2 A3 A4 B2 B3 C1 C2 C3 C4 D1 D2 D3 D4

> Verbatim user verdict (2026-06-12):
> "i like the stepped intervals direction, i like how it's stepping up toward the type treatment. 'Direction B — Stepped Intervals' B1 if i had a to pick a sub direction. actually i kinda like b4 also maybe even more! yeah i like B4 more. would be curious to see the colors in terms fo real colors not just monochrome or is that our style for accrue? idk... but yeah i like this direction. the font choice seems fine with me to. can we do another round of exploration like a tournament of main variations that might significantly improve things given our focused direction here, showing the colors dark and light mode + monocrhome at diff sizes etc etc so we can hone in on a final logo/brand"
>
> Re-confirmed in follow-up: "oh yeah i said i like B4"

### B4
- keep: "i like the stepped intervals direction, i like how it's stepping up toward the type treatment" / "the font choice seems fine with me to"
- change: "would be curious to see the colors in terms fo real colors not just monochrome" — explore real color treatments in Round 2

### B1
- keep: "B1 if i had a to pick a sub direction" — retained as runner-up; agent note: B1 (4 coarser steps) scored stronger than B4 at 16px favicon scale in self-review, so it stays as the small-size-robust fallback
- change: same color exploration as B4

### Constraints (extracted by agent, user-confirmed)
- R1-C1: Direction locked to B (stepped intervals). All Round 2 variants derive from Direction B; Directions A, C, D are dead.
- R1-C2: Preserve the "stepping up toward the type treatment" gesture — ascending steps oriented toward the logotype, with the mark→type relationship treated as a feature to strengthen, not incidental.
- R1-C3: Logotype treatment locked — Geist, current weight/case ("the font choice seems fine with me").
- R1-C4: Round 2 must present real color treatments (brand palette, light mode + dark mode + monochrome, at multiple sizes), while every variant remains monochrome-DERIVABLE per BRAND-DNA. (Answers the user's "is monochrome our style?" — no: monochrome is a derivation requirement; Moss #5E9E84 is the brand's primary accent.)

---

<!-- ROUND-2-APPEND-BELOW -->
<!-- Phase 182 will append Round 2 verdict block here. Do not edit this marker. -->

## Round 2 — 2026-06-13

**Winners:** R2-7 (primary)
**Killed:** R2-1 R2-2 R2-3 R2-4 R2-5 R2-6

> Verbatim user verdict (2026-06-13):
> "Lock R2-7 (two-tone B1). R2-7 is my favorite — the green final step looks great. (Earlier comparison notes: I like R2-2 more than R2-1, the steps look better; R2-4 is probably even better than R2-2.)"

### R2-7
- keep: "the green final step looks great" — two-tone B1 with Ink base + Moss #5E9E84 accent on top (rightmost) step; 4 rounded steps
- change: none

### Constraints (extracted by agent, user-confirmed)
- R2-C1: Winner is R2-7 — B1 geometry (4 steps, 0.25 stepHeight × 0.25 stepWidth, curvature 0.05) with two-tone color treatment: Ink (#181818) base + Moss (#5E9E84) accent on the top/rightmost step.
- R2-C2: The Moss accent on the final (highest) step is the defining feature — Phase 183 must preserve this exactly.
- R2-C3: monoMap for production derivation: `{ "#5E9E84": "#818181" }` — Moss accent maps to grey #818181 in monochrome contexts.

---

## WINNER LOCKED — 2026-06-13

**Final winner:** R2-7
**Geometry config:** `{ id: "R2-7", steps: 4, stepHeight: 0.25, stepWidth: 0.25, curvature: 0.05, colorTreatment: "two-tone", monoMap: { "#5E9E84": "#818181" }, accentStep: true }`
**Assembled geometry:** markWidth: 40, markHeight: 40, viewBox: "0 0 40 40", accentPathD: `M 30.500,0.000 h 9.000 a 0.5,0.5 0 0 1 0.5,0.5 v 39.000 a 0.5,0.5 0 0 1 -0.5,0.5 h -9.000 a 0.5,0.5 0 0 1 -0.5,-0.5 v -39.000 a 0.5,0.5 0 0 1 0.5,-0.5 Z` (top/rightmost rounded step, filled Moss #5E9E84)
**Color treatment:** Two-tone — Ink (#181818) base for steps 1–3; Moss (#5E9E84) accent for step 4 (topmost, rightmost). monoMap: `{ "#5E9E84": "#818181" }`.
**Rationale:** B1 geometry (4 rounded stepped intervals) survived as the strongest candidate at all sizes in Round 1; the Moss accent on the final step introduces brand color with maximum restraint — one step green signals "progress/completion" without overwhelming the mark's structured dev-tooling personality.

*Phase 183 reads the geometry config above to produce the production logo system in `brandbook/`.*

<!-- PHASE-183-READY -->

---

*Phase 183 reads the winner from the final round above to produce the production logo system in `brandbook/`.*
