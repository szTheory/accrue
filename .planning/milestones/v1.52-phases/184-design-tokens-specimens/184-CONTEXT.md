# Phase 184: Design Tokens & Specimens - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 184 establishes the committed **brand-layer token vocabulary** at `brandbook/tokens/` — the `--accrue-*` raw palette plus the palette-bearing semantic color roles the admin's `--ax-*` layer consumes — as a DTCG-formatted `tokens.json` source that generates `tokens.css`. It ships an **automated consistency check** that fails CI on undocumented drift between brandbook token values and the admin SSOT (`accrue_admin/assets/css/theme.css`), and **visual specimen artifacts** (`brandbook/examples/`) rendering every swatch, type step, and spacing step.

**Hard scope anchors (from the v1.52 milestone + Phase-180 audit):**
- **Zero admin code changes.** `accrue_admin/assets/css/theme.css` is the READ-ONLY SSOT for product UI. The brandbook documents the brand layer *below* it; the check adapts to theme.css, never the reverse.
- Brandbook stays **buildless for consumers** — Phase 186 inlines raw `tokens.css` into a self-contained `file://` `index.html` (no JS frameworks, no network, no build step).
- **SVG-first, lean on binaries**, ≤2 MB total committed `brandbook/` weight (enforced at the Phase-186 gate). Token/specimen artifacts are kilobyte-scale; harness `node_modules` is gitignored and does not count.
- Exploration/tooling output that isn't a brandbook deliverable stays out of `brandbook/`.

**Not in scope:** any `--ax-*` edits; adding a token *build pipeline for consumers*; Phase-186 assembly; voice/copy (Phase 185).
</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched with parallel `gsd-advisor-researcher` agents (ecosystem idiom, OSS brand-book exemplars, DX, cohesion with the established Node-`.mjs`/determinism convention). The user's standing preference (cohesive one-shot synthesis; only flag truly irreversible/published forks) applies. **Every advisor flagged its area `high-impact-fork = FALSE`** — all decisions are internal, reversible tooling with no published-API or external-consumer commitment. Decisions below are **locked defaults**; sanity-check at CONTEXT/PR review and override there if desired.

### A — tokens.json schema & SSOT model
- **D-01:** **`tokens.json` is the single source of truth; `tokens.css` is GENERATED from it.** Drift between the two files is eliminated by construction, not policed. One obvious answer to "which file is truth?" → the JSON.
- **D-02:** **`tokens.json` is W3C DTCG-formatted** (the spec reached its first **stable version, v2025.10** — conformance is no longer betting on a moving draft). Use `$value` / `$type` / `$description` with nested groups. This is the one feature that makes shipping a JSON sibling (vs raw CSS) worthwhile for a *public* OSS brand book — it's ingestible by Figma / Tokens Studio / Style Dictionary / Primer-style pipelines.
- **D-03:** **No Style Dictionary.** v5.4.4 is ~4.4 MB unpacked with 13 direct deps (prettier, glob, memfs, zip.js, colorjs) — grossly disproportionate to ~7 raw + ~14–16 semantic tokens and hostile to a deliberately buildless, ≤2 MB milestone. Instead a **small (~≤60-line) Node `.mjs` generator** walks the DTCG tree and emits `:root{ --… }`, reusing the exact 181–183 harness pattern (committed `.mjs` + lockfile, `node_modules` gitignored, `git diff --exit-code` determinism gate). Revisit Style Dictionary only if multi-platform token export (SCSS/iOS/Android) is ever needed — swappable later against the same DTCG JSON, zero external blast radius.
- **D-04:** The brand→admin **`--ax-*` mapping is encoded in DTCG `$extensions`** per token (see D-09), so the JSON is the single home for both the value and its parity relationship.

