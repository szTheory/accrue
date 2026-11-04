---
phase: 253-real-groups-and-a-whole-subscription-job
plan: "05"
subsystem: testing
tags: [storybook, phoenix-liveview, playwright, responsive-ui, transparency]

# Dependency graph
requires:
  - phase: 253-02
    provides: Production-backed subscriptions collection and scoped row navigation
  - phase: 253-03
    provides: Whole-page subscription scenarios rendered through production components
  - phase: 253-04
    provides: Mounted journey, authorization, effects, and validated-return assertions
provides:
  - Per-cell responsive browser evidence for ten collection states and nine page scenarios
  - Production-owned page-boundary cursor fixture and browser load-more coverage
  - Bounded current/injected presentation and synthetic-attribution controls
affects: [253-06, storybook, subscription-ui, verification]

# Measured from the plan commit ledger at summary authoring time.
commits: 5
plan_head_before: 553edeff97b6f953460a045f789cfb1ba8de059f
plan_head_after: 7665b3a56aa558baedd978da4bfec0ef39dce72d

# Actuals (#2632): measured realized diff is 432887 chars / 4.
actuals:
  tokens: 108222
  tasks: 3
  commits: 5

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Record each browser cell with run, manifest, source, served-asset, and executed-test identity
    - Apply bounded public-claim checks to current sources and injected subjects through the same assertion
    - Keep story-render evidence explicitly presentation-only

key-files:
  created:
    - accrue_admin/e2e/phase253-composition-helpers.js
    - scripts/ci/verify_phase253_presentation.test.mjs
    - scripts/ci/fixtures/phase253-transparency/clean.json
    - scripts/ci/fixtures/phase253-transparency/presentation-violation.json
    - scripts/ci/fixtures/phase253-transparency/attribution-violation.json
  modified:
    - accrue_admin/e2e/subscription-compositions-phase253.spec.js
    - accrue_admin/assets/css/app.css
    - accrue_admin/priv/static/accrue_admin.css
    - accrue_admin/priv/static/storybook.css
    - accrue_admin/storybook/_support/subscription_collection.ex
    - accrue_admin/storybook/_support/subscription_compositions_manifest.ex
    - accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs
    - accrue_admin/test/accrue_admin/dev/subscription_page_slice_test.exs
    - scripts/ci/verify_phase252_transparency.mjs
    - storybook/pages/subscription.story.exs
    - storybook/phase252-manifest.json

key-decisions:
  - "Keep the page-boundary fixture's one-row limit inside the deterministic story adapter and continue using Behaviour.paginate for cursor generation."
  - "Use supported PhoenixStorybook navigation tabs and a story-only LiveComponent/overlay adapter while preserving the production page markup."
  - "Refresh Phase252 source digests from the existing manifest owner when source hashes are stale; keep its compiled cases unchanged."
  - "Retain Amount unavailable where source facts provide no numeric price, and retain all presentation-only and synthetic-stress labels."

patterns-established:
  - "Responsive results reconcile exact individual cells and source/served-asset identity rather than pooled evidence."
  - "Transparency checks reject affirmative contradictions even when the same source also contains accurate disclaimers."

requirements-completed: [SBK-04, SBK-05, SBK-06, UXQ-01, UXQ-03]

