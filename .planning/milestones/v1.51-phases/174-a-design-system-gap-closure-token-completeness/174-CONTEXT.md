# Phase 174: A — Design-System Gap Closure & Token Completeness - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Close every remaining design-token gap in the `accrue_admin` CSS so that line-height, letter-spacing, breakpoint, transition, and reading-measure values all resolve from named `ax-*` tokens; kill the last token bypasses (the `dunning_banner.ex` inline-hex fallback + any residual inline styles); and publish a maintainer-facing component-variants reference at `/dev/components`. This is pure design-system substrate — **no new screens, no new billing primitives, no IA/nav changes** (those are Phase B+). Satisfies requirements DSY-01, DSY-02, DSY-03.

</domain>

<decisions>
## Implementation Decisions

All four areas were researched (parallel advisor agents) and the synthesized package was locked as-is by the user. The four interlock: one shared `--ax-*` taxonomy, everything composed from the v1.50 token atoms, **zero new build dependencies**, and every change carries an anti-churn justification token (a literal or bypass eliminated).

### Breakpoint tokenization (DSY-01)
- **D-01: Mechanism = documented `--ax-bp-*` constants block + grep-guard. NO build-pipeline change.** CSS `@media` conditions cannot read `var()`, and the CSS build is the Tailwind-v3 CLI (`tailwindcss@3.4.17`) → esbuild with **no** `postcss.config.js` (`lib/mix/tasks/accrue_admin.assets.build.ex`).
  - **Rejected — PostCSS `@custom-media`:** native `@custom-media` is not Baseline (Firefox-only as of 2026) so it needs build-time expansion anyway; Tailwind v3's internal PostCSS does not expose it → would force a new PostCSS pipeline the project deliberately omits. Wrong for a library shipping a committed bundle.
  - **Rejected — Tailwind `@screen`:** relocates breakpoints into JS config (splits the token home, soft "Tailwind migration") **and `@screen` was removed in Tailwind v4** — a guaranteed future migration / dead-end.
- **D-02: Implementation shape.** A single commented registry block at the top of `app.css` (the source of truth for the values), and **every `@media` carries an inline token comment** (e.g. `@media (min-width: 768px) { /* --ax-bp-md ↑ */ ... }`) so it is grep-able and self-documenting from within `app.css`.
- **D-03: Token names.** `--ax-bp-sm` = 600 · `--ax-bp-md` = 768 · `--ax-bp-lg` = 1024. **Rename the `640px` value to `--ax-bp-content`** (it sits *below* 768, so naming it `xl` would break monotonic ordering — it is an intrinsic content step, not a layout tier). Min-width = mobile-first up-query; max-width uses the existing `-0.02px` guard form (e.g. `599.98px` → `--ax-bp-sm ↓`, `1023.98px` → `--ax-bp-lg ↓`).
- **D-04: Enforcement.** The existing token-bypass grep guard / test must flag any `min-width:`/`max-width:` literal in `app.css` that is not a registered value and not accompanied by an `--ax-bp-*` comment. ⚠️ **Per the known coupling, the new guard needle must be added to BOTH the guard script AND its negative-test seed fixture** (see canonical refs — `verify_package_docs ↔ test` coupling), or the negative tests break.
- **D-05: Deferred (do NOT do now).** The 600/640 proximity (two breakpoints 40px apart) is flagged for possible *reconciliation* during Phase C's mobile-first rewrite — not changed here. Phase 174 only **names** the existing values; it introduces no layout behavior change.

### Type micro-tokens — line-height, letter-spacing, reading-measure (DSY-01)
- **D-06: Naming = semantic, NOT numeric t-shirt.** These axes are role-driven (display-tighten / body / uppercase-caps), not a smooth perceptual ramp, so semantic names kill the "which number do I want" guess. This is coherent with the existing **motion** tokens' semantic style (`--ax-ease-out`, `--ax-ease-emphasis`), and uses Tailwind's widely-recognized `leading`/`tracking` vocabulary under the `--ax-` prefix.
- **D-07: Exact token block to add to `theme.css`** (match the existing house comment/px-annotation style):
  ```css
  /* Line-height — unitless (inherits as a ratio) */
  --ax-leading-tight: 1.2;     /* display, headings */
  --ax-leading-normal: 1.4;    /* body, labels — the default */
  --ax-leading-relaxed: 1.5;   /* prose / long-form copy */
  /* Letter-spacing — em (scales with font-size) */
  --ax-tracking-tight: -0.02em; /* large display tightening */
  --ax-tracking-normal: 0;
  --ax-tracking-wide: 0.04em;   /* smaller uppercase labels */
  --ax-tracking-caps: 0.08em;   /* uppercase eyebrows / section labels */
  /* Reading measure — ch ≈ one "0" advance; 68ch ≈ 66 chars (60–75 sweet spot) */
  --ax-measure: 68ch;
  ```
  Plus a consuming utility class in `app.css`: `.ax-measure { max-width: var(--ax-measure); }`.
