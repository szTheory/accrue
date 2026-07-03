# Design-Lens Rubric (Admin UI Ratchet)

This file is the scoring contract for the **comparative graphic-design lens** of the admin UI
ratchet (`accrue_admin/e2e/ratchet/ratchet-propose.mjs`, Phase 205 plan 04). It sharpens a
subset of the 12 audit dimensions for one purpose: judging whether an admin surface reads as
**quiet, well-made developer tooling** at Accrue's own density bar — and catching drift toward
either density pole (cramped *or* wasteful) and toward generic SaaS / fintech taste.

The lens is **comparative, not absolute.** It does not assign an award score or a 0–100 grade.
It asks a single relative question per surface: *does this surface hold up against Accrue's own
correctly-dense good exemplar and stay clear of the matched bad exemplar and the named
quiet-dev-tooling tier anchors?* Findings are emitted defect-only (0..N per image); a surface
that holds the bar emits nothing.

## Precedence

`brandbook/` is the authoritative brand DNA source. **`brandbook/` supersedes
`prompts/accrue-brand-book.md` wherever they conflict; the older prompt remains historical
context only.** Where this rubric and `brandbook/{voice.md,README.md,copy.md,tokens/}` disagree,
`brandbook/` wins and this rubric is corrected.

Structured data wins over prose: if this markdown disagrees with `region-tags.js` (the identity
SSOT) or `exemplars/PROVENANCE.json` (the exemplar manifest), those artifacts are canonical and
this file is regenerated to match.

## 1. Purpose & Scope

- **In scope:** comparative graphic-design judgement of a rendered admin surface against
  Accrue's brand DNA and its own-render exemplar set — hierarchy, spacing rhythm (both poles),
  responsive behavior, and brand expression, with token and contrast as support.
- **Out of scope:** the 6 job-anchored persona lenses (they own task-completion blockers, not
  taste); the frozen 30,348-cell census 0–3 score (the ratchet layers on it via `cell_refs`,
  never replaces it); anything the persona lenses already own (focus semantics, interaction
  integrity, motion, state coverage, reuse — dimensions 4/7/9/10/11 are not sharpened here).
- **Never gates CI.** The lens is a proposer only; its output is `candidates.ndjson` rows for the
  Phase 206 verifier. A human, not the model, decides what ships.

## 2. Brand DNA Anchor (`brandbook/`)

Accrue's UI target, in the brandbook's own terms:

- **Quiet, well-made developer tooling — not fintech, not generic SaaS.** The surface should feel
  built by "a maintainer you trust" (`voice.md` north star), not a marketing team.
- **Measured / exact / native / durable** (`voice.md`). Visually this reads as: restrained color,
  operator density over decoration, `ax-*` tokens over one-off values, Geist type, domain
  vocabulary. No exclamation-energy, no gradient-glossy hero treatment, no adjective-led chrome.
- **Anti-fintech vocabulary is a hard brand rule.** `voice.md` bans `wallet`, `money`, `funds`.
  A surface that *looks* like a consumer-finance / fintech dashboard (saturated gradients, glossy
  pill CTAs, rounded card-everything, drop-shadow depth) is off-register even if its copy is clean.
- **Correct density is the brand risk.** The admin is a **data-dense operator console**. The single
  biggest failure mode of this lens is biasing toward over-whitespacing a surface that is
  *correctly* dense. The GOOD dashboard exemplar exists to hold that line; dimension 3 penalizes
  **wasteful** whitespace exactly as hard as it penalizes **cramped** spacing.

## 3. Comparative Tier Anchors (textual, license-safe)

The design lens is calibrated against **named** quiet-dev-tooling products, held as **textual**
anchors (not committed screenshots — more stable than one overfit third-party capture, and
license-clean). These describe the *tier* the surface is being compared against; they are never
attached as images.

**Brand-positive tier anchors** (the register Accrue aims for — restrained, operator-dense,
token-disciplined, quietly branded):

- **Linear** — hierarchy and keyboard-first operator density.
- **Vercel** dashboard — calm surface, disciplined spacing rhythm, no decoration.
- **Prisma** — technical clarity, structured-data legibility.
- **Tailscale** — plain, honest admin density without SaaS gloss.
- **Oban** (Web) — Elixir-native operator console; the closest in-ecosystem reference.

