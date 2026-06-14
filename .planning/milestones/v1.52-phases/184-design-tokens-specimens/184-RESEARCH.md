# Phase 184: Design Tokens & Specimens - Research

**Researched:** 2026-06-13
**Domain:** DTCG design-token authoring + a Node `.mjs` CSS-AST parity check + generated SVG specimens (buildless brand layer)
**Confidence:** HIGH (toolchain APIs verified empirically in-session; DTCG spec cited from official 2025.10 report; values cross-checked against in-repo theme.css and contrast-table.txt)

## Summary

Phase 184 is almost entirely a "HOW, not WHETHER" phase: CONTEXT.md D-01..D-17 lock every design decision, BRAND-AUDIT §7 binds the token vocabulary, and theme.css is the read-only parity target. The remaining knowledge gaps are purely mechanical and this research closes all of them with verified API shapes. The four deliverable surfaces are: (1) a DTCG-2025.10 `tokens.json` SSOT; (2) a ~≤60-line `.mjs` generator emitting `tokens.css`; (3) a `.mjs` parity check that live-derives expected values from `theme.css` and exits non-zero on undocumented drift; (4) three deterministic specimen SVGs.

The single most important verified finding: **culori 4.0.2 does NOT parse `color-mix()` — `parse("color-mix(...)")` returns `undefined`.** The parity check must pre-resolve `color-mix()` itself by walking the `postcss-value-parser` AST and evaluating the mix with culori's `interpolate(...)` in the named color space. I verified the entire pipeline end-to-end in a scratch install (postcss 8.5.15 + postcss-value-parser 4.2.0 + culori 4.0.2 on Node v22.14.0) against the exact forms in theme.css (`var()` indirection, `color-mix(in srgb …)`, `color-mix(in oklch …)`, hex-case, `rgb()/rgba()`). All forms normalize cleanly to a canonical `#rrggbb` lowercase string for exact-match comparison — no ΔE epsilon is needed for the values currently in theme.css.

Second key finding: the DTCG **2025.10 stable** color `$value` is a **structured object** (`{colorSpace, components, hex}`), and dimension `$value` is **`{value, unit}`** with `unit` restricted to `px|rem`. This is a meaningful change from older drafts where `$value` was a bare hex string. The generator must read `$value.hex` (or serialize from `components`) for colors and `${value}${unit-as-css}` for dimensions.

**Primary recommendation:** One shared harness at `brandbook/tokens/harness/` with deps `postcss postcss-value-parser culori` (+ optionally `geist opentype.js` reused from the logo harness for the type specimen). Author `tokens.json` (DTCG 2025.10, color `$value` objects with `hex`, `$extensions["org.accrue.ax"]` carrying `axMap` + optional `divergesFrom`/`reason`). Generate `tokens.css` deterministically (sorted keys, trailing newline). Parity check: postcss-walk theme.css → for each ax-mapped brand token resolve both sides to lowercase `#rrggbb` (resolving `var()` and evaluating `color-mix()` via culori `interpolate`) in light + dark → exit non-zero on undocumented mismatch. Gate generated outputs with `git diff --exit-code` like the logo suite.

## Project Constraints (from CLAUDE.md)

- **GSD workflow enforcement:** All file edits must flow through a GSD command (this is planning output, not edits).
- **Monorepo:** `accrue/` + `accrue_admin/` siblings; shared `.github/workflows/`. Phase 184 touches neither mix project — it adds `brandbook/tokens/` + `brandbook/examples/` only.
- **Phase-184 tooling is Node `.mjs`, NOT mix tasks** (explicit in the objective and D-05). Do not introduce an Elixir code path.
- **No admin code changes** (`theme.css` READ-ONLY) — milestone-level v1.52 exclusion + D-01..D-17.
- **License:** MIT; Geist outlines already carry OFL provenance in `brandbook/LICENSE-FONTS.txt` (only relevant if the type specimen reuses opentype.js glyph paths).

## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-17 — DO NOT re-litigate)

- **D-01:** `tokens.json` is SSOT; `tokens.css` is GENERATED. Drift eliminated by construction.
- **D-02:** `tokens.json` is W3C DTCG-formatted, **v2025.10 stable**. Use `$value`/`$type`/`$description` + nested groups.
- **D-03:** **No Style Dictionary.** Small (~≤60-line) `.mjs` generator walks the DTCG tree and emits `:root{…}`, reusing the 181–183 harness pattern.
- **D-04:** brand→admin `--ax-*` mapping encoded in DTCG `$extensions` per token.
- **D-05:** Runtime = Node `.mjs`, own harness dir, committed `package.json`+lockfile, gitignored `node_modules`.
- **D-06:** Parsing = real parser (`postcss` + `postcss-value-parser`) + `culori` for color normalization. NOT regex.
- **D-07:** Check compares RESOLVED concrete values keyed by per-token ax-map, in BOTH light and dark. Resolves `var()` indirection in light; value-to-value in dark. Null-ax-map tokens skipped.
- **D-08:** Exit-code contract: `0` when all ax-mapped tokens match (or documented divergence); **non-zero on any undocumented drift**. Live derivation from theme.css — no golden/snapshot file. Separate `git diff --exit-code` gate covers generated `tokens.css` determinism.
- **D-09:** Brandbook declares as REAL tokens: 7 raw `--accrue-*` + palette-bearing semantic color roles (surface base/elevated/sunken; content primary/muted/subtle; interactive accent/focus-ring; feedback success/warning/danger/info). These carry explicit `axMap` and are value-checked.
- **D-09b:** Brand-only tokens (`--accrue-fog`, `--accrue-cobalt` raw, plus new brandbook **code-block** and **callout** tokens) get `axMap: null` / brand-only marking; parity skips them. `code-block`/`callout` *values* are new brand-layer definitions this phase authors.
- **D-10:** Divergence declaration lives in `tokens.json` `$extensions` (`{ divergesFrom: "--ax-…", reason: "…" }`). Check tolerates a mismatch only when such an entry names the diverging `--ax-*` and a reason.
- **D-11:** Non-color scales (type/spacing/radius/state/motion) documented by REFERENCE, NOT re-declared as `--accrue-*`. MAY appear in `tokens.json` as `$type: dimension` reference entries aliasing the ax names, but `axMap: null`-style (NOT value-enforced).
- **D-12:** (implied in D-07) dark-mode duplicated tokens are checkable without false positives because each side is resolved to a concrete color.
- **D-13:** Generated SVG specimens (Node `.mjs` reading `tokens.json`), `git diff --exit-code`-gated.
- **D-14:** Three files: `examples/palette.svg`, `examples/typography.svg`, `examples/spacing.svg`.
- **D-15:** Per-specimen content checklist (locked) — see Architecture Patterns below.
- **D-16:** Consolidate tooling under `brandbook/tokens/harness/` with committed `package.json`+lockfile (`postcss`, `postcss-value-parser`, `culori`), gitignored `node_modules`. Prefer ONE shared harness/`node_modules` install — do NOT create three.
- **D-17:** Determinism: commit `.mjs`+lockfile, gitignore `node_modules`, reinstall in CI, `git diff --exit-code` over generated outputs (`tokens.css`, three `examples/*.svg`). Parity check is a SEPARATE CI gate.

