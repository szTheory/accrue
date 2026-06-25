# Phase 193: Research, re-baseline & pattern lock - Context

**Gathered:** 2026-06-25
**Status:** Ready for planning

<domain>
## Phase Boundary

The foundation phase of v1.54. It delivers four contracts that every later phase (194–200) conforms to — nothing user-visible ships yet:

1. **Lock three archetype pattern specs** — SPEC-OVERVIEW / SPEC-LIST / SPEC-DETAIL as the design contracts every `accrue_admin` page is built or conformed against.
2. **Extend the forward-only baseline** — add `surface_type:"page-flow"` cells over the ~20 admin routes so the v1.53 zero-regression gate can see whole composed pages.
3. **Stand up PhoenixStorybook (dev/test-only)** — dependency + leak-proof guarded mount + the four spike decisions recorded.
4. **Ship three new CSS source guards** — spacing-literal ban, `:focus-visible` enforcement, truncation-without-`min-width:0` — merge-blocking in `verify_package_docs.sh`/CI.

**Fixed guardrails (carried forward, not re-litigated):** scope is the `accrue_admin` operator UI only; no new billing primitives, domain features, or breaking API/route changes; no Tailwind migration (custom `ax-*` CSS + tokens stay SSOT); core `accrue` stays LiveView-runtime-free (Storybook is `accrue_admin` dev/test-only and must not reach adopter runtime); no pixel-diff / SaaS visual-regression (TOOL-02 stays deferred — the scored-cell forward-only gate is the mechanism); the in-app `/dev/components` kitchen stays as the second renderer backing the Phase-189/190 drift tests.

</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched in parallel (advisor subagents) and resolved into one cohesive package. Each decision is coherent with the others: the **overlay primitive** is the structural backbone; the **pattern specs** are shipped guides whose machine-checkable invariants feed the gate; the **Storybook scaffold** is a walking skeleton that de-risks the foundation without front-loading breadth.