**Density/IA reference only, under an explicit anti-fintech caveat:**

- **Stripe** — cite ONLY for operator density and information architecture. **Borrow its operator
  density, never its brand, color, or voice.** Stripe is a fintech brand and is explicitly **not**
  a brand-positive exemplar for Accrue (dimension 8 DNA is "no generic SaaS/fintech taste";
  `voice.md` bans wallet/money/funds). A surface that reads as Stripe-branded is off-register.

## 4. Sharpened Sub-Criteria

The 12 canonical dimension anchors live in
`.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` and in `region-tags.js`
(`DIMENSIONS`, 1..12). This lens **sharpens four** of them and uses **two** as support. It adds
**no 13th dimension** — a new dimension would fork the `DIMENSIONS` map across the proposer,
verifier, gate, and digest. Layer/z-index and other cross-cutting concerns stay overlay tags.

Primary (the lens raises findings on these):

- **d2 · visual-hierarchy** — Is the operator's next useful read obvious? One clear focal path,
  established heading/table/action patterns, no competing focal points. Below bar when a surface
  buries the primary operator action or flattens everything to one weight.
- **d3 · spacing-rhythm** — Density appropriate to a **data-dense operator console**, on the
  `ax-*` spacing scale. **Penalize BOTH poles equally:**
  - *cramped* — rows/controls/sections butt together, no breathing room between distinct groups,
    touch targets too tight, content collides. (See `exemplars/bad/cramped.png`.)
  - *wasteful* — oversized padding/gaps push the operator's data below the fold, one-screen work
    becomes multi-scroll, the console reads like a marketing page. (See `exemplars/bad/wasteful.png`.)
  A finding here MUST carry the `direction: air|cramped` self-flag (§6) so the Phase-206
  operator-density-defender can apply a higher confirm bar to `air`-ward (more-whitespace) claims.
- **d5 · responsive-mobile-first** — Works from narrow mobile to desktop with established
  responsive patterns, not a squeezed desktop layout. Below bar on clipping, unreachable controls,
  or awkward degradation.
- **d8 · brand-expression** — Reads as distinctly Accrue and restrained: `ax-*` tokens, Geist,
  domain vocabulary, quiet color. Below bar when generic/decorative/off-register or
  fintech-glossy. (See `exemplars/bad/off-register.png`.)

Support (consulted to substantiate a primary finding; not raised standalone by this lens):

- **d1 · token-compliance** — bare palette values, ad-hoc spacing, inline-style drift.
- **d6 · contrast** — text/control/role contrast in both themes; never color-alone.

## 5. Exemplar Set Reference

The full curated set (5 own-render PNGs, license-clean by construction — own screenshots of an
MIT repo) lives under `exemplars/` and is documented in `exemplars/PROVENANCE.json`. The design
lens attaches **exactly two** images per call (bounded regardless of surface): **one
archetype-matched GOOD + one archetype-matched BAD** (D-20 hybrid few-shot).

| Role | File | Density pole | Purpose |
|------|------|--------------|---------|
| good | `exemplars/good/dashboard.png` | correctly dense | data-dense-operator anchor; the primary density-footgun suppressor |
| good | `exemplars/good/dev-components.png` | correctly dense | foundation / component-kitchen anchor |
| bad  | `exemplars/bad/cramped.png` | cramped | under-spaced pole |
| bad  | `exemplars/bad/wasteful.png` | wasteful | over-whitespaced pole |
| bad  | `exemplars/bad/off-register.png` | — | fintech-glossy / off-brand negative |

**Archetype-matched selection is keyed off `surface_type`** (RESEARCH Open Q3, resolved). A small
static map picks the pair for each call:

| `surface_type` | GOOD exemplar | BAD exemplar |
|----------------|---------------|--------------|
| `page-flow` (list/overview operator surfaces, e.g. dashboard, lists) | `good/dashboard.png` | `bad/cramped.png` (dense surfaces fail cramped-ward first) |
| `component` / `component-group` (foundation, `/dev/components`) | `good/dev-components.png` | `bad/wasteful.png` (sparse component surfaces fail air-ward first) |

`off-register.png` is the **brand-expression (d8) reference**: attach it as the BAD exemplar when
the lens is specifically probing brand register, regardless of `surface_type`. Only two images
ship per call — never the whole gallery (payload bloat, diminishing returns past ~2).

