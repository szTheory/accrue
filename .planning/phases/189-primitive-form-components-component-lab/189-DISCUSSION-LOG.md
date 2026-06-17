# Phase 189: Primitive & form components + component lab - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 189-primitive-form-components-component-lab
**Areas discussed:** 189/190 component split, Lab gallery structure, State-matrix scope + verification, Root-fix enforcement (CMP-05)
**Mode:** advisor (minimal_decisive tier — opinionated profile)

---

## 189 / 190 Component Split

| Option | Description | Selected |
|--------|-------------|----------|
| Leaf/atomic primitives + form controls in 189; composites/overlays in 190 | button, input, textarea, checkbox/radio/toggle, select, field wrapper, status_badge, icon, money_formatter, json_viewer, spinner, tooltip, empty-state hero → 189; tables/cards/nav/tabs/pagination/kpi/detail/timeline/drawer/modal/dropdown → 190 | ✓ |

**User's choice:** Recommended split (selected for confirmation; locked).
**Notes:** Overlay components (dropdown_menu, detail_drawer, step_up_auth_modal, flash_group) routed to 190 because they are group/meta surfaces consuming the Phase-188 layer tokens. Defects on primitives originating in group composition: fix the primitive root in 189, route the group manifestation to 190.

---

## Lab Gallery Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Single registry-driven route + declarative state-matrix grid | Extend `/dev/components` + `ComponentRegistry`; add `states`/`specimens` fields; render rows=states × side-by-side light/dark; viewport via existing top-bar controls | ✓ |
| Per-component routes | `/dev/components/:family`, one canvas per component | |

**User's choice:** Single route, registry-driven (advisor-researched, decisive recommendation).
**Notes:** Per-component routes erode registry-as-SSOT and force rewrite of 4 existing drift tests for no functional gain on a non-prod surface. GOTCHA captured: previously-inert per-specimen theme wrappers — new `.ax-dev-state-grid` columns must genuinely re-scope `--ax-*`, and drift test must assert a resolved-color delta. Registry field additions require lockstep test updates.

---

## State-Matrix Scope + Verification

| Option | Description | Selected |
|--------|-------------|----------|
| Extend the Phase-187 manifest-driven harness | `applicable_states` per registry entry; `n/a`-with-reason rows; 3 verification layers (axe + computed-style probes + vision pass); frozen 2 viewports; results keyed to `p187__…` cell-ids | ✓ |
| Add visual-regression / component-test layer | Playwright `toHaveScreenshot` snapshots or experimental-ct mounting | |

**User's choice:** Extend existing harness (advisor-researched, decisive recommendation).
**Notes:** Visual-regression rejected — cross-platform-flaky, semantically blind to WCAG, creates a parallel scoring axis Phase 192 would have to reconcile against the frozen grid. Computed-style assertions are the WCAG-correct way to prove focus-ring geometry, disabled/readonly tokens, contrast, and no-clip. Keep 1440/390 viewports.

---

## Root-Fix Enforcement (CMP-05)

| Option | Description | Selected |
|--------|-------------|----------|
| Component-root fixes only + verifier/negative-fixture guard | Fix in component HEEx + theme.css/app.css tokens; add guard flagging per-page overrides of primitive `ax-*` classes | ✓ |

**User's choice:** Recommended (locked).
**Notes:** Follows the established Phase-188 verifier ↔ negative-fixture coupling pattern; complements existing typography-literal and z-index-literal bans.

---

## Claude's Discretion

- Exact registry schema shape for `states`/`specimens`/`applicable_states`.
- Exact `.ax-dev-state-grid` layout/markup (provided theme columns re-scope `--ax-*`).
- Guard implementation (Elixir test, shell verifier, or both).
- Plan/wave decomposition.

## Deferred Ideas

- Per-component lab routes / Storybook-style canvases — deferred.
- Visual-regression snapshot baselines — deferred/rejected for v1.53.
- Meta-component / group cohesion — Phase 190.
- Page/flow interaction, focus restoration, microcopy, seed stress — Phase 191.
- PhoenixStorybook adoption — deferred across v1.53 (TOOL-01).