### Claude's Discretion (research recommends below)

- DTCG group nesting / token naming + CSS var-name derivation rule → **Recommendation in Architecture Patterns.**
- Whether type specimen reuses logo harness opentype.js/Geist glyph metrics → **Recommendation: simple text labels with the Geist `font-family`, NOT glyph outlines** (rationale below).
- `$extensions` namespace (`org.accrue.ax` vs `accrue.parity`) → **Recommendation: single namespace `org.accrue.ax`.**
- Color-normalization tolerance (exact vs ΔE epsilon) → **Recommendation: exact lowercase `#rrggbb` match** (verified sufficient for current theme.css; no `color-mix`/`oklch` case forces epsilon for ax-mapped raw/role tokens — the only color-mix tokens in theme.css are NOT in the D-09 brand-mapped set).
- Prose mapping-table format for reference-only scales (D-11) → **Recommendation in Architecture Patterns.**

### Deferred Ideas (OUT OF SCOPE)

- Style Dictionary / multi-platform export (SCSS/iOS/Android) — deferred (D-03).
- Minting `--accrue-*` for spacing/radius/type — deferred (D-11), reference-only.
- `examples/readme-header.svg` — Phase 185/186, not 184.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOK-01 | `tokens.json` + `tokens.css` define raw palette, semantic color roles, typography, spacing, radius, focus-ring, state tokens per audit spec | DTCG 2025.10 color+dimension `$value` shapes (Standard Stack, Code Examples); 7 raw hexes + role list from BRAND-AUDIT §7; type/space/radius are reference-only DTCG dimension entries (D-11); focus-ring + state are brand-layer definitions |
| TOK-02 | Automated consistency check verifies brandbook token values vs admin `--ax-*` SSOT, mapping documented, zero admin changes | Verified postcss+value-parser+culori pipeline (Code Examples); resolve `var()` + evaluate `color-mix()` via `interpolate`; exit-code contract (D-08); divergence via `$extensions` (D-10) |
| TOK-03 | Palette + typography specimen artifacts in `examples/` | Deterministic SVG generation pattern mirroring logo harness; per-specimen checklist (D-15); AA annotations sourced from contrast-table.txt |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token authoring (truth) | `tokens.json` (DTCG, hand-authored) | — | D-01: JSON is SSOT; one obvious answer to "which file is truth?" |
| CSS variable export | `tokens.css` (generated `.mjs`) | — | D-01/D-03: generated, never hand-edited; consumers read raw CSS (buildless) |
| Brand↔admin parity proof | parity-check `.mjs` (CI) | `theme.css` (read-only input) | D-05/D-07/D-08: live derivation; theme.css is input not output |
| Visual documentation | specimen `.mjs` → `examples/*.svg` | `tokens.json` (input) | D-13/D-14: generated from the same SSOT |
| Determinism enforcement | `git diff --exit-code` (CI) + parity check (CI) | committed lockfile | D-17: two distinct gates — reproducibility vs correctness |
| Glyph metrics (type specimen) | CSS `font-family` text labels (recommended) | logo harness opentype.js (available, not recommended) | Discretion: text labels keep specimens tiny + dependency-light |

## Standard Stack

### Core (parity check + generator)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `postcss` | `^8.5.15` | CSS → AST; walk rules + custom-property declarations | The CSS-AST standard; `postcss.parse(css)` + `walkRules`/`walkDecls` is the canonical safe way to read `--token: value;` without regex. [VERIFIED: npm registry — 8.5.15, modified 2026-05-19; pipeline run in-session] |
| `postcss-value-parser` | `^4.2.0` | Parse a declaration's value into function/word nodes | Resolves `var(--x)` references and exposes `color-mix(...)` argument structure as walkable nodes. [VERIFIED: npm registry — 4.2.0, modified 2026-06-04; verified in-session] |
| `culori` | `^4.0.2` | Normalize/convert/compare colors; evaluate color-mix via `interpolate` | CSS Color Level 4 coverage; `formatHex` canonicalizes hex-case/rgb/rgba; `interpolate(...,space)` evaluates `color-mix` by hand. [VERIFIED: npm registry — 4.0.2, modified 2026-04-03; verified in-session] |

### Supporting (type specimen only — OPTIONAL, reuse from logo harness)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `geist` | `^1.7.2` | Geist + Geist Mono TTFs | Only if type specimen embeds real glyph outlines (NOT recommended — see Discretion). Already vendored in logo harness. |
| `opentype.js` | `^2.0.0` | Per-glyph path extraction | Same — only for embedded outlines. `loadGeistMonoFont()`/`extractGlyphs()` already exist in `brandbook/logo/harness/geist-spine-mono.mjs`. |
| `svgo` | `^4.0.1` | Optimize specimen SVGs deterministically | Reuse `brandbook/logo/harness/svgo.config.mjs` (multipass, preserves `viewBox`/`<title>`/`<desc>`). Recommended for `git diff` stability of specimens. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `culori` color-mix-via-interpolate | `@csstools/css-color-parser` | Parses `color-mix()` natively (recursive color functions). Adds a dep + the `@csstools` parser stack. **Not needed:** the only color-mix tokens in theme.css (`--ax-danger-surface`, `--ax-accent-*`, `--ax-focus-ring`) are NOT in the D-09 brand-mapped set, so the parity check never has to compare a color-mix value. Keep culori-only; if a future ax-mapped token uses color-mix, evaluate via `interpolate` (verified working) before reaching for `@csstools`. |
| Style Dictionary | small `.mjs` generator | D-03: SD is ~4.4 MB / 13 deps — disproportionate to ~21 tokens and hostile to the buildless ≤2 MB milestone. |
| postcss text walk | regex on CSS | D-06: regex cannot reliably resolve `var()`/`color-mix()`/hex-case. Rejected. |

**Installation (shared harness):**
```bash
# brandbook/tokens/harness/
npm install postcss postcss-value-parser culori
# optional (only if type specimen uses glyph outlines — generally NOT recommended):
# npm install geist opentype.js svgo
```

**Version verification (run in-session 2026-06-13, Node v22.14.0):**
- `postcss` → 8.5.15 (modified 2026-05-19), repo github.com/postcss/postcss
- `postcss-value-parser` → 4.2.0 (modified 2026-06-04), repo github.com/TrySound/postcss-value-parser
- `culori` → 4.0.2 (modified 2026-04-03), repo github.com/Evercoder/culori

## Package Legitimacy Audit

slopcheck was not installable in this session (`pip install slopcheck` produced no usable binary; the `slopcheck` on PATH is an unrelated homebrew shim that does not accept the `install` verb). Per the graceful-degradation rule, the three core packages are tagged `[ASSUMED]` and the **planner must gate the harness `npm install` behind a `checkpoint:human-verify` task** — even though all three are long-established, high-trust packages with real source repos verified via `npm view`.