The exemplar set is **version-pinned**. It is refreshed only via a deliberate "re-baseline
exemplars" maintainer commit (PNGs + `PROVENANCE.json` together) — never auto-drifted from the
latest render. A drifting anchor would break run-to-run comparability.

## 6. Output Contract

The design lens emits **defect-only** `candidates.ndjson` rows (the shared schema in
`region-tags.js`; identity re-derived by the harness, never trusted from the model):

- **Dimensions:** only `{2, 3, 5, 8}` primary, with `{1, 6}` as support. A design-lens row whose
  `dimension` is outside this set is dropped at the parse-time gate.
- **`direction: air | cramped`** — mandatory self-flag on every design-lens finding. `air` = the
  fix would ADD whitespace; `cramped` = the fix would REMOVE whitespace / tighten. This drives the
  Phase-206 operator-density-defender's asymmetric confirm bar (higher bar for `air`-ward claims,
  because over-whitespacing a dense console is the brand risk).
- **`severity: minor | real`** — the shared 2-level ordinal. The lens never invents other levels.
- **`raised_by`** — `{ lens_kind: "design" }` (no `persona_id`/`job` for the design lens).
- **Free text** (`defect`, `suggested_fix`, `exemplar_ref`) is excluded from identity. `defect`
  MUST name a concrete object + dimension; the taste denylist rejects "nicer/cleaner/prettier/
  sleek/more modern" unless paired with a dimension and a named object.
- **`exemplar_ref`** — which curated exemplar the surface fell short of (e.g.
  `exemplars/bad/wasteful.png`).

## 7. Justification-Token Vocabulary

Every emitted row carries exactly one `justification_token`, enforced by the deterministic
parse-time gate (`isAdmissibleToken` in `region-tags.js`) — a row without an admissible token is
dropped before any human sees it:

| Token | Use when |
|-------|----------|
| `rubric-dim-below-bar` | The surface falls below a sharpened dimension's bar (d2/d3/d5/d8, or d1/d6 in support). The design lens's primary token. |
| `persona-job-miss:<job>` | A design defect literally blocks a persona's job (`<job>` names the job). Rare for the design lens; usually a persona-lens token. |
| `token-bypass` | The surface bypasses the `ax-*` token system (bare palette/spacing/layer values) — a d1 support finding. |

## 8. Anti-Patterns / Footgun Table

| Footgun | Why it is wrong | Guardrail |
|---------|-----------------|-----------|
| Over-whitespacing a correctly-dense console | The admin is an operator console; air-ward drift buries data below the fold. This is the milestone's biggest brand risk. | d3 penalizes wasteful == cramped; `direction: air` findings face a higher Phase-206 confirm bar; `good/dashboard.png` is the density anchor. |
| Treating Stripe as a brand-positive exemplar | Stripe is a fintech brand; d8 DNA forbids fintech taste; `voice.md` bans wallet/money/funds. | Stripe is density/IA-only under the anti-fintech caveat (§3); brand-positive anchors are Linear/Vercel/Prisma/Tailscale/Oban. |
| Absolute "award" / 0–100 score | Invites grade inflation and non-comparable run-to-run drift on a deterministic count gate. | Comparative only: judge against the matched good/bad exemplar + tier anchors; emit defect-only rows, no score. |
| Adding a 13th "design" dimension | Would fork the `DIMENSIONS` map across proposer/verifier/gate/digest. | Sharpen existing dims 2/3/5/8 (+1/6 support) only; cross-cutting concerns use overlay tags. |
| Fintech-glossy chrome (gradients, glossy pill CTAs, rounded-everything, heavy shadows, off-brand serif) | Off-register; contradicts "quiet, well-made developer tooling". | d8 below-bar; `bad/off-register.png` is the negative anchor. |
| Taste-only "make it nicer/cleaner/sleeker" findings | Non-actionable, non-checkable, prose-flakiness vector. | Taste denylist at the gate; `defect` must name a dimension + concrete object. |
| Trusting a model-supplied `claim_key`/`finding_id`/`region_tag` | Reintroduces prose flakiness → breaks DEDUP-02. | Harness re-derives all identity from closed enums (`region-tags.js`); model output is advisory only. |
