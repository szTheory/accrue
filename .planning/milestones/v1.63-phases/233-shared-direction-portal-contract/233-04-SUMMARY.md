---
phase: 233-shared-direction-portal-contract
plan: 04
subsystem: ui
tags: [phoenix-liveview, playwright, admin, portal, visual-baseline]
requires: []
provides:
  - Current route/flow/component/state ownership inventory and rendered baseline for Admin and Portal.
  - Served Admin and Portal CSS/JS body-to-source hash checks in a canonical-host browser test.
  - Shared semantic direction with measurable accessibility targets and package/brand ownership boundaries.
affects: [233-01, 233-06, 233-02, 233-03, 233-07, 233-05, 234, 235, 236, 237, 238, 239]
actuals:
  tokens: 6533
  tasks: 3
  commits: 3
plan_head_before: 1cc8322e7b1528d2a14e2a592b1e89999de7828b
plan_head_after: 594f7a33d411d03c776d9a6b6562e3cac495a9d9
commits: 3
tech-stack:
  added: []
  patterns: [served-asset-body-hash-assertion, package-owned-semantic-role-contract]
key-files:
  created:
    - .planning/phases/233-shared-direction-portal-contract/233-INVENTORY.md
    - .planning/phases/233-shared-direction-portal-contract/233-BASELINE.md
    - .planning/phases/233-shared-direction-portal-contract/DESIGN.md
    - .planning/phases/233-shared-direction-portal-contract/captures/admin-overview.png
    - .planning/phases/233-shared-direction-portal-contract/captures/portal-home.png
    - .planning/phases/233-shared-direction-portal-contract/captures/portal-state.png
    - examples/accrue_host/e2e/phase233-baseline.spec.js
  modified: []
key-decisions:
  - "Share semantic meaning and observable checks while preserving Admin --ax-* and public/core Portal --accrue-* ownership, separate shells, and host customer branding."
  - "Use deterministic canonical-host pages and verify served CSS/JS bytes against current package sources and URL digests."
patterns-established:
  - "Browser baseline tests fetch each referenced hashed CSS/JS asset and compare its body with the checked-out package source."
requirements-completed: [BASE-01, SYS-01, SYS-02]
coverage:
  - id: D1
    description: "Current Admin/Portal routes, flows, component/state ownership, assets, and later-phase owners are inventoried separately from historical render evidence."
    requirement: BASE-01
    verification:
      - kind: other
        ref: "node inline assertion on 233-INVENTORY.md route families and source/historical provenance"
        status: pass
    human_judgment: false
  - id: D2
    description: "Current served Admin and Portal screenshots record routes, fixtures, themes, viewports, source SHA, and matching asset hashes."
    requirement: BASE-01
    verification:
      - kind: automated_ui
        ref: "examples/accrue_host/e2e/phase233-baseline.spec.js#capture current served Admin and Portal baseline with asset provenance"
        status: pass
    human_judgment: false
  - id: D3
    description: "Shared semantic roles and measurable targets preserve distinct Admin and Portal token, shell, and brand ownership."
    requirement: SYS-01
    verification:
      - kind: other
        ref: "node inline assertion on DESIGN.md semantic categories and token namespaces"
        status: pass
      - kind: automated_ui
        ref: "examples/accrue_host/e2e/phase233-baseline.spec.js#capture current served Admin and Portal baseline with asset provenance"
        status: pass
    human_judgment: false
  - id: D4
    description: "Admin identity and host-branded customer Portal remain separate in the documented contract, with no UI dependency or public token rename."
    requirement: SYS-02
    verification:
      - kind: other
        ref: "node inline assertion on DESIGN.md --ax-* and --accrue-* ownership contract"
        status: pass
    human_judgment: false
duration: 25min
completed: 2026-10-07
status: complete
---

# Phase 233 Plan 04: Current Admin and Portal Baseline Summary

**Current-source inventory, served browser captures with exact package asset hashes, and a shared semantic contract that keeps Admin and Portal identity separate.**

## Performance

- **Duration:** 25 minutes
- **Started:** 2026-10-07T18:33:12Z (continuation handoff)
- **Completed:** 2026-10-07T18:58:03Z
- **Tasks:** 3 / 3
- **Files changed for the plan:** 4 source/document files and 3 PNG captures (7 files total)

## Accomplishments

- Verified the committed source inventory precedes the new rendering evidence; route and component ownership remains distinguishable from historical July screenshots and pass counts.
- Built Admin assets and captured a seeded Admin overview, Portal home, and empty-subscriptions Portal state from the canonical host. The Playwright test confirmed the actual served Admin CSS/JS, Portal CSS/JS, and core brand CSS bodies match the current source and their hashed URLs.
- Defined semantic roles and measurable contrast, focus, status, motion, typography, spacing, and 320px reflow targets while retaining the separate `--ax-*` and `--accrue-*` namespaces, shells, assets, and brand responsibilities.

## Task Commits

