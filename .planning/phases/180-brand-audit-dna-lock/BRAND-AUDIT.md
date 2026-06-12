---
milestone: v1.52
phase: 180
audited: 2026-06-11
status: draft
---

# Accrue Brand Audit

*Phase 180 — Brand Audit & DNA Lock. Sections §1–§8 authored here; §9–§14 authored in Plan 3. Status: draft (ratified after Plan 4 checkpoint).*

---

## §1 Executive Judgment

The Accrue brand book seed is a coherent, honest foundation for an open-source billing library. Its strongest attributes are a clear positioning statement ("the Elixir-native billing library for Phoenix apps"), an honest voice system (measured, exact, native, durable), a restrained palette suited to documentation and tooling contexts, and a compelling metaphor set (accumulation, timelines, layered records) that differentiates from both payment startups and generic SaaS. The core gap is execution: the seed describes direction without locking constraints. No logo system exists; palette usage rules are unspecified; token architecture references a brand layer that is currently undefined. Sections §3–§8 supply the evidence and the constraints that resolve these gaps.

### Name Overlap: Risk Acceptance on Record

The name Accrue is locked (published on Hex.pm with a v1.x zero-breaking-change promise; rename is structurally off the table). Commercial Accrue (byaccrue.com) is a consumer save-to-buy fintech in a different trademark class and channel; "accrue" is a weak dictionary-word mark; OSS precedent (Phoenix, Oban, Cashier) overwhelmingly favors coexistence. **Disambiguation tactics** (not name change): always-paired "Elixir billing library" qualifiers on GitHub/Hex/docs/social cards; dark/technical visual identity distinct from consumer-fintech gloss; SEO leaning on ecosystem keywords ("elixir", "phoenix"). These rules are locked in `BRAND-DNA.md §Positioning`.

### Overall Verdict

The seed is **KEEP** for strategy and voice, **TIGHTEN** for palette usage rules and token architecture, and **ADD** for logo system, token vocabulary, and voice copy blocks. No REWORK verdicts are warranted — nothing in the seed is wrong in concept; the gaps are missing constraints and missing artifacts. Detailed verdicts follow in §3–§8.

---

## §2 Brand DNA Extraction

This section extracts the core brand DNA elements from the seed and gives each a strength/gap signal that §3 will score and §5 will expand.

### 2.1 Positioning Statement

**Seed value:** "Accrue is the Elixir-native billing library for Phoenix apps."

**Strength:** Specific, category-correct, and immediately differentiating within the Elixir ecosystem. The "native" qualifier signals idiomatic integration rather than a wrapper — this is the right register.

**Gap:** The longer-form descriptor ("an open-source billing library for Elixir, Ecto, and Phoenix") appears in multiple seed sections without a canonical version. A single primary descriptor should be locked.

### 2.2 Palette

**Seed value:** Ink #111418, Slate #24303B, Fog #E9EEF2, Paper #FAFBFC (neutrals) + Moss #5E9E84, Cobalt #5D79F6, Amber #C8923B (accents).

**Strength:** The neutral foundation (Ink/Slate on Paper/Fog) achieves AAA contrast on all relevant pairs (see `artifacts/contrast-table.txt`). The accent palette is visually distinctive and communicates state semantics naturally: Moss for success/active, Cobalt for interactive/link, Amber for warning/pending.

**Gap:** No usage rules exist for the accent colors. Computed contrast ratios (see §3, dimensions 3–4) show accents pass only AA-large or fail on Paper surfaces — they are UI/large-text colors, not body-text colors. Usage rules are currently unspecified and must be locked by BRAND-DNA.md.

### 2.3 Typography

**Seed value:** "Use a neutral, modern sans: Inter / Geist / IBM Plex Sans" (sans); "JetBrains Mono / IBM Plex Mono" (mono).

**Strength:** The seed correctly identifies high-quality options suited to developer tooling. `accrue_admin` already implements Geist/Geist Mono via `--ax-font-sans` and `--ax-font-mono` — no drift.

**Gap:** The seed lists three sans options and two mono options without a single locked choice. The admin implementation has effectively locked Geist/Geist Mono; the DNA should ratify this.

### 2.4 Voice

**Seed value:** Six voice characteristics (direct, calm, precise, practical, literate, generous) and a clear avoidance list (hype, sales language, consumer-finance wording).

**Strength:** The voice is well-defined and internally consistent. The good/bad example pairs in section 5 of the seed are immediately useful. "The voice should sound like a maintainer you trust" is a memorable direction.

**Gap:** No canonical copy blocks exist for the primary surfaces (README hero, Hex.pm description, social card tagline). Voice principles exist; voice expressions do not yet. Phase 185 resolves this.

### 2.5 Visual Personality