# Coverage metadata (#1602)
coverage:
  - id: D1
    description: Ten collection variations retain essential identity, actions, and layout across narrow/desktop, 767/768, and 640px-container cells, with hidden-content and page-overflow negative controls.
    requirement: UXQ-01
    verification:
      - kind: automated_ui
        ref: "e2e/subscription-compositions-phase253.spec.js; run 41f1f6299863e0aa9674db1bc5dac5f1ac6b, 151 current-run records plus reconciliation, all pass; manifest c6a9d18f3dea265eb13d03651c8e45a545dc83c6587a66bff06d316772a8943e"
        status: pass
    human_judgment: false
  - id: D2
    description: Nine complete page scenarios retain details, review/step-up/result content, return controls, and long-text stress content across the contracted widths and themes.
    requirement: UXQ-03
    verification:
      - kind: automated_ui
        ref: "e2e/subscription-compositions-phase253.spec.js#reconciles every compiled collection and whole-page cell against this run and served assets; 90 page cells and 6 separately labelled synthetic stress cells passed in run 41f1f6299863e0aa9674db1bc5dac5f1ac6b"
        status: pass
    human_judgment: false
  - id: D3
    description: Actual direct Storybook routes render the connected collection and complete production page composition, including an actual collection load-more path; evidence remains presentation-only.
    requirement: SBK-04
    verification:
      - kind: integration
        ref: "accrue_admin/test/accrue_admin/dev/subscription_compositions_manifest_test.exs (7/7); disposable browser run 41f1f6299863e0aa9674db1bc5dac5f1ac6b (152/152)"
        status: pass
    human_judgment: false
  - id: D4
    description: Static-effect/provider-completion and synthetic-as-customer claims fail independently beside disclaimers; current and clean injected subjects pass, and malformed/missing/empty sources fail closed.
    requirement: SBK-05
    verification:
      - kind: unit
        ref: "scripts/ci/verify_phase253_presentation.test.mjs plus existing Phase252 owners (9/9); verify_phase252_transparency.mjs --self-test --only compositions (current/clean green; both independent violations red)"
        status: pass
    human_judgment: false
  - id: D5
    description: The retained Phase252 canonical and compatibility browser assertions still pass from an isolated current run without changing the tracked historical evidence.
    requirement: SBK-06
    verification:
      - kind: automated_ui
        ref: "e2e/subscription-stories-phase252.spec.js; run 72dca2b25c3df19e6efea0ab1224f8ad9813, 12 canonical plus 3 compatibility cells and reconciliation (16/16)"
        status: pass
    human_judgment: false

# Metrics
duration: 96min
completed: 2026-10-27
status: complete
---

# Phase 253 Plan 05: Responsive Subscription Compositions Summary

**Production-backed subscription collection and page stories now have source-bound responsive browser evidence plus independent controls for static-effect and synthetic-customer claims.**

## Performance

- **Duration:** 96 minutes from the first task commit through completion.
- **Started:** 2026-10-27T18:57:29Z
- **Completed:** 2026-10-27T20:33:04Z
- **Tasks:** 3
- **Files modified:** 20 across plan task commits.

## Accomplishments

- Verified all ten collection states, all nine page scenarios, responsive breakpoints, 640px containers, both themes, synthetic long-text stress, and explicit hidden-content/page-overflow controls. Final browser run `41f1f6299863e0aa9674db1bc5dac5f1ac6b` passed 151 cell records plus reconciliation (152/152), with current source and served-asset identity.
- Kept `page_boundary` tied to the real DataTable `load-more` event and production cursor generation. No numeric amount was inferred; the source facts still report Amount unavailable.
- Adapted the whole-page Storybook story to its supported `tab` transport, nested LiveComponent render context, and portal host while preserving the production page markup.
- Added finite transparency assertions over the current guide, story moduledocs, manifest attribution, browser labels, and source identities. The current and clean subjects pass; static-effects and synthetic-as-customer controls each fail on their contradictory sentence.
- Re-ran the Phase252 browser suite in a unique result file: 12 canonical cells, 3 compatibility cells, and reconciliation passed (16/16). The tracked historical result file was restored byte-for-byte after the wrapper wrote its default path.

## Task Commits

1. **Task 1: Read collection states across responsive and layout edges** — `2efab1cf6`, `10b581d1d`, `5da38ade8` (inventory assertion, page-boundary RED regression, implementation and responsive evidence).
2. **Task 2: Read whole-page details and review/result states** — `528d46f05` (Storybook page transport/render adaptation and regenerated stale Phase252 source digests).
3. **Task 3: Prove truthful story and synthetic-data attribution** — `7665b3a56` (current/injected assertion and independent fixtures).