| Package | Registry | Age | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-------------|-----------|-------------|
| `postcss` | npm | ~12 yrs, current 8.5.15 (2026-05) | github.com/postcss/postcss | unavailable | `[ASSUMED]` — planner adds checkpoint (well-known: PostCSS core, used by every modern CSS toolchain) |
| `postcss-value-parser` | npm | mature, current 4.2.0 (2026-06) | github.com/TrySound/postcss-value-parser | unavailable | `[ASSUMED]` — planner adds checkpoint (the standard value parser; bundled by autoprefixer etc.) |
| `culori` | npm | mature, current 4.0.2 (2026-04) | github.com/Evercoder/culori | unavailable | `[ASSUMED]` — planner adds checkpoint (Evercoder/culori, the CSS Color L4 reference JS lib) |

**Packages removed due to [SLOP]:** none.
**Packages flagged [SUS]:** none.
**Note:** none of the three declare a `postinstall` script of concern; `culori` is pure-JS (no native build), `postcss`/`postcss-value-parser` are pure-JS. (The logo harness already installs native-build deps like `@resvg/resvg-js` and `playwright`; the tokens harness deliberately avoids those.)

## Architecture Patterns

### System Architecture Diagram

```
  tokens.json  (DTCG 2025.10, HAND-AUTHORED SSOT)
   │  color $value = {colorSpace, components, hex}
   │  $extensions["org.accrue.ax"] = { axMap | null, divergesFrom?, reason? }
   │
   ├──────────────► generate-tokens-css.mjs ──────► brandbook/tokens/tokens.css
   │                  walk tree, derive --names,        (:root{…} light + dark block)
   │                  emit sorted :root decls            │
   │                                                     ▼
   │                                              git diff --exit-code  (DETERMINISM gate)
   │
   ├──────────────► generate-specimens (3 .mjs) ─► examples/palette.svg
   │                  read tokens.json,                examples/typography.svg
   │                  emit deterministic <svg>          examples/spacing.svg
   │                  (AA status ← contrast-table)        │
   │                                                      ▼
   │                                               git diff --exit-code  (DETERMINISM gate)
   │
   └──────────────► parity-check.mjs  ◄──── accrue_admin/assets/css/theme.css (READ-ONLY)
                       for each ax-mapped brand token:        (postcss.parse → walkRules/walkDecls)
                         resolve admin side (light: var()→raw; dark: standalone hex)
                         resolve brand side (tokens.json hex)
                         normalize both → lowercase #rrggbb (culori formatHex;
                                          color-mix via interpolate if ever needed)
                         compare; tolerate mismatch ONLY if $extensions divergesFrom+reason
                       exit 0 if all match/documented, NON-ZERO on undocumented drift  (PARITY gate)
```

### Component Responsibilities
| File | Responsibility |
|------|----------------|
| `brandbook/tokens/tokens.json` | DTCG SSOT — values + ax-map + divergence declarations |
| `brandbook/tokens/tokens.css` | GENERATED CSS custom properties (light `:root` + dark block) |
| `brandbook/tokens/harness/generate-tokens-css.mjs` | DTCG tree → `tokens.css` (deterministic) |
| `brandbook/tokens/harness/parity-check.mjs` | live theme.css derivation → exit-code drift gate |
| `brandbook/tokens/harness/lib.mjs` (recommended) | shared helpers: flatten DTCG tree, name derivation, `resolveColor()` (var+color-mix+normalize) — imported by generator, parity check, AND specimens |
| `brandbook/examples/harness/*.mjs` OR same harness | three specimen generators reading tokens.json |
| `brandbook/tokens/harness/package.json` + `package-lock.json` | committed; ONE shared `node_modules` (gitignored) |

### Pattern 1: DTCG group nesting + CSS var-name derivation (Discretion recommendation)
**What:** Nest tokens by semantic group; derive CSS var names from group+token path with a fixed rule.
**When to use:** Authoring `tokens.json` and the generator's name function.
**Recommendation:**
- Raw palette under `color.brand.*` → emit `--accrue-<token>` (e.g. `color.brand.moss` → `--accrue-moss`). Carry the raw name explicitly so the rule is "raw tokens map to `--accrue-<leaf>`".
- Semantic roles under `color.surface.*`, `color.content.*`, `color.interactive.*`, `color.feedback.*` → these are the brandbook's role layer; emit `--accrue-<group>-<leaf>` (e.g. `--accrue-surface-base`). Their `axMap` names the corresponding `--ax-*` for the parity check.
- Derivation rule (deterministic): join the path segments BELOW the top `color` group with `-`, prefix `--accrue-`, lowercase. Store the canonical CSS name in `$extensions["org.accrue.ax"].cssVar` if any path would not derive cleanly (explicit beats clever).
**Example:** see Code Examples below.

### Pattern 2: `$extensions` namespace (single, consistent)
**What:** One reverse-domain namespace per token carrying parity metadata.
**Recommendation:** `org.accrue.ax` (DTCG recommends reverse-domain notation; CITED below). Shape:
```jsonc
"$extensions": {
  "org.accrue.ax": {
    "axMap": "--ax-success",        // null for brand-only (D-09b) → parity skips
    "divergesFrom": "--ax-danger",  // OPTIONAL (D-10) — only when intentionally divergent
    "reason": "brand danger is warmer than admin danger by design"
  }
}
```
The parity check keys off `axMap`. `axMap: null` ⇒ skip. Presence of `divergesFrom`+`reason` ⇒ tolerate the named mismatch.

### Pattern 3: Reference-only scales table (D-11) (Discretion recommendation)
**What:** Document type/spacing/radius/state/motion by pointing at the existing `--ax-*` tokens; do NOT mint `--accrue-*` for them.
**Recommendation:** Two complementary artifacts:
1. In `tokens.json`, OPTIONAL DTCG `$type: dimension` reference entries that alias the ax names, each with `axMap: null` (documentation/interop only; NOT value-enforced). Use the `{value, unit}` object form (e.g. `{ "value": 0.5, "unit": "rem" }`).
2. A prose Markdown mapping table (in `brandbook/tokens/README.md` or a `REFERENCE.md`) with columns: `Brand category | Admin token(s) | Value | Notes`. Example row: `Spacing md | --ax-space-md | 1rem (16px) | reference-only; admin SSOT`. This satisfies BRAND-AUDIT §7's "category present" requirement with zero drift liability.

