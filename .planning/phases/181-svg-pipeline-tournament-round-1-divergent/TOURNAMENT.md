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

## Round 1 — {date-placeholder}

<!-- ROUND-1-PASTE-BELOW -->
<!-- Paste the verdict block from round-1-gallery.html immediately below this line. -->
<!-- Example schema (do not fill in manually — use the Copy button in the gallery): -->

**Winners:** (fill from gallery verdict block)
**Killed:** (fill from gallery verdict block)

### {Winner ID}
- keep: "(verbatim keep note from gallery)"
- change: "(verbatim change note from gallery)"

### Constraints (extracted by agent, user-confirmed)
- R1-C1: (Phase 182 agent fills this after reading your keep/change notes)
- R1-C2: (Phase 182 agent fills this after reading your keep/change notes)

---

<!-- ROUND-2-APPEND-BELOW -->
<!-- Phase 182 will append Round 2 verdict block here. Do not edit this marker. -->

---

*Phase 183 reads the winner from the final round above to produce the production logo system in `brandbook/`.*