### Overlay primitive direction (the milestone backbone — owned/built in 195/199, decided here)
- **D-01 — PRIMARY: body-level portal.** The canonical overlay primitive is a JS hook that portals overlay markup to a body-level `#ax-overlay-root`, **reusing the already-shipped `FocusTrap` hook + the isolated `--ax-z-*` scale + a new ref-counted iOS-safe `ScrollLock` hook + `inert` background + a single idempotent dismissal contract (backdrop click + Escape → same close) + origin-aware enter motion.** One primitive, three presentations: centered **modal** / edge-docked **drawer** / anchored **popover** — they share the same portal + dismissal + scroll-lock contract (so Phase 195's action-menu popover does NOT fork a parallel overlay path).
- **D-02 — FALLBACK: native `<dialog showModal()>` + top-layer**, reserved for *individual* surfaces only if the Phase-199 transformed-ancestor audit finds a `transform`/`filter`/`contain` ancestor re-rooting a `position:fixed` shell that we cannot remove at the source. **Reject "hold both open as the default posture."**
- **D-03 — Why portal over native `<dialog>` as primary:** the decisive reason is **LiveView fit, not browser support**. `<dialog>`'s `showModal()`/`close()` write a client-imperative `open` attribute that morphdom actively fights (requires `JS.ignore_attributes("open")` + a state-reconciliation bridge hook) — new impedance against the server-driven `:if={@open}` + `phx-mounted`/`phx-remove` model both shipped shells (`detail_drawer.ex`, `step_up_auth_modal.ex`) already use correctly. `<dialog>`'s "free" wins (Escape, focus containment, inert) are **already shipped** in the solid `FocusTrap` hook; its one genuinely-unsolved problem (iOS body scroll-lock) is **not** solved by `<dialog>` and must be built either way (R-1). So native `<dialog>` buys structural insurance we may not need, at the cost of fighting LiveView and discarding working a11y code.
- **D-04 — Keep the `<dialog>` swap-seam clean.** Phase 193 ships the portal as A but isolates the shell markup behind the primitive's component boundary so Phase 199 can flip *individual* surfaces to B without touching their ~20 call sites.
- **D-05 — The Phase-193 overlay spike must empirically prove (Playwright hit-test), regardless of A/B:** (1) the open overlay's primary action AND an inner focusable control click-succeed *while the scrim is present*, across desktop+mobile × light/dark (Pitfall-1 AC); (2) the portal re-parent survives a LiveView `phx-update`/navigation without orphaning or double-mounting `#ax-overlay-root`; (3) opening locks body scroll with **no** scrollbar-gutter jump (before/after layout-box of a header element unchanged) and inner scroll uses `overscroll-behavior:contain`; (4) the **transformed-ancestor probe** — wrap the shell in a `transform:translateZ(0)` test ancestor and confirm the portal still escapes it (the exact condition that flips a surface to B).

### Pattern-spec home & durability
- **D-06 — Ship the three specs as durable ExDoc guides** at `accrue_admin/guides/spec-overview.md`, `accrue_admin/guides/spec-list.md`, `accrue_admin/guides/spec-detail.md` (kebab-case, matching `core-admin-parity.md`/`theme-exceptions.md`). NOT planning-internal — the audience is genuinely three-way (build agents 194–200, the maintainer, AND fork/extend adopters), and only a shipped home serves all three.
- **D-07 — Wire them like `motion.md` does** (the exact in-repo precedent: shipped + ExDoc-published + needle-pinned + enforcement-guarded): add all three to `accrue_admin/mix.exs` `docs/0` `extras` **and** the `Guides:` `groups_for_extras` group; the package `files:` already includes `guides`. Add a `require_fixed` needle per spec to `scripts/ci/verify_package_docs.sh` (one stable anchor heading each, e.g. `## SPEC-DETAIL — summary-then-drill`) plus the three `mix.exs` `"guides/spec-*.md"` needles.
- **D-08 — Honor the verify_package_docs ↔ test coupling invariant:** every new doc needle added to `verify_package_docs.sh` MUST also be mirrored into `PackageDocsVerifierTest`'s `seed_tmp_dir!`, or all 6 negative tests fail (standalone script stays green). This is a known repo footgun — do not skip it.

### Pattern-spec rigor
- **D-09 — Layered specs (prose intent + per-archetype machine-checkable invariant checklist).** The repo is already a layered enforcement machine, and the specs must mirror it rather than fight it: the page-flow Playwright driver (`phase191-page-flow-helpers.js`) already exposes discrete assertions (`assertTopPointerTarget`, `assertScrollReachable`, `assertNoHorizontalClip`, `assertFocusWithin`); the 12-dim rubric (`187-RUBRIC.md`) handles judge-graded taste; `verify_package_docs.sh` is grep-shaped source-lint. So "machine-gradable vs judge-graded" is **a line to draw, not a choice to invent.**
- **D-10 — The line:** make an item a **machine assertion** only if the page-flow driver / source-guards / axe-core can decide it deterministically; everything residual (visual hierarchy, brand voice, info-dump density, persona ordering, card-in-card taste) stays **prose for the 12-dim adversarial judge** — recorded as rubric cells, never faked as assertions. This is exactly the SUMMARY thesis: *"prevent via source-lint where mechanical, rendered-detection where compositional; do not try to lint taste."*
- **D-11 — Concrete invariant split per archetype (seed content for the specs):**
  - **SPEC-OVERVIEW** — *machine:* exactly one `<h1>`; ⌘K trigger present + focusable; KPI cluster is a DOM-sibling *after* the attention-rail/task-launcher zones (not first child); healthy/empty attention-rail renders a non-interactive hero (no `cursor:pointer`/`role=button`). *Prose (judge):* exceptions read as higher-signal than KPIs; KPIs demoted not deleted; Recovery reads as a work-queue not a chart wall.
  - **SPEC-LIST** — *machine:* renders 4 *distinct* states (populated / first-run-empty / filtered-empty / loading) with distinct copy strings; filter chips + result count + clear-all all present when a filter is active; every truncating cell pairs ellipsis with `min-width:0` (new source-guard); no pager rendered when `pages≤1`. *Prose (judge):* column priority serves identity·state·money·time; "deliberate dense" padding rhythm.
  - **SPEC-DETAIL** — *machine:* ≤2 primary action buttons + an overflow menu; action forms NOT pre-expanded on load (visible action-band `<form>` count == 0 until menu invoked); exactly one related-resources strip (no duplicate); overlay/drawer hit-testable above its scrim (`assertTopPointerTarget`) with body scroll locked. *Prose (judge):* summary-list answers "what state, what's wrong" at a glance; no card-in-card double-border; tabs only for peer record-sets.
- **D-12 — Document the checklist IN the shipped guide** (GOV.UK-style published acceptance criteria) — adopters benefit from seeing the rules. The *executable* enforcement is the Playwright helpers + source-guards + rubric cells the planning-side wiring maps to; the guide is documentation, not a forever-stable machine API, so we make no perpetual machine-contract promise to adopters.

### Storybook Phase-193 footprint
- **D-13 — Minimal scaffold (walking skeleton), NOT full generator.** Land in 193: (1) `{:phoenix_storybook, "~> 1.2", only: [:dev, :test]}`; (2) an env-guarded `AccrueAdmin.Dev.Storybook` backend module; (3) a `Code.ensure_loaded?(PhoenixStorybook.Router)`-guarded sibling-scope router wrap chained after the Mailglass wrap — this guard is **mandatory** (a host's `:dev` compile never fetches our `:dev,:test` dep yet defaults `dev_routes? = true`; a bare `import PhoenixStorybook.Router` is a compile-time router dependency that would fail the host build); (4) Storybook CSS/JS served through the **same** committed-bundle mechanism `AccrueAdmin.Assets` already uses (`File.read!` + `@external_resource` + md5 hash), NOT the official Tailwind recipe; (5) exactly **ONE** generated proof-of-concept story (`button`) built via a real `RegistryStory.variations_for/1` reading `ComponentRegistry.variants_for/1`, proving the registry→`%Variation{}` pipeline end-to-end; (6) a passing host-absence compile test (`examples/accrue_host` compiles in `:dev` AND `:prod` with the dep absent and exposes no `/dev/storybook` route).
- **D-14 — Defer cleanly to Phase 200:** generating the remaining ~13 families + all 8 `group_contracts/0` stories (STY-02), and verifying *both* color modes against the shipped `ax-*` bundle (STY-03). Rationale: 193 is a strictly-linear foundation phase blocking five others — prove the riskiest end-to-end path early with minimal flesh; do not concentrate bulk-authoring risk in the gating phase, and do not leave a half-built generator rotting through 194–199.
- **D-15 — Registry stays SSOT; the kitchen stays.** Storybook is a *second renderer*, never a replacement. The `/dev/components` kitchen and its `data-ax-family`/`data-ax-state`/`data-component-group` drift-test locators (Phase 189/190) stay untouched.

### Claude's Discretion (research-default, no user fork needed)
- **D-16 — Baseline storage = additive sibling file.** Extend the Phase-187 baseline via an additive sibling `baseline.page-flow.cells.json` (clean provenance, no churn on the existing `baseline.cells.json`), reusing the Phase-191 page-flow Playwright driver + the 12-dim rubric. Research-recommended; planner may finalize the exact filename/location next to the v1.53 baseline.
- **D-17 — The three remaining (non-overlay) Phase-193 spikes** — `data-theme` dark-mode shim for Storybook color-mode (class→attribute bridge under `.psb-sandbox` vs `html.accrue-admin[data-theme="dark"]`); `inert` vs `aria-hidden`+focusguard browser-floor; Storybook asset-serving without a Tailwind rebuild — are resolved as part of standing up the single PoC story (which forces all three through a load-bearing path). Each gets a recorded decision per RES-03.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authoritative design source (read first)
- `.planning/research/SUMMARY.md` — the v1.54 synthesis; the cross-cutting linchpin (defects are STRUCTURAL, invisible to source-lint), the two-part backbone (canonical overlay primitive + rendered state-matrix gate), the adversarial tension table with each chosen direction.
- `.planning/research/FEATURES.md` — the three archetype specs' draft content (overview / list / detail directions, counterpositions argued + rejected). This is the seed material for SPEC-OVERVIEW/LIST/DETAIL.
- `.planning/research/ARCHITECTURE.md` — motion K1–K15 audit + overlay structural fixes R-1..R-6 + the 12 IXN acceptance criteria.
- `.planning/research/PITFALLS.md` — 9 maintainer bug classes → root cause → prevention → guard/AC → gap-vs-gate (the source for the 3 new guards).
- `.planning/research/v1.54-storybook-and-forward-only-qa.md` — full PhoenixStorybook adoption research: leak-proof mount, registry generator, asset serving without Tailwind, theming bridge, the host-compile gotcha, page-flow baseline extension.

### Forward-only gate machinery (reuse, do not rebuild)
- `.planning/milestones/v1.53-phases/187-audit-baseline/187-RUBRIC.md` — the 12-dimension rubric the page-flow cells score against.
- `.planning/milestones/v1.53-phases/187-audit-baseline/baseline.cells.json` — the v1.53 baseline the page-flow cells extend (additive sibling per D-16).
- `accrue_admin/e2e/admin-page-flow-phase191.spec.js` + `accrue_admin/e2e/phase191-page-flow-helpers.js` — the page-flow Playwright driver to reuse; exposes `assertTopPointerTarget` / `assertScrollReachable` / `assertNoHorizontalClip` / `assertFocusWithin`.

### Overlay primitive groundwork
- `accrue_admin/lib/accrue_admin/components/detail_drawer.ex` — the `:if={@open}` + `phx-mounted`/`phx-remove` + FocusTrap shell the portal extends.
- `accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex` — second shell, same shape (destructive-action step-up handoff).
- `accrue_admin/assets/js/hooks/focus_trap.js` — the shipped, solid a11y hook the primitive reuses.
- `accrue_admin/assets/css/theme.css` (isolated `--ax-z-*` scale) + `accrue_admin/assets/css/app.css` (both shells use `isolation:isolate`; drawer enter is wrong-axis `translateX` — the R-3 geometry bug).
- `accrue_admin/guides/motion.md` — motion token vocabulary (stays as-is) + the shipped-design-contract precedent (needle-pinned).

### Storybook scaffold
- `accrue_admin/lib/accrue_admin/router.ex` — the Mailglass sibling-scope mount precedent (the wrap to chain after).
- `accrue_admin/lib/accrue_admin/dev/component_registry.ex` — the SSOT the generator reads (`entries/0`, `group_contracts/0`, `variants_for/1`, ~14 families / 8 groups).
- `accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex` — the existing second renderer + drift-test locators to keep green.
- `accrue_admin/lib/accrue_admin/assets.ex` (or the `AccrueAdmin.Assets` controller) — the committed-bundle serving mechanism to reuse for Storybook assets.
- `accrue_admin/mix.exs` — deps + `only: [:dev,:test]` gating + `docs/0` `extras`/`groups_for_extras` + `package.files` allowlist.

### Source guards
- `scripts/ci/verify_package_docs.sh` — the guard host; `require_fixed`/`require_regex` shape to mirror for the 3 new guards AND the spec doc-needles. Pairs with `PackageDocsVerifierTest` `seed_tmp_dir!` (D-08 coupling invariant).

### Brand
- `prompts/accrue-brand-book.md` (gitignored, may be absent locally) — "well-made dev tooling, quiet polish," not fintech; informs the specs' tone. If absent, the in-repo brand book / `accrue_admin/guides/admin_ui.md` carry the same voice.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `FocusTrap` hook (`focus_trap.js`): shipped + solid — the overlay primitive reuses it for focus containment/Escape/restore rather than discarding it for `<dialog>`'s built-ins.
- `detail_drawer.ex` / `step_up_auth_modal.ex`: both already follow the server-driven `:if={@open}` + `phx-mounted`/`phx-remove` shape the body-level-portal primitive extends.
- `ComponentRegistry` (`component_registry.ex`): SSOT with `variants_for/1`/`entries/0`/`group_contracts/0` — `variations/0` for Storybook is an ordinary function, so stories are *generated* from the registry.
- `AccrueAdmin.Assets` committed-bundle serving: reuse for Storybook CSS/JS (the no-Tailwind path).
- Page-flow Playwright driver + helpers (Phase 191): reuse for the new `surface_type:"page-flow"` cells.
- `motion.md`: the proven shipped-guide-with-CI-needle pattern the three specs replicate.

### Established Patterns
- **Source-lint where mechanical, render-detect where compositional** — the 3 new guards mirror the proven FND-01/MOT-01 grep-shaped guard; everything compositional lives in the page-flow rubric cells.
- **`verify_package_docs.sh` ↔ `PackageDocsVerifierTest` coupling** — every new needle must be mirrored into `seed_tmp_dir!` (D-08).
- **Sibling-scope mount, never nested** (Mailglass precedent) + env/`Code.ensure_loaded?` guarding for dev/test-only routes (zero adopter-runtime leak).
- **Custom `ax-*` CSS + committed bundle is SSOT** — editing source CSS ships nothing until rebuilt + committed (a known prior-phase footgun).

### Integration Points
- New `ScrollLock` hook + `#ax-overlay-root` portal target + `inert` toggle wire into the LiveView app shell.
- Storybook sibling scope chains after the existing Mailglass wrap in `router.ex`.
- `surface_type:"page-flow"` cells fold into the unchanged `regressions.ndjson` zero-regression gate.
- Three new guards + three spec doc-needles fold into `verify_package_docs.sh`/CI.

</code_context>

<specifics>
## Specific Ideas

- "One primitive, three presentations" — modal/drawer/popover share one portal + dismissal + scroll-lock contract; Phase 195's action-menu popover must NOT fork a parallel overlay path.
- Specs follow `motion.md` exactly: shipped ExDoc guide + CI needle + enforcement guard.
- The Storybook PoC story is specifically `button` (a simple registry family) — enough to prove the registry→`%Variation{}` pipeline + the three Storybook spikes, nothing more.

</specifics>

<deferred>
## Deferred Ideas

- **Promoting native `<dialog>` to primary overlay** — only revisited per-surface in Phase 199 if the transformed-ancestor audit finds unremovable re-rooting (D-02).
- **Full Storybook story breadth (13 families + 8 group contracts) + both-color-mode theming verification** — Phase 200 (STY-02/STY-03), not this phase (D-14).
- **`--ax-dur-sheet` motion token** — held pending mobile-sheet UAT (Phase 199), must be ≤300ms if introduced; no new motion tokens in 193.
- **View Transitions API for list/stream motion** — candidate spike, explicitly deferred out of v1.54.
- **Empirical loves/hates (HN/Reddit operator-UX pull)** — optional MEDIUM-confidence hardening, not required for the phase.

</deferred>

---

*Phase: 193-research-re-baseline-pattern-lock*
*Context gathered: 2026-06-25*