- **D-08: line-height is unitless** (a multiplier inherits as a ratio; rem/px would break on nested type). **letter-spacing stays in `em`** (scales with font-size; rem would decouple it). **measure uses `ch`**.
- **D-09: Keep body line-height at 1.4 — do NOT force 1.5 globally.** WCAG 1.4.12 governs user *override* capability, not the default; 1.4 is correct for a dense admin. `--ax-leading-relaxed` (1.5) is reserved for genuine prose/reading regions (settings copy, empty-state descriptions, the `.ax-measure` region).
- **D-10: Keep BOTH `--ax-tracking-wide` (0.04em) and `--ax-tracking-caps` (0.08em)** — they serve uppercase at two different optical sizes; merging would visually regress one existing use.
- **D-11: Migration is a pure 1:1 literal→token rename with ZERO value changes** (non-visual, safe). Map: `line-height:1.2`→`tight`, `1.4`→`normal`, `1.5`→`relaxed`; `letter-spacing:-0.02em`→`tight`, `0.04em`→`wide`, `0.08em`→`caps`. `--ax-measure` is the only net-new/additive token (no literal to replace).

### Transition bundles (DSY-01)
- **D-12: Shape = property-bundles** (full multi-property `transition` values), NOT timing-only bundles. Property-bundles collapse the ~5 multi-line `transition:` blocks in `app.css` to a single token each — which is the phase goal; timing-only bundles (the existing `--ax-motion-*` shape) cannot collapse them.
- **D-13: Ship exactly 4 bundles, composed strictly from the existing dur/ease atoms (never hardcoded ms/curves), enter-neutral (`--ax-ease-out`):** `--ax-transition-colors` (color/background-color/border-color), `--ax-transition-transform`, `--ax-transition-shadow`, `--ax-transition-base` (the colors+transform+shadow combo for cards/tiles). Property partition follows Tailwind's proven `transition-colors/-transform/-shadow` split, trimmed to what the admin actually animates. **No `--ax-transition-all`** (`transition: all` is a perf/footgun antipattern). Use `background-color` (not the `background` shorthand) so the skeleton shimmer's `background-position` is never accidentally transitioned.
- **D-14: Naming = new `--ax-transition-*` family. Freeze the legacy `--ax-motion-*` / `--ax-theme-transition` aliases as back-compat — do NOT extend them** (two parallel families = maintainer confusion). Single-property transition sites that already use `--ax-motion-*` may stay as-is; only the multi-line blocks are collapse targets.
- **D-15: Reduced-motion override at the token level** — inside the existing `@media (prefers-reduced-motion: reduce)` block, redefine the bundles on the root element using `--ax-dur-instant` so every consumer gets reduced-motion correctness for free (color/shadow cross-fades go instant; transform-lift collapses to 0ms).
- **D-16: Exit-asymmetry is deferred to Phase D (Motion).** Phase A only ships the bundle substrate; do not over-design motion semantics here. Any intentionally-snappy transform divergence found during collapse should be flagged for Phase D rather than encoded as a 5th bundle.

### `/dev/components` component-variants reference (DSY-03)
- **D-17: Approach = hand-rolled LiveView gallery** extending the existing `lib/accrue_admin/dev/component_kitchen_live.ex` — zero new deps.
  - **Rejected — `phoenix_storybook`:** violates the "no new heavy deps / extend existing" guardrail; its `.story.exs` files become a second source of truth that drifts from the `ax-*` tokens.
  - **Rejected (for now) — full `Phoenix.Component` attr reflection:** components don't declare `attr :variant, values: [...]` today (only `Button` declares `:variant`, none use `values:`; variant truth lives in private `*_class/1` clauses), so auto-derivation is a refactor in disguise.
