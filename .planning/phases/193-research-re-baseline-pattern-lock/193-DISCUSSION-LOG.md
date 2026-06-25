# Phase 193: Research, re-baseline & pattern lock - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-25
**Phase:** 193-research-re-baseline-pattern-lock
**Areas discussed:** Overlay primitive direction, Pattern-spec home & durability, Pattern-spec rigor, Storybook Phase-193 footprint

> **Method:** User selected all four gray areas and asked for deep parallel research (one advisor subagent per area) covering pros/cons/tradeoffs, idiomatic Elixir/Phoenix/LiveView patterns, lessons from comparable libs/design systems, DX/UX, and brand/vision coherence — then a one-shot cohesive recommendation set. Each option below was resolved by research, not a manual A/B pick.

---

## Overlay primitive direction

| Option | Description | Selected |
|--------|-------------|----------|
| A) Body-level portal (reuse FocusTrap + z-scale + ScrollLock + inert) | JS hook portals to `#ax-overlay-root`; one primitive, three presentations | ✓ (PRIMARY) |
| B) Native `<dialog showModal()>` + top-layer | Structurally stacking-immune, but fights LiveView morphdom on the `open` attr | ✓ (FALLBACK, per-surface, only if Phase-199 audit demands) |
| C) Hold both genuinely open (spike decides, no default) | No pre-committed direction | rejected as default posture |

**User's choice:** A primary / B documented fallback (research recommendation, accepted).
**Notes:** Decisive factor = **LiveView fit, not browser support**. `<dialog>`'s imperative `open` attribute fights morphdom (needs `JS.ignore_attributes("open")` + a bridge hook) vs the server-driven `:if={@open}` model both shipped shells already use. `<dialog>`'s "free" a11y wins are already shipped in `FocusTrap`; its one unsolved problem (iOS scroll-lock) isn't solved by `<dialog>` and must be built either way. Phase-193 spike must still prove 4 things via Playwright hit-test (scrim hit-testability, portal survives `phx-update`, scroll-lock with no gutter jump, transformed-ancestor probe). Swap-seam kept clean so 199 can flip individual surfaces to B.

---

## Pattern-spec home & durability

| Option | Description | Selected |
|--------|-------------|----------|
| A) Durable shipped ExDoc guides in `accrue_admin/guides/` | Adopter-visible on HexDocs; mirrors `motion.md` precedent | ✓ |
| B) Planning-internal `.planning/` docs | Invisible to adopters; rots on milestone regen | |
| C) Hybrid (shipped language + planning detail) | Folded into A: guide carries prose + documented checklist | (partial — see rigor) |

**User's choice:** A (ship as ExDoc guides), accepted.
**Notes:** Audience is three-way (build agents 194–200, maintainer, fork/extend adopters) — only a shipped home serves all three. Wire exactly like `motion.md`: `mix.exs` extras + groups_for_extras + package files + `verify_package_docs.sh` `require_fixed` needles, mirrored into `PackageDocsVerifierTest` `seed_tmp_dir!` (the known coupling footgun).

---

## Pattern-spec rigor

| Option | Description | Selected |
|--------|-------------|----------|
| A) Machine-gradable contracts only | Unambiguous + auto-verified, but Goodhart/soulless risk | |
| B) Prose design guidelines only | Captures taste, but re-litigates 18 pages, reviewer-dependent | |
| C) Layered (prose intent + per-archetype machine-checkable invariant checklist) | Best DX; mirrors the repo's existing layered enforcement machine | ✓ |

**User's choice:** C (layered), accepted.
**Notes:** "Machine-gradable vs judge-graded" is a line to *draw*, not a choice to invent — the page-flow driver already exposes discrete assertions, the 12-dim rubric already handles taste, and source-guards are grep-shaped. The line: machine-assert only what the driver/guards/axe decide deterministically; taste stays prose for the adversarial judge. Concrete per-archetype invariant lists captured in CONTEXT D-11. Coheres with the shipped-guide home: prose = adopter-facing language, checklist = documented acceptance criteria (GOV.UK-style), enforcement = the test machinery (not a forever machine-API promise).

---

## Storybook Phase-193 footprint

| Option | Description | Selected |
|--------|-------------|----------|
| A) Minimal scaffold (dep + guarded mount + asset serving + ONE PoC story) | Walking skeleton; de-risks foundation without front-loading | ✓ |
| B) Full registry generator now (all families + groups) | Over-builds the phase blocking five others; generator-rot risk | |
| C) Spike-only (throwaway proofs, generator at 200) | Re-incurs integration risk at milestone end | |

**User's choice:** A (minimal scaffold / walking skeleton), accepted.
**Notes:** 193 is a strictly-linear foundation phase. Prove the riskiest end-to-end path (registry→`%Variation{}`→leak-proof mount→shipped `ax-*` bundle renders) with ONE `button` story + a host-absence compile test; defer the 13 families + 8 group contracts + both-color-mode verification to Phase 200 (STY-02/STY-03). The `Code.ensure_loaded?(PhoenixStorybook.Router)` guard is mandatory (compile-time router dependency would fail a host `:dev` compile with the dep absent). Registry stays SSOT; the `/dev/components` kitchen + drift tests stay untouched.

## Claude's Discretion

- Baseline storage: additive sibling `baseline.page-flow.cells.json` (research-default; planner finalizes exact path).
- The three non-overlay Phase-193 spikes (`data-theme` dark-shim, `inert` vs `aria-hidden` floor, no-Tailwind asset serving) resolved as part of standing up the single PoC story, each with a recorded decision per RES-03.

## Deferred Ideas

- Native `<dialog>` as primary — revisited per-surface only in Phase 199 if the transformed-ancestor audit finds unremovable re-rooting.
- Full Storybook story breadth + theming verification → Phase 200.
- `--ax-dur-sheet` token (≤300ms) → held pending Phase-199 mobile-sheet UAT.
- View Transitions API → deferred out of v1.54.
- Empirical operator-UX loves/hates (HN/Reddit) → optional, not required.