### Anti-Patterns to Avoid
- **Bare hex string as DTCG `$value`** — the 2025.10 stable color value is an object (`{colorSpace, components, hex}`). A bare `"#5E9E84"` is the OLD draft shape; non-conformant. (Tools may still accept it, but D-02 says ship conformant.)
- **Minting `--accrue-space-*`/`--accrue-radius-*`** — forbidden by D-11 (pure drift liability vs read-only admin SSOT).
- **Snapshot/golden file for parity** — D-08 forbids it; the check live-derives from theme.css so it can't rot.
- **Regex CSS parsing** — D-06; use postcss.
- **`color-mix()` passed straight to culori `parse`/`formatHex`** — returns `undefined` (verified). Must pre-resolve via `interpolate`.
- **Non-deterministic JSON key iteration in the generator** — sort keys; otherwise `git diff --exit-code` flakes.

### Recommended harness layout (one shared install — D-16)
```
brandbook/
├── tokens/
│   ├── tokens.json                 # DTCG SSOT (hand-authored)
│   ├── tokens.css                  # GENERATED
│   ├── README.md                   # reference-only scale table (D-11)
│   └── harness/
│       ├── package.json            # postcss, postcss-value-parser, culori (+opt svgo/geist/opentype.js)
│       ├── package-lock.json       # committed
│       ├── .gitignore              # node_modules/  (or rely on repo-root ignore)
│       ├── lib.mjs                 # shared: flatten tree, name derivation, resolveColor()
│       ├── generate-tokens-css.mjs # tokens.json → tokens.css
│       ├── parity-check.mjs        # theme.css live derivation → exit code
│       └── generate-specimens.mjs  # OR three files; reads tokens.json → examples/*.svg
└── examples/
    ├── palette.svg                 # GENERATED
    ├── typography.svg              # GENERATED
    └── spacing.svg                 # GENERATED
```
Note: repo root `.gitignore` already contains `node_modules/` (verified), so a new harness `node_modules` is ignored automatically — but mirror the logo harness and keep it explicit if a local `.gitignore` exists there.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parse `--token: value;` out of CSS | regex line scanner | `postcss.parse` + `walkRules`/`walkDecls(/^--/)` | Handles comments, nested at-rules (`@media`, `[data-theme]`), whitespace, multi-line values (theme.css has all of these). |
| Resolve `var(--x)` / read `color-mix()` args | string splitting | `postcss-value-parser` walk | Correctly tokenizes function nodes, dividers, percentages. Verified on the three theme.css forms. |
| Normalize `#FFF` vs `#ffffff` vs `rgb()` vs `rgba()` | manual hex padding/case logic | `culori` `formatHex(parse(x))` | One canonical lowercase `#rrggbb`; handles 3-digit expand, rgb→hex, alpha drop. Verified. |
| Evaluate `color-mix(in srgb/oklch, …)` | manual channel math | `culori` `interpolate([b,a], space)(t)` | Correct per-space interpolation incl. oklch. Verified `interpolate(["#ffffff","#5D79F6"],"rgb")(0.08)` = `#f2f4fe`. |
| DTCG color object → CSS value | bespoke serializer | read `$value.hex` (present in your authored tokens) | The 2025.10 color object carries `hex`; emit it directly. Fall back to `formatHex({mode, ...components})` only if `hex` omitted. |

**Key insight:** Every footgun in this phase is a color/CSS-string normalization edge case, and all of them are solved libraries. The ONLY hand-rolled logic should be: (a) the ~≤60-line DTCG-tree-walk + name derivation, (b) the exit-code/divergence policy, (c) deterministic SVG string assembly. Color comparison itself is entirely culori.

## Runtime State Inventory

This is a greenfield additive phase (new files under `brandbook/`), NOT a rename/refactor. No runtime state to migrate.
- **Stored data:** None — no datastores involved.
- **Live service config:** None.
- **OS-registered state:** None.
- **Secrets/env vars:** None.
- **Build artifacts:** New `brandbook/tokens/harness/node_modules/` is gitignored (verified repo-root `.gitignore` has `node_modules/`); reinstalled in CI from committed lockfile. No stale-artifact risk.
**Verified:** the only generated outputs are `tokens.css` + three `examples/*.svg`, all freshly authored this phase.

## Common Pitfalls

### Pitfall 1: culori silently returns `undefined` for `color-mix()`
**What goes wrong:** `formatHex("color-mix(in srgb, …)")` → `undefined`; a naive `===` comparison then "passes" (both sides undefined) or crashes downstream.
**Why:** culori 4.0.2 does not implement `color-mix()` parsing (verified in-session).
**How to avoid:** In `resolveColor()`, detect a `color-mix` function node via postcss-value-parser FIRST, evaluate it with `interpolate([secondColor, firstColor], space)(percentAsT)`, only THEN `formatHex`. Assert non-undefined and throw a clear error if a color fails to resolve (never compare `undefined`).
**Warning signs:** parity check passing when you expect drift; `undefined` in debug output.

### Pitfall 2: color-mix percentage → interpolation `t` direction
**What goes wrong:** `color-mix(in srgb, A p%, B)` means `p%` of **A** and `(100−p)%` of **B**. `interpolate([B, A])(t)` walks B→A, so `t = p/100`. Getting the order backwards inverts the mix.
**Why:** interpolate's `t=0` is the first array element. Put the *second* color-mix arg first so `t=percentOfFirst`.
**How to avoid:** `interpolate([second, first], space)(firstPercent/100)`. Verified: `color-mix(in srgb, #5D79F6 8%, #ffffff)` ≈ `interpolate(["#ffffff","#5D79F6"],"rgb")(0.08)` = `#f2f4fe`.
**Warning signs:** mixes that look ~white instead of ~tinted (or vice-versa).
**Mitigation note:** This pitfall only bites if a *brand-mapped* token ever uses color-mix. Today none do (the color-mix tokens are admin-internal), so the parity check's hot path is pure hex/var resolution. Document the helper anyway for the specimen generators / future-proofing.

### Pitfall 3: theme.css selector is `html.accrue-admin`, not `:root`
**What goes wrong:** A parity check that only reads `:root` rules finds nothing in theme.css.
**Why:** Admin scopes tokens to `html.accrue-admin` (and `html.accrue-admin[data-theme="dark"]`, plus `@media (prefers-color-scheme: dark) html.accrue-admin[data-theme="system"]`). The raw `--accrue-*` tokens are NOT defined in theme.css at all — only referenced via `var(--accrue-*)`.
**How to avoid:** Walk ALL rules; build a map of `prop → value` per scope. For "light" use the `html.accrue-admin` base rule; for "dark" use `html.accrue-admin[data-theme="dark"]` (and/or the system media block — pick one consistently; the dark `[data-theme="dark"]` block and the system media block carry identical values, so either works). Resolve `var(--accrue-paper)` etc. against the brandbook's own `tokens.json` raw values (theme.css does NOT define them — that is GAP-C2, which tokens.css completes).
**Warning signs:** "no tokens found" or every var() unresolved.

### Pitfall 4: DTCG 2025.10 `$value` object shape (not bare hex)
**What goes wrong:** Authoring `"$value": "#5E9E84"` (old draft) → non-conformant; generator that expects an object crashes, or interop tools reject it.
**Why:** Stable 2025.10 color `$value` = `{colorSpace, components, hex?}`; dimension `$value` = `{value, unit}`.
**How to avoid:** Author the object form. For colors include `hex` (your authoritative source) AND `components` (srgb 0–1 floats) for conformance. The generator reads `$value.hex`.
**Warning signs:** generator reads `undefined` for `.hex`/`.value`.

