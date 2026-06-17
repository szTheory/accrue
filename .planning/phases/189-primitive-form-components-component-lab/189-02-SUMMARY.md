---
phase: 189-primitive-form-components-component-lab
plan: "02"
subsystem: accrue_admin/components
tags: [components, phoenix-component, a11y, aria, form-controls, display-primitives]
dependency_graph:
  requires: []
  provides:
    - AccrueAdmin.Components.Textarea
    - AccrueAdmin.Components.Checkbox
    - AccrueAdmin.Components.Radio
    - AccrueAdmin.Components.Toggle
    - AccrueAdmin.Components.Spinner
    - AccrueAdmin.Components.Tooltip
    - AccrueAdmin.Components.EmptyState
    - AccrueAdmin.Components.InlineId
  affects:
    - accrue_admin/lib/accrue_admin/dev/component_registry.ex (Plan 03 registry entries)
    - accrue_admin/lib/accrue_admin/dev/component_kitchen_live.ex (Plan 03 renderer)
tech_stack:
  added: []
  patterns:
    - Phoenix.Component HEEx with ax-* CSS class convention
    - ARIA APG switch role pattern (role=switch + aria-checked)
    - CSS-driven tooltip (hover + focus-within reveal, no JS)
    - ax-field-inline inline-label pattern for checkbox/radio/toggle
key_files:
  created:
    - accrue_admin/lib/accrue_admin/components/textarea.ex
    - accrue_admin/lib/accrue_admin/components/checkbox.ex
    - accrue_admin/lib/accrue_admin/components/radio.ex
    - accrue_admin/lib/accrue_admin/components/toggle.ex
    - accrue_admin/lib/accrue_admin/components/spinner.ex
    - accrue_admin/lib/accrue_admin/components/tooltip.ex
    - accrue_admin/lib/accrue_admin/components/empty_state.ex
    - accrue_admin/lib/accrue_admin/components/inline_id.ex
  modified: []
decisions:
  - "Textarea error IDs use Enum.with_index to avoid duplicate id attributes (D-08 fix); all errors wrapped in a single <div id={@id <> '-errors'}> referenced by described_by"
  - "Checkbox indeterminate uses data-indeterminate for JS hook pickup + aria-checked=mixed for screen readers"
  - "Toggle uses role=switch + aria-checked on <button type=button>; includes hidden input for form value emission"
  - "InlineId comment placed before the <code> tag (not inside the opening tag) to avoid HEEx tokenizer ParseError"
  - "Spinner uses CSS-animated span (ax-spinner-track) instead of inline SVG — matches existing app.css ax-spinner pattern"
  - "EmptyState aliases AccrueAdmin.Components.Icon directly for the Icon.icon call"
  - "Pre-existing test failures (dashboard_live_test, query_modules_test) are not regressions from this plan"
metrics:
  duration: "3 min"
  completed_date: "2026-06-17"
  tasks: 2
  files: 8
---

# Phase 189 Plan 02: Create 8 Primitive Phoenix.Component Modules — Summary

8 new Phoenix.Component modules created: textarea, checkbox, radio, toggle, spinner, tooltip, empty_state, and inline_id. All compile cleanly, follow the ax-* CSS class convention, and satisfy the a11y contracts from the UI-SPEC (CMP-03).

## Tasks Completed

| Task | Name | Commit | Files Created |
|------|------|--------|---------------|
| 1 | textarea.ex, checkbox.ex, radio.ex, toggle.ex | dacc3c8a | 4 form-control components |
| 2 | spinner.ex, tooltip.ex, empty_state.ex, inline_id.ex | cc9bddf6 | 4 display/utility primitives |

## Key Outcomes

**Task 1 — Form controls:**
- `textarea.ex`: `AccrueAdmin.Components.Textarea` — ax-field wrapper, ax-textarea class, Enum.with_index error IDs (D-08 fix), described_by/3 references a -errors wrapper div
- `checkbox.ex`: `AccrueAdmin.Components.Checkbox` — ax-field-inline, aria-checked=mixed for indeterminate, data-indeterminate for JS hook
- `radio.ex`: `AccrueAdmin.Components.Radio` — ax-field-inline, required value attr, ax-radio class
- `toggle.ex`: `AccrueAdmin.Components.Toggle` — role=switch, aria-checked, hidden input for form value emission, ax-toggle-track/ax-toggle-thumb structure

**Task 2 — Display/utility primitives:**
- `spinner.ex`: `AccrueAdmin.Components.Spinner` — role=status, aria-live=polite, aria-label, CSS-driven animation (no inline SVG)
- `tooltip.ex`: `AccrueAdmin.Components.Tooltip` — CSS hover+focus-within reveal, role=tooltip, ax-tooltip-content at --ax-z-popover layer
- `empty_state.ex`: `AccrueAdmin.Components.EmptyState` — non-interactive ax-empty container, optional actions slot, no phx-click/role=button on wrapper (CMP-03)
- `inline_id.ex`: `AccrueAdmin.Components.InlineId` — ax-inline-id code element, title attr for full text access (CMP-02), structural max-width inline style with CMP-05 exemption comment above style= attribute

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] HEEx comment inside tag attribute position**
- **Found during:** Task 2 — inline_id.ex compilation
- **Issue:** Plan specified placing the CMP-05 exemption comment above the `style=` attribute inside the opening tag, but the HEEx tokenizer (Phoenix.LiveView.Tokenizer) rejects `<%!-- --%>` comments inside tag attribute positions — they must appear between tags
- **Fix:** Moved the exemption comment to a position immediately before the `<code>` opening tag (between HEEx tags), not inside it. The comment still visually precedes the style= attribute when reading the source
- **Files modified:** `accrue_admin/lib/accrue_admin/components/inline_id.ex`
- **Commit:** cc9bddf6

## Known Stubs

None. All 8 components wire real attrs and render real HTML. No placeholder text, no hardcoded empty returns.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All components are pure Phoenix.Component HEEx renderers.

## Test Results

- `mix compile`: clean (zero errors, zero warnings)
- `mix test`: 268 tests, 3 failures — all 3 failures are pre-existing (dashboard_live_test seed-data mismatch, query_modules_test query pattern mismatch). None introduced by this plan's changes.

## Self-Check

- [x] All 8 files exist: textarea.ex, checkbox.ex, radio.ex, toggle.ex, spinner.ex, tooltip.ex, empty_state.ex, inline_id.ex
- [x] Task 1 commit dacc3c8a exists
- [x] Task 2 commit cc9bddf6 exists
- [x] toggle.ex uses role="switch" and aria-checked (CMP-03)
- [x] empty_state.ex has no interactive affordances on container (CMP-03)
- [x] inline_id.ex emits title attr for full-text access (CMP-02) and has structural-constraint comment above style= attribute
