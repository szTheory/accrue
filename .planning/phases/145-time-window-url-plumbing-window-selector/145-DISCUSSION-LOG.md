# Phase 145: Time-window URL plumbing + window selector - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 145-time-window-url-plumbing-window-selector
**Areas discussed:** Data loading orchestration, Window selector button model, WindowSelector — new component or inline

---

## Data loading orchestration

| Option | Description | Selected |
|--------|-------------|----------|
| A — All data in handle_params | Move Dunning.funnel/1 + Dunning.recovered_vs_lost_mrr/1 calls to handle_params/3; mount/3 becomes pure session setup. Idiomatic LiveView 1.1. | ✓ |
| B — Split mount + handle_params | Keep initial data load in mount/3, re-fetch on window change in handle_params/3 with a change-detection guard. | |

**User's choice:** A — All data in handle_params
**Notes:** User confirmed the recommended option. Research established that handle_params fires before initial render (after mount) in LiveView 1.1, making Option B's change-detection guard redundant complexity.

---

## Window selector button model

| Option | Description | Selected |
|--------|-------------|----------|
| A — `<.link patch>` styled as buttons | Each preset renders as a patch link styled as a button. handle_params fires automatically. Active state from @window assign. URL-first with zero handle_event boilerplate. | ✓ |
| B — handle_event + push_patch | Buttons fire handle_event("set_window"), server calls push_patch. Adds an extra server round-trip but uses real `<button>` elements. | |

**User's choice:** A — `<.link patch>` styled as buttons
**Notes:** This is the first live_patch-style navigation in accrue_admin. Sets the idiom for Phases 146 + 148. Existing Tabs component uses plain `<a href>` — this upgrade to `<.link patch>` is appropriate for within-LiveView URL updates.

---

## WindowSelector — new component or inline

| Option | Description | Selected |
|--------|-------------|----------|
| A — Extract AccrueAdmin.Components.WindowSelector | New Phoenix.Component with current_window + base_path attrs. Used by Phases 146 and 148 as well. One source of truth, consistent with Tabs/KpiCard/FunnelChart pattern. | ✓ |
| B — Inline in RecoveryLive only | Keep the 3 buttons as inline HEEx in RecoveryLive for now. Extract later when Phase 146 needs it. | |

**User's choice:** A — Extract AccrueAdmin.Components.WindowSelector
**Notes:** Rule-of-three threshold pre-met (Phases 145, 146, 148 all need window selector). Extraction cost: 1 file + 2 attrs. Deferred extraction cost: 3 copy-paste sites + mid-milestone refactor.

---

## Claude's Discretion

- Window validation fallback: unknown `?window=` values → default `"30d"`
- `:until` derivation: `DateTime.utc_now()` (rolling window, simplest)
- CSS class names for window selector states (reuse `ax-tab`/`ax-tab-active` or new `ax-window-selector-*`)
- Helper function name for window → `{since, until}` derivation (e.g., `parse_window/1`)
- `@window` assign uses raw string (`"30d"`), not atom, matching URL param directly
- Whether to add `@doc` note on `funnel/1` about legacy-event cutoff semantics (Phase 148 adds the UI badge; Phase 145 may add `@doc` comment)

## Deferred Ideas

None — discussion stayed within Phase 145 scope.
