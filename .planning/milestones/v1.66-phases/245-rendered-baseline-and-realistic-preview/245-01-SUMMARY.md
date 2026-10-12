---
phase: 245-rendered-baseline-and-realistic-preview
plan: 245-01
subsystem: testing
tags: [fake-processor, preview-seeds, playwright, rendered-evidence, postgres]
requires:
  - phase: 243
    provides: protected preview custody sentinel and snapshot comparison
provides:
  - isolated Fake-only ordinary seed entrypoint and repeatable invoice journey
  - retained mounted invoice list/detail browser capture with source and asset digests
  - documented isolated preview startup, recovery, custody, and teardown
affects: [245-02, rendered-baseline, ordinary-preview]
actuals:
  tokens: 6726
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns:
    - "Guard explicit seed entrypoints with exact Compose project, skip-seed flag, and processor checks."
    - "Bind browser capture manifests to the committed source revision and verify compiled, package, and served asset digests."
key-files:
  created:
    - examples/accrue_host/priv/repo/seeds/helpers.exs
    - examples/accrue_host/priv/repo/seeds/ordinary.exs
    - examples/accrue_host/test/ordinary_preview_seed_test.exs
    - examples/accrue_host/e2e/phase245-admin-baseline.spec.js
    - examples/accrue_host/playwright.phase245.config.js
    - .planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-tracer/invoice-detail.png
    - .planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-tracer/manifest.json
  modified:
    - examples/accrue_host/priv/repo/seeds.exs
    - examples/accrue_host/README.md
key-decisions:
  - "Use the existing linked healthy-account invoice PORTAL-LAUNCH-001 as the tracer; preserve showcase rows without inventing missing billing relationships."
  - "Refresh the evidence manifest after the implementation commit so source_revision and source digests identify committed code."
patterns-established:
  - "Ordinary preview seeds run explicitly after a skip-seeds boot and never invoke the Phase 191 stress aggregator."
  - "Capture artifacts contain fixture identity and digests, with no credentials, cookies, or tokens."
requirements-completed: [DEMO-01, BASE-01, BASE-02]
coverage:
  - id: D1
    description: "An isolated Fake-only ordinary preview seeds one coherent paid invoice journey idempotently and excludes Phase 191 narration."
    requirement: DEMO-01
    verification:
      - kind: unit
        ref: "examples/accrue_host/test/ordinary_preview_seed_test.exs#ordinary seed reruns keep one coherent invoice journey and exclude Phase 191"
        status: pass
      - kind: integration
        ref: "ordinary seed command run twice; database identity/counts stable; Phase 191 event count 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "A mounted Admin invoice list and detail render from the isolated Fake instance, with retained revision-bound PNG and asset provenance."
    requirement: BASE-01
    verification:
      - kind: e2e
        ref: "playwright: examples/accrue_host/e2e/phase245-admin-baseline.spec.js (1 passed)"
        status: pass
      - kind: other
        ref: ".planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-tracer/manifest.json (source, package, compiled, served, and screenshot digests verified)"
        status: pass
    human_judgment: false
  - id: D3
    description: "README documents isolated boot, recovery, custody checks, operator credential source, and instance-only shutdown."
    requirement: BASE-02
    verification:
      - kind: unit
        ref: "README required-token rg check"
        status: pass
    human_judgment: false
metrics:
  duration: 8min
  completed: 2026-10-11
  status: complete
  plan_head_before: 4105e0080e9ade3f845cd60e3aff27dc66ea8700
  plan_head_after: 134dae572004d7f5645d17b2a6dec808c1e37612
  commits: 4
---

# Phase 245 Plan 01: Rendered Baseline and Realistic Preview Summary

**Isolated Fake-backed ordinary preview with a repeatable paid invoice journey and a revision-bound mounted Admin capture.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-11T13:09:00Z
- **Completed:** 2026-10-11T13:17:47Z
- **Tasks:** 2
- **Files modified:** 9 tracked implementation/evidence files, plus this summary

## Accomplishments

- Extracted shared seed helpers unchanged and added a guarded ordinary seed entrypoint that loads the hero, background, and showcase stories without the Phase 191 aggregator. The ordinary paid invoice, customer, and active subscription retain the same IDs across repeated seed runs.
- Captured the signed-in `/admin/invoices` list and invoice detail on the isolated Fake instance. The retained PNG is bound to source revision `c9184ef6`; the manifest records matching package, compiled, and HTTP-served CSS/JS digests, plus route, scenario, viewport, theme, browser, and screenshot digest.
- Documented the exact isolated boot, explicit seed, warm recovery, Phase 243 custody, and instance-specific shutdown commands.

## Task Commits

1. **Task 1: Bootstrap one ordinary invoice journey and capture the mounted route** - `7d6b89a8` (TDD RED assertion)
2. **Task 1: Bootstrap one ordinary invoice journey and capture the mounted route** - `c9184ef6` (implementation and first evidence capture)
3. **Task 1: Refresh evidence provenance after implementation commit** - `b6f913a5` (manifest bound to committed source revision)
4. **Task 2: Document safe ordinary preview startup and recovery** - `134dae57` (documentation and focused data assertions)