### Pitfall 5: non-deterministic generation breaks `git diff --exit-code`
**What goes wrong:** CI fails the determinism gate on a re-run with no source change.
**Why:** unsorted object-key iteration, platform line endings, missing trailing newline, floating-point formatting drift.
**How to avoid:** Sort token keys with a stable comparator before emitting; write `\n` line endings; end the file with exactly one trailing newline; round any computed numbers to fixed decimals; if using svgo on specimens, use the committed `svgo.config.mjs` (multipass) exactly as the logo suite does.
**Warning signs:** `git diff` shows reordered lines after regeneration.

### Pitfall 6: AA annotations inventing contrast claims
**What goes wrong:** palette.svg labels a swatch "AA" that contrast-table.txt doesn't support.
**Why:** computing contrast independently can disagree with the cited table (rounding/threshold differences).
**How to avoid:** Source AA/contrast status from `artifacts/contrast-table.txt` rows (or recompute and assert equality with the table). Specifically annotate **Moss/Cobalt/Amber FAIL AA-body on light surfaces** (Paper vs Moss 3.03 AA-large; Paper vs Cobalt 3.66 AA-large; Paper vs Amber 2.66 FAIL) per D-15 + BRAND-AUDIT §7.
**Warning signs:** annotation text that has no matching contrast-table row.

## Code Examples

### tokens.json skeleton (DTCG 2025.10 — adopt this shape)
```jsonc
// Source: DTCG Format Module 2025.10 — designtokens.org/tr/2025.10/format/ [CITED]
{
  "$schema": "https://tr.designtokens.org/format/tokens.schema.json",
  "color": {
    "$type": "color",
    "brand": {
      // 7 raw --accrue-* tokens (D-09). hex is the authoritative value.
      "ink":    { "$value": { "colorSpace": "srgb", "components": [0.067, 0.078, 0.094], "hex": "#111418" },
                  "$description": "Ink — primary text, dark surface baseline",
                  "$extensions": { "org.accrue.ax": { "axMap": "--ax-primary" } } },
      "slate":  { "$value": { "colorSpace": "srgb", "components": [0.141, 0.188, 0.231], "hex": "#24303b" },
                  "$extensions": { "org.accrue.ax": { "axMap": "--ax-subtle" } } },
      "fog":    { "$value": { "colorSpace": "srgb", "components": [0.914, 0.933, 0.949], "hex": "#e9eef2" },
                  "$extensions": { "org.accrue.ax": { "axMap": null } } },   // brand-only (D-09b)
      "paper":  { "$value": { "colorSpace": "srgb", "components": [0.980, 0.984, 0.988], "hex": "#fafbfc" },
                  "$extensions": { "org.accrue.ax": { "axMap": "--ax-base" } } },
      "moss":   { "$value": { "colorSpace": "srgb", "components": [0.369, 0.620, 0.518], "hex": "#5e9e84" },
                  "$extensions": { "org.accrue.ax": { "axMap": "--ax-success" } } },
      "cobalt": { "$value": { "colorSpace": "srgb", "components": [0.365, 0.475, 0.965], "hex": "#5d79f6" },
                  "$extensions": { "org.accrue.ax": { "axMap": null } } },   // brand-only (D-09b)
      "amber":  { "$value": { "colorSpace": "srgb", "components": [0.784, 0.573, 0.231], "hex": "#c8923b" },
                  "$extensions": { "org.accrue.ax": { "axMap": "--ax-warning" } } }
    },
    // Palette-bearing semantic roles (D-09) — value-checked against --ax-*.
    "surface": {
      "$type": "color",
      "base":     { "$value": "{color.brand.paper}", "$extensions": { "org.accrue.ax": { "axMap": "--ax-base" } } },
      "elevated": { "$value": { "colorSpace": "srgb", "components": [1,1,1], "hex": "#ffffff" },
                    "$extensions": { "org.accrue.ax": { "axMap": "--ax-elevated" } } },
      "sunken":   { "$value": { "colorSpace": "srgb", "components": [0.945,0.961,0.973], "hex": "#f1f5f8" },
                    "$extensions": { "org.accrue.ax": { "axMap": "--ax-sunken" } } }
    },
    "content":  { "$type": "color", "primary": { /* {color.brand.ink}, ax --ax-primary */ },
                  "muted": { /* #5d6a73, ax --ax-muted */ }, "subtle": { /* {color.brand.slate}, ax --ax-subtle */ } },
    "interactive": { "$type": "color", "accent": { /* cobalt, ax --ax-accent (brand-only if no ax value) */ },
                     "focus-ring": { /* see note — admin --ax-focus-ring is a color-mix; document as divergence or brand-only */ } },
    "feedback": { "$type": "color",
                  "success": { /* {color.brand.moss}, ax --ax-success */ },
                  "warning": { /* {color.brand.amber}, ax --ax-warning */ },
                  "danger":  { /* #d64b4b, ax --ax-danger */ },
                  "info":    { /* #3878a6, ax --ax-info */ } },
    // Brand-only NEW tokens this phase authors (D-09b) — no upstream:
    "code-block": { "$type": "color", /* author value, axMap:null */ },
    "callout":    { "$type": "color", /* author value, axMap:null */ }
  },
  // Reference-only dimension entries (D-11) — axMap:null, NOT value-enforced. OPTIONAL.
  "dimension": {
    "space": {
      "$type": "dimension",
      "md": { "$value": { "value": 1, "unit": "rem" },
              "$extensions": { "org.accrue.ax": { "axMap": null, "referencesAx": "--ax-space-md" } } }
      // … remaining rungs as reference-only
    }
  }
}
```
> NOTE on `interactive.focus-ring`: the admin `--ax-focus-ring` is `color-mix(in oklch, var(--ax-accent) 70%, white)` — NOT a flat palette color. Per D-11/D-09b treat the brand focus-ring spec as a brand-only/reference token (BRAND-AUDIT §7 item 6 specifies "2px solid Cobalt focus ring w/ 2px offset" — a *spec*, not a hex). Do NOT value-check it against the admin color-mix. Document it; set `axMap: null` (or declare a `divergesFrom` with reason if you want it linked).

