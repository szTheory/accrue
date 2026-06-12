# Phase 180: Brand Audit & DNA Lock — Research

**Researched:** 2026-06-11
**Domain:** Brand identity audit, WCAG contrast verification, dev-tool brand exemplars, GSD writing-phase checkpoint mechanics
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01 — Name locked:** Accrue is published on Hex.pm with a v1.x zero-breaking-change promise; the audit does NOT include a name-risk assessment or contingency naming.

**D-02 — Risk-acceptance preamble on record:** Short (3–4 sentence) preamble: commercial Accrue (byaccrue.com) is a consumer save-to-buy fintech in a different trademark class and channel; "accrue" is a weak dictionary-word mark; OSS precedent (Phoenix, Oban, Cashier) overwhelmingly favors coexistence.

**D-03 — Concrete disambiguation tactics:** always-paired "Elixir billing library" qualifiers on GitHub/Hex/docs/social cards; dark/technical visual identity distinct from consumer-fintech gloss; SEO on ecosystem keywords. Rules land in BRAND-DNA.md.

**D-04 — Palette evidence computed, not asserted:** ~30-line zero-dependency WCAG 2.x contrast script plus its output table committed as Phase 180 artifacts. Every contrast claim cites the table.

**D-05 — 16px rendering deferred to Phase 181:** Audit marks legibility claims as deferred, never asserts them as evidence.

**D-06 — Known computed findings (TIGHTEN triggers, not palette-change triggers):**
- Moss #5E9E84 on Paper = 3.03:1 (AA-large only, fails AA body); on Fog = 2.68:1 (fails 3:1)
- Cobalt #5D79F6 on Paper = 3.66:1 (AA-large only)
- Amber #C8923B on Paper = 2.66:1 (fails 3:1); on Ink = 6.71:1 (AA-body)
- Neutrals pass AAA: Ink on Paper = 17.83:1

**D-07 — Single itemized checkpoint** at phase end. All artifacts authored before the checkpoint sitting.

**D-08 — Checkpoint structure:** REWORK/ADD/REMOVE + evidence-gated proposals = explicit accept/reject items; KEEP/TIGHTEN = batch-approved; BRAND-DNA.md + logo brief = whole-document approval.

**D-09 — Inline flip-variants pre-drafted** for 1–3 genuinely contested items. Staged gates only if >5 contested verdicts.

**D-10 — BRAND-DNA.md is a terse one-page decision record** — ratified facts only, no rationale prose.

**D-11 — No rationale in DNA:** Each section carries a `BRAND-AUDIT.md §N` pointer; audit holds argument.

**D-12 — Every DNA fact is a concrete value:** exact hex, exact font name, exact phrase — no hedging.

### Claude's Discretion

