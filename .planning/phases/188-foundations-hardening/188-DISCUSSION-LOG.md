# Phase 188: Foundations hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-15
**Phase:** 188-foundations-hardening
**Areas discussed:** Typography Bundle Contract, Layer Stack Contract, Tailwind SSOT Resolution, Semantic Role Completion

---

## Typography Bundle Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Atomic tokens only | Keep current `--ax-type-*`, `--ax-leading-*`, and `--ax-tracking-*` atoms. Lowest churn, but preserves per-property soup and fails FND-01's composed-bundle intent. | |
| DTCG-style composed role tokens plus role classes | Add `--ax-type-{role}-font` and `--ax-type-{role}-tracking` roles, keep atoms as internals, migrate classes to roles, and enforce no raw type literals after migration. | yes |
| Component-local typography bundles | Let each component own its type bundle. Smaller global vocabulary, but duplicates semantics and weakens cross-surface hierarchy. | |
| Tailwind text utility preset | Use Tailwind utilities/preset for type. Familiar but conflicts with no-Tailwind-migration and splits the SSOT. | |
| Generated token pipeline | Full DTCG-style generated type tokens. Strong long-term tooling, but too much build/dependency surface for Phase 188. | |

**User's choice:** The user asked to consider all areas with subagent-backed research and produce one cohesive recommendation set so they do not have to choose. The researched recommendation is selected.

**Notes:** Role tokens should use semantic names: `body`, `body-sm`, `body-relaxed`, `label`, `label-sm`, `eyebrow`, `title`, `title-lg`, `heading`, `display`, `metric`, `code`, `code-xs`. Strict migration follows the root pass, with documented allowlists only.

---

## Layer Stack Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Accrue semantic layer tokens | Publish `base/sticky/dropdown/popover/drawer/modal/toast` tokens with 100-point gaps and migrate all overlay/sticky CSS to them. | yes |
| Keep compact partial scale | Add missing names around current `10/20/30/40` values. Lowest churn, but keeps ambiguous old semantics alive. | |
| Bootstrap-style scale | Borrow large Bootstrap z-index values. Battle-tested, but imports another framework's component assumptions. | |
| Portal/root-overlay host contract plus tokens | Strongest defense against stacking-context traps, but larger architectural scope than FND-02 alone. | |
| Strict no-literal enforcement | Enforce tokens and allow only documented micro-stacking exceptions. Complements the selected semantic layer approach. | yes |

**User's choice:** The researched recommendation is selected: semantic layer tokens plus strict enforcement.

**Notes:** Exact tokens: `--ax-z-base: 0`, `--ax-z-sticky: 100`, `--ax-z-dropdown: 200`, `--ax-z-popover: 300`, `--ax-z-drawer: 400`, `--ax-z-modal: 500`, `--ax-z-toast: 600`. A temporary `--ax-z-topbar` alias is allowed only as deprecated migration compatibility.

---

## Tailwind SSOT Resolution

| Option | Description | Selected |
|--------|-------------|----------|
| Remove config/preset, keep Tailwind CLI as compiler/minifier | Delete `tailwind.config.js` and `tailwind_preset.js`, remove `--config`, keep `tailwindcss@3.4.17` only as package-local CSS build tooling. | yes |
| Keep config/preset as reference-only | Lowest churn, but file existence keeps implying Tailwind utilities are an authoring path. | |
| Replace Tailwind CLI with neutral bundler/minifier | Strongest "no Tailwind" signal, but introduces a new build-tool decision and unnecessary asset drift risk. | |

**User's choice:** The researched recommendation is selected.

**Notes:** Advisor verified no-config Tailwind CLI output as byte-identical to the current committed bundle. Phase 188 should not replace the compiler; it should delete the ambiguous config/preset and update docs/tests.

---

## Semantic Role Completion

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal selector patch | Small diff for visible bugs, but keeps state semantics scattered and dark/system parity fragile. | |
| Complete local semantic role layer | Add role tokens for focus, scrollbar, disabled/read-only, interactive states, and statuses in light/dark/system; migrate selectors to roles. | yes |
| Adopt external taxonomy by reference | Use Primer/Polaris/Radix/GOV.UK naming ideas. Useful precedent, but direct names may not fit Accrue. | |
| Import external token/color package | Mature values but adds dependency/build concerns and violates admin `ax-*` SSOT spirit. | |

**User's choice:** The researched recommendation is selected: local semantic role layer, borrowing discipline from mature systems but not importing them.

**Notes:** Required roles include focus, scrollbar, disabled/read-only, interactive hover/active/selected, and status pairs for success/warning/danger/info/neutral. Focus must be a visible 2px-ish `:focus-visible` indicator with offset/halo; disabled custom controls must lose activation and hover/active affordance.

---

## the agent's Discretion

- Exact token block placement and ordering in `theme.css`.
- Exact guard implementation, as long as it enforces the locked invariants and follows the guard plus negative-fixture pattern.
- Whether to keep a temporary deprecated `--ax-z-topbar` alias during migration.
- Exact component-lab presentation of foundation specimens.

## Deferred Ideas

- Full Tailwind CLI replacement with another bundler/minifier.
- Broad root overlay portal architecture unless a Phase 188 root stacking issue forces it.
- Importing external token packages.
- PhoenixStorybook adoption.