## Files Created/Modified

- `accrue_admin/e2e/phase253-composition-helpers.js` and `accrue_admin/e2e/subscription-compositions-phase253.spec.js` — source/asset-bound collection and whole-page geometry/content records, stress cases, and negative controls.
- `accrue_admin/storybook/_support/subscription_collection.ex` and `accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs` — state-specific page-boundary fixture contract and direct cursor regression.
- `storybook/pages/subscription.story.exs`, the Phase253 manifest owner/tests, and `storybook/phase252-manifest.json` — supported whole-page Storybook transport and source identity.
- `accrue_admin/assets/css/app.css`, `accrue_admin/priv/static/accrue_admin.css`, and `accrue_admin/priv/static/storybook.css` — demonstrated responsive text/layout corrections at the existing CSS owner and rebuilt assets.
- `scripts/ci/verify_phase252_transparency.mjs`, `scripts/ci/verify_phase253_presentation.test.mjs`, and three Phase253 transparency fixtures — bounded checks with current, clean, and independent violation controls.
- `.planning/phases/253-real-groups-and-a-whole-subscription-job/253-05-01-red-evidence.json` and `253-05-02-red-evidence.json` — persisted target-test RED reports for the manifest inventory and page-boundary transport gaps.

## Decisions Made

- Keep cursor authority in the existing `Behaviour.paginate` path. Only the deterministic `page_boundary` story adapter sets a one-row limit, so the browser sees a real continuation cursor and actual load-more interaction.
- Select whole-page Storybook presentations through PhoenixStorybook's supported navigation tabs. Render nested LiveComponents in a LiveView diff context and add the portal mount only to the Storybook wrapper; the inner production markup remains byte-identical.
- Regenerate the Phase252 manifest through its existing owner when its hashes for `subscription_live.ex` and `subscriptions_live.ex` are stale. The six compiled entries remained unchanged.
- Keep browser evidence in the presentation-only lane and preserve all synthetic stress labels. These checks do not prove mounted authorization, persistence, action dispatch, or provider completion.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The page-boundary fixture used the caller's broad query limit**

- **Found during:** Task 1.
- **Issue:** The story adapter passed its normal query limit to `Behaviour.paginate`, so a caller with a limit of 25 received both fixture rows and no continuation cursor. That made the browser's required load-more state impossible to observe.
- **Fix:** Apply a one-row limit only for the deterministic `:page_boundary` story state and keep `Behaviour.paginate` responsible for cursor generation. The production scoped query and cursor implementation were not changed.
- **Files modified:** `accrue_admin/storybook/_support/subscription_collection.ex`, `accrue_admin/test/accrue_admin/dev/subscription_collection_transport_test.exs`.
- **Verification:** The persisted RED report records the prior two-row/no-cursor failure. The fixed transport suite passed, and the final browser run exercised page-boundary cells with all 152 tests passing.
- **Committed in:** `5da38ade8`.

**2. [Rule 3 - Blocking] PhoenixStorybook page routes did not use the assumed variation query transport**

- **Found during:** Task 2.
- **Issue:** PhoenixStorybook 1.2 selects page stories through navigation tabs; `variation_id` is read for component/live-component stories. Nested global-search LiveComponents also needed a LiveView diff context, and portal-backed drawer/step-up snapshots needed the Storybook page's overlay target.
- **Fix:** Map the supported `tab` values to compiled scenarios, render the inner production component through the existing Phoenix LiveView test rendering entry point, and append the Storybook-only overlay target. The production-rendered page fragment stays identical.
- **Files modified:** `storybook/pages/subscription.story.exs`, `accrue_admin/storybook/_support/subscription_compositions_manifest.ex`, its manifest/page-slice tests, the Phase253 helper/spec, and `storybook/phase252-manifest.json`.
- **Verification:** Page-slice TAP 7/7; final Phase253 browser run 152/152, including whole-page overlays and result states.
- **Committed in:** `528d46f05`.

