---
phase: "252"
plan: "05"
subsystem: ui
tags: [phoenix-storybook, phoenix-liveview, subscriptions, coverage]

requires:
  - phase: "252-02"
    provides: Compiled production-backed subscription story and scenario attribution.
provides:
  - Stable manifest generated from compiled subscription variation declarations.
  - Keyed production caller map with registry, route, and source evidence.
  - Generated Admin and Portal subscription composition coverage guide.
affects: ["252-06", "252-07", "253", "254"]

actuals:
  tokens: 20043
  tasks: 2
  commits: 5
  plan_head_before: ae6599df7ec94fe686c98585d49fd838dfe96337
  plan_head_after: b5505854f80685ac162f8db67d1adcdd4b41b446

tech-stack:
  added: []
  patterns:
    - DB-free ExUnit script for compiled Storybook discovery and current-source coverage.
    - Stable caller identity combines label, owner, source path, tier, and disposition.

key-files:
  created:
    - storybook/phase252-manifest.json
    - guides/subscription-story-coverage.md
    - .planning/phases/252-production-backed-subscription-stories/252-05-01-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-05-01-freshness-red-evidence.json
    - .planning/phases/252-production-backed-subscription-stories/252-05-02-red-evidence.json
  modified:
    - accrue_admin/storybook/_support/subscription_manifest.ex
    - accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs
    - accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs

key-decisions:
  - "Build the caller ledger from compiled declarations, validated source markers, actual router routes, and ComponentRegistry contracts so missing links fail closed."
  - "Keep static-render reachability separate from browser DOM proof and mounted Admin or Portal behavior; those remain visible gaps for their owning plans."

patterns-established:
  - "Production caller rows require source evidence and a reason for uncovered or not-applicable dispositions."
  - "Generated subscription artifacts bind to SHA-256 digests of every consumed Admin and Portal source file."

requirements-completed: [SBK-01, SBK-02]
status: complete
coverage:
  - id: D1
    description: Compiled subscription variations receive stable keyed entries, direct routes, attribution, factual expectations, and source digests.
    requirement: SBK-01
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs#compiled subscription story discovers each real retained variation with stable routes and source digests"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs#grouped and same-ID declarations keep path and group identity in stable keys and routes"
        status: pass
    human_judgment: false
  - id: D2
    description: Production composition and caller evidence identifies reachable, uncovered, and reasoned not-applicable Admin and Portal jobs.
    requirement: SBK-02
    verification:
      - kind: unit
        ref: "MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs#current caller map reconciles production sources, registry contracts, manifest links, and explicit gaps"
        status: pass
      - kind: unit
        ref: "MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs#subscription composition coverage reconciles registry families, group identity, and manifest links"
        status: pass
    human_judgment: false

metrics:
  duration: 15min
  completed: 2026-10-26
  status: complete
---

# Phase 252 Plan 05: Compiled Subscription Manifest and Caller Coverage Summary

**Compiled Storybook variation discovery now produces stable subscription routes and a source-backed Admin/Portal caller map with explicit coverage gaps.**

## Performance

- **Duration:** 15 min from the first preserved plan commit through Task 2 completion. The initial read interval was not retained across the context handoff.
- **Started:** 2026-10-26T20:53:47-04:00 (first preserved RED commit)
- **Completed:** 2026-10-26T21:08:38-04:00
- **Tasks:** 2
- **Files changed:** 8 across task commits

## Accomplishments

- Generated six manifest entries from compiled PhoenixStorybook declarations, including three source-supported compatibility IDs. Each entry retains a stable path/group/variation key, direct route, actor/job/source attribution, production owner, expected facts, and source digests.
- Added deterministic caller-map normalization with empty and duplicate rejection, stable ordering, and identity keys that preserve equal labels from different owners or tiers.
- Generated the composition ledger from source call sites, Admin and Portal routes, the compiled manifest, and live ComponentRegistry data. It marks the shared Admin area and action band reachable, and names the uncovered group contract, Admin full page/list/action journey, and Portal list/detail/action jobs.
- Kept mounted authority, provider completion, persistence, and action success explicitly outside the static-render proof lane.

## Verification Evidence