### generate-tokens-css.mjs — deterministic CSS emit (~≤60 lines)
```js
// Source: pattern synthesized for DTCG 2025.10; verified emit determinism approach
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const tokens = JSON.parse(fs.readFileSync(path.join(__dirname, "../tokens.json"), "utf8"));

// Flatten DTCG tree → [{ cssVar, hex }] for color tokens. Resolve {alias} refs.
function flatten(node, pathSegs, out, root) {
  for (const [key, val] of Object.entries(node)) {
    if (key.startsWith("$")) continue;
    const segs = [...pathSegs, key];
    if (val && typeof val === "object" && "$value" in val) {
      const hex = resolveHex(val.$value, root);
      if (hex) out.push({ cssVar: deriveName(segs), hex });
    } else if (val && typeof val === "object") {
      flatten(val, segs, out, root);
    }
  }
}
function resolveHex(v, root) {
  if (typeof v === "string" && v.startsWith("{")) {            // alias {color.brand.paper}
    const ref = v.slice(1, -1).split(".").reduce((o, k) => o?.[k], root);
    return resolveHex(ref.$value, root);
  }
  return v?.hex ?? null;                                       // color object carries hex
}
// raw palette (color.brand.*) → --accrue-<leaf>; roles → --accrue-<group>-<leaf>
function deriveName(segs) {
  const [top, ...rest] = segs;                                 // drop leading "color"/"dimension"
  if (rest[0] === "brand") return `--accrue-${rest.slice(1).join("-")}`;
  return `--accrue-${rest.join("-")}`;
}
const rows = [];
flatten(tokens, [], rows, tokens);
rows.sort((a, b) => a.cssVar.localeCompare(b.cssVar));         // DETERMINISM
const body = rows.map(r => `  ${r.cssVar}: ${r.hex};`).join("\n");
const css = `/* GENERATED from tokens.json — do not edit. Run: npm run generate */\n:root {\n${body}\n}\n`;
fs.writeFileSync(path.join(__dirname, "../tokens.css"), css);  // trailing \n included
```
> Dark-mode block: emit a second `:root[data-theme="dark"] { … }` (or `@media`) section from dark `$value` overrides if you model dark in tokens.json (BRAND-AUDIT §7 says dark counterparts MUST be defined). Sort the same way.

### parity-check.mjs — live theme.css derivation + exit code (VERIFIED pipeline)
```js
// Source: postcss + postcss-value-parser + culori — all calls verified in-session 2026-06-13
import fs from "fs"; import path from "path"; import { fileURLToPath } from "url";
import postcss from "postcss";
import valueParser from "postcss-value-parser";
import { parse as parseColor, formatHex, interpolate } from "culori";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const THEME = path.resolve(__dirname, "../../../accrue_admin/assets/css/theme.css");
const tokens = JSON.parse(fs.readFileSync(path.join(__dirname, "../tokens.json"), "utf8"));

// 1. Build per-scope decl maps from theme.css.
function buildScopes(css) {
  const root = postcss.parse(css);
  const scopes = {};                       // selector -> { prop: rawValue }
  root.walkRules(rule => {
    const map = (scopes[rule.selector] ??= {});
    rule.walkDecls(/^--/, d => { map[d.prop] = d.value; });
  });
  return scopes;
}
// 2. Resolve a raw value (var / color-mix / hex / rgb) to canonical #rrggbb.
function resolveColor(raw, vars, brandRaw) {
  const ast = valueParser(raw);
  // bare var(--x): resolve from admin scope first, then brand raw (--accrue-*)
  if (ast.nodes.length === 1 && ast.nodes[0].type === "function" && ast.nodes[0].value === "var") {
    const name = ast.nodes[0].nodes[0].value;
    const next = vars[name] ?? brandRaw[name];
    if (next == null) throw new Error(`unresolved var ${name}`);
    return resolveColor(next, vars, brandRaw);
  }
  // color-mix(in <space>, A p%, B): evaluate via interpolate (culori can't parse it)
  const mix = ast.nodes.find(n => n.type === "function" && n.value === "color-mix");
  if (mix) return resolveColorMix(mix, vars, brandRaw);
  const c = parseColor(raw);
  if (!c) throw new Error(`culori could not parse: ${raw}`);
  return formatHex(c);                     // lowercase #rrggbb
}
function resolveColorMix(node, vars, brandRaw) {
  const args = node.nodes.filter(n => n.type !== "div" && n.type !== "space");
  const space = args[1].value;             // after "in"
  // args[2..] = first color (+ optional %), then second color (+ optional %)
  // (parse positions defensively; theme.css color-mix args are not brand-mapped today)
  // ... extract first/second color strings + firstPercent → interpolate([second, first], space)(firstPercent/100)
  // return formatHex(...)
}
// 3. Compare every ax-mapped brand token, light + dark.
const lightVars = buildScopes(fs.readFileSync(THEME, "utf8"))["html.accrue-admin"];
const darkVars  = buildScopes(fs.readFileSync(THEME, "utf8"))['html.accrue-admin[data-theme="dark"]'];
const brandRaw  = /* { "--accrue-paper": "#fafbfc", ... } from tokens.json raw palette */ {};
let failures = 0;
for (const { axMap, brandHex, divergesFrom, reason, name } of iterAxMappedTokens(tokens)) {
  if (axMap == null) continue;                                 // brand-only (D-09b) → skip
  for (const [label, scope] of [["light", lightVars], ["dark", darkVars]]) {
    const adminRaw = scope?.[axMap];
    if (adminRaw == null) continue;                            // token not present in this scope
    const adminHex = resolveColor(adminRaw, scope, brandRaw);
    if (adminHex !== brandHex.toLowerCase()) {
      if (divergesFrom === axMap && reason) {
        console.log(`OK  (documented divergence) ${name} ${label}: ${reason}`);
      } else {
        console.error(`DRIFT ${name} ${label}: brand ${brandHex} != admin ${axMap} ${adminHex}`);
        failures++;
      }
    }
  }
}
process.exit(failures === 0 ? 0 : 1);                          // D-08 exit contract
```
> The empirical proof these calls work (run in-session):
> `formatHex(parse("#FFF"))` → `"#ffffff"`; `formatHex("rgba(36,48,59,1)")` → `"#24303b"`;
> `parse("color-mix(in srgb, …)")` → `undefined` (hence interpolate);
> `formatHex(interpolate(["#ffffff","#5D79F6"],"rgb")(0.08))` → `"#f2f4fe"`;
> postcss `walkRules`+`walkDecls(/^--/)` yields each `--ax-*` decl; value-parser exposes `var()` ref names and `color-mix` arg nodes (`word:in | word:srgb | function:var | word:8% | function:var`).

