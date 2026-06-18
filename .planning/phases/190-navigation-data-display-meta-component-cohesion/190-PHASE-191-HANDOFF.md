---
phase: 190
handoff_to: 191
source_phase: 187
created: 2026-06-18
status: ready-for-phase-191-planning
---

# Phase 190 to Phase 191 Handoff

Phase 190 built the group contract lab/probe surface for navigation, data display, metadata, and component cohesion. It intentionally did not close overlay interaction behavior, fixture expansion, or broad microcopy work assigned to Phase 191.

Browser probe implementation is present in `accrue_admin/e2e/admin-group-contracts.spec.js`, but local Playwright execution is still blocked before tests by e2e server migration startup returning `{:error, "killed"}`. Phase 191 should rerun the Phase 190 browser suite before treating this handoff as verified runtime evidence.

## Phase 190 Visibility Defects Covered by Lab Probes

These owner_phase `190` rows are visibility/group-contract defects addressed by the lab fixtures and browser probes, not Phase 191 interaction work.

| Surface | AX187 keys | Count | Phase 190 coverage |
|---------|------------|-------|--------------------|
| detail-header/metadata/actions | AX187-001..AX187-770, non-contiguous owner190 set | 245 | Proof roots, named metadata/actions, active state visibility, and responsive overflow checks. |
| table/empty/loading/error/pagination | AX187-335..AX187-339 | 5 | Empty/loading/error, no-pagination, and has-pagination probes. |
| drawer/form | AX187-771..AX187-775 | 5 | Drawer/form group locator and focusable inactive-DOM checks only. |
| KPI/chart/table | AX187-776..AX187-780 | 5 | KPI/chart/table group visibility and reachable recovery action checks. |
| modal-confirm | AX187-781..AX187-785 | 5 | Modal-confirm group locator visibility only. |
| page-header/actions/breadcrumbs | AX187-786..AX187-790 | 5 | Page-header hierarchy, breadcrumbs, and action reachability checks. |
| tabs/subviews | AX187-791..AX187-795 | 5 | Selected tab/window cue visibility checks. |
| toolbar/search/filter/sort | AX187-796..AX187-800 | 5 | Filter, sort, and active search state visibility checks. |

## D-30: focus trap

- **Phase 191 owner:** Overlay/modal/drawer interaction contract.
- **Keys:** overlay_tags: `focus-trap`, related actionability defects AX187-097..AX187-118.
- **Boundary:** Phase 190 checks that inactive table/card DOM is not focusable and that overlay proof roots render. It does not prove modal or drawer focus trap cycling.
- **Phase 191 acceptance target:** Keyboard tab order remains inside active overlays until the overlay is dismissed, with no background focus escape.

## D-30: focus restore

- **Phase 191 owner:** Overlay close and LiveView patch return focus behavior.
- **Keys:** AX187-113, AX187-114, AX187-117, AX187-118; overlay_tags: `focus-restore`.
- **Boundary:** Phase 190 names active controls and verifies visible proof roots. It does not assert focus returns to the opener after close.
- **Phase 191 acceptance target:** Closing drawer/modal/popover returns focus to the invoking control after click, keyboard dismissal, and LiveView patch completion.

## D-30: Escape

- **Phase 191 owner:** Keyboard dismissal for overlays and transient surfaces.
- **Keys:** AX187-117, AX187-118; overlay_tags: `escape`.
- **Boundary:** Phase 190 representative probes avoid Escape/click-outside behavior per D-25.
- **Phase 191 acceptance target:** Escape closes the active overlay, preserves page context, and does not trigger unrelated navigation or form submission.

## D-30: click outside

- **Phase 191 owner:** Pointer dismissal for popovers, menus, drawers, and modal-adjacent surfaces.
- **Keys:** AX187-113, AX187-114; overlay_tags: `click-outside`.
- **Boundary:** Phase 190 only checks that the relevant group surfaces exist and visible actions are reachable.
- **Phase 191 acceptance target:** Outside click dismissal is consistent, does not close protected confirm dialogs unexpectedly, and restores focus to a deterministic target.

## D-30: scroll reachability

- **Phase 191 owner:** Long overlay/page-flow scroll behavior.
- **Keys:** AX187-436, AX187-437, AX187-438, AX187-439, AX187-446, AX187-447; overlay_tags: `scroll-reachability`.
- **Boundary:** Phase 190 checks long-content lab specimens for off-screen actions at 320, 375, 768, 1024, and 1440 widths. It does not prove every live long overlay flow.
- **Phase 191 acceptance target:** Primary and recovery actions remain reachable in long overlays and dense page flows without hidden fixed-footer or clipping failures.

## D-30: overlay position

- **Phase 191 owner:** Layer positioning, stacking, and viewport clipping.
- **Keys:** AX187-102, AX187-103, AX187-111, AX187-112; overlay_tags: `overlay-position`, `layer-z-index`.
- **Boundary:** Phase 190 verifies group visibility and avoids a second visual-regression axis. It does not certify overlay placement across all trigger positions.
- **Phase 191 acceptance target:** Overlays remain attached to their trigger or intended viewport region at mobile and desktop widths without clipping actionable content.

## D-30: LiveView patch focus

- **Phase 191 owner:** LiveView navigation/patch focus management.
- **Keys:** AX187-116; overlay_tags: `live_focus`.
- **Boundary:** Phase 190 representative probes sample live routes for group drift, not focus after patch.
- **Phase 191 acceptance target:** LiveView patches set focus to the correct heading, alert, or retained control without dumping focus to the document body.

## D-30: fixture gaps

- **Phase 191 owner:** Fixture completeness for overlay and page-flow edge cases.
- **Keys:** AX187-116, AX187-442, AX187-443, AX187-444, AX187-445; overlay_tags: `fixture-gap`.
- **Boundary:** Phase 190 does not expand the Phase 187 fixture matrix and keeps representative live probes narrow per D-07.
- **Phase 191 acceptance target:** Add the minimum fixture states needed to prove focus, dismissal, scroll, permission, disconnected/reconnecting, and error-copy behavior.

## D-30: microcopy

- **Phase 191 owner:** Broad user-facing copy quality, especially overlay/page-flow guidance and recovery text.
- **Keys:** AX187-012, AX187-024, AX187-036, AX187-048, AX187-060, AX187-072, AX187-084, AX187-096, AX187-130..AX187-770 sampled non-contiguous microcopy set; overlay-specific AX187-440, AX187-441, AX187-442, AX187-443.
- **Boundary:** Phase 190 checks named state cues and visible labels needed for group contracts. It does not claim broad microcopy completion.
- **Phase 191 acceptance target:** Empty/error/recovery and overlay guidance text is specific, actionable, and consistent across the representative page-flow matrix.

## Phase 191 Starting Checks

1. Rerun `cd accrue_admin && npm run e2e -- e2e/admin-group-contracts.spec.js` after local test database capacity is healthy.
2. Build Phase 191 tests from the D-30 categories above without marking Phase 190 visibility rows incomplete.
3. Keep generated traces/screenshots under ignored Playwright output paths; cite AX187 IDs and overlay tags in committed planning artifacts.