- **D-18: Scope to exactly DSY-03's four families** — button / badge / status / card. The rest of the kitchen (Detail, RelatedResources, Icon, empty-state) stays a looser sanity-check, NOT token-mapped reference rows (anti-churn: don't mirror the whole UI / avoid style-guide rot).
- **D-19: Token-mapping format.** Drive every reference row from a new curated data module `AccrueAdmin.Dev.ComponentRegistry` returning `%{family, variant, ax_class, tokens: [~w(--ax-...)]}`, so the page and the drift test share one list. Each row shows: a **live-rendered swatch** of the real component + the **copy-paste `ax-*` class** + the **`--ax-*` tokens it resolves to** (a small `<dl>`).
- **D-20: Render BOTH light and dark side-by-side** per row via `data-ax-theme="light|dark"` wrappers (theme tokens cascade from the wrapper). The per-theme token-resolution difference is the page's primary reference value.
- **D-21: Drift-prevention test** — a `ComponentRegistryTest` that (a) renders the page and asserts every registry variant appears, and (b) asserts the registry's `ax_class` set exactly matches the component's known class outputs (so adding a 5th variant without a registry entry fails CI).
- **D-22: Wire `/dev/components` into the Phase F Playwright sweep** (`e2e/admin-visuals.spec.js`) as a cheap anchor shot across {light,dark} (mobile not needed for this page) — one screenshot per theme regresses the entire button/badge/status/card token surface.

### Claude's Discretion
- **Legitimate hardcoded hex that are OUT of scope (do not "fix"):** the runtime brand-config defaults (`accent_hex: "#5D79F6"` etc. across `*_live.ex`, `layouts.ex`, `brand_plug.ex`) and the favicon SVG hex in `layouts.ex` are host-overridable branding config / asset literals at the Elixir layer, **not** CSS token bypasses. DSY-02's "no surface bypasses the token system" targets the CSS/HEEx render path — specifically the `dunning_banner.ex:27` inline `style=` with hex fallbacks, and any residual inline styles on invoice surfaces. Scope the hex/inline-style cleanup to render-path bypasses, not branding config.
- **Optional high-DX follow-on (planner may include if cheap):** since DSY-01 already opens every component for token work, adding `attr :variant, :string, values: [...]` to Button/KpiCard/StatusBadge while in-file makes future drift protection near-automatic. Ship the registry-list version first regardless — it works today with no refactor.
- Exact placement of new token blocks within `theme.css`, exact `.ax-measure` consumption sites, and CSS section ordering are left to the planner/executor.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative design source (read first)
- `.planning/research/v1.51-admin-ui-depth-design.md` — the milestone's authoritative design source. §3 locked decisions (custom `ax-*` CSS, no Tailwind migration), §4 Phase A scope (lines 90–94), §6 evaluation rubric + verification commands, §7 scope guardrails, §8 critical files.
- `.planning/REQUIREMENTS.md` §DSY-01/02/03 (lines 32–34, 76–78) — the three requirements this phase satisfies.
- `.planning/ROADMAP.md` — Phase 174 detailed block (goal + 3 success criteria) and the v1.51 anti-churn rule + 10-dimension rubric.

