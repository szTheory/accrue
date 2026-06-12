# Phase 180: Brand Audit & DNA Lock - Context

**Gathered:** 2026-06-11
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 180 is a **writing + ratification phase** — no creative assets are produced. It pressure-tests the 437-line brand book seed (`prompts/accrue-brand-book.md`, gitignored) through the 14-section audit and produces four planning artifacts, all ratified at a single ✋ user checkpoint before any logo work begins:

1. `BRAND-AUDIT.md` — 14-section pressure test, every verdict tagged KEEP / TIGHTEN / REWORK / ADD / REMOVE with a cited justification (no churn without a cited failure)
2. Locked `BRAND-DNA.md` — ratified positioning, palette, typography, voice tone, visual personality
3. Binding **logo design brief** — explicitly recording the 4 hard logo constraints
4. Phase-186 **quality-gate checklist**

The 14 audit sections (from the design source): (1) executive judgment, (2) brand DNA extraction, (3) 15-dimension scorecard, (4) ~25-surface stress tests, (5) gaps by severity, (6) upgrade recommendations, (7) token spec, (8) logo-system spec, (9) visual-example guidance, (10) voice/microcopy, (11) landing/docs blueprint, (12) repo artifact plan, (13) prioritized actions, (14) final quality gate.

All outputs live in `.planning/` phase artifacts (committed `brandbook/` arrives in later phases). Downstream: Phase 181 consumes the logo brief; Phases 184/185 depend only on 180; Phase 186 consumes 180's structure + quality-gate checklist.

</domain>

<decisions>
## Implementation Decisions

### Name-overlap handling
- **D-01:** The name **Accrue is locked** — `accrue` is published on Hex.pm with a v1.x zero-breaking-change promise; rename is structurally off the table. The audit does NOT include a name-risk assessment section or contingency naming.
- **D-02:** The audit includes a short (3–4 sentence) **risk-acceptance preamble on record**: the commercial Accrue (byaccrue.com) is a consumer save-to-buy fintech in a different trademark class and channel; "accrue" is a weak dictionary-word mark; OSS precedent (Phoenix, Oban, Cashier) overwhelmingly favors coexistence. This prevents future re-litigation.
- **D-03:** The section's substance is **concrete disambiguation tactics**: always-paired "Elixir billing library" qualifiers on GitHub/Hex/docs/social cards; dark/technical visual identity distinct from consumer-fintech gloss; SEO leaning on ecosystem keywords ("elixir", "phoenix"). Qualifier rules land in BRAND-DNA.md.