### Specimen SVG — deterministic standalone `<svg>` (palette.svg shape)
```js
// Read tokens.json → emit ONE self-contained <svg> with light AND dark surface bands.
// Each swatch: rect(fill=hex) + text(token name) + text(hex) + text(role) + text(AA status).
// AA status sourced from contrast-table.txt rows (Moss/Cobalt/Amber FAIL AA-body on light).
// Use <text font-family="Geist, system-ui"> labels (NOT glyph outlines — see Discretion).
// Deterministic: fixed coordinate math, fixed decimals, sorted token order, trailing \n.
// Optionally run through committed svgo.config.mjs for byte-stable optimization.
const svg =
`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" role="img">` +
`<title>Accrue palette specimen</title><desc>Raw palette and semantic roles on light and dark surfaces with hex, token, role, and AA status.</desc>` +
swatches.map(s =>
  `<g transform="translate(${s.x},${s.y})">` +
  `<rect width="${SW}" height="${SH}" fill="${s.hex}"/>` +
  `<text x="0" y="${SH+14}" font-family="Geist, system-ui" font-size="11" fill="#111418">${s.token}</text>` +
  `<text x="0" y="${SH+28}" font-family="Geist Mono, monospace" font-size="10" fill="#24303b">${s.hex}</text>` +
  `<text x="0" y="${SH+42}" font-family="Geist, system-ui" font-size="10" fill="#5d6a73">${s.role} · ${s.aa}</text>` +
  `</g>`
).join("") + `</svg>\n`;
```

### Type-specimen glyph-metrics decision (Discretion)
**Recommendation: simple `<text font-family="Geist…">` labels, NOT opentype.js outlines.** Specimens are documentation viewed in a browser where Geist is available (or degrades to system-ui acceptably); embedding per-glyph outlines bloats the SVG (kills the kilobyte budget intent), reintroduces the opentype.js coordinate-flip footgun (`flipY:false`), and adds the geist/opentype.js deps to a harness meant to stay lean. The logo suite needs outlines because logos must be font-independent and pixel-exact; specimens do not. Label each step with px + rem + a sample line in Geist sans / Geist Mono. (If a reviewer later demands font-independent type specimens, the logo harness's `loadGeistMonoFont()`/`extractGlyphs()` are reusable — but default to text.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| DTCG `$value` as bare hex string (drafts) | `$value` = `{colorSpace, components, hex}` object; dimension = `{value, unit}` | 2025.10 stable (2025-10-28) | Author objects, not strings — conformance + interop with Figma/Tokens Studio/Style Dictionary. |
| Style Dictionary for any token export | small bespoke `.mjs` for buildless single-platform | D-03 (this project) | ~4.4 MB / 13 deps avoided; swap SD back in later against same JSON if multi-platform ever needed. |
| Snapshot/golden parity tests | live derivation from the SSOT being checked | D-08 (this project) | Can't rot against stale golden; reflects theme.css as-is. |

**Deprecated/outdated:**
- DTCG `$value: "#hex"` bare-string form — superseded by the object form in 2025.10 stable.
- Passing `color-mix()` to culori `parse()` — unsupported (returns undefined); use `interpolate`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `postcss`/`postcss-value-parser`/`culori` are legitimate (slopcheck unavailable this session) | Package Legitimacy Audit | LOW — all three have verified GitHub repos + years of history + are PostCSS/CSS-color ecosystem staples; planner still gates install behind checkpoint per protocol |
| A2 | Exact lowercase `#rrggbb` match (no ΔE epsilon) suffices for all ax-mapped brand tokens | Discretion / parity check | LOW — verified the only color-mix tokens in theme.css are NOT brand-mapped; raw+role tokens are flat hex/var. If a future ax-mapped token uses oklch color-mix, an epsilon MAY be needed for cross-space rounding |
| A3 | `components` srgb floats in the tokens.json skeleton are illustrative (hex is authoritative) | Code Examples | LOW — generator reads `$value.hex`; components are for DTCG conformance/interop only. Author may regenerate components from hex via culori to guarantee agreement |
| A4 | Dark scope to compare against is `html.accrue-admin[data-theme="dark"]` (values identical to the `prefers-color-scheme` system block) | Pitfall 3 / parity check | LOW — verified both dark blocks in theme.css carry identical values; either is valid |
| A5 | `code-block` and `callout` brand token VALUES are not yet defined anywhere (this phase authors them) | D-09b | MEDIUM — confirmed no upstream in theme.css; the actual hex values are a brand-layer authoring decision the planner/author must make (suggest deriving from Fog/Slate/Ink family for code-block, and a tinted neutral for callout). User may want to ratify these two new values |

## Open Questions

1. **`code-block` / `callout` token values (D-09b new brand-layer tokens).**
   - What we know: they have NO upstream `--ax-*` counterpart; this phase must author their values; they are marked `axMap: null` so parity skips them.
   - What's unclear: the exact hex values (not specified in BRAND-AUDIT or BRAND-DNA).
   - Recommendation: author from the existing neutral family (e.g. code-block surface from Fog/Slate, code-block text from Ink) and surface them in the CONTEXT/PR review for a one-line ratification. Low risk, fully reversible.

2. **Does tokens.json model dark-mode color values, or only light?**
   - What we know: BRAND-AUDIT §7 says "Dark-mode counterparts MUST be defined in Phase 184's tokens.css using a `[data-theme="dark"]` selector". theme.css carries standalone dark hexes for roles (e.g. `--ax-base:#0f1318`).
   - What's unclear: whether the brand layer re-declares dark role values (creating a parity surface for dark) or whether dark is admin-only.
   - Recommendation: model dark role values in tokens.json (DTCG 2025.10 theming or a parallel dark group) so the parity check's dark pass (D-07) has a brand side to compare. Raw `--accrue-*` stay single-value; only roles get dark counterparts. Planner should pick the DTCG mechanism (parallel group vs the 2025.10 theming feature) — a parallel `color.dark.*` group is the simplest deterministic option.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | all harness `.mjs` | ✓ | v22.14.0 | — |
| npm | harness install | ✓ | (bundled w/ Node 22) | — |
| `postcss` | parity check | ✗ (not yet installed) | target ^8.5.15 | install in harness |
| `postcss-value-parser` | parity check | ✗ | target ^4.2.0 | install in harness |
| `culori` | parity + specimens | ✗ | target ^4.0.2 | install in harness |
| `git` | determinism gate | ✓ | (repo present) | — |
| `accrue_admin/assets/css/theme.css` | parity target | ✓ | read-only | — |
| Geist TTFs (opt) | type specimen IF outlines | ✓ (in logo harness node_modules) | geist 1.7.2 | text labels (recommended default) |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** the three npm packages are installed by the harness from the committed lockfile (reinstalled in CI); standard and expected.

## Validation Architecture

nyquist_validation is enabled (`.planning/config.json: workflow.nyquist_validation = true`). This project's "test framework" for brandbook tooling is the **`.mjs` smoke-test convention** (logo harness uses `node <file>.mjs --test` smoke gates + `git diff --exit-code` + a dedicated parity exit-code check) — there is no Elixir ExUnit coverage of `brandbook/` (correctly: it's Node tooling, not the library).

