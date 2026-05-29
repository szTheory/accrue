---
phase: 150-documentation-adopter-proof
plan: 01
subsystem: docs
tags: [dunning, banner, guides, accrue_admin, phoenix_component, adopter-proof]

requires:
  - phase: 149
    provides: "AccrueAdmin.Components.DunningBanner.dunning_banner/1 + Accrue.Dunning.requires_attention?/1"
provides:
  - "guides/dunning.md ## In-App Banners section documenting both integration paths (BAN-03)"
  - "Copy/paste adopter instructions for surfacing dunning state in a Phoenix UI"
affects: [dunning-docs, adopter-onboarding]

tech-stack:
  added: []
  patterns:
    - "Dependency-boundary callout: component in accrue_admin (LiveView-runtime), helper in core accrue"
    - "Scope-bound customer resolution to avoid get-or-create-on-render side effect"

key-files:
  created: []
  modified:
    - "accrue/guides/dunning.md"

key-decisions:
  - "Placed ## In-App Banners between ## Over-email warning and ## Lifecycle and entitlements interaction per D-06"
  - "Documented two subsections: accrue_admin component path (default + inner_block CTA) and core-only DIY path per D-07/D-08"
  - "Used ~p\"/app/billing\" as the example CTA route, matching the example host"
  - "Documented the raw-billable get-or-create Pitfall 1 and scope-bound resolution to mitigate T-150-01/T-150-02"

patterns-established:
  - "Dependency-boundary table + blockquote: which package supplies which surface"

requirements-completed: [BAN-03]

duration: 4min
completed: 2026-05-28
---

# Phase 150 Plan 01: In-App Banners Documentation Summary

**Added a `## In-App Banners` section to `accrue/guides/dunning.md` documenting both the ready-made `accrue_admin` `dunning_banner/1` component (zero-config default + inner_block CTA) and the core-only DIY path via `Accrue.Dunning.requires_attention?/1`, with an explicit package dependency boundary and a cross-link from the over-email warning.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-05-28
- **Completed:** 2026-05-28
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- New `## In-App Banners` section placed correctly between `## Over-email warning` and `## Lifecycle and entitlements interaction`.
- Component path: zero-config default usage with verbatim default copy, plus an `inner_block` "Update your card" CTA linking `~p"/app/billing"`.
- Core-only DIY path: `<%= if Accrue.Dunning.requires_attention?(@customer) do %>` gated markup with the same CTA.
- Explicit dependency-boundary table + blockquote (component in `accrue_admin`; helper in core `accrue`; core stays LiveView-runtime-free).
- Cross-link added from the over-email warning section into `[In-App Banners](#in-app-banners)`.
- Documented the raw-billable get-or-create pitfall and scope-bound resolution (mitigates threat-register T-150-01 tampering and T-150-02 cross-tenant leak).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the In-App Banners guide section with both integration paths** - `29f25d0f` (docs)

## Files Created/Modified
- `accrue/guides/dunning.md` - Added the `## In-App Banners` section (two integration paths, dependency boundary, pitfall callout) and a cross-link from `## Over-email warning`.

## Decisions Made
None beyond the plan's pre-decided D-06/D-07/D-08 — executed as specified. The threat-register mitigations (T-150-01, T-150-02) were folded into the pitfall blockquote and the scope-bound `customer_for_scope/1` resolution example.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. All four pre-existing `verify_package_docs.sh` dunning.md needles (`Accrue.Dunning.Engine`, `Accrue.Integrations.Chimeway`, `dunning: [engine:`) live in the untouched Chimeway section and were verified present after the edit.

## Threat Surface Scan
No new security-relevant surface introduced — this is docs-only. The plan's threat register (T-150-01, T-150-02) was actively mitigated in the snippet guidance; T-150-SC (supply-chain) is N/A (no package installs).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ROADMAP SC#1 satisfied: `guides/dunning.md` now has clear copy/paste instructions for both the component path and the core-only DIY path.
- Ready for the next plan in Phase 150.

## Self-Check: PASSED

- FOUND: accrue/guides/dunning.md
- FOUND: .planning/phases/150-documentation-adopter-proof/150-01-SUMMARY.md
- FOUND commit: 29f25d0f

---
*Phase: 150-documentation-adopter-proof*
*Completed: 2026-05-28*