### Evidence rigor (AUD-03)
- **D-04:** Palette evidence is **computed, not asserted**: a ~30-line zero-dependency WCAG 2.x contrast script (Node or Elixir — planner's choice) plus its output table are committed as Phase 180 audit artifacts. Every contrast claim in a verdict cites the computed table.
- **D-05:** **16px rendering / legibility claims are explicitly deferred to Phase 181's** screenshot pipeline — the audit marks them as deferred items, never asserts them as evidence.
- **D-06:** Known computed findings to fold into TIGHTEN verdicts (usage rules, NOT palette-change triggers): Moss #5E9E84 on Paper = 3.03:1 (UI/large-text only, fails AA body text; 2.68:1 on Fog — fails even 3:1); Cobalt #5D79F6 on Paper = 3.66:1 (UI-only); Amber #C8923B on Paper = 2.66:1 (dark-surface or icon-only; 6.71:1 on Ink). Neutrals all pass AAA (Ink on Paper 17.83:1). Expected shape: "accents are UI/large-text colors on light surfaces, never body-text colors."

### Checkpoint mechanics
- **D-07:** **Single itemized checkpoint** at phase end. Author all artifacts in dependency order (audit → DNA → brief → quality-gate checklist) within the phase, then ONE ratification sitting.
- **D-08:** At the checkpoint: contested verdicts (every REWORK / ADD / REMOVE, plus any evidence-gated palette/font proposal) are presented as **explicit accept/reject items** (AskUserQuestion); KEEP/TIGHTEN verdicts are batch-approved; BRAND-DNA.md and the logo brief are approved as whole documents.
- **D-09:** If a contested verdict flips, DNA + brief are revised **inline in the same sitting**. Mitigation: pre-draft flip-variants for the 1–3 genuinely contested items before presenting. Fall back to staged gates only if >5 contested verdicts emerge (not expected — churn is evidence-gated).

### BRAND-DNA.md altitude
- **D-10:** **Terse one-page decision record** — ratified facts only: positioning statement, palette table (hex + role + usage rule), type stack, voice adjectives + 3 do/don't pairs, visual personality keywords, the 4 hard logo constraints by reference.
- **D-11:** **No rationale prose in the DNA** — each section carries a one-line `BRAND-AUDIT.md §N` pointer instead. The audit holds the argument; the DNA is the locked constraint file downstream agents load cheaply and use as the tiebreaker.
- **D-12:** Every DNA fact is a **concrete value** (exact hex, exact font name, exact phrase) — never a description of one. No hedging.

### Claude's Discretion
- Contrast script language (Node vs Elixir) and exact location within the phase artifacts.
- Exact plan breakdown (~4 plans per design source) and which exemplar/antipattern research lands where.
- Stress-test surface list composition (~25 surfaces per design source — exact enumeration is the audit author's call).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Seed under audit
- `prompts/accrue-brand-book.md` — the 437-line brand strategy seed being pressure-tested (gitignored; stays gitignored). Palette: Ink #111418, Slate #24303B, Fog #E9EEF2, Paper #FAFBFC, Moss #5E9E84, Cobalt #5D79F6, Amber #C8923B. Geist/Geist Mono. Tagline "Billing state, modeled clearly."

### Authoritative design source
- `.planning/research/v1.52-brand-system-design.md` — authoritative milestone design: 14-section audit structure, hard logo constraints, evidence-gating rule, phase outputs, Phase-186 quality-gate dimensions (designer-buildable / engineer-implementable / dark-mode / small-size / specific-to-Accrue / no-thrash), exemplar list (Vercel, Prisma, Tailscale, Supabase, Phoenix, Oban) + antipattern list (gradient blobs, meaningless hexagons, rect-container marks).

### Milestone bookkeeping
- `.planning/ROADMAP.md` — Phase 180 goal + success criteria (4 criteria), hard logo constraints, guardrails (no admin `ax-*` changes, exploration stays in `.planning/`).
- `.planning/REQUIREMENTS.md` — AUD-01, AUD-02, AUD-03 (Phase 180's three requirements).

### Read-only token SSOT reference
- `accrue_admin/assets/css/theme.css` — admin `ax-*` tokens (151 token references; Geist already the admin font). READ-ONLY this milestone; the audit's token spec (§7) documents the brand layer and its mapping to these values, never changes them.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `accrue_admin/assets/css/theme.css` — the admin already runs Geist/Geist Mono with an Ink-derived shadow system (`rgba(17, 20, 24, …)`), type/space/radius/icon scales. The audit's token spec (§7) should map brand tokens to these as the existing-practice baseline.
- Phase 179 Playwright screenshot QA precedent exists in the repo — relevant to Phase 181, not 180 (180 defers all rendering evidence).

### Established Patterns
- Evidence-gated churn is the milestone-wide rule: Geist + existing palette are defaults; changes require a cited failure + user ratification (this phase's checkpoint is where that happens).
- Exploration artifacts convention: galleries, rejected candidates, TOURNAMENT.md stay in `.planning/milestones/v1.52-phases/` — never in `brandbook/`.

### Integration Points
- Phase 181 consumes the logo brief verbatim (4 hard constraints become pre-gate lints).
- Phase 184 consumes the audit's token spec (§7) + DNA palette table.
- Phase 185 consumes the DNA voice section + audit §10.
- Phase 186 consumes the audit's landing/docs blueprint (§11), repo artifact plan (§12), and quality-gate checklist (§14).

</code_context>

<specifics>
## Specific Ideas

- The 4 hard logo constraints (binding, must appear verbatim in the logo brief): (1) NO rectangular background/container shape behind the logomark; (2) logotype sits optically close to the mark; (3) main lockup carries no subtitle — a separate with-subtitle variant ships; (4) fully-integrated custom typemark options required.
- Audit posture: "well-made dev tooling," not fintech — state/lifecycle imagery (accumulation, timelines, layered records), never finance clichés (coins, cards, carts).
- The checkpoint is deliberately "the cheapest place to disagree" — surface real forks here so Phases 181–186 never re-litigate.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 180-Brand Audit & DNA Lock*
*Context gathered: 2026-06-11*