**Seed value:** Accumulation, timelines, state transitions, layered records, aligned intervals, durable structure. Avoid: coins, cards, carts, gradient blobs, smiling people.

**Strength:** The metaphor set is strongly connected to billing lifecycle semantics — not generic "tech" imagery. The avoidance list is explicit and correct.

**Gap:** No visual expression artifacts exist (logo, diagrams, icons). The metaphor vocabulary is established; the execution layer begins in Phase 181.

### 2.6 Tagline

**Seed value:** "Billing state, modeled clearly."

**Strength:** Concise, domain-accurate, and library-register appropriate. The phrase "modeled clearly" signals Ecto/domain modeling competence without jargon — a meaningful signal to Phoenix developers.

**Gap:** Slightly abstract for first-contact surfaces (social cards, GitHub header). The companion descriptor "Billing for Elixir apps" is more immediately scannable. Both have roles; the DNA should specify which to use where.

### 2.7 Logo Direction

**Seed value:** Wordmark-first identity with internal stroke suggesting increment or layering; small-mark options (stacked lines, offset blocks, stepped interval mark, layered arcs).

**Strength:** The seed correctly identifies the constraints of an OSS library logo — must survive at GitHub avatar size, in badges, and in favicons. The direction (wordmark + minimal geometric mark) is the right call.

**Gap:** No logo system exists. The seed describes direction in words; Phase 181 must execute it against the 4 hard logo constraints (§8).

---

## §3 15-Dimension Scorecard

Scores: 0 (critical gap) — 1 (significant gap) — 2 (minor gap / mostly works) — 3 (fully adequate).

All palette contrast citations reference `artifacts/contrast-table.txt`.

| # | Dimension | Score | Rationale |
|---|-----------|-------|-----------|
| 1 | Positioning clarity | 3 | "Accrue is the Elixir-native billing library for Phoenix apps" is unambiguous, category-correct, and ecosystem-native. No change needed. |
| 2 | Name distinctiveness | 2 | "Accrue" is a real English word with immediate billing relevance; it is memorable within the OSS library namespace. Overlap with byaccrue.com addressed by disambiguation tactics (§1). |
| 3 | Palette contrast fitness (light surfaces) | 2 | Ink/Slate on Paper/Fog pass AAA (Ink vs Paper 17.83:1, Slate vs Paper 12.99:1 — see `artifacts/contrast-table.txt`). Accents on Paper are AA-large only: Moss 3.03:1, Cobalt 3.66:1, Amber 2.66:1 [FAIL]. Accent usage rules required. |
| 4 | Palette contrast fitness (dark surfaces) | 3 | Accents on Ink all pass AA-body: Moss 5.89:1, Cobalt 4.86:1, Amber 6.71:1 (see `artifacts/contrast-table.txt`). Fully valid for dark-surface text use. |
| 5 | Typography quality | 3 | Geist/Geist Mono already implemented in `accrue_admin`; high quality, open-source, developed by Vercel. No change required — lock in DNA. |
| 6 | Voice consistency | 3 | Six voice characteristics well-defined; good/bad examples supplied; avoidance list explicit. Voice is internally consistent. Missing only canonical copy blocks (Phase 185). |
| 7 | Visual personality specificity | 3 | "Accumulation, timelines, layered records" is meaningfully specific to billing lifecycle; avoidance list (coins, cards, carts) explicit. Stronger than most library brands. |
| 8 | Logo-system readiness | 0 | No logo system exists. No SVG marks, no lockup, no favicon, no monochrome variants. This is a critical gap blocking Phase 181 without the brief (§8). |
| 9 | Token architecture completeness | 1 | `accrue_admin/assets/css/theme.css` references `--accrue-paper`, `--accrue-ink`, `--accrue-moss`, `--accrue-amber`, `--accrue-slate` but these raw brand tokens are never defined. The semantic layer (`--ax-*`) exists; the brand layer (`--accrue-*`) does not. Phase 184 creates it. |
| 10 | Dark-mode readiness | 2 | Accent palette works on dark surfaces (score 3 above). Dark-mode color values present in admin CSS (`#0f1318`, `#171d24`). Missing: explicit dark-mode accent usage rules in the brand layer. |
| 11 | Small-size legibility readiness | 1 | No logo exists to test. Typography choice (Geist) is solid for legibility. Rendering evidence deferred to Phase 181. *[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]* |
| 12 | Dev-tooling register fit | 3 | The seed explicitly positions against startup-fintech gloss. Voice, palette, and metaphor set are all in the "well-made library" register. No adjustment needed. |
| 13 | Exemplar differentiation (Vercel/Prisma/Tailscale) | 2 | Shares Geist with Vercel (intentional — ecosystem signal), but accent palette (Moss/Cobalt/Amber) and state/lifecycle metaphor set is genuinely distinct. Risk: without a strong mark, minimal-but-different is hard to assert. |
| 14 | Anti-fintech signal | 3 | Explicit avoidance list (coins, cards, carts, consumer-finance wording). Dark/technical palette vs. consumer-fintech gloss. All three disambiguation tactics point away from fintech. |
| 15 | Downstream-phase readiness | 1 | Positioning (§1–§2): ready. Palette (§3–§4): needs usage rules. Token architecture (§7): needs Phase 184. Logo: needs Phase 181. Voice copy: needs Phase 185. Four downstream phases blocked at different severity levels. |