### Test "Framework"
| Property | Value |
|----------|-------|
| Framework | Node `.mjs` scripts with `--test` smoke guards + `git diff --exit-code` + parity exit code (mirrors logo harness `package.json` scripts) |
| Config file | `brandbook/tokens/harness/package.json` (scripts: `generate`, `parity`, `specimens`, `test`) — to be created |
| Quick run command | `cd brandbook/tokens/harness && node parity-check.mjs` (exit code is the assertion) |
| Full suite command | `npm run generate && npm run specimens && git diff --exit-code -- brandbook/tokens/tokens.css brandbook/examples/*.svg && node parity-check.mjs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SC#1 / TOK-01 | `tokens.json` + `tokens.css` exist & complete (7 raw + roles + reference scales + focus-ring + state) | structural assert | `node verify-tokens.mjs` (assert all 7 raw + each role group present; tokens.css regenerates byte-identical) + `git diff --exit-code -- brandbook/tokens/tokens.css` | ❌ Wave 0 |
| SC#2 / TOK-02 | parity check exits NON-ZERO on undocumented drift, ZERO when matched/documented | exit-code (positive + negative) | `node parity-check.mjs` (expect 0 on clean repo) **and** a fixture test: inject drift into a copied theme.css → assert non-zero | ❌ Wave 0 |
| SC#3 / TOK-03 | three specimen SVGs render every swatch / type-step / spacing-step | content assert + determinism | `node verify-specimens.mjs` (assert each token name appears in palette.svg; each type step in typography.svg; each space rung in spacing.svg) + `git diff --exit-code -- brandbook/examples/*.svg` | ❌ Wave 0 |

### How the parity check ITSELF is tested (the key SC#2 subtlety)
The live-derivation design (D-08, no golden file) means you cannot test "it detects drift" against the real theme.css (which should always match). Test it with an **injected-drift fixture**:
1. Copy theme.css to a temp file; mutate ONE ax-mapped value (e.g. change `--ax-success: var(--accrue-moss)` to a different hex).
2. Run the parity logic pointed at the fixture; **assert exit non-zero** and the drift is named.
3. Add a documented-divergence fixture: inject the same drift BUT add a matching `$extensions.divergesFrom + reason` to a temp tokens.json; **assert exit zero**.
4. Positive path: real theme.css + real tokens.json → **assert exit zero**.
Implement as a `--test` smoke mode in `parity-check.mjs` or a sibling `parity-check.test.mjs` (mirrors the logo harness `geist-spine-mono.mjs --test` pattern). This is the single most important test in the phase — it proves SC#2 both directions.

### Sampling Rate
- **Per task commit:** `node parity-check.mjs` (fast, exit-code).
- **Per wave merge:** full suite (generate + specimens + `git diff --exit-code` + parity + the `--test` fixture).
- **Phase gate:** all green + the parity `--test` negative case proven before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `brandbook/tokens/harness/package.json` + `package-lock.json` (postcss, postcss-value-parser, culori) — Wave 0 install + commit
- [ ] `brandbook/tokens/harness/lib.mjs` — shared flatten / name-derive / `resolveColor` (var + color-mix + normalize)
- [ ] `parity-check.mjs` with `--test` injected-drift fixture mode — covers SC#2 both directions
- [ ] `verify-tokens.mjs` (or inline asserts) — covers SC#1 completeness
- [ ] `verify-specimens.mjs` (or inline asserts) — covers SC#3 content coverage
- [ ] CI wiring: add `git diff --exit-code` over `brandbook/tokens/tokens.css` + `brandbook/examples/*.svg` and a parity-check step (mirror `accrue_admin_assets.yml` line 30 / `ci.yml` line 396 determinism-gate shape)

## Security Domain

`security_enforcement` is not set to false; however this phase has minimal security surface: it adds Node build-time tooling (no runtime, no network, no user input, no secrets). The only meaningful control:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | minor | Parse CSS/JSON with real parsers (postcss/`JSON.parse`), not eval; reject unresolved colors with a thrown error (no silent undefined). |
| V6 Cryptography | no | — |
| V14 Config / Supply-chain | yes | Committed lockfile + gitignored node_modules + reinstall-in-CI (D-17); planner gates `npm install` behind `checkpoint:human-verify` (slopcheck unavailable). No `postinstall` scripts in the three deps (verified pure-JS). |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious/typosquatted dep | Tampering | Lockfile pin + human-verify checkpoint + verified source repos (postcss/TrySound/Evercoder) |
| Non-deterministic build → diff noise hiding a real change | Repudiation | `git diff --exit-code` determinism gate (D-17) |

No ASVS V2/V3/V4 (auth/session/access-control) categories apply — no runtime, no users.

## Sources

### Primary (HIGH confidence)
- DTCG Format Module 2025.10 — https://www.designtokens.org/tr/2025.10/format/ — color `$value` object shape, dimension `{value,unit}`, `$extensions` reverse-domain, alias `{…}` syntax, group `$type` inheritance [CITED]
- W3C announcement, first stable version 2025.10 — https://www.w3.org/community/design-tokens/2025/10/28/design-tokens-specification-reaches-first-stable-version/ [CITED]
- In-session empirical verification (Node v22.14.0, scratch install): culori 4.0.2 `parse`/`formatHex`/`interpolate` behavior incl. `color-mix` → undefined; postcss 8.5.15 `walkRules`/`walkDecls`; postcss-value-parser 4.2.0 `var()` + `color-mix` node structure — run against the exact theme.css forms [VERIFIED]
- `accrue_admin/assets/css/theme.css` (read in full) — selector scoping `html.accrue-admin`, var() indirection, color-mix tokens, dark/system/reduced-motion blocks [VERIFIED: codebase]
- `.planning/phases/180-brand-audit-dna-lock/BRAND-AUDIT.md` §7 + `BRAND-DNA.md` §Palette/§Typography + `artifacts/contrast-table.txt` — binding token spec, 7 hexes, AA rows [VERIFIED: codebase]
- `brandbook/logo/harness/` (package.json, svgo.config.mjs, geist-spine-mono.mjs, generate-logo-suite.mjs) — the harness/determinism convention to mirror [VERIFIED: codebase]
- npm registry (`npm view`) — postcss 8.5.15, postcss-value-parser 4.2.0, culori 4.0.2 + repo URLs [VERIFIED: npm registry]

### Secondary (MEDIUM confidence)
- culori docs/api — https://culorijs.org/api/ — `formatHex`/`converter`/`interpolate` semantics (corroborated by in-session run)
- WebSearch corroboration that culori does not target browser-exact `color-mix()` parsing; `@csstools/css-color-parser` exists for native color-mix (noted as the alternative)

### Tertiary (LOW confidence)
- Third-party DTCG explainer pages (designzig, camoa dev-guides) — used only to confirm the 2025.10 stable date; superseded by the official spec pages above

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions verified via npm + full pipeline run in-session
- Architecture (DTCG shapes, generator, parity flow): HIGH — spec cited + pipeline empirically proven against the actual theme.css forms
- Pitfalls: HIGH — culori color-mix-undefined, percentage direction, selector scoping all reproduced in-session
- Specimen determinism: MEDIUM-HIGH — mirrors a proven logo-harness convention; specific specimen code is a pattern, not yet run
- code-block/callout values & dark modeling: MEDIUM — open questions flagged for author ratification

**Research date:** 2026-06-13
**Valid until:** 2026-07-13 (stable spec + mature deps; ~30 days). Re-verify culori `color-mix` support if bumping to culori 5.x.