**Plan metadata:** summary commit follows this execution report.

## Files Created/Modified

- `examples/accrue_host/priv/repo/seeds/helpers.exs` - extracted shared `AccrueHost.Seeds.Helpers` module.
- `examples/accrue_host/priv/repo/seeds/ordinary.exs` - exact-instance, skip-seeds, and Fake-processor guarded ordinary seed entrypoint.
- `examples/accrue_host/test/ordinary_preview_seed_test.exs` - repeat-seed identity, counts, invoice amounts, ownership, subscription status, and Phase 191 exclusion assertions.
- `examples/accrue_host/e2e/phase245-admin-baseline.spec.js` - authenticated mounted invoice flow, package/compiled/served asset checks, and capture manifest writer.
- `examples/accrue_host/playwright.phase245.config.js` - exact ordinary preview URL and single Chromium project guard.
- `.planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-tracer/` - retained invoice detail PNG and provenance manifest.
- `examples/accrue_host/priv/repo/seeds.exs` - loads extracted helpers before the unchanged default seed list.
- `examples/accrue_host/README.md` - isolated ordinary preview setup and recovery guide.

## Decisions Made

- Used `in_seed_healthy_portal_launch_paid` / `PORTAL-LAUNCH-001`, which has a source-supported link to the healthy demo customer and active subscription. Existing `in_showcase_paid_usd` lacks a `subscription_id`; it remains untouched for Plan 245-02 integrity review rather than receiving an invented relationship.
- Kept the required capture as a committed artifact, then refreshed its manifest in a follow-up commit so provenance points at committed implementation code.

## TDD Gate Compliance

- **RED:** the new seed journey assertion failed before implementation because the ordinary target invoice was absent (1 test, 1 failure).
- **GREEN:** after implementation, `MIX_ENV=test mix test test/ordinary_preview_seed_test.exs` passed (1 test, 0 failures).
- The required browser tracer passed (1 test, 0 failures), the repeated explicit seed command preserved the invoice identity with one row and zero Phase 191 events, and the post-run custody comparison preserved the protected Phase 243 preview.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected ordinary seed file paths after the first focused run**
- **Found during:** Task 1
- **Issue:** The new entrypoint resolved seed paths relative to the repository seed root, but `Code.eval_file` provides the `seeds/` directory as `__DIR__`.
- **Fix:** Resolve `helpers.exs`, `hero_accounts.exs`, `background_data.exs`, and `showcase.exs` directly from that directory.
- **Files modified:** `examples/accrue_host/priv/repo/seeds/ordinary.exs`
- **Verification:** focused ExUnit and two explicit ordinary seed executions passed.
- **Committed in:** `c9184ef6`.

**2. [Plan output] Retained the required capture artifacts and refreshed provenance after commit**
- **Found during:** Task 1
- **Issue:** Capture outputs are required plan evidence but are not listed among the source `files` entries.
- **Fix:** Retain and commit the PNG and manifest; rerun the tracer after implementation commit and commit the refreshed manifest tied to that revision.
- **Files modified:** `.planning/phases/245-rendered-baseline-and-realistic-preview/captures/phase245-tracer/`
- **Verification:** Playwright passed; screenshot SHA-256 and every source digest match; manifest source revision equals `c9184ef6`.
- **Committed in:** `c9184ef6`, `b6f913a5`.

**Total deviations:** 2 (1 auto-fixed bug, 1 required evidence artifact handling).
**Impact on plan:** No feature scope expansion; changes ensure the entrypoint works and provenance accurately names the captured code.

## Issues Encountered

- Browser login was implemented using the existing Phase 243 CSRF/login pattern. The first assertion then found duplicate visible invoice-number text in the list and detail views; selectors were narrowed to the list link and detail heading. The final browser capture passed.
- The existing showcase paid invoice has no linked subscription ID. This is recorded for Plan 245-02 integrity assessment; no relationship was inferred or written.
- `mix test` reports existing Money exchange-rate auto-start and generated operation-ID warnings, plus a benign helper module redefinition warning from evaluating seed helpers in the focused test. The focused test still passes.

## User Setup Required

None. The local demo operator account described in the existing README is used only through the isolated browser test; no external service configuration was needed.

## Next Phase Readiness

Plan 245-02 can inspect the retained source-revision-bound ordinary invoice capture and evaluate the existing showcase row inconsistency. The protected Phase 243 custody sentinel was verified unchanged after ordinary seeding.

## Self-Check: PASSED

- Summary, capture PNG, and capture manifest exist.
- Task commits `7d6b89a8`, `c9184ef6`, `b6f913a5`, and `134dae57` are ancestors of HEAD.

---
*Phase: 245-rendered-baseline-and-realistic-preview*
*Completed: 2026-10-11*