### B — Consistency-check script
- **D-05:** **Runtime = Node `.mjs`**, in its own harness dir with a committed `package.json` + lockfile and gitignored `node_modules` — matching the established brand-harness convention. (Elixir `mix`-task option rejected: it forces hand-rolling the CSS-AST + color-normalization logic that is the entire footgun; the repo has no mature Elixir CSS parser. Shell+grep rejected: cannot reliably resolve `var()` / `color-mix()` / hex-case.)
- **D-06:** **Parsing = real parser, not regex.** `postcss` + `postcss-value-parser` to AST-walk `--token: value;` declarations and resolve `var(--accrue-*)` indirection; **`culori`** to normalize heterogeneous color forms (`#FFF` vs `#ffffff`, `rgb()/rgba()`, `color-mix(in srgb …)`, `color-mix(in oklch …)`) to a canonical value before comparison. Value normalization is load-bearing — theme.css contains all of these forms and is read-only.
- **D-07:** **Check compares RESOLVED concrete values keyed by the per-token ax-map, in BOTH light and dark.** This reconciles the two advisors: in light `:root` the admin side is `--ax-*: var(--accrue-*)` (resolve the indirection); in dark/`@media` the admin side is a standalone hex (compare value-to-value). The check does not *require* var-indirection to exist — it resolves each side to a concrete color and compares — so dark-mode duplicated tokens (D-12) are checkable without false positives. Tokens without an ax-map (D-09) are skipped entirely.
- **D-08:** **Exit-code contract:** exit `0` when every ax-mapped brandbook token matches its admin counterpart (or carries a documented divergence, D-10); exit **non-zero on any undocumented drift** (SC#2). One-shot live check — it derives expected values from `theme.css` at runtime, so it **cannot rot against a stale golden file** (no snapshot/fixture). The separate `git diff --exit-code` gate continues to cover determinism of the *generated* `tokens.css`.
- **D-10:** **Divergence declaration = DTCG `$extensions` in `tokens.json`** (e.g. `$extensions["accrue.parity"] = { divergesFrom: "--ax-…", reason: "…" }`). Colocated with the token the author is already editing → least-surprising, machine-readable (no comment-parsing), and keeps read-only `theme.css` untouched. The check tolerates a mismatch **only** when such an entry names the diverging `--ax-*` token and a reason.

### C — Token vocabulary scope & brand↔ax mapping (Option B: curated)
- **D-09:** **Brandbook declares as REAL tokens:** (1) the **7 raw `--accrue-*`** (ink `#111418`, slate `#24303B`, fog `#E9EEF2`, paper `#FAFBFC`, moss `#5E9E84`, cobalt `#5D79F6`, amber `#C8923B`); (2) the **palette-bearing semantic color roles** the §7 audit enumerates — surface (base/elevated/sunken), content (primary/muted/subtle), interactive (accent/focus-ring), feedback (success/warning/danger/info). These carry an explicit `axMap` (the `--ax-*` they correspond to) in `$extensions` and are value-checked by the parity script. Rationale: this is where divergence is a *visible brand bug*, and it makes SC#2 genuinely meaningful.
- **D-11:** **Non-color scales are documented by REFERENCE, not re-declared.** Typography scale, spacing scale, radius, state, and motion point at `--ax-type-*` / `--ax-space-*` / `--ax-radius-*` etc. via a prose mapping table — they are **not** minted as `--accrue-*` tokens. Reason: theme.css is read-only, so every duplicated value is a pure drift liability with no brand upside; a brand book has no reason to re-own a 4px spacing rung. This satisfies the §7 "category present" requirement without a maintenance tax. (The DTCG `tokens.json` MAY carry these as `$type: dimension` reference entries that alias the ax names for documentation/interop, but they get `axMap: null`-style treatment in the parity scope — i.e. not value-enforced.)
- **D-09b:** **Brand-only tokens (no ax-* counterpart)** — `--accrue-fog`, `--accrue-cobalt` (raw), and the brandbook-specific **code-block** and **callout** tokens — are marked **`axMap: null` / brand-only** in `tokens.json` (and a matching `/* brand-only: no --ax-* counterpart */` note in `tokens.css`). The parity check keys off the explicit ax-map field and skips null-mapped tokens, so they never trigger false drift. `code-block` and `callout` token *values* are new brand-layer definitions this phase must author (no upstream to mirror).

### D — Specimen artifacts
- **D-13:** **Generated SVG**, authored by Node `.mjs` scripts reading `tokens.json` — deterministic, drift-free, `git diff --exit-code`-gated like the logo suite. (Hand-authored SVG rejected: silently drifts when a token changes. HTML fragments rejected: "inlining" into Phase-186's `index.html` becomes a CSS-scope/cascade merge rather than a clean self-contained `<svg>` node-drop.)
- **D-14:** **Three separate files:** `examples/palette.svg`, `examples/typography.svg`, `examples/spacing.svg`. Separate keeps each generator simple and lets Phase 186 inline/section them independently (the audit file-plan already named `palette.svg` + `typography.svg`; `spacing.svg` is the SC#3 addition).
- **D-15:** **Per-specimen content checklist (locked):**
  - `palette.svg` — every 7 raw `--accrue-*` swatch + semantic color roles; each annotated with **hex + token name + role**; **AA/contrast status** explicitly flagging that **Moss/Cobalt/Amber FAIL AA-body on light surfaces** (per the audit usage rules); rendered on **both light and dark** surfaces.
  - `typography.svg` — full **Geist sans + Geist Mono** size scale, each step labeled with **px + rem** and a sample line at that size.
  - `spacing.svg` — **every spacing step** as a labeled visual ruler/bar (token name + px/rem).

### Harness placement & determinism (cross-cutting)
- **D-16:** Consolidate Phase-184 tooling under **`brandbook/tokens/harness/`** (token generator + parity check) with its own committed `package.json` + lockfile (`postcss`, `postcss-value-parser`, `culori`) and **gitignored `node_modules`** — mirroring `brandbook/logo/harness/`. Specimen generators may live alongside or under `brandbook/examples/harness/`; **prefer one shared harness/`node_modules` install** to avoid a second dependency tree. Planner decides the exact split, but do not create three separate `node_modules` installs.
- **D-17:** **Determinism convention (inherited from Phase 183):** commit `.mjs` + lockfile, gitignore `node_modules`, reinstall in CI; assert `git diff --exit-code` over generated outputs (`tokens.css`, the three `examples/*.svg`). The parity check is the *separate* CI gate; the diff gate guards generation reproducibility.

### Claude's Discretion (left to research/planning)
- Exact DTCG group nesting / token naming inside `tokens.json` (e.g. `color.brand.moss` vs `accrue.moss`) and the CSS var-name derivation rule.
- Whether specimen generators reuse the logo harness's Geist/opentype.js for precise type-ramp glyph metrics, or label sizes without per-glyph metrics.
- Exact `$extensions` key namespacing (`org.accrue.ax` vs `accrue.parity`) — pick one consistent namespace.
- Color-normalization tolerance policy (exact-match vs ΔE epsilon) for the parity check — default to exact canonical-form match unless a real `color-mix`/`oklch` case forces an epsilon.
- The prose mapping-table format for the reference-only scales (D-11).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative token spec (THE source for what to build)
- `.planning/phases/180-brand-audit-dna-lock/BRAND-AUDIT.md` §7 "Token Specification" (lines ~296–367) — the binding token spec: two-layer architecture, the 7-token raw mapping table with admin bindings, per-token contrast/usage rules (Moss/Cobalt/Amber AA constraints), the 7 required token categories, and the file-plan (`tokens/tokens.json` "W3C DTCG format", `tokens/tokens.css`, `examples/palette.svg`, `examples/typography.svg`). §12.1–12.3 file/guardrail plan.
- `.planning/phases/180-brand-audit-dna-lock/BRAND-DNA.md` §Palette, §Typography — locked palette hexes + Geist/Geist Mono, usage rules.
- `.planning/phases/180-brand-audit-dna-lock/artifacts/contrast-table.txt` — the cited contrast rows behind every AA usage rule (specimen AA annotations must match these).

### Admin SSOT (READ-ONLY this milestone — the parity target)
- `accrue_admin/assets/css/theme.css` — 131 `--ax-*` tokens. Light `:root` carries `--ax-*: var(--accrue-*)` bindings (the brand indirection); `[data-theme="dark"]` + `@media (prefers-color-scheme: dark)` carry standalone-hex overrides; `@media (prefers-reduced-motion)` overrides motion. The parity check reads this file; it is never edited.

### Milestone framing & guardrails
- `.planning/ROADMAP.md` — Phase 184 block (lines ~186–198: goal, SC#1–#3, TOK-01/02/03) and v1.52 milestone header (lines ~31–49: posture, guardrails, dependency shape `180→{184,185}→186`).
- `.planning/research/v1.52-brand-system-design.md` — authoritative milestone design source (Phase-184 paragraph line ~54; file tree lines ~83–85; token-drift risk line ~106/111).
- `prompts/accrue-brand-book.md` — full brand strategy seed (gitignored, on disk): palette hexes, Geist typography, voice, tagline.

### Reusable harness convention (the pattern to mirror)
- `brandbook/logo/harness/` — committed `.mjs` generators + `package.json` + `package-lock.json` + `svgo.config.mjs`; `node_modules` gitignored. This IS the determinism/harness convention Phase 184 reuses.
- `.planning/phases/183-logo-system-production/183-CONTEXT.md` — D-08/D-11 determinism decisions (`git diff --exit-code` artifact gate, lockfile-pinned deps, render-at-size) that Phase 184 inherits.
- `.planning/phases/183-logo-system-production/183-04-SUMMARY.md` — confirms the determinism gate passes; reference for CI wiring shape.

### Standing process preference
- `~/.claude/.../memory/feedback_decision_synthesis_style.md` — cohesive one-shot synthesis; decide everything, only flag truly irreversible/published forks. Applied here (no forks surfaced).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`brandbook/logo/harness/`** — working Node `.mjs` pipeline with committed lockfile; the token generator, parity check, and specimen generators follow this exact shape (commit scripts+lockfile, gitignore `node_modules`, `git diff --exit-code` gate). Geist/opentype.js already vendored there if the type specimen wants real glyph metrics.
- **`accrue_admin/assets/css/theme.css`** — the complete `--ax-*` vocabulary the brand layer maps to: raw `--accrue-*` references (lines 105–116), semantic roles, type/space/radius/motion scales, dark + reduced-motion overrides. Source of every parity expectation.
- **`prompts/accrue-brand-book.md`** — locked palette hexes + Geist stacks + tagline for token values and specimen sample copy.

### Established Patterns
- **Two-layer token architecture** (`--accrue-*` raw → `--ax-*` semantic). Phase 184 owns the raw layer + the palette-bearing role aliases; it must NOT redefine `--ax-*`.
- **Generate-and-gate determinism** — artifacts are emitted from a frozen source by `.mjs` and asserted reproducible via `git diff --exit-code`; node_modules reinstalled in CI from a committed lockfile.
- **Evidence-gated palette** — every usage rule traces to a cited `contrast-table.txt` row; specimen AA annotations must not invent contrast claims.

### Integration Points
- **Phase 186 (downstream):** inlines the generated `tokens.css` + the three `examples/*.svg` into a buildless `index.html`. Favors SVG specimens (clean inline nodes) and raw CSS (no consumer build).
- **Admin cascade:** the admin references `var(--accrue-*)` but those raw tokens are currently undefined (GAP-C2) — Phase 184's `tokens.css` is what completes that cascade for any host that loads it. (No admin file is edited; this is documentation of the brand layer, not wiring it into the admin build.)
</code_context>

<specifics>
## Specific Ideas

- DTCG **v2025.10 stable** is the format bar — not a draft.
- Parity check is a **live derivation** from `theme.css`, explicitly *not* a snapshot, so it can't rot.
- Divergences are declared **in `tokens.json` `$extensions`**, never as edits to the read-only `theme.css`.
- Specimen exemplar lineage: Vercel Geist / GitHub Primer / Radix — primitive layer is the owned/published artifact; specimens are generated from tokens.
</specifics>

<deferred>
## Deferred Ideas

- **Style Dictionary / multi-platform token export (SCSS/iOS/Android):** explicitly deferred (D-03). Reconsider post-v1.52 only if a real multi-platform consumer appears; the DTCG `tokens.json` keeps that door open with zero rework.
- **Minting `--accrue-*` tokens for spacing/radius/type scales:** deferred (D-11) — reference-only this phase to avoid drift liability against the read-only admin SSOT. Could be promoted if the brand layer ever needs to ship standalone with zero `accrue_admin` dependency.
- **`examples/readme-header.svg`:** belongs to Phase 185/186 per the audit file-plan — not a Phase-184 deliverable.

None of the above are scope creep into 184; they are correctly-placed future work.
</deferred>

---

*Phase: 184-design-tokens-specimens*
*Context gathered: 2026-06-13*