- Contrast script language (Node vs Elixir) and exact location within phase artifacts
- Exact plan breakdown (~4 plans per design source) and which exemplar/antipattern research lands where
- Stress-test surface list composition (~25 surfaces — enumeration is the audit author's call)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUD-01 | 14-section pressure-test audit of `prompts/accrue-brand-book.md`; every verdict tagged KEEP/TIGHTEN/REWORK/ADD/REMOVE with cited justification — no churn without a cited failure | WCAG formula (§ Standard Stack / Code Examples), exemplar patterns (§ Architecture Patterns), tone/posture analysis (§ Architecture Patterns §2) |
| AUD-02 | Locked BRAND-DNA.md + binding logo design brief (4 hard logo constraints) ratified at explicit checkpoint before any logo work | Checkpoint mechanics (§ Architecture Patterns §3), DNA altitude rules D-10/D-11/D-12 |
| AUD-03 | Any proposed palette/font change cites a concrete failure (contrast, distinctiveness, 16px rendering) and is user-ratified | Full contrast table (§ Code Examples), WCAG threshold definitions (§ Standard Stack) |
</phase_requirements>

---

## Summary

Phase 180 is a **writing and ratification phase** that produces four planning artifacts: a 14-section brand audit (`BRAND-AUDIT.md`), a locked one-page brand DNA (`BRAND-DNA.md`), a binding logo design brief, and a Phase-186 quality-gate checklist. No creative assets are produced here; the entire deliverable is structured prose with evidence-backed verdicts, ending in a single human checkpoint where contested items are presented as explicit accept/reject decisions.

The research covers three independent domains. First, the WCAG 2.x contrast formula — this is the mathematical foundation for every palette verdict in the audit, and the ~30-line contrast script is itself a required Phase 180 artifact (D-04). The formula is well-specified and computationally verified in this session against all seven Accrue palette colors. Second, the dev-tool brand exemplar landscape — how Vercel, Prisma, Tailscale, Supabase, Phoenix, and Oban express identity gives the audit author the grounding to cite real precedent rather than vibes when writing verdicts. Third, GSD checkpoint mechanics for a writing/ratification phase — understanding how `checkpoint:decision` vs `checkpoint:human-verify` interact with `human_verify_mode: end-of-phase` (the repo's current setting) so plans are structured correctly.

**Primary recommendation:** Organize Phase 180 into approximately 4 plans in dependency order: (1) contrast script + palette evidence table, (2) audit sections §1–§8 (factual/evidence-heavy sections), (3) audit sections §9–§14 plus BRAND-DNA.md and logo brief, (4) checkpoint presentation. Pre-draft flip-variants for the 1–3 genuinely contested items before the checkpoint task runs.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Contrast script execution | CLI / local Node or Elixir | — | Zero-dependency script committed as a planning artifact; runs once to produce the evidence table |
| BRAND-AUDIT.md authoring | Planning artifact (Claude auto task) | — | Prose document; executor writes Markdown, no runtime system involved |
| BRAND-DNA.md authoring | Planning artifact (Claude auto task) | — | Locked one-page decision record; downstream phases load it as context |
| Logo design brief | Planning artifact (Claude auto task) | — | Structured constraints document; consumed verbatim by Phase 181 |
| Phase-186 quality-gate checklist | Planning artifact (Claude auto task) | — | Referenced by BOOK-02 success criterion |
| User ratification checkpoint | Human checkpoint (AskUserQuestion) | — | D-07/D-08: single sitting; blocked until user approves |
| Token SSOT reference | Read-only: `accrue_admin/assets/css/theme.css` | — | Never written this phase; audit §7 documents what it contains |

---

## Standard Stack

### Core — Phase 180 (writing phase, minimal tooling)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Node.js (built-in) | System (any LTS) | Contrast script runtime | Zero-dependency; `node -e "..."` works without install; already on system (verified: `node --version` returns v22.x in CI) |
| Markdown | — | Audit/DNA/brief format | All downstream phases consume these as `.md` planning artifacts |

**No npm packages are installed for this phase.** The contrast script is intentionally ~30 lines of vanilla JS (or Elixir) with no dependencies — per D-04, the constraint is "zero-dependency." [VERIFIED: direct computation in this session]

### Supporting — WCAG Reference Values

The audit §3 scorecard and §5 gaps section cite these thresholds directly. They are canonical W3C values, not library-specific.

| Level | Text Size | Minimum Contrast | Notes |
|-------|-----------|-----------------|-------|
| AA | Normal (< 18pt / < 14pt bold) | 4.5:1 | Body text, labels |
| AA | Large (≥ 18pt / ≥ 14pt bold) | 3.0:1 | Headings, large UI text |
| AAA | Normal | 7.0:1 | Enhanced accessibility |
| AAA | Large | 4.5:1 | Enhanced accessibility |
| 1.4.11 | UI components / icons | 3.0:1 | Non-text contrast |
| — | Logotypes / decorative | None | Explicitly exempt per WCAG |

**Large text in px:** ≥ 18pt = ≥ 24px; ≥ 14pt bold = ≥ 18.67px. [CITED: www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html]

---

## Package Legitimacy Audit

**No external packages are installed in Phase 180.** The contrast script uses no npm dependencies. This section is not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
prompts/accrue-brand-book.md  (seed, gitignored, read-only)
        |
        v
[Plan 1: Contrast Script]
  node contrast.js  →  contrast-table.txt  (artifact)
        |
        v
[Plans 2–3: Audit Authoring]
  Audit §1–§8   →  BRAND-AUDIT.md (partial, sections 1–8)
  Audit §9–§14  →  BRAND-AUDIT.md (complete)
        |            + BRAND-DNA.md
        |            + logo-brief.md
        |            + quality-gate-checklist.md
        |
        v
[Plan 4: Checkpoint]
  All 4 artifacts  →  AskUserQuestion (accept/reject/batch-approve)
        |
        v
  [if verdicts flip]
  Inline revision of DNA + brief in same task
        |
        v
  Phase 180 complete  →  Phase 181 (consumes logo-brief.md)
                          Phase 184 (consumes audit §7 token spec)
                          Phase 185 (consumes audit §10 voice section)
                          Phase 186 (consumes audit §11–§12 blueprint + §14 checklist)
```

### Recommended Phase-180 Artifact Structure

```
.planning/phases/180-brand-audit-dna-lock/
  180-CONTEXT.md           # already exists
  180-DISCUSSION-LOG.md    # already exists
  180-RESEARCH.md          # this file
  180-N-PLAN.md            # ~4 plans (planner to create)
  artifacts/
    contrast.js            # ~30-line zero-dep WCAG script (Plan 1 output)
    contrast-table.txt     # computed output table — every audit palette claim cites this
  BRAND-AUDIT.md           # 14-section pressure test (Plans 2–3 output)
  BRAND-DNA.md             # locked one-page decision record (Plan 3 output)
  logo-brief.md            # binding logo design brief (Plan 3 output)
  quality-gate-checklist.md  # Phase-186 gate (Plan 3 output)
```

All artifacts stay in `.planning/` — no `brandbook/` writes this phase. [VERIFIED: ROADMAP.md guardrails]

### Pattern 1: Evidence-Gated Verdict Structure

**What:** Every audit verdict that proposes a change must cite a specific, computable failure. The failure citation refers to the contrast-table.txt artifact by row (not a vague assertion).

**When to use:** Any REWORK, ADD, or REMOVE verdict. Also any TIGHTEN that imposes a usage restriction (e.g., "Moss is UI/large-text only on light surfaces").

**Example (correct):**
```markdown
**§3.4 Moss #5E9E84 — TIGHTEN**
Moss on Paper = 3.03:1 (see `contrast-table.txt` row "Moss vs Paper").
Passes AA-large (≥ 3.0:1) but fails AA-body (< 4.5:1).
Usage rule: Moss may be used for interactive states, icons, and large-text
accent on Paper or Fog surfaces. Never as body-text color on light surfaces.
No palette hex change required.
```

**Example (incorrect — no citation):**
```markdown
**§3.4 Moss — TIGHTEN**
Moss has limited contrast on light backgrounds and should be used carefully.
```

The incorrect form lacks a cited failure and would violate AUD-01/AUD-03. [CITED: REQUIREMENTS.md AUD-01, AUD-03]

### Pattern 2: BRAND-DNA.md Structure (D-10/D-11/D-12)

**What:** Terse one-page decision record. No prose rationale — only `BRAND-AUDIT.md §N` back-references. Every fact is a concrete value.

**Example skeleton:**
```markdown
# Accrue Brand DNA
*Ratified: [date] — Phase 180 checkpoint*

## Positioning
Accrue is the Elixir-native billing library for Phoenix apps.
Qualifier rule: always paired with "Elixir billing library" on GitHub/Hex/docs/social cards.
→ BRAND-AUDIT.md §1, §2

## Palette
| Token | Hex | Role | Usage Rule |
|-------|-----|------|------------|
| Ink | #111418 | Primary text, dark surface | Body text, structural dark |
| Slate | #24303B | Secondary dark | Borders, subtext on light |
| Fog | #E9EEF2 | Soft neutral light | Section backgrounds |
| Paper | #FAFBFC | Doc background | Page base |
| Moss | #5E9E84 | Brand accent / success | UI states, icons, large text only on light |
| Cobalt | #5D79F6 | Interactive / link | Focus, links, active states |
| Amber | #C8923B | Warning / pending | Dark-surface or icon-only on light |
→ BRAND-AUDIT.md §3, §4 (see contrast-table.txt for all ratios)

## Typography
Primary: Geist (sans)
Mono: Geist Mono
→ BRAND-AUDIT.md §3

## Voice
Adjectives: measured, exact, native, durable
Do: direct, calm, precise, practical, literate, generous
Don't: hype, sales language, consumer-finance wording
→ BRAND-AUDIT.md §10

## Visual Personality
Metaphors: accumulation, timelines, state transitions, layered records, aligned intervals
Avoid: coins, cards, carts, gradient blobs, smiling people
→ BRAND-AUDIT.md §8

## Logo Constraints (4 hard constraints)
1. No rectangular background/container behind the logomark
2. Logotype optically close to the mark
3. Main lockup carries no subtitle (with-subtitle variant ships separately)
4. Fully-integrated custom typemark options required
→ BRAND-AUDIT.md §8
```

[CITED: 180-CONTEXT.md D-10, D-11, D-12]

### Pattern 3: Checkpoint Task Structure (writing/ratification phase)

**Context:** `human_verify_mode` is `end-of-phase` (the repo default). `auto_advance` is false. This means `checkpoint:human-verify` tasks are suppressed; instead, `checkpoint:decision` tasks (which ARE emitted in end-of-phase mode) are used for genuine ratification gates where work must stop for a user decision.

Phase 180's single ratification checkpoint is a genuine gate — the user's verdict determines which items in BRAND-DNA.md and the logo brief are locked. This is a `checkpoint:decision` pattern, not a `checkpoint:human-verify` (it gates what downstream phases implement, not verification of completed work).

**Structure for the checkpoint task (Plan 4):**

```xml
<task type="checkpoint:decision">
  <name>Ratify audit verdicts, BRAND-DNA.md, and logo brief</name>
  <what-to-present>
    1. CONTESTED VERDICTS (explicit accept/reject per D-08):
       Present each REWORK / ADD / REMOVE verdict as a named item.
       For each, offer: Accept | Reject | Modify (freeform).
       Pre-draft flip-variants for the 1–3 most likely-contested items.
    2. BATCH APPROVAL (per D-08):
       All KEEP and TIGHTEN verdicts presented as a group for single approval.
    3. WHOLE-DOCUMENT APPROVAL (per D-08):
       BRAND-DNA.md — present as complete document, ask: Approve | Request changes
       Logo brief — present as complete document, ask: Approve | Request changes
  </what-to-present>
  <inline-revision>
    If any contested verdict flips, revise BRAND-DNA.md and logo-brief.md
    inline in this same task before marking the checkpoint complete (D-09).
  </inline-revision>
  <resume-signal>All items resolved — DNA and brief are locked.</resume-signal>
</task>
```

**Gate-prompt patterns to use (from references/gate-prompts.md):**
- Individual contested verdict: `approve-revise-abort` pattern
- Batch KEEP/TIGHTEN: `yes-no` confirmation ("Approve all KEEP/TIGHTEN verdicts?")
- Whole-document: `approve-revise-abort` pattern

[CITED: references/gate-prompts.md; references/planner-human-verify-mode.md]

### Anti-Patterns to Avoid

- **Churn without citation:** Marking something REWORK without a specific cited failure (contrast row, legibility failure, distinctiveness argument) — violates AUD-01, triggers scope creep.
- **Palette change without ratification:** Proposing a new hex value as a TIGHTEN (usage-rule-only) adjustment is correct; proposing it as a palette replacement requires AUD-03 evidence + explicit checkpoint acceptance.
- **16px rendering claims in audit:** Asserting rendering quality without screenshot evidence — D-05 explicitly defers all rendering evidence to Phase 181.
- **Multiple ratification checkpoints:** More than one `checkpoint:decision` task in the phase (D-07 specifies a single itemized checkpoint). If mid-phase questions arise, they should be deferred to the checkpoint task, not added as interim gates.
- **Rationale prose in BRAND-DNA.md:** D-11 prohibits this. Rationale belongs in the audit; the DNA is a machine-loadable constraint file.
- **Audit sections out of order:** The 14-section order is fixed by the design source. Plans that author sections out of order create inconsistent cross-references.

---

## Dev-Tool Brand Exemplar Analysis

This section grounds the audit's exemplar and antipattern research so the audit author cites real precedent.

### Verified Exemplar Observations

**Vercel** [CITED: vercel.com/geist/brands]
- Geometric symbol: upward triangle (▲) as a standalone mark
- Monochromatic palette (black / white only) — zero accent color in the logo system
- Works at any size because it's a single flat path with no container
- Typeface: Geist (their own, now open source — same as Accrue)
- Philosophy: clarity and authenticity above decoration; mark breathes without a background box
- Anti-pattern it avoids: no roundel/squircle behind the triangle; the mark IS the shape

**Prisma** [CITED: github.com/prisma/presskit]
- Symbol: geometric prism form
- Dual-component system: symbol + wordmark, symbol used standalone only when space-constrained
- Typography: Barlow (headings), Inter (body), Roboto Mono (code)
- Design philosophy: minimalist, no shadows/gradients/recoloring; the mark maintains proportions
- Anti-pattern it avoids: no rectangular bounding box

**Tailscale** [CITED: together.agency/work/tailscale/]
- Identity: understated, minimal, quietly confident
- Primary color: #D04841 (strong red accent anchoring the identity)
- Typography: Inter throughout
- Design language: restrained; white space central; shapes give structure, not decoration
- Evolution: maintained developer authenticity while scaling to enterprise — preserved open-source trust signal
- Anti-pattern it avoids: no blob gradients; shapes are geometric and structural

**Supabase** [CITED: supabase.com/brand-assets]
- Primary color: #3ECF8E (vibrant green)
- Logo: lightning bolt shape suggesting speed / real-time (metaphor tied directly to product benefit)
- Typography: Circular (headings), Source Code Pro (code)
- Dark emerald theme; code-first aesthetic
- Note for Accrue contrast: Supabase's accent (#3ECF8E) is more saturated and higher-chroma than Moss (#5E9E84); their green reads as product-speed signal, not calm library tooling

**Phoenix (Elixir framework)** [ASSUMED]
- Orange phoenix bird mark — recognizable but occasionally cited as generic "fiery startup" feeling
- The brand works because Phoenix (the bird) directly names the framework; the metaphor is non-negotiable
- Lesson: literal metaphors that name the product are defensible; abstract metaphors must be tightly argued

**Oban** [ASSUMED]
- Text-dominant identity; no prominent standalone mark outside documentation headers
- Relies heavily on type treatment + purple/plum accent palette
- Lesson: for a job-queue library, the brand lives in docs quality + consistent color use, not a complex logomark

### The Antipattern List (direct citations to avoid in Accrue's mark)

[CITED: v1.52-brand-system-design.md]

| Antipattern | Why it fails for Accrue | Common offender type |
|-------------|------------------------|---------------------|
| **Gradient blobs** | No semantic connection to billing state; ages poorly; screams generic SaaS startup | VC-backed B2B startups 2018–2022 |
| **Meaningless hexagons** | Overused in "tech" branding; conveys "we needed a shape"; no specific meaning | Security / infrastructure SaaS |
| **Rectangular container behind mark** | Breaks visual breathing; forces padding; mark inside rect = the rect IS the logo | Rushed logo systems; convenience-first |
| **Coins / cards / carts / price tags** | Finance clichés; contradict "well-made dev tooling" posture | Payment startups; not OSS libraries |
| **Smiling people / lifestyle** | Wrong register entirely for a low-level library | Consumer apps; marketing-first brands |
| **Stacked wordmark with subtitle in main lockup** | The subtitle becomes the mark; logo is unusable at small sizes | Over-explained brands with weak marks |

### Accrue's Differentiating Position

The correct exemplar family for Accrue is: **technically precise, calm, OSS-community signal**. This puts it closer to Prisma/Vercel (minimal, geometric, high-precision) than to Supabase (vibrant, velocity-forward) or Phoenix (mascot-driven). The key differentiator from Vercel and Prisma is the state/lifecycle metaphor — accumulation, layered records, intervals — which is specific to billing infrastructure and immediately legible to backend developers.

---

## WCAG 2.x Contrast Formula — Complete Reference

### Formula [CITED: www.w3.org/TR/WCAG20-TECHS/G17.html; www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html]

**Step 1 — Normalize to 0–1:**
```
R_sRGB = R_8bit / 255  (same for G, B)
```

**Step 2 — Linearize (piecewise, per channel):**
```
if channel_sRGB <= 0.03928:
    channel_linear = channel_sRGB / 12.92
else:
    channel_linear = ((channel_sRGB + 0.055) / 1.055) ^ 2.4
```
Note: W3C WCAG 2.0 original uses 0.03928; WCAG 2.1 Understanding document uses 0.04045. The difference is negligible in practice (< 0.01% change in computed ratios for any real color). Use 0.03928 to match the normative WCAG 2.0 formula.

**Step 3 — Relative luminance:**
```
L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
```

**Step 4 — Contrast ratio:**
```
contrast = (L_lighter + 0.05) / (L_darker + 0.05)
```
Where L_lighter >= L_darker. Output is a ratio (e.g., 4.5 means 4.5:1).

### Verified Accrue Palette Luminance Values

Computed in this session using the formula above with threshold 0.03928: [VERIFIED: direct computation]

| Token | Hex | Relative Luminance |
|-------|-----|--------------------|
| Ink | #111418 | 0.006854 |
| Slate | #24303B | 0.028047 |
| Amber | #C8923B | 0.331529 |
| Moss | #5E9E84 | 0.284993 |
| Cobalt | #5D79F6 | 0.226557 |
| Fog | #E9EEF2 | 0.848835 |
| Paper | #FAFBFC | 0.963466 |

### Full Contrast Matrix (all pairs) [VERIFIED: direct computation]

| Pair | Ratio | WCAG Level |
|------|-------|------------|
| Ink vs Paper | 17.83:1 | AAA body + large |
| Ink vs Fog | 15.81:1 | AAA body + large |
| Slate vs Paper | 12.99:1 | AAA body + large |
| Slate vs Fog | 11.52:1 | AAA body + large |
| Moss vs Ink | 5.89:1 | AA body + large |
| Amber vs Ink | 6.71:1 | AA body + large |
| Amber vs Slate | 4.89:1 | AA body + large |
| Cobalt vs Ink | 4.86:1 | AA body + large |
| Moss vs Slate | 4.29:1 | AA large only |
| Cobalt vs Slate | 3.54:1 | AA large only |
| Cobalt vs Fog | 3.25:1 | AA large only |
| Cobalt vs Paper | 3.66:1 | AA large only |
| Moss vs Paper | 3.03:1 | AA large only (barely) |
| Amber vs Paper | 2.66:1 | FAIL (< 3.0:1) |
| Moss vs Fog | 2.68:1 | FAIL (< 3.0:1) |
| Amber vs Fog | 2.36:1 | FAIL |
| Ink vs Slate | 1.37:1 | FAIL (same-family pair, expected) |
| Fog vs Paper | 1.13:1 | FAIL (same-family pair, expected) |
| Cobalt vs Moss | 1.21:1 | FAIL (accent vs accent) |
| Amber vs Moss | 1.14:1 | FAIL (accent vs accent) |
| Amber vs Cobalt | 1.38:1 | FAIL (accent vs accent) |

**Interpretation for audit verdicts:**
- Accents (Moss, Cobalt, Amber) on dark surfaces (Ink, Slate) all pass AA-body or AA-large — valid for text on dark backgrounds.
- Accents on light surfaces (Paper, Fog) range from borderline AA-large (Moss 3.03:1) to full fail (Amber 2.66:1) — none pass AA-body on light backgrounds.
- The correct usage rule (D-06): "Accents are UI/large-text colors on light surfaces, never body-text colors."
- Neutrals all pass AAA in appropriate light-on-dark or dark-on-light pairings.
- No palette change is triggered by these ratios — they confirm the seed palette is usable with usage-rule restrictions (TIGHTEN verdicts, not REWORK).

### ~30-Line Contrast Script (Node, zero dependencies)

```javascript
// contrast.js — WCAG 2.x relative luminance & contrast ratio
// Usage: node contrast.js
// Output: contrast-table.txt (printed to stdout)

function linearize(v) {
  const s = v / 255;
  return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}
function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}
function contrast(l1, l2) {
  const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
  return (hi + 0.05) / (lo + 0.05);
}
function hex(h) {
  const c = h.replace('#', '');
  return [parseInt(c.slice(0,2),16), parseInt(c.slice(2,4),16), parseInt(c.slice(4,6),16)];
}
const PALETTE = {
  Ink:    '#111418', Slate:  '#24303B',
  Fog:    '#E9EEF2', Paper:  '#FAFBFC',
  Moss:   '#5E9E84', Cobalt: '#5D79F6', Amber: '#C8923B'
};
const lums = Object.fromEntries(
  Object.entries(PALETTE).map(([n,h]) => [n, luminance(...hex(h))])
);
const names = Object.keys(lums);
console.log('# Accrue palette WCAG 2.x contrast ratios');
console.log('# Pair | Ratio | AA-body(4.5:1) | AA-large(3.0:1) | AAA(7.0:1)');
for (let i = 0; i < names.length; i++) {
  for (let j = i+1; j < names.length; j++) {
    const [a, b] = [names[i], names[j]];
    const r = contrast(lums[a], lums[b]);
    const level = r >= 7 ? 'AAA' : r >= 4.5 ? 'AA-body' : r >= 3 ? 'AA-large' : 'FAIL';
    console.log(`${a} vs ${b}: ${r.toFixed(2)}:1  [${level}]`);
  }
}
```

This is the exact script to commit at `artifacts/contrast.js` in Plan 1. [CITED: D-04 from 180-CONTEXT.md]

---

## Admin Token SSOT — What Audit §7 Must Map Against

The audit's token specification section (§7) documents the brand layer and its mapping to the existing `accrue_admin/assets/css/theme.css` tokens. This file is READ-ONLY this milestone.

Key findings from reading `theme.css` [VERIFIED: direct file read]:

**Typography (already Geist):**
- `--ax-font-sans: "Geist"` — sans serif already set to Geist
- `--ax-font-mono: "Geist Mono"` — mono already set to Geist Mono
- This means the brand book's typography decision is already implemented in the admin; no drift.

**Color tokens in the admin (semantic, not raw):**
- `--ax-base: var(--accrue-paper)` — relies on `--accrue-paper` CSS custom property (brand-layer raw token)
- `--ax-primary: var(--accrue-ink)` — relies on `--accrue-ink`
- `--ax-success: var(--accrue-moss)` — relies on `--accrue-moss`
- `--ax-warning: var(--accrue-amber)` — relies on `--accrue-amber`
- These `--accrue-*` raw tokens are referenced but NOT defined in `theme.css` — they are expected to come from a brand-layer file (currently undefined, to be authored as `tokens.css` in Phase 184).

**Dark theme values:**
- Dark base: `#0f1318` (near-black, Ink-family)
- Dark elevated: `#171d24`
- Dark primary: `#f4f7fa` (near-white)

**Shadow system:**
- Uses `rgba(17, 20, 24, …)` = Ink RGB as shadow tint — brand-aware shadows already

**The §7 mapping task:** Document the five `--accrue-*` raw token references in `theme.css` as the brand layer's required export surface. The audit §7 should specify: raw tokens → `--accrue-ink`, `--accrue-paper`, `--accrue-moss`, `--accrue-amber`, `--accrue-slate`, `--accrue-fog`, `--accrue-cobalt`. Phase 184 will then define these in `tokens.css`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contrast ratio math | Custom algorithm with sRGB approximations | The ~30-line formula above (W3C canonical) | The sRGB linearization threshold (0.03928 vs 0.04045) matters; hand-rolled approximations drift from WCAG compliance |
| Color space conversion | HSL-based contrast approximation | Luminance formula with correct linearization | HSL lightness ≠ perceptual luminance; will produce wrong ratios (up to 15% off for saturated colors) |
| Brand audit structure | Free-form critique document | Fixed 14-section structure per design source | Downstream phases (181, 184, 185, 186) depend on specific section numbers as canonical back-references |
| Checkpoint presentation | Multi-message ratification sequence | Single `checkpoint:decision` task with batch structure | D-07 mandates single sitting; multiple tasks would require multiple cold-starts (per planner-human-verify-mode.md) |

---

## Common Pitfalls

### Pitfall 1: TIGHTEN vs REWORK Confusion

**What goes wrong:** The auditor marks a color as REWORK when the correct verdict is TIGHTEN. REWORK implies the palette hex should change; TIGHTEN means the usage rules must be more restrictive.

**Why it happens:** Seeing a low contrast ratio and concluding the color itself is broken, rather than concluding its usage context must be constrained.

**How to avoid:** Ask: "Does the color fail in ALL plausible uses, or only in specific uses?" If accents (Moss, Cobalt, Amber) pass AA-large on Paper and AA-body on Ink, they are valid colors with usage-rule restrictions → TIGHTEN, not REWORK.

**Warning signs:** A REWORK verdict that proposes a new hex without a cited use case where no usage rule could fix the failure.

### Pitfall 2: Over-Contesting the Checkpoint

**What goes wrong:** Too many REWORK/ADD/REMOVE verdicts, creating a >5-item contested checkpoint that triggers staged gates (D-09 fallback).

**Why it happens:** Audit rigor applied without the evidence-gating filter — finding theoretical weaknesses and calling them failures.

**How to avoid:** D-04/AUD-03 evidence rule: no verdict proposes a change unless there is a cited, computable failure. Verdicts not tied to a specific contrast row, a specific distinctiveness argument, or a specific platform failure are KEEP, not REWORK.

**Warning signs:** More than 3 REWORK verdicts in the palette/typography sections, or REWORK verdicts in sections §1–§2 (those are brand strategy, not technical failures).

### Pitfall 3: Audit Sections Authored Out of Dependency Order

**What goes wrong:** §7 (token spec) is authored before §3 (scorecard) and §5 (gaps), so the token roles are based on the seed rather than the audited verdicts.

**Why it happens:** Splitting audit authoring across plans without maintaining section order within each plan.

**How to avoid:** Plan 2 should complete §1–§8 in order. Plan 3 should complete §9–§14 in order. §7 token spec should be authored after §5 gaps are settled so it reflects corrected usage rules.

### Pitfall 4: Rendering Claims Without Screenshot Evidence

**What goes wrong:** Audit §4 stress-test asserts "Geist renders cleanly at 16px" or "Cobalt is legible in a favicon context" without screenshot evidence.

**Why it happens:** Training data bias toward optimistic legibility claims; writing what feels true.

**How to avoid:** Per D-05, all rendering/legibility claims are explicitly marked "deferred to Phase 181 screenshot pipeline." The audit uses "[DEFERRED: Phase 181]" inline wherever a rendering verdict would otherwise appear.

### Pitfall 5: Checkpoint Structure Errors (human_verify_mode Mismatch)

**What goes wrong:** Plan 4 uses `checkpoint:human-verify` instead of `checkpoint:decision`, causing the checkpoint to be suppressed in end-of-phase mode and the ratification to never happen.

**Why it happens:** Confusing "verifying work is done" (human-verify) with "getting a user decision before downstream phases proceed" (decision).

**How to avoid:** Per `planner-human-verify-mode.md`: `checkpoint:decision` and `checkpoint:human-action` ARE emitted in end-of-phase mode. The Phase 180 ratification is a `checkpoint:decision` (the user's verdict determines what the locked documents contain). Do NOT use `checkpoint:human-verify` for this gate.

---

## Code Examples

### WCAG Script (full, commit-ready)

```javascript
// Source: W3C WCAG 2.0 Techniques G17 + WCAG 2.1 Understanding SC 1.4.3
// artifacts/contrast.js — zero external dependencies
// Run: node artifacts/contrast.js > artifacts/contrast-table.txt

function linearize(v) {
  const s = v / 255;
  return s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4);
}
function luminance(r, g, b) {
  return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
}
function contrastRatio(l1, l2) {
  const [hi, lo] = l1 > l2 ? [l1, l2] : [l2, l1];
  return (hi + 0.05) / (lo + 0.05);
}
function parseHex(h) {
  const c = h.replace('#', '');
  return [parseInt(c.slice(0,2),16), parseInt(c.slice(2,4),16), parseInt(c.slice(4,6),16)];
}

const PALETTE = {
  Ink:    '#111418',
  Slate:  '#24303B',
  Fog:    '#E9EEF2',
  Paper:  '#FAFBFC',
  Moss:   '#5E9E84',
  Cobalt: '#5D79F6',
  Amber:  '#C8923B',
};

const lums = Object.fromEntries(
  Object.entries(PALETTE).map(([name, hex]) => [name, luminance(...parseHex(hex))])
);

const names = Object.keys(PALETTE);
const header = 'Accrue palette WCAG 2.x contrast ratios (threshold: 0.03928)';
const divider = '='.repeat(60);
console.log(header);
console.log(divider);
for (let i = 0; i < names.length; i++) {
  for (let j = i + 1; j < names.length; j++) {
    const [a, b] = [names[i], names[j]];
    const r = contrastRatio(lums[a], lums[b]);
    const level = r >= 7.0 ? 'AAA' : r >= 4.5 ? 'AA-body' : r >= 3.0 ? 'AA-large' : 'FAIL';
    console.log(`${a} vs ${b}: ${r.toFixed(2)}:1  [${level}]`);
  }
}
```

### BRAND-DNA.md Hard Logo Constraints Block

```markdown
## Logo Constraints
*(4 hard constraints — binding on every Phase 181+ candidate; source: Phase 180 logo brief)*

1. **No rectangular background/container shape** behind the logomark — marks breathe / break boundaries
2. **Logotype optically close** to the mark — not visually separated
3. **Main lockup carries no subtitle** — a separate with-subtitle variant ships
4. **Fully-integrated custom typemark options required** — motif/flourish worked into letterforms, not icon-left-of-text

→ `logo-brief.md` (binding), `BRAND-AUDIT.md §8`
```

### Phase-186 Quality-Gate Checklist (required output of Phase 180)

```markdown
# Phase 186 Quality-Gate Checklist
*(authored Phase 180; consumed by Phase 186 BOOK-02 success criterion)*

- [ ] Designer-buildable: each brandbook section could be rebuilt from its token/artifact inputs alone
- [ ] Engineer-implementable: every CSS token has a documented role + usage rule; no magic values
- [ ] Dark-mode: all color surfaces pass WCAG AA-large (≥ 3:1) in dark theme; accent usage rules honored
- [ ] Small-size: primary lockup readable at 32px; icon mark recognizable at 16px (screenshot evidence)
- [ ] Specific-to-Accrue: no element of the identity could plausibly be mistaken for another billing or fintech brand
- [ ] No-thrash: zero changes to `accrue_admin/assets/css/theme.css`; zero new billing primitives; no breaking changes
- [ ] Size budget: `du -sh brandbook/` ≤ 2 MB
- [ ] Standalone: `brandbook/index.html` opens via `file://` with no server, no build step, no JS framework
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Contrast ratio threshold 0.03928 | WCAG 2.1 Understanding uses 0.04045 (practically equivalent) | WCAG 2.1, 2018 | No material change for any real color; use 0.03928 to match normative WCAG 2.0 G17 |
| WCAG 2.x relative luminance only | WCAG 3.0 (draft) proposes APCA (Accessible Perceptual Contrast Algorithm) | 2023 draft, not finalized | WCAG 2.x remains the standard; APCA not yet normative; stick with WCAG 2.x formula |
| ASCII-art brand specs | Design token JSON (W3C DTCG format `tokens.json`) | 2022–2023 | Phase 184 targets this format; Phase 180 documents the human-readable spec |
| "No usage rules needed" | Explicit role + usage rule per token | 2020s design-system era | The audit §7 outputs a role+rule table, not just a hex list |

**Deprecated:**
- HSL lightness as a contrast approximation: incorrect (HSL L ≠ perceptual luminance); never use for WCAG claims.
- `strokeWidth` / drop-shadow in logo SVG finals: outdated practice; Phase 183 requires outlined paths only.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phoenix (Elixir) brand personality is primarily mascot-driven (orange bird) and cited here as a "literal metaphor works" lesson | Exemplar Analysis | Low — this is observable from the Phoenix logo; no audit verdict depends on it |
| A2 | Oban identity is text-dominant with a plum/purple accent | Exemplar Analysis | Low — Oban's brand is observable from oban.pro and GitHub README; not a load-bearing audit claim |

All palette contrast claims are VERIFIED via direct computation. All WCAG thresholds are CITED from W3C. All project artifact observations are VERIFIED via direct file reads.

---

## Open Questions

1. **Contrast script language: Node vs Elixir?**
   - What we know: Both are capable (~30 lines each). Node is available in all environments where Phase 181's opentype.js pipeline will also run. Elixir is the project's primary language.
   - What's unclear: Whether there's a preference for consistency with Phase 181 (Node) vs. language-nativeness (Elixir).
   - Recommendation: Claude's discretion per CONTEXT.md — Node is recommended for consistency with Phase 181's toolchain.

2. **Exact 14-section sub-structure for stress-test surfaces (§4)**
   - What we know: ~25 surfaces per design source; examples include GitHub header, README hero, Hex.pm, HexDocs, favicon, dark/light, social card, slides.
   - What's unclear: Exact ordering and whether any surfaces should be split into sub-entries.
   - Recommendation: Planner specifies ~25 named surfaces as a `<files>` or `<action>` enumeration in the §4 authoring task; executor enumerates them during writing.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | contrast.js script | ✓ | System LTS (22.x verified in project CI) | Elixir equivalent script (~30 lines, same formula) |
| Markdown files | All 4 phase artifacts | ✓ | — | — |
| `accrue_admin/assets/css/theme.css` | Audit §7 token mapping | ✓ | Current (213 lines, read-only) | — |
| `prompts/accrue-brand-book.md` | Audit seed | ✓ | 437 lines, gitignored | — |

**Missing dependencies with no fallback:** None.

---

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` — this section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Phase 180 is a writing phase — no automated test framework applies to the primary deliverables (Markdown documents) |
| Config file | N/A |
| Quick run command | `node .planning/phases/180-brand-audit-dna-lock/artifacts/contrast.js` (validates script runs, output matches known values) |
| Full suite command | Same — the contrast script is the only automated artifact in this phase |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Artifact Exists? |
|--------|----------|-----------|-------------------|-----------------|
| AUD-01 | Every verdict in BRAND-AUDIT.md is tagged KEEP/TIGHTEN/REWORK/ADD/REMOVE with cited justification | Manual | `grep -c "KEEP\|TIGHTEN\|REWORK\|ADD\|REMOVE" BRAND-AUDIT.md` (spot check) | ❌ Wave 0 |
| AUD-02 | BRAND-DNA.md exists; logo brief exists; 4 hard constraints appear verbatim | Automated grep | `grep -q "No rectangular background" logo-brief.md && grep -q "optically close" logo-brief.md` | ❌ Wave 0 |
| AUD-03 | Every palette/font change verdict cites contrast-table.txt | Automated | `node artifacts/contrast.js > /dev/null && echo "script runs"` | ❌ Wave 0 |

### Wave 0 Gaps

- [ ] `artifacts/contrast.js` — covers AUD-03 evidence requirement (Plan 1 creates this)
- [ ] `BRAND-AUDIT.md` — covers AUD-01 (Plans 2–3 create this)
- [ ] `BRAND-DNA.md` + `logo-brief.md` — covers AUD-02 (Plan 3 creates these)
- [ ] `quality-gate-checklist.md` — covers Phase-186 BOOK-02 (Plan 3 creates this)

*(All gaps are expected for a greenfield writing phase — every artifact is a Wave 0 creation.)*

---

## Security Domain

> `security_enforcement` is not set in `.planning/config.json`; treating as enabled. Phase 180 produces planning documents (Markdown) and a ~30-line Node script. No user inputs, no network calls, no sensitive data processed.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase produces no auth surfaces |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | No access-controlled resources |
| V5 Input Validation | No | Contrast script takes no external input (hardcoded palette) |
| V6 Cryptography | No | No cryptographic operations |

**No ASVS controls are required for this phase.** The contrast script takes no external input and produces no sensitive output.

---

## Project Constraints (from CLAUDE.md)

Directives relevant to Phase 180 planning:

- **Tech stack:** Elixir/Phoenix/Ecto/PostgreSQL project; Phase 180 is a writing phase that touches none of these
- **Monorepo layout:** `accrue/` and `accrue_admin/` sibling packages; Phase 180 artifacts stay in `.planning/` only
- **No admin `ax-*` changes:** `accrue_admin/assets/css/theme.css` is READ-ONLY this milestone (ROADMAP.md guardrail confirmed by CLAUDE.md convention)
- **GSD Workflow Enforcement:** Must proceed via `/gsd-plan-phase`, `/gsd-execute-phase` etc. — no direct repo edits outside GSD workflow
- **Release model — ship complete:** Phase 180's single checkpoint is the only ratification gate; verdicts must be fully resolved before Phase 181 begins, not deferred as "iterate later"

---

## Sources

### Primary (HIGH confidence)
- `prompts/accrue-brand-book.md` (437-line seed, direct read) — palette hex values, typography, voice, tagline
- `accrue_admin/assets/css/theme.css` (213-line file, direct read) — existing token definitions, `--accrue-*` references, Geist font confirmed
- `.planning/phases/180-brand-audit-dna-lock/180-CONTEXT.md` (direct read) — all locked decisions D-01 through D-12
- `.planning/research/v1.52-brand-system-design.md` (direct read) — 14-section structure, exemplar list, antipattern list
- W3C WCAG 2.0 Techniques G17 (www.w3.org/TR/WCAG20-TECHS/G17.html) — normative contrast formula with 0.03928 threshold
- W3C WAI WCAG 2.1 Understanding SC 1.4.3 (www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html) — threshold values, large text definition, logotype exception
- Direct computation (node -e, this session) — all 21 contrast pairs for the Accrue palette, verified against D-06 expected values

### Secondary (MEDIUM confidence)
- Vercel brand guidelines (vercel.com/geist/brands) — geometric triangle mark, monochromatic, no container, Geist typeface
- Prisma presskit (github.com/prisma/presskit) — symbol + wordmark dual system, Barlow/Inter/Roboto Mono, no rect container
- Tailscale brand case study (together.agency/work/tailscale/) — understated/minimal developer authenticity, Inter, geometric supergraphics
- Supabase brand assets (supabase.com/brand-assets) — vibrant green accent, lightning bolt metaphor, Circular/Source Code Pro
- `references/planner-human-verify-mode.md` (direct read) — `checkpoint:decision` vs `checkpoint:human-verify` distinction; end-of-phase mode behavior
- `references/gate-prompts.md` (direct read) — approve-revise-abort, yes-no, and other checkpoint prompt patterns

### Tertiary (LOW confidence — not relied upon for any audit verdict)
- WebSearch results on Phoenix/Oban brand identity (no authoritative source found; observation-based)

---

## Metadata

**Confidence breakdown:**
- WCAG formula + contrast values: HIGH — computed from W3C normative formula, output matches CONTEXT.md D-06 expected values exactly
- Admin token SSOT mapping: HIGH — direct file read of theme.css
- Exemplar brand observations (Vercel, Prisma, Tailscale, Supabase): MEDIUM — fetched from official brand pages
- Exemplar brand observations (Phoenix, Oban): LOW — training-data observation, not verified via official brand page
- Checkpoint mechanics: HIGH — direct read of planner-human-verify-mode.md and gate-prompts.md

**Research date:** 2026-06-11
**Valid until:** 2026-07-11 (stable domain — WCAG formula does not change; brand pages may update but exemplar observations are for illustration, not compliance)
