---
phase: 260620-ps2
plan: 01
subsystem: accrue_admin
status: complete
tags: [admin-ui, design-system, timeline, component-lab, css-bundle]
requires:
  - AccrueAdmin.Components.StatusBadge (shared, unmodified)
  - committed priv/static/accrue_admin.css bundle workflow
provides:
  - Elevated AccrueAdmin.Components.Timeline (rail, ringed nodes, threaded-feed entries, StatusBadge status, semantic <time>, dedicated empty state)
  - timeline-scoped CSS (rail, calmer node, threaded-feed entry, timestamp, empty)
  - "timeline" component-lab family with populated + empty specimens
affects:
  - /admin recent activity, webhook health, webhook attempts, subscription timeline (all render unchanged — zero data-contract changes)
  - /billing/dev/components (new Timeline family)
tech-stack:
  added: []
  patterns:
    - "Shared StatusBadge reuse with tone passthrough so node dot + badge agree"
    - "Timeline-scoped CSS overrides placed AFTER shared grouped selectors; tokens-only"
    - "Rebuild + commit priv/static/accrue_admin.css (admin serves committed bundle, not source app.css)"
key-files:
  created: []
  modified:
    - accrue_admin/lib/accrue_admin/components/timeline.ex
    - accrue_admin/assets/css/app.css
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex
    - accrue_admin/test/accrue_admin/components/display_components_test.exs
    - accrue_admin/priv/static/accrue_admin.css
decisions:
  - "Removed now-unused private humanize/1 from timeline.ex (status humanization is now owned by StatusBadge) to avoid an unused-function warning under --warnings-as-errors"
metrics:
  duration: ~3 min
  completed: 2026-06-20
  tasks: 3
  files: 6
---

# Phase 260620-ps2 Plan 01: Elevate the Timeline component into a proper design-system timeline — Summary

Restyled and enriched `AccrueAdmin.Components.Timeline` into an on-brand threaded-feed timeline — a continuous vertical rail threading calm ringed nodes, status rendered via the shared `StatusBadge` (tone passed through so node dot and badge agree), semantic tabular `<time>` timestamps, and a dedicated calm empty state — plus a registered `timeline` family in the in-app component lab, extended tests, and the rebuilt committed CSS bundle. Zero changes to the item data contract; all 4 call sites render unchanged.

## What was built

### Task 1 — Restyle + enrich the Timeline component (commit 84f93221)
- Added `alias AccrueAdmin.Components.StatusBadge`.
- Replaced the bespoke `ax-timeline-status` span with `<StatusBadge.status_badge :if={...} status={...} tone={tone(item)} />` (kept the `:if` guard for nil-status rows; tone passthrough keeps node dot and badge in agreement).
- Wrapped the timestamp in a semantic `<time class="ax-timeline-time">` (no `datetime` attribute — call-site values are display strings, machine value out of scope).
- Replaced the empty-state borrow `ax-filter-chip-empty` with a dedicated `ax-timeline-empty` block.
- Removed the now-unused private `humanize/1` (status humanization is now owned by StatusBadge) — required to keep `--warnings-as-errors` clean.
- Kept the `<details>`/`<pre>` "Inspect details" inspector, the semantic `<ol>`/`<li>`, and `aria-hidden="true"` dots verbatim.

### Task 2 — Timeline-scoped CSS (commit 03803624)
Added timeline-scoped override rules AFTER the existing `.ax-timeline-*` block (after `.ax-timeline-meta`), without touching the shared grouped selectors (`.ax-kpi-card`/`.ax-timeline-card` border+background group, `.ax-timeline-status` kpi/json group):
- **(a) Rail** — `.ax-timeline-item:not(:last-child)::before`: 1px `var(--ax-border-strong)` line at the node-column center, drawn only between consecutive nodes (never above the first / below the last), `z-index: 0` so the dot paints over it.
- **(b) Node** — shrunk `.ax-timeline-dot` to `0.6875rem` with a `box-shadow: 0 0 0 3px var(--ax-elevated)` surface ring and `z-index: 1`; tone fills untouched.
- **(c) Entry** — borderless, transparent `.ax-timeline-card` with lighter padding (`--ax-space-sm`/`--ax-space-md`), `border-radius: var(--ax-radius-md)`, and a token-based `:hover { background: var(--ax-interactive-hover) }` with `transition: var(--ax-transition-colors)`. Also resolves the card-in-card nesting on the dashboard.
- **(d) Timestamp** — `.ax-timeline-time { font-variant-numeric: tabular-nums; font-size: var(--ax-type-sm); color: var(--ax-muted); }`.
- **(e) Empty** — `.ax-timeline-empty`: centered, muted, comfortable token padding, no border/pill.
- **(f) Dark mode / (g) reduced motion** — chosen tokens (`--ax-border-strong`, `--ax-elevated`, `--ax-interactive-hover`, `--ax-muted`) auto-adapt via theme.css dark overrides; `--ax-transition-colors` already collapses under reduced-motion. No extra explicit overrides needed.