### Files to modify (token gap-closure)
- `accrue_admin/assets/css/theme.css` — add line-height / letter-spacing / measure / transition-bundle token blocks; add reduced-motion bundle overrides. Existing token house-style: `--ax-{category}-{size}` with rem + px comments (type/space/radius), semantic naming for motion (`--ax-ease-*`, `--ax-dur-*`). Existing atoms: durations `--ax-dur-instant/1/2/3/exit`, easings `--ax-ease-out/in/inout/emphasis`, and legacy composed aliases `--ax-motion-fast/standard`, `--ax-theme-transition`.
- `accrue_admin/assets/css/app.css` — breakpoint registry block + inline `--ax-bp-*` comments; migrate line-height/letter-spacing/transition literals to tokens; add `.ax-measure` utility.
- `accrue_admin/lib/accrue_admin/components/dunning_banner.ex` — line 27: kill the inline `style=` with hex fallbacks (`#fef2f2`/`#991b1b`/`#fecaca`) — the concrete DSY-02 bypass.
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — extend into the variants reference (renders Button/StatusBadge/KpiCard/Detail today).
- NEW: `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — curated variant→class→tokens registry.
- NEW: `accrue_admin/test/` — `ComponentRegistry` drift-prevention test.

### Build / verification
- `accrue_admin/lib/mix/tasks/accrue_admin.assets.build.ex` — the asset build (Tailwind v3 CLI → esbuild, no PostCSS). Confirms the breakpoint decision's "zero build change". After any CSS/JS edit: `cd accrue_admin && mix accrue_admin.assets.build` and commit `priv/static`.
- The token-bypass grep guard + its negative-test seed fixture — both must gain the new breakpoint needle (the `verify_package_docs ↔ test` coupling pattern; whichever guard script enforces token compliance for this package).
- `accrue_admin/e2e/admin-visuals.spec.js` — Phase F sweep; `/dev/components` to be added (Phase F, but note the anchor-shot intent here).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`theme.css` token system** — already tokenizes type scale, spacing (`2xs`–`3xl`), radius, shadow (dual-layer), motion duration+easing atoms, z-index, and semantic colors. New tokens slot into the same `:root`/`data-theme` element and house style. Do NOT re-do the v1.50 foundation — extend it.
- **`--ax-motion-*` / `--ax-theme-transition`** — existing composed timing aliases; keep frozen for back-compat, the new property-bundles live alongside.
- **`component_kitchen_live.ex`** — existing dev-only LiveView at `/dev/components` importing `Button, KpiCard, StatusBadge, Detail`; the base to extend.
- **Existing `@media (prefers-reduced-motion: reduce)` block** in `app.css` (~line 2258) — the hook for token-level reduced-motion bundle overrides.

### Established Patterns
- **No-Tailwind-utility convention** — custom `ax-*` BEM-adjacent classes + CSS custom-property tokens; Tailwind is configured but inert. All four decisions honor this.
- **Phoenix function-components with `attr :variant`** — variant truth currently lives in private `*_class/1` clauses, not `attr values:` (relevant to the registry approach + the optional `values:` follow-on).
- **Committed asset bundle** — `priv/static/accrue_admin.css` is committed; host apps don't run accrue_admin's Tailwind. This is *why* minimal-build-dep wins for breakpoints.
- **verify_package_docs ↔ test coupling** — a new guard needle must be added to both the standalone script and the negative-test seed fixture or the negative tests fail (see memory; applies to the breakpoint guard needle).

### Integration Points
- Token additions in `theme.css` are consumed by `app.css` class definitions; no LiveView/runtime changes for tokens.
- `ComponentRegistry` module is consumed by both `component_kitchen_live.ex` (render) and the drift test (assert) — single source of truth.

</code_context>

<specifics>
## Specific Ideas

- **User mandate for this discussion:** deep, subagent-backed research per area — pros/cons/tradeoffs with concrete examples, what's idiomatic for the Elixir/Phoenix/Ecto ecosystem, lessons (right + footguns) from comparable libs/apps in any popular framework, strong DX/UX, principle of least surprise, and a cohesive one-shot recommendation set "so I don't have to think." Calibration tier = `minimal_decisive` (opinionated user; decisive single recommendations). All four were delivered as a coherent locked package.
- **Reference precedents surfaced by research** (for the planner/researcher to lean on): open-props (closest token precedent; confirms `@custom-media` is build-time-only), Tailwind's `transition-colors/-transform/-shadow` property partition, Tailwind `leading`/`tracking` vocabulary, GOV.UK / Primer / Radix for the variant-reference altitude.

</specifics>

<deferred>
## Deferred Ideas

- **Reconcile the 600px/640px breakpoint proximity** → Phase C (mobile-first rewrite). Phase 174 only names the existing values.
- **Exit-asymmetry motion bundles / deep motion semantics** → Phase D (Motion & Micro-interaction). Phase 174 ships only the neutral bundle substrate.
- **Normalize components to `attr :variant, values: [...]` for near-automatic drift protection** → optional; may be folded into Phase 174 if cheap, otherwise a later DX improvement. The registry-list approach ships regardless.
- **Adding `/dev/components` to the screenshot sweep** is logically Phase F; noted here as intent so the page is built screenshot-ready.

*Discussion stayed within phase scope — no scope creep into IA/nav (Phase B) or per-screen uplift (Phase C).*

</deferred>

---

*Phase: 174-a-design-system-gap-closure-token-completeness*
*Context gathered: 2026-06-03*
