# Phase 174: A — Design-System Gap Closure & Token Completeness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-03
**Phase:** 174-a-design-system-gap-closure-token-completeness
**Areas discussed:** Breakpoint tokenization, Type micro-token taxonomy, Transition bundles, /dev/components reference
**Mode:** advisor (calibration tier `minimal_decisive` — opinionated user); 4 parallel research agents, then a synthesized cohesive package locked in one shot.

---

## Breakpoint tokenization

| Option | Description | Selected |
|--------|-------------|----------|
| Documented `--ax-bp-*` constants block + grep-guard | Centralized commented registry in app.css; inline token comment beside every @media; enforced by existing token-bypass guard. Zero build change. | ✓ |
| PostCSS `@custom-media` | True `@media (--ax-bp-md)` token indirection; requires a new PostCSS pipeline + plugin (Tailwind v3 CLI doesn't expose custom-media; native @custom-media not Baseline). | |
| Tailwind `@screen` / `theme.screens` | Reuses existing Tailwind CLI but relocates breakpoints to JS config; `@screen` was removed in Tailwind v4 (dead-end). | |

**User's choice:** Documented constants block + grep-guard (decisive recommendation accepted).
**Notes:** Names `--ax-bp-sm`(600)/`-md`(768)/`-lg`(1024); rename 640px → `--ax-bp-content` (below 768, breaks monotonic ordering — it's a content step not a layout tier). New guard needle must go in both the guard script and its negative-test seed fixture. 600/640 reconciliation deferred to Phase C. No layout behavior change in this phase.

---

## Type micro-token taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Semantic names (`--ax-leading-*`, `--ax-tracking-*`, `--ax-measure`) | Tailwind-style role-driven names; coherent with existing semantic motion tokens; unitless line-height, em tracking, ch measure. | ✓ |
| Numeric t-shirt (`--ax-leading-xs…lg`) | Mirrors the `--ax-type-*` scale but the values are discrete roles, not a perceptual ramp — reintroduces the "pick a rung" guess. | |
| Abbreviated (`--ax-lh-*`, `--ax-ls-*`) | Shortest to type but cryptic, poor grep-ability, no ecosystem precedent. | |

**User's choice:** Semantic naming (decisive recommendation accepted).
**Notes:** 1:1 literal→token rename, zero visual change. Keep body at 1.4 (not forced to 1.5 — WCAG 1.4.12 is about user override, not default); `relaxed` 1.5 reserved for prose. Keep both `wide`(0.04em) and `caps`(0.08em) tracking tokens. `--ax-measure: 68ch` + `.ax-measure` utility is the only net-new token.

---

## Transition bundles

| Option | Description | Selected |
|--------|-------------|----------|
| Property-bundles (`--ax-transition-colors/-transform/-shadow/-base`) | Full multi-property transition values; collapses the ~5 multi-line blocks to one token each; composed from existing atoms. | ✓ |
| Timing-only bundles (extend `--ax-motion-*`) | Maximally composable but does NOT collapse multi-line declarations — fails the phase goal. | |
| `--ax-transition-all` (`transition: all`) | Shortest authoring; `all` is a perf/footgun antipattern. | |

**User's choice:** Property-bundles (decisive recommendation accepted).
**Notes:** Ship exactly 4, composed from dur/ease atoms, enter-neutral (ease-out), no `-all`. Use `background-color` not `background` shorthand (protects skeleton shimmer's background-position). New `--ax-transition-*` family; freeze legacy `--ax-motion-*` (don't extend — two families = confusion). Reduced-motion override at token level via `--ax-dur-instant`. Exit-asymmetry deferred to Phase D.

---

## /dev/components reference

| Option | Description | Selected |
|--------|-------------|----------|
| Hand-rolled LiveView gallery, 4 families, registry-driven, light+dark, drift-tested | Extends existing component_kitchen_live.ex; curated ComponentRegistry drives page + drift test; both themes side-by-side. Zero deps. | ✓ |
| `phoenix_storybook` dep | Purpose-built but violates "no heavy deps" guardrail; `.story.exs` becomes a second drifting source of truth. | |
| Full `Phoenix.Component` attr reflection | Can't drift in principle, but components don't declare `attr values:` yet — a refactor in disguise. | |
| Exhaustive mirror of all ~12 components | "Complete" but gold-plates a dev page (anti-churn violation) and invites style-guide rot. | |

**User's choice:** Hand-rolled registry-driven gallery scoped to button/badge/status/card (decisive recommendation accepted).
**Notes:** Token-mapping row = live swatch + copy-paste `ax-*` class + `--ax-*` tokens via `<dl>`. Render both light+dark via `data-ax-theme` wrappers. Drift test asserts every registry variant renders + matches the component's class truth. Wire into Phase F Playwright sweep as an anchor shot. Optional: add `attr :variant, values:` to components while DSY-01 has them open.

---

## Claude's Discretion

- Scope of hex/inline-style cleanup: target render-path bypasses (`dunning_banner.ex:27` inline style with hex fallbacks; residual invoice inline styles) — NOT the legitimate runtime brand-config defaults (`accent_hex` across `*_live.ex`, `layouts.ex`, `brand_plug.ex`) or favicon SVG hex, which are host-overridable Elixir-layer branding, not CSS token bypasses.
- Exact placement/ordering of new token blocks in theme.css, `.ax-measure` consumption sites, and CSS section ordering.
- Whether to fold the optional `attr :variant, values:` normalization into this phase (ship registry-list version regardless).

## Deferred Ideas

- Reconcile 600px/640px breakpoint proximity → Phase C (mobile-first rewrite).
- Exit-asymmetry / deep motion semantics → Phase D (Motion).
- `attr :variant, values:` normalization for automatic drift protection → optional now / later DX win.
- Adding `/dev/components` to the screenshot sweep → logically Phase F (built screenshot-ready here).