**3. [Rule 1 - Bug] A browser assertion used a label absent from the production facts table**

- **Found during:** Task 2.
- **Issue:** The assertion requested `Quantity`, while the actual production row is labelled `Seats / quantity`.
- **Fix:** Assert the production row label without altering rendered copy or inventing a value.
- **Files modified:** `accrue_admin/e2e/phase253-composition-helpers.js`.
- **Verification:** Final Phase253 browser run passed all 152 tests.
- **Committed in:** `528d46f05`.

**4. [Rule 3 - Blocking] The Phase252 manifest carried stale source digests**

- **Found during:** Task 2 browser verification.
- **Issue:** The tracked Phase252 manifest hashes for `accrue_admin/lib/accrue_admin/live/subscription_live.ex` and `subscriptions_live.ex` no longer matched their sources, so the exact retained browser command stopped before its assertions.
- **Fix:** Regenerate the manifest through `SubscriptionManifest.write!/1`. Its six compiled entries remained identical; only the two source digests changed.
- **Files modified:** `storybook/phase252-manifest.json`.
- **Verification:** The final isolated Phase252 run passed all 16 tests, and the historical tracked result ledger remained byte-identical to `HEAD`.
- **Committed in:** `528d46f05`.

**Total deviations:** 4 auto-fixed (2 Rule 1 bugs, 2 Rule 3 transport/evidence blockers).
**Impact on plan:** Each fix was required to produce the planned live collection and whole-page browser evidence. No new dependency, production architecture, Phase254 scope, or numeric subscription amount was introduced.

## Verification

- Manifest compilation checks: 7 tests, 0 failures.
- Final Phase253 direct-browser run: 152/152 tests; 151 per-cell records passed and reconciled. Coverage: 40 viewport cells, 8 breakpoint cells, 4 container cells, 2 collection text-stress cells, 1 geometry negative-control case, 90 page-composition cells, and 6 page text-stress cells.
- Final retained Phase252 browser run: 16/16 tests; 12 canonical and 3 compatibility records plus reconciliation.
- Transparency command: 9/9 Node tests, 0 skipped/TODO/cancelled; the composition self-test passed current and clean controls and observed both named independent RED controls. The unchanged default Phase252 transparency self-test also passed.
- Current Phase253 browser evidence is identified by run `41f1f6299863e0aa9674db1bc5dac5f1ac6b`, manifest SHA-256 `c6a9d18f3dea265eb13d03651c8e45a545dc83c6587a66bff06d316772a8943e`.
- Isolated Phase252 evidence is at `accrue_admin/tmp/phase252/render-results-72dca2b25c3df19e6efea0ab1224f8ad9813.json`; the historical tracked result file matches `HEAD`.

## Issues Encountered

- The first disposable-lab attempt hit sandbox `ps EPERM` before tests started. Elevated execution let the wrapper complete its process-identity check and the planned tests passed.
- A Phase252 run initially wrote to the wrapper's default tracked result path. Its new result was copied to the run-specific ignored path above, and the tracked historical file was restored and confirmed identical to `HEAD`.

## User Setup Required

None.

## Next Phase Readiness

Plan 253-05 is complete. Plan 253-06 can verify required-owner/CI admission and only then consider prohibition metadata. The four flagged unclassified assumptions and both bespoke prohibition entries remain unresolved as recorded; this plan does not promote them or claim static stories prove mounted effects.

---
*Phase: 253-real-groups-and-a-whole-subscription-job*
*Completed: 2026-10-27*

## Self-Check: PASSED

- Key created files exist; all five task commits are ancestors of the plan head recorded above.
- Acceptance evidence was rerun against committed source: manifest 7/7, Phase253 browser 152/152, Phase252 browser 16/16, transparency tests 9/9, plus both composition and legacy default self-tests.
- No tests were skipped, left TODO, or cancelled; no Known Stubs or new threat surface were introduced.