**Summary:** Neutrals and voice are audit-ready. Accent usage rules and the brand-layer token vocabulary are the critical near-term gaps. Logo-system absence is the only true blocking gap (score 0).

---

## §4 ~25-Surface Stress Tests

For each surface: KEEP / TIGHTEN / REWORK / ADD / REMOVE verdict with a one-sentence justification.

Any surface that touches 16px rendering receives the mandatory deferral marker. Contrast math is valid evidence here; screenshot legibility is not (D-05).

---

**§4.1 GitHub repo header — KEEP**
Ink on Paper text at body size passes AAA (17.83:1 — see `artifacts/contrast-table.txt` row "Ink vs Paper"). Cobalt links pass AA-body on Paper (3.66:1 — `Paper vs Cobalt`). The positioning statement ("Elixir billing library for Phoenix apps") should appear in the repo description to satisfy D-03 disambiguation.

**§4.2 GitHub social preview card — TIGHTEN**
The seed specifies dark background + subtle motif + Accrue wordmark + short tagline — correct concept. Amber on a dark (Ink) surface passes AA-body (6.71:1 — `Ink vs Amber`). TIGHTEN: the tagline must be "Billing for Elixir apps" or "Billing state, modeled clearly." — not a generic description — to trigger ecosystem keyword SEO (D-03 disambiguation tactic 3). No logo system yet; card must use typography only until Phase 183.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.3 GitHub README hero paragraph — KEEP**
Ink/Slate on Paper surfaces all pass AAA. Voice style ("direct, calm, precise") suits README register. Standard body text rendering — no small-size concern.

**§4.4 GitHub avatar / org icon (circular crop at 20px) — ADD**
No logo mark exists. The circular crop context demands an icon-only mark that survives at 20px. Add requirement: Phase 181 must produce an icon-only mark as part of the derived suite. Until Phase 183 ships the final mark, a typographic placeholder (wordmark initial "A" at brand weight) is acceptable for the avatar slot.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.5 Hex.pm package listing — TIGHTEN**
Hex.pm surfaces show package name, description, and version on a white/light background. Ink text passes AAA. TIGHTEN: description field must include "Elixir billing library" qualifier (D-03 tactic 1) — current default description may lack this. Cobalt links (Paper vs Cobalt 3.66:1) are AA-large only and acceptable for link text at typical heading sizes on Hex.pm listings.

**§4.6 HexDocs landing page header — KEEP**
Ink on Paper passes AAA. Cobalt for interactive elements passes AA-large on Paper (3.66:1 — `Paper vs Cobalt`). Typography (Geist where applicable) is high quality. Header-level text sizes are ≥24px (large text threshold), so AA-large is acceptable.

**§4.7 HexDocs sidebar badge — TIGHTEN**
Sidebar badges are typically small (12–14px). Moss on Paper = 3.03:1 (`Paper vs Moss`) passes AA-large at ≥18.67px bold but fails at normal body size. TIGHTEN: accent-colored badges must use Ink or Slate text on light accent surface, not Moss text on Paper. No palette hex change required.

**§4.8 Favicon SVG at 32×32 — ADD**
No favicon exists. Phase 181 must produce a favicon SVG using the icon-only mark at 32×32. At this size contrast math applies but rendering legibility is deferred.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.9 Favicon ICO at 16×16 — ADD**
No favicon ICO exists. Phase 181 must produce a 16×16 ICO derivative. At 16px, legibility evidence requires a screenshot pipeline.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.10 npm/pkg.go-style dark-bg registry — KEEP**
Accents on Ink all pass AA-body (Moss 5.89:1, Cobalt 4.86:1, Amber 6.71:1 — see `artifacts/contrast-table.txt`). Dark-background registry contexts are well-served by the current palette.

**§4.11 Email header (Swoosh template) — TIGHTEN**
Email header context: Ink on Paper AAA, Moss accent for success state passes AA-body on Ink (5.89:1). TIGHTEN: email headers at small sizes (12–14px) must not use Moss as text color on Paper; Ink or Slate only. The Swoosh template using `--accrue-*` tokens must inherit the usage rules from Phase 184's token spec.