Tokens-only — no hardcoded hex in any timeline rule.

### Task 3 — Component-lab registration, tests, bundle rebuild (commit f6cda082)
- **Registry** (`component_registry.ex`): added `"timeline"` family — `ax_class: "ax-timeline ax-timeline-item"`, the 10 listed tokens, `applicable_states: ["default","hover","empty"]`, `na_states` with per-state reasons, and two specimens (`"Multi-tone feed"`, `"Empty"`).
- **Kitchen** (`component_kitchen_live.ex`): aliased `Timeline`, added `family_label("timeline") -> "Timeline"`, and two `do_render_specimen` clauses — `"empty"` renders `<Timeline.timeline items={[]} />`, default renders a non-empty multi-tone sample (succeeded/retrying/canceled, with a status, timestamp, body, and a details block) so `ax-timeline-item` appears for the render-coverage guardrail.
- **Tests** (`display_components_test.exs`): extended the existing Timeline test with structural assertions (per-item `ax-timeline-item` count == 2, `ax-status-badge` present, `<time`/`ax-timeline-time` present, no `ax-filter-chip-empty`) and added a dedicated empty-state test. All prior assertions kept green.
- **Bundle**: ran `mix accrue_admin.assets.build` to regenerate `priv/static/accrue_admin.css`; the rebuilt bundle contains the rail rule. JS bundle was unchanged (not staged).

## Verification (run from accrue_admin/)
- `mix compile --warnings-as-errors` — clean (no timeline warnings).
- `mix accrue_admin.assets.build` — succeeded ("Rebuilt AccrueAdmin assets in priv/static/").
- 4 named live/component suites: **41 tests, 0 failures**
  (`display_components_test.exs`, `dashboard_live_test.exs`, `webhook_live_test.exs`, `subscription_live_test.exs`).
- Full `accrue_admin` suite: **325 tests, 0 failures** (component-lab render-coverage + axe-a11y guardrails green with the new timeline family).
- Bundle grep: `grep -c ax-timeline priv/static/accrue_admin.css` = **1** (>= 1; the bundle is minified so all timeline rules sit on one line) AND `grep -q 'ax-timeline-item:not(:last-child)' priv/static/accrue_admin.css` → **rail rule present in the BUILT bundle**.
- No hardcoded hex in any timeline CSS rule; shared `.ax-kpi-card` / `.ax-timeline-status` / json-tree grouped selectors unmodified; `StatusBadge` unmodified.

## Repo-hygiene
- Staged ONLY the 6 files actually changed for this task.
- `examples/accrue_host/mix.lock` (pre-existing dirty) and `.planning/research/.cache/` (untracked) were left out of all commits — confirmed absent from HEAD, HEAD~1, HEAD~2.
- `accrue_admin/priv/static/accrue_admin.js` was not modified by the rebuild — not staged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug/warning] Removed now-unused private `humanize/1` from `timeline.ex`**
- **Found during:** Task 1.
- **Issue:** After routing status through `StatusBadge`, `timeline.ex` no longer called its private `humanize/1`, which would trip `mix compile --warnings-as-errors` (unused function).
- **Fix:** Removed the three `humanize/1` clauses. This was explicitly anticipated by the plan ("if and only if it becomes fully unused, remove it"). Verified via grep that nothing else in the module referenced `humanize/1`.
- **Files modified:** accrue_admin/lib/accrue_admin/components/timeline.ex
- **Commit:** 84f93221

## Commits
- 84f93221 — feat(260620-ps2): elevate Timeline component (StatusBadge, &lt;time&gt;, dedicated empty state)
- 03803624 — feat(260620-ps2): add timeline-scoped CSS (rail, calmer ringed node, threaded-feed entry, time, empty)
- f6cda082 — feat(260620-ps2): register timeline component-lab family, extend tests, rebuild CSS bundle

## Known Stubs
None.

## Self-Check: PASSED
- accrue_admin/lib/accrue_admin/components/timeline.ex — FOUND
- accrue_admin/assets/css/app.css — FOUND
- accrue_admin/lib/accrue_admin/dev/component_registry.ex — FOUND
- accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex — FOUND
- accrue_admin/test/accrue_admin/components/display_components_test.exs — FOUND
- accrue_admin/priv/static/accrue_admin.css — FOUND
- Commit 84f93221 — FOUND
- Commit 03803624 — FOUND
- Commit f6cda082 — FOUND
