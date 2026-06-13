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

---

*Phase 183 reads the winner from the final round above to produce the production logo system in `brandbook/`.*