1. **Task 1: Inventory current routes, flows, components and state ownership** — `03ddfedf8b9935e24ffce695ba70a044852ce70e` (`docs`).
2. **Task 2: Capture representative current served Admin and Portal states** — `c7b1026a` (`test`).
3. **Task 3: Establish semantic direction from observed consumers** — `594f7a33` (`docs`).

The close-out metadata commit is separate from the three task commits.

## Files Created

- `233-INVENTORY.md` — current route, flow, component/state owner, asset owner, and planned follow-up map.
- `233-BASELINE.md` — screenshot provenance, current served asset hashes, viewport/theme/state notes, and verification results.
- `DESIGN.md` — shared semantic direction, observable acceptance targets, token ownership, and phase ownership.
- `captures/admin-overview.png`, `captures/portal-home.png`, `captures/portal-state.png` — inspected current served renders.
- `examples/accrue_host/e2e/phase233-baseline.spec.js` — seeded browser capture and source/served-body hash assertions.

## Decisions Made

- Align semantic roles and quality checks while keeping package-owned tokens, delivery, brand identity, shells, and audience density separate.
- Use the canonical host's deterministic seed and current served package routes; retain no historical image as current-render proof.
- Treat WCAG contrast ratios and 320px reflow as implementation targets, not as a certification claim from these three representative pages.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Established the host Admin organization context in the capture test**
- **Found during:** Task 2
- **Issue:** Navigating directly to the Admin mount before choosing an organization did not establish the context required by the mounted view.
- **Fix:** Reused the canonical fixture's workspace billing path and organization switch control before capturing the Admin overview.
- **Files modified:** `examples/accrue_host/e2e/phase233-baseline.spec.js`
- **Verification:** The canonical-host Playwright test passed and captured the selected Admin organization.
- **Committed in:** `c7b1026a`.

**2. [Rule 1 - Bug] Read both stylesheet href and script src asset URLs**
- **Found during:** Task 2
- **Issue:** The first asset assertion helper read only `href`, so a valid JavaScript `<script src>` produced no URL.
- **Fix:** Resolve either `href` or `src`, then fetch and compare the actual served body with the matching package source.
- **Files modified:** `examples/accrue_host/e2e/phase233-baseline.spec.js`
- **Verification:** The passing Playwright test checked CSS and JS for both Admin and Portal, plus core brand CSS.
- **Committed in:** `c7b1026a`.

**Total deviations:** 3 (2 Rule 1 test fixes, 1 Rule 3 state/roadmap progress adjustment). **Impact:** Required to make the capture exercise real host context and validate every package-owned CSS/JS asset, and to reconcile documented planning progress without marking the phase complete; no dependency or product-source changes.

**3. [Rule 3 - Blocking Issue] Reconciled GSD state/roadmap progress with this repository's artifact format**
- **Found during:** Plan close-out
- **Issue:** `state.update-progress` initially found no body `Progress:` field, and `roadmap.update-plan-progress 233` refused the existing wave-list ROADMAP structure with `missing_phase_details`.
- **Fix:** Added the expected STATE progress line and reran the recalculation; it now reports 0% milestone progress with one of seven plans complete. Checked only the completed `233-04` wave plan item in ROADMAP; Phase 233 remains unchecked because six plans and verification remain.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** `state.update-progress` returned `updated: true`; the plan summary count is 1/7; ROADMAP marks only `233-04-PLAN.md` complete.
- **Committed in:** final plan-metadata commit.

## Issues Encountered

- The existing pinned Tailwind/esbuild build initially could not write to the default npm cache. The build passed using a temporary cache under `/tmp`; package versions and dependency files were unchanged.
- Chromium was initially blocked from launching by sandbox process permissions. The planned Playwright verification passed when run with the necessary process permission.
- The host logged PostgreSQL `too_many_connections` warnings from its Oban notifier at startup; the seeded application still served the tested pages and the browser test passed.
- Baseline scope is representative, not exhaustive: no denied mutation/result state, numeric contrast audit, or 320px screenshot was produced. Those remain explicit route-slice targets in `DESIGN.md`; no pass or certification is claimed for them.

## User Setup Required

None.

## Next Phase Readiness

The later slices have a current source/render reference and a concise semantic target. Phase 234 owns the Admin customer/subscription information hierarchy; Phase 235 owns checkout handoff and secure hooks; Phase 236 owns Portal self-service states and billed-identity presentation. Wider status and integrated route coverage remain with Phases 238–239.

## Self-Check: PASSED

- Inventory, baseline, design, all three PNG captures, and the Playwright spec exist.
- Task commits `03ddfedf8b9935e24ffce695ba70a044852ce70e`, `c7b1026a`, and `594f7a33` are ancestors of the current phase branch tip.
- Plan commit ledger measures three commits from `1cc8322e7b1528d2a14e2a592b1e89999de7828b` through `594f7a33d411d03c776d9a6b6562e3cac495a9d9`.
- Inventory, design token/category assertions, Admin asset build, and the one-test canonical-host Playwright run passed.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*