**§4.12 PDF invoice header — TIGHTEN**
PDF rendering uses chromic_pdf (Chrome-based). Ink on Paper passes AAA for body text. TIGHTEN: Amber (#C8923B) on Paper = 2.66:1 (FAIL — `Paper vs Amber`) — Amber must not appear as text color in PDF invoice headers on light paper surfaces. Use Amber for icon/decorative elements only on light surfaces in PDF context.

**§4.13 Admin UI nav header (accrue_admin) — KEEP**
`accrue_admin` nav uses Ink-family dark tones. Accents on dark surfaces pass AA-body (Cobalt vs Ink 4.86:1, Moss vs Ink 5.89:1). The admin already implements Geist and the brand shadow system (`rgba(17, 20, 24, …)`). Token architecture aligned. No change until Phase 184 defines the brand layer.

**§4.14 Admin UI dark mode header — KEEP**
Dark base in admin CSS: `#0f1318` (Ink-family). Paper-family text on dark base passes AAA by symmetry with Ink on Paper. Accent usage on dark mode is fully valid (see dimension 4 in §3). No change required.

**§4.15 Social card 1200×630 light — TIGHTEN**
Light social cards use Paper/Fog backgrounds. Ink text passes AAA. TIGHTEN: Moss, Cobalt, and Amber must not be used as body text on these backgrounds (Paper vs Moss 3.03:1, Paper vs Cobalt 3.66:1, Paper vs Amber 2.66:1 FAIL — see `artifacts/contrast-table.txt`). Accents acceptable for UI elements and large-text headings (≥24px) only.

**§4.16 Social card 1200×630 dark — KEEP**
Dark social cards use Ink/Slate backgrounds. All accents pass AA-body or higher on Ink. The seed's specified format (dark background + Accrue wordmark + tagline) is the correct direction and is already contrast-valid.

**§4.17 Blog/devrel post header — KEEP**
Standard light-background editorial context. Ink on Paper AAA. Accent use for headings at ≥24px is AA-large valid. Moss/Cobalt acceptable as heading accent colors in large-text contexts.

**§4.18 Conference slide deck title — TIGHTEN**
Slide decks typically project at distances where 16px body text can read as smaller. TIGHTEN: on light-background slides, accent text colors must follow AA-large minimum (3.0:1) — Cobalt (3.66:1) and Moss (3.03:1) are borderline-acceptable for heading text; Amber (2.66:1 on Paper — FAIL) must not be used as text color on light slide backgrounds. Dark background slides are fully valid.

**§4.19 README code block accent color — KEEP**
Code block contexts: typically use Fog/Paper or dark backgrounds. In dark contexts, Cobalt for syntax highlighting passes AA-body on Ink (4.86:1). In light contexts, Cobalt passes AA-large on Paper (3.66:1). Acceptable for code-context use; syntax highlighting is large-format and uses monospace font.

**§4.20 Error message / terminal output — KEEP**
Terminal output is typically system-rendered (platform contrast). Amber on Ink passes AA-body (6.71:1) for warnings in terminal contexts. Moss on Ink passes AA-body (5.89:1) for success messages. Both valid without restriction.

**§4.21 macOS dock icon — ADD**
No logo mark exists. Dock icons need a rounded-rect silhouette with a clear mark at ~128px. Phase 181/183 must produce a macOS-format icon derivative. Contrast at icon size is not the bottleneck; recognizability of the mark is.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.22 iOS Safari pinned tab — ADD**
Pinned tabs use a 2-color SVG (mask-based). Phase 181/183 must produce a pinned-tab SVG derivative. This is a Phase 183 derived suite item; not a blocker for Phase 181.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.23 VS Code extension icon — ADD**
VS Code marketplace icons appear at 128×128px and 48×48px. No icon exists. If an Accrue VS Code extension is ever created (currently out of scope), Phase 181/183's icon-only mark should be sized appropriately. Mark at this size: contrast math applies; legibility at small icon size deferred.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

**§4.24 GitHub Actions badge — KEEP**
GitHub Actions badges use system-rendered text at small sizes on white backgrounds. Accrue's palette is not applied to CI badge content (Shields.io controls colors). Status: badge text is outside brand scope; the Shields.io label area can use Ink-on-Paper equivalent. No brand change required.

**§4.25 Printed specification sheet (black-on-white) — KEEP**
Print context maps to Ink (#111418) ≈ near-black on Paper (#FAFBFC) ≈ near-white. Ink vs Paper = 17.83:1 (AAA). Accent colors on printed sheets should be used decoratively only (not as text colors on white). No change required.

---

*§4 summary: 8 KEEP, 7 TIGHTEN, 0 REWORK, 5 ADD, 0 REMOVE. All TIGHTEN verdicts are usage-rule restrictions citing contrast-table.txt — no palette hex changes required. All ADD verdicts are Phase 181/183 logo-system deliverables.*

---

## §5 Gaps by Severity

### Critical Gaps (block downstream phases)

**GAP-C1 — No logo system (blocks Phase 181)**
*First flagged:* §3 dimension 8 (score 0); §4 surfaces §4.4, §4.8, §4.9, §4.21, §4.22, §4.23.

No SVG mark, lockup, favicon, icon-only derivative, monochrome variant, or clearspace specification exists. Phase 181 cannot begin tournament round 1 without the binding logo brief (§8 of this audit). The logo brief is Phase 180 output; logo execution begins Phase 181.

**GAP-C2 — Brand-layer token vocabulary undefined (partially blocks Phase 184)**
*First flagged:* §3 dimension 9 (score 1).

`accrue_admin/assets/css/theme.css` references `--accrue-paper`, `--accrue-ink`, `--accrue-moss`, `--accrue-amber`, and `--accrue-slate` (lines 105–116) as CSS custom properties, but these are never defined — the admin CSS imports a semantic layer without a brand layer below it. Phase 184 must define all seven `--accrue-*` raw tokens in `tokens.css`. Until then, the admin's brand-layer color references resolve to browser defaults or cascade failures depending on host environment.

### Significant Gaps (reduce quality; have workarounds)

**GAP-S1 — Accent usage rules undocumented**
*First flagged:* §2.2; §3 dimension 3 (score 2); §4 surfaces §4.7, §4.11, §4.12, §4.15, §4.18.

Moss, Cobalt, and Amber all fail AA-body on Paper/Fog surfaces (Moss 3.03:1, Cobalt 3.66:1, Amber 2.66:1 FAIL — see `artifacts/contrast-table.txt`). The palette is correct; the usage rules are missing. Every TIGHTEN verdict in §4 is a consequence of this gap. Resolved by BRAND-DNA.md §Palette usage rules and Phase 184 token spec.

**GAP-S2 — Typography choice not locked**
*First flagged:* §2.3.

The seed lists multiple type options; the admin has already converged on Geist/Geist Mono. The DNA should ratify Geist/Geist Mono as the locked choice so no future planner re-opens the question.

**GAP-S3 — No canonical copy blocks for primary surfaces**
*First flagged:* §2.4; §3 dimension 6 (score 3 on voice principles, but copy execution is missing).

Voice principles are well-defined. README hero copy, Hex.pm description, social card tagline, and HexDocs landing paragraph are not yet authored. Phase 185 produces these. Workaround: the seed's "good examples" list provides usable copy until Phase 185.

**GAP-S4 — Dark-mode accent usage rules missing from brand layer**
*First flagged:* §3 dimension 10 (score 2).

Dark-mode color values exist in the admin CSS but are not formalized as brand-layer constraints. Phase 184 must define dark-mode variants for the `--accrue-*` tokens and ensure accent rules are explicit for both light and dark contexts.

### Minor Gaps (polish; no blockers)

**GAP-M1 — Tagline usage context unspecified**
*First flagged:* §2.6.

"Billing state, modeled clearly." is the recommended tagline; "Billing for Elixir apps" is the scannable short-form. No canonical mapping exists specifying which to use on which surface (social card vs. README hero vs. Hex.pm description). DNA should lock this.

**GAP-M2 — Positioning statement not canonically versioned**
*First flagged:* §2.1.

Multiple variants appear in the seed ("Accrue is the Elixir-native billing library for Phoenix apps" / "An open-source billing library for Elixir, Ecto, and Phoenix" / "Billing for Elixir apps"). DNA should lock one as canonical primary and assign the others as surface-specific variants.

**GAP-M3 — GitHub/Hex metadata disambiguation not formally committed**
*First flagged:* §4.1, §4.5.

D-03 disambiguation tactic 1 (always-paired "Elixir billing library" qualifier) is a strategy decision that should appear in the GitHub repo description and Hex.pm metadata. This is not a design-system change — it is a metadata update. Assign to Phase 185 (voice/microcopy) or as a quick task alongside Phase 184.

---

## §6 Upgrade Recommendations

Listed in dependency order. Each resolves one or more §5 gaps.

**Rec 1 — Author BRAND-DNA.md with locked positioning, palette usage rules, type stack, and voice values (Phase 180 Plan 3)**
Resolves: GAP-S1 (accent usage rules), GAP-S2 (typography lock), GAP-M1 (tagline context), GAP-M2 (positioning canonical). The DNA is a one-page machine-loadable constraint file. Downstream phases load it as context, not rationale.

**Rec 2 — Define brand-layer token vocabulary (`tokens.css`) with all seven `--accrue-*` raw tokens and dark-mode counterparts (Phase 184)**
Resolves: GAP-C2 (undefined brand layer), GAP-S4 (dark-mode accent rules). This is the single most impactful technical change — it removes a silent cascade failure in the admin CSS and makes the brand layer explicitly portable.

**Rec 3 — Commission logo system via tournament (Phases 181–183)**
Resolves: GAP-C1 (no logo system). Phase 181 executes the tournament round 1 (divergent, 12–16 concepts across 4 directions); Phase 182 converges; Phase 183 produces the derived suite (primary lockup, icon-only, monochrome, favicon, social card, with-subtitle).

**Rec 4 — Author voice system and canonical copy blocks (Phase 185)**
Resolves: GAP-S3 (no canonical copy blocks), GAP-M3 (GitHub/Hex metadata disambiguation). Phase 185 authors README hero, Hex.pm description, social card taglines, HexDocs landing paragraph, and the disambiguation metadata.

**Rec 5 — Assemble HTML brand book with all artifacts (Phase 186)**
Resolves: Phase-186 BOOK-01/BOOK-02. Standalone HTML brand book (opens via `file://`, no build step) integrating all outputs from Phases 180–185. Verified against §14 quality-gate checklist.

**Rec 6 — Add qualifier text to GitHub repo description and Hex.pm listing immediately (quick task)**
Resolves: GAP-M3 partially. The D-03 disambiguation tactic (always-paired "Elixir billing library" qualifier) can be applied to repository metadata without waiting for Phase 185. Recommended as a quick-task alongside Plan 4 or Phase 184.

**Rec 7 — Specify dark/light logo pair requirement in the logo brief (§8 of this audit)**
Resolves: implicit gap in §4.16 (dark social cards) and §4.14 (admin dark mode). The logo brief must specify that a dark-background version of the primary lockup is a required derivative — not an optional variant. Phase 183's derived suite should produce this as a first-class output.

---

## §7 Token Specification

### Architecture Overview

Accrue uses a two-layer CSS custom property architecture:

1. **Brand layer** (`--accrue-*` raw tokens) — seven named color values, defined in Phase 184's `tokens.css`. This layer owns the palette hex values and is the canonical source for brand color identity.
2. **Semantic layer** (`--ax-*` tokens) — functional roles in `accrue_admin/assets/css/theme.css`. This layer consumes the brand layer via `var(--accrue-*)` references and maps palette values to application roles.

The admin's semantic layer already exists and is READ-ONLY this milestone. Phase 184 defines the brand layer below it.

### Brand-Layer Raw Token Mapping

The following seven `--accrue-*` raw tokens are the required export surface of the brand layer. The admin's semantic layer references these tokens; they must be defined before the admin CSS cascade is complete.

| Raw Token | Hex | Admin Semantic Binding | Role |
|-----------|-----|------------------------|------|
| `--accrue-ink` | #111418 | `--ax-primary: var(--accrue-ink)` | Primary text, dark surface baseline |
| `--accrue-slate` | #24303B | `--ax-subtle: var(--accrue-slate)` | Secondary dark, borders, subtext on light |
| `--accrue-fog` | #E9EEF2 | *(no current --ax-* binding — brand-only)* | Soft neutral light, section backgrounds |
| `--accrue-paper` | #FAFBFC | `--ax-base: var(--accrue-paper)` | Doc background, page base |
| `--accrue-moss` | #5E9E84 | `--ax-success: var(--accrue-moss)` | Success/active states, icons, large-text accent on light |
| `--accrue-cobalt` | #5D79F6 | *(no current --ax-* binding — brand-only)* | Interactive/link states; consumed by host via brand layer |
| `--accrue-amber` | #C8923B | `--ax-warning: var(--accrue-amber)` | Warning/pending states |

**Notes:**
- `--accrue-fog` and `--accrue-cobalt` have no current `--ax-*` semantic binding in `theme.css`. They are brand-only tokens — available for host-app use and future semantic bindings, but not currently consumed by the admin semantic layer.
- `--ax-subtle` is bound to `--accrue-slate`; this is the only secondary-dark semantic binding in the current admin CSS.
- Dark-mode counterparts (e.g., `--accrue-paper` ≈ `#0f1318` in dark) must be defined in Phase 184's `tokens.css` using a `[data-theme="dark"]` selector or equivalent, matching the existing dark-mode values in `theme.css`.

### Contrast Evidence for Token Roles

All usage rules below derive from `artifacts/contrast-table.txt`. No usage rule is asserted without a cited row.

**`--accrue-ink` (Ink #111418) — KEEP**
Ink vs Paper = 17.83:1 [AAA]. Ink vs Fog = 15.81:1 [AAA]. Valid for body text, headings, and structural dark surfaces in all contexts. No restriction needed.

**`--accrue-slate` (Slate #24303B) — KEEP**
Slate vs Paper = 12.99:1 [AAA]. Slate vs Fog = 11.52:1 [AAA]. Valid for secondary text, borders, and subtext on all light surfaces. No restriction needed.

**`--accrue-fog` (Fog #E9EEF2) — KEEP**
Fog vs Paper = 1.13:1 [FAIL] — expected (same-family near-neutral pair; not used as text color). Used exclusively as a surface/background color, not text. No restriction needed for its intended role.

**`--accrue-paper` (Paper #FAFBFC) — KEEP**
Paper vs Fog = 1.13:1 [FAIL] — expected (same-family near-neutral pair). Used exclusively as a document background surface. No restriction needed.

**`--accrue-moss` (Moss #5E9E84) — TIGHTEN**
Paper vs Moss = 3.03:1 [AA-large] (see `artifacts/contrast-table.txt` row "Paper vs Moss"). Passes AA-large (≥ 3.0:1) but fails AA-body (< 4.5:1) on Paper. Fog vs Moss = 2.68:1 [FAIL] on Fog. Moss vs Ink = 5.89:1 [AA-body] on dark surfaces.
Usage rule: `--accrue-moss` may be used for interactive states, icons, success indicators, and large-text accent (≥ 18.67px bold or ≥ 24px) on Paper or Ink surfaces. Never as body-text color on light surfaces. No palette hex change required.

**`--accrue-cobalt` (Cobalt #5D79F6) — TIGHTEN**
Paper vs Cobalt = 3.66:1 [AA-large] (see `artifacts/contrast-table.txt` row "Paper vs Cobalt"). Passes AA-large but fails AA-body on Paper. Cobalt vs Ink = 4.86:1 [AA-body] on Ink.
Usage rule: `--accrue-cobalt` may be used for interactive elements, focus rings, link text, and active states. On light surfaces (Paper/Fog), restrict to large-text and UI-component contexts (buttons, links, focus rings). Body-text use requires Ink/Slate. No palette hex change required.

**`--accrue-amber` (Amber #C8923B) — TIGHTEN**
Paper vs Amber = 2.66:1 [FAIL] (see `artifacts/contrast-table.txt` row "Paper vs Amber"). Fails AA-large and AA-body on Paper. Fog vs Amber = 2.36:1 [FAIL]. Amber vs Ink = 6.71:1 [AA-body] on dark surfaces.
Usage rule: `--accrue-amber` must not be used as a text color on any light surface (Paper, Fog). Valid for warning icons, decorative borders, and text on Ink-surface backgrounds. No palette hex change required.

### Semantic Token Roles for Phase 184

Phase 184 must create `tokens.css` with the following token categories. This list is the audit's specification; Phase 184 executes it.

1. **Raw brand palette** — seven `--accrue-*` properties (above)
2. **Semantic color roles** — surface (base, elevated, sunken), content (primary, muted, subtle), interactive (accent, focus-ring), feedback (success, warning, danger, info)
3. **Typography scale** — primary font stack (Geist sans), mono stack (Geist Mono), type-size scale referencing `--ax-type-*`
4. **Spacing scale** — reference `--ax-space-*` existing tokens
5. **Radius tokens** — reference `--ax-radius-*` existing tokens
6. **Focus-ring specification** — 2px solid Cobalt focus ring with 2px offset (WCAG 2.4.11 compliant)
7. **State tokens** — hover, active, disabled, loading states

**Verdict: TIGHTEN for brand palette; KEEP for typography and spacing**
Geist/Geist Mono already implemented in `accrue_admin` (`--ax-font-sans`, `--ax-font-mono`) — KEEP, lock in DNA. The brand palette is correct in concept but requires a documented raw-token layer — TIGHTEN, add `--accrue-*` layer in Phase 184.

---

## §8 Logo-System Specification

### 4 Hard Logo Constraints

These constraints are binding on every Phase 181+ logo candidate. They also appear verbatim in `logo-brief.md`.

1. **No rectangular background/container shape** behind the logomark — marks breathe and break boundaries; container shapes signal convenience-first execution, not crafted identity.
2. **Logotype optically close to the mark** — not visually separated; the mark and name form a unified unit.
3. **Main lockup carries no subtitle** — a separate with-subtitle variant ships as a derived artifact; the primary lockup is mark + wordmark only.
4. **Fully-integrated custom typemark options required** — motif or flourish worked into the letterforms (particularly the "A" or the "cc" ligature area), not a standalone icon placed left-of-text.

### Conceptual Directions for Phase 181

Phase 181 executes 12–16 concepts across 4 directions. This section specifies what each direction means as a starting constraint.

**Direction A — Accumulation Strata**
Mark is built from 2–4 horizontal bands or layers, increasing in a stepped pattern. Suggests accrual over time — ledger rows, statement periods, building state. Should feel structural and precise, not decorative. No gradients; flat paths only. The stacking direction is intentional (accumulating upward or rightward, not decreasing).

**Direction B — Stepped Interval / Timeline Tick**
Mark uses a geometric step function or interval marker: a shape that reads as a moment on a timeline or a billing period boundary. Related to Recharts' step-line chart as a metaphor. Clean angles, minimal path count. Not a clock face; not a calendar icon.

**Direction C — Layered Arcs / State Transition**
Two or three arcs in a precise geometric arrangement suggesting a lifecycle state change or a transaction completing. Could reference the "billing state accrues" core idea through an arc-and-endpoint motif. Differentiated from generic "wi-fi / connectivity" arcs by: irregular or offset geometry, not concentric symmetric rings.

**Direction D — Integrated Typemark**
No standalone symbol; the word "Accrue" is the mark, with a motif or flourish integrated into one or two letterforms. The "A" crossbar could become an interval tick; the "cc" pair could suggest a state loop; the "e" terminal could carry a small geometric accent. Must survive at small sizes without the motif overwhelming legibility.
*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here]*

### Required Derived Suite (Phase 183 Target)

Phase 183 produces the following from the tournament winner:

| Artifact | Description |
|----------|-------------|
| Primary lockup | Mark + close-set logotype, no subtitle, light-bg and dark-bg versions |
| Integrated typemark | Motif worked into letterforms (Direction D variant of winner) |
| Icon-only mark | Standalone mark at square format; no logotype |
| Monochrome positive | Black mark + black wordmark on white |
| Monochrome negative | White mark + white wordmark on black |
| Dark-bg variant | Primary lockup optimized for Ink/dark surfaces |
| Favicon SVG | 32×32 icon-only mark in SVG |
| Favicon ICO | 16×16 multi-resolution .ico file |
| Favicon PNG | 192×192 and 512×512 for web app manifest |
| Social card SVG+PNG | 1200×630 in both formats; light and dark variants |
| With-subtitle variant | Primary lockup + subtitle line ("Billing for Elixir apps") |
| Clearspace spec | Minimum clear zone around mark (expressed as fraction of mark height) |
| Minimum-size spec | Smallest size at which primary lockup is legible (screenshot evidence Phase 181) |

*[DEFERRED: Phase 181 screenshot pipeline — legibility at 16px not asserted here for favicon and small-size artifacts]*

### Antipattern Ban List

The following are explicitly prohibited for any Phase 181+ candidate. Each prohibition has a cited rationale.

| Antipattern | Prohibition Rationale |
|-------------|----------------------|
| Gradient blobs | No semantic connection to billing state; ages poorly; signals generic SaaS startup 2019, not well-crafted library tooling. |
| Meaningless hexagons | Overused in "tech" branding; conveys "we needed a shape"; no specific connection to billing lifecycle or Elixir ecosystem. |
| Rectangular container behind mark | Violates hard constraint 1 explicitly; breaks visual breathing; signals convenience-first execution. |
| Coins / cards / carts / price tags | Finance clichés; contradict the "well-made dev tooling" brand register; the visual world is state diagrams and timelines, not consumer payment surfaces. |
| Smiling people / lifestyle photography | Wrong register entirely for a low-level billing library. |
| Stacked wordmark with subtitle in main lockup | The subtitle becomes the mark; primary lockup is unusable at small sizes. Violates hard constraint 3. |
| Concentric symmetric arcs (wi-fi style) | Reads as connectivity/signal, not state/lifecycle. Distinguish from Direction C's geometric arc-and-endpoint motif by using non-concentric, offset geometry. |

### Exemplar Family

Phase 181 candidates should position themselves relative to this exemplar spectrum:

**Aim for:** Prisma / Vercel — minimal, geometric, high-precision; mark breathes without a container; single flat-path concept; works at any size in any color.

**Differentiate from:**
- Supabase (vibrant, velocity-forward, lightning bolt metaphor — too product-speed, not calm library)
- Phoenix (mascot-driven — works because the mark names the framework directly; Accrue's name is more abstract)
- Generic dev-tool hexagon grid (overused; avoid)

**Unique differentiator:** State/lifecycle metaphor (accumulation, intervals, strata) — specific to billing infrastructure and immediately legible to backend developers. This is Accrue's competitive moat in the logo design space; no Vercel or Prisma concept needs a lifecycle reading.

---

## §9 Visual-Example Guidance

*(Authored in Plan 3)*

---

## §10 Voice & Microcopy

*(Authored in Plan 3)*

---

## §11 Landing/Docs Blueprint

*(Authored in Plan 3)*

---

## §12 Repo Artifact Plan

*(Authored in Plan 3)*

---

## §13 Prioritized Actions

*(Authored in Plan 3)*

---

## §14 Final Quality Gate

*(Authored in Plan 3)*