- `cd accrue_admin && MIX_ENV=test mix run --no-start test/accrue_admin/dev/subscription_manifest_test.exs` — **10/10 TAP tests passed**. This self-starting script does not load the database test helper or Repo.
- `mix format --check-formatted` for the support module and two test files — passed.
- `git diff --check` — passed.
- Task 1 and Task 2 RED reports were accepted by `gsd_run check tdd-red-evidence` as `RED_EVIDENCE_OK`; the planned behavior assertions failed before their corresponding implementations.
- Browser DOM, mounted authorization, provider completion, and persistence are not asserted by this plan; browser verification remains in 252-06 and broader journeys remain in Phase 253.

## Task Commits

1. **Task 1 RED:** `9ca22509` — specify compiled subscription manifest discovery.
2. **Task 1 RED extension:** `cff757ab` — require generated source freshness validation.
3. **Task 1 GREEN:** `aa92dd9e` — generate compiled subscription story manifest.
4. **Task 2 RED:** `032097fa` — specify production caller coverage map.
5. **Task 2 GREEN:** `b5505854` — generate subscription caller coverage map.

**Plan metadata:** Summary, state, roadmap, and requirement updates are committed after this task summary.

## Files Created/Modified

- `accrue_admin/storybook/_support/subscription_manifest.ex` — compiled variation discovery, source hashing, caller-map normalization, and generated guide output.
- `accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs` — DB-free manifest, freshness, caller identity, and coverage contracts.
- `accrue_admin/test/accrue_admin/dev/storybook_coverage_test.exs` — registry-family and group-contract reconciliation for the subscription map.
- `storybook/phase252-manifest.json` — generated manifest bound to the selected Admin/Portal source set.
- `guides/subscription-story-coverage.md` — generated composition chain, direct story routes, production evidence, and remaining jobs.
- `.planning/phases/252-production-backed-subscription-stories/252-05-01-red-evidence.json`, `.planning/phases/252-production-backed-subscription-stories/252-05-01-freshness-red-evidence.json`, and `.planning/phases/252-production-backed-subscription-stories/252-05-02-red-evidence.json` — machine-accepted pre-implementation reports.

## Decisions Made

- Use the compiled Storybook tree for declared variation identity and direct routes; use checked source markers and router declarations for current production callers.
- Treat `detail-header-metadata-actions` as an existing registry contract that the selected story does not cover, rather than implying the area-only story proves the full group or page.
- Keep Portal subscription jobs visible in this guide while leaving their implementation and broader action journeys to later planning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Made the standalone scenario checks initialize their required locale runtime.**
- **Found during:** Task 1 (compiled manifest discovery)
- **Issue:** The DB-free `mix run --no-start` script validates localized production scenarios but the locale application is not started by that command.
- **Fix:** The script starts Localize itself and restores the prior environment settings; the compiled story module is loaded before checking its exported variation function.
- **Files modified:** `accrue_admin/test/accrue_admin/dev/subscription_manifest_test.exs`, `accrue_admin/storybook/_support/subscription_manifest.ex`
- **Verification:** The planned DB-free test command passed after the fix.
- **Committed in:** `aa92dd9e`

**2. [Rule 1 - Bug] Corrected caller evidence matching and metadata normalization.**
- **Found during:** Task 2 (production caller coverage)
- **Issue:** Several story declarations span lines, and the first implementation did not carry the registry proof identifier into the normalized group row or name the whole-page gap as asserted.
- **Fix:** Match a stable variation ID token across formatted source lines, retain registry proof metadata, and state the whole-page gap explicitly.
- **Files modified:** `accrue_admin/storybook/_support/subscription_manifest.ex`
- **Verification:** The final DB-free suite passed all 10 tests, including source, registry, and gap reconciliation.
- **Committed in:** `b5505854`

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 3 blocking setup issue).
**Impact on plan:** Both fixes enabled the planned DB-free verification and accurate coverage reporting; scope stayed within the planned artifacts.

## Issues Encountered

- An initial identity assertion conflated the internal subscription UUID with the processor subscription ID. The assertion was corrected to verify both separately before the Task 1 GREEN commit.
- No unresolved issues or unrun plan verifications remain.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 252-06 can use the generated manifest to verify rendered DOM against each direct variation route.
- Phase 253 retains the uncovered Admin page/list/mounted-action work. Portal list, detail, and mounted-action jobs are recorded for later coverage planning.
- Static stories remain evidence of settled presentation only; they do not establish mounted authority, provider completion, persistence, or action success.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- All five task commits are ancestors of the current plan branch HEAD.

---
*Phase: 252-production-backed-subscription-stories*
*Completed: 2026-10-26*
