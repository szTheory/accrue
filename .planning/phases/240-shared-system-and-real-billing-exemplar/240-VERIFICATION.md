---
phase: 240-shared-system-and-real-billing-exemplar
verified: 2026-10-09T23:44:55Z
status: passed
score: 47/47 must-haves verified
covered_files:
  - .github/workflows/accrue_admin_browser.yml
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-01-PLAN.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-01-SUMMARY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-02-PLAN.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-02-SUMMARY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-03-PLAN.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-03-SUMMARY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-04-PLAN.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-04-SUMMARY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-05-PLAN.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-05-SUMMARY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-06-PLAN.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-06-SUMMARY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/final-gates/exemplar-privacy-copy.xml
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/final-gates/package-browser-privacy-copy.xml
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/final-gates/results.json
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/invoice-collection.png
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/invoice-review.png
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/manifest.json
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/recovery.png
  - .planning/phases/240-shared-system-and-real-billing-exemplar/captures/phase237-exemplar/subscription-detail.png
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/hooks/accrue_theme.js
  - accrue_admin/assets/js/hooks/connection_state.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase191.spec.js
  - accrue_admin/e2e/admin-spec-detail-phase198.spec.js
  - accrue_admin/e2e/admin-spec-list-phase196.spec.js
  - accrue_admin/e2e/visual-baseline-set.cjs
  - accrue_admin/lib/accrue_admin/components/detail.ex
  - accrue_admin/lib/accrue_admin/components/step_up_auth_modal.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/e2e_fixtures_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - accrue_admin/test/js/focus_trap_test.mjs
  - accrue_admin/test/js/visual_baseline_set_test.mjs
  - accrue_admin/test/support/e2e_fixtures.ex
  - accrue_admin/test/support/e2e_plug.ex
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  - scripts/ci/verify_phase240_evidence.mjs
covered_digest: "v3:sha256:384909b69f301aeea8a38d0ec7347e55dfa82566f6abff38feaa57381c341cb5"
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "Subscription detail's adjacent global invoice-queue panels and their route-specific presentation are not consolidated in this exemplar."
    addressed_in: "Phase 241"
    evidence: "ROADMAP Phase 241 success criterion 1 assigns subscription invoice destinations and separately labeled owner-queue links; 240-CONTEXT and 240-REVIEW-DISPOSITION explicitly defer queue composition/destinations to that journey phase."
  - truth: "Final reviewed Linux visual comparisons for selected goldens have not been executed on this macOS host."
    addressed_in: "Phase 243"
    evidence: "ROADMAP Phase 243 success criterion 1 owns reviewed Linux baselines; Phase 240's early eight-file failure guard is already wired and its 12 focused controls pass."
---

# Phase 240: Shared System and Real Billing Exemplar Verification Report

**Phase Goal:** Operators can use a coherent, truthful invoice list → detail → action review flow and a dense subscription view through the incumbent Admin system, with shared interaction and evidence patterns ready for other existing routes.
**Verified:** 2026-10-09T23:44:55Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

The six PLAN files contain 47 observable truths. The five ROADMAP success criteria restate outcomes covered by those truths, so the merged contract contains 47 distinct must-haves. Each plan cohort below was checked against current source, its wired owner tests, and the recorded final gates; all 47 pass.

| # | Roadmap truth | Status | Evidence |
|---|---|---|---|
| 1 | Invoice list/detail/review and dense subscription surfaces preserve identity, scope, exact current facts, supported actions and evidence; the tested narrow, intermediate/coarse-pointer and enlargement cases retain essential access. | ✓ VERIFIED | LiveView list/detail source uses scoped repository data and canonical MoneyFormatter; Phase 196/198 browser owners assert JPY identity/money/state/target, hit geometry, coarse-pointer access and CSS enlargement/text spacing. Phase 237 manifest records mounted subscription long-identity wrapping and no document overflow at 320/768/1280px, fine/coarse pointer. |
| 2 | Light, Dark and System selection persists, effective styles follow System OS changes, and host-forced appearance takes precedence. | ✓ VERIFIED | Phase 199 browser assertions and Phase 238 host test exercise stored preference separately from computed colors across OS changes, patch/reload and forced host theme; theme hook synchronizes replaced controls. |
| 3 | Keyboard review, validation, focus containment/return, busy completion and reconnect preserve accurate controls and do not replay staged actions. | ✓ VERIFIED | Phase 199 keyboard owner checks Tab/Shift+Tab, associated invalid feedback, correction, submission and removed-opener fallback. Phase 191 held-action browser owner exercises busy state, repeated patches/replaced controls, online-before-ready lock, actual completion, dispatch/audit count and no replay. Node FocusTrap owner passes 41 tests. |
| 4 | Empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown states communicate uncertainty and only supported next steps. | ✓ VERIFIED | Invoice/subscription state branches and copy are exercised by LiveView owners; invoice tests cover stale/foreign target rejection, unsupported recovery, exact amount/currency, pending/requires-action vs completed, ambiguous/unknown outcomes and duplicate confirmation. |
| 5 | Current route/component/state coverage, provenance, recurring acceptance owners, focused failure controls and lightweight diagnostics are inspectable. | ✓ VERIFIED | `240-COVERAGE.md` plus ledger CLI validates 21 production routes, 8 requirement owners, registry 30/42/8 and 43 source modules; mounted manifest binds fixture/source/render state to package/compiled/served CSS, JS and Geist font hashes, and records diagnostics. Guard, docs and asset owners are present and green. |

### Plan-Specific Truth Coverage

The additional plan-specific details were also verified, including the conditions not repeated in ROADMAP wording. Plan counts are 7 + 4 + 13 + 10 + 6 + 7 = 47, with roadmap outcomes deduplicated against them.

| Plan cohort | Count | Status | Evidence checked |
|---|---:|---|---|
| 240-01 invoice tracer, action authority, shared geometry and subscription cross-check | 7 | ✓ VERIFIED | `invoice_live.ex`/`invoices_live.ex`/`subscription_live.ex`; invoice and subscription owner tests; Phase 237 mounted assertions; source keeps `--ax-*` hierarchy and 2px dense / 1px structural roles. |
| 240-02 exact Linux baseline set, unchanged masks/thresholds and blocking order | 4 | ✓ VERIFIED | Exact eight-name validator; 12 Node controls; `.github/workflows/accrue_admin_browser.yml` unconditionally invokes guard, complete-set preflight, then existing blocking pixel command. |
| 240-03 distinct invoice state/copy, width/content boundaries, zoom limits, empty/error/partial/long/zero-one-many cases | 13 | ✓ VERIFIED | Invoice Copy/LiveView and owner tests plus Phase 196/198 mounted cases. Browser logs label CDP 3x/4x page scale as pinch/visual scaling and explicitly state faithful 400% browser zoom is unavailable; this does not claim actual zoom. |
| 240-04 stored/effective theme, forced theme, disabled/loading controls, keyboard review, focus lifecycle and reduced-motion teardown | 10 | ✓ VERIFIED | Theme hook/owners, Phase 199 and Phase 238 browser owners, FocusTrap Node tests. Browser and harness assertions exercise transitions rather than symbol presence alone. |
| 240-05 server-held busy completion, repeated patches, online/reconnect readiness and exactly-once dispatch | 6 | ✓ VERIFIED | Test-only fixture hold/release and authoritative provider/event/audit state; Phase 191 owner asserts original disabled state and no replay across reconnect. |
| 240-06 current inventory, source/fixture/build/served/exercised provenance, resource diagnostics and acceptance-owner map | 7 | ✓ VERIFIED | Evidence CLI self-test rejects a missing route; current ledger and manifest tie actual mounted route to package, compiled host and served assets and identify fixture/theme/viewport/browser limits. |

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | Scoped invoice collection and truthful current facts | ✓ VERIFIED | Renders database-backed rows; scoped links and canonical amount formatting are exercised by ExUnit and mounted Phase 196/237 owners. |
| `accrue_admin/lib/accrue_admin/live/invoice_live.ex` | Invoice detail, action review and fresh server validation | ✓ VERIFIED | Real LiveView handlers and repository loader; review names invoice/customer/owner target and exact money; owner tests reject stale/foreign/duplicate dispatch. |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex`, `subscription_live.ex` | Dense list/detail with exact facts, current actions and honest unknowns | ✓ VERIFIED | Repository-backed scoped data, identity/status/price/period/action rendering; tests cover empty, one/many, unavailable facts, stale actions and long mounted identity. Queue composition is recorded under the Phase 241 deferral. |
| `accrue_admin/e2e/visual-baseline-set.cjs` and `test/js/visual_baseline_set_test.mjs` | Exact expected-set validator and negative controls | ✓ VERIFIED | 12 focused Node tests; full set has 8/8 PNGs. |
| `.github/workflows/accrue_admin_browser.yml` | Fail-closed guard wired ahead of blocking pixel comparison | ✓ VERIFIED | Workflow runs expected-set tests and exact-set check before the unconditional existing visual regression step. |
| `accrue_admin/e2e/admin-spec-list-phase196.spec.js`, `admin-spec-detail-phase198.spec.js` | Responsive invoice assertions | ✓ VERIFIED | Desktop/mobile evidence covers target/money/state, enlargement, text spacing, coarse pointer and accurate zoom-method disclosure. |
| `accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js`, `admin-page-flow-phase191.spec.js` | Theme, keyboard, busy, patch and reconnect behavior | ✓ VERIFIED | Existing browser owners are wired to fixture-backed state transitions; results are in final JUnit privacy copy. |
| `accrue_admin/test/accrue_admin/live/*invoice*`, `*subscription*` and fixture owners | Server-side states, exact money and authorization | ✓ VERIFIED | Full Admin suite completed 618 tests, 0 failures, warnings-as-errors compile. |
| `scripts/ci/verify_phase240_evidence.mjs` and `240-COVERAGE.md` | Current route and evidence ledger | ✓ VERIFIED | CLI validates 21 routes, all 8 Phase 240 requirements and incumbent registry/module counts; missing-route negative was observed. |
| `examples/accrue_host/e2e/phase237-admin-billing.spec.js` and capture manifest | Mounted exemplar and served asset/resource evidence | ✓ VERIFIED | Native privacy-copy JUnit: 1 test, 0 failures. Package/compiled/served/browser-request digests match for CSS, JS and both Geist fonts; stale-JS negative was rejected then restored. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Invoice list | Scoped invoice detail | Real row/card link and owner scope | ✓ WIRED | LiveView builds scoped detail path; mounted owner opens the seeded list record and checks the detail target. |
| Invoice detail/review | Existing server-authorized action dispatch | LiveView events, fresh target/material-state checks, step-up and duplicate guard | ✓ WIRED | `invoice_live.ex` handlers call server validation; ExUnit asserts stale/foreign/repeated submissions do not dispatch. |
| Invoice/subscription LiveViews and Detail | Shared `--ax-*` roles and rebuilt package assets | Component classes → package build → host `/admin` | ✓ WIRED | Phase 198 compares mounted served CSS bytes with package artifact; Phase 237 binds package, compiled and served CSS/JS/font bytes. |
| Stored theme selection | Effective rendered theme | `accrue_theme` hook, OS media changes, forced host theme | ✓ WIRED | Phase 199 and Phase 238 exercise selection, replacement, reload and host precedence. |
| Review opener | Overlay focus/validation/focus return | Focus trap and actual form events | ✓ WIRED | Mounted Phase 199 interaction checks both-direction focus containment, associated error/correction/submission, dismissal and fallback focus. |
| Held fixture action | LiveView busy state and completion | Test-only hold/release with authoritative fixture counters | ✓ WIRED | Phase 191 observes actual completion and matching provider dispatch/event/audit count. |
| Network reconnect | Fresh LiveView readiness and eligible controls | `connection_state.js` waits for LiveView reconnected state | ✓ WIRED | Browser owner proves online alone does not unlock, replacements preserve original disabled state, and reconnect does not replay. |
| Expected PNG set | Existing blocking Linux pixel job | Workflow exact-set preflight followed by pixel command | ✓ WIRED | Guard unit suite proves all/partial missing rejection; workflow has no any-PNG conditional skip. |
| Compiled route/registry authorities | Evidence ledger and recurring owners | Phase 239 route source and live registry APIs | ✓ WIRED | Ledger CLI verifies 21 current routes, owner rows and live registry counts; self-test rejects an omitted route. |

## Data-Flow Trace (Level 4)

| Artifact | Rendered data | Source | Produces real data | Status |
|---|---|---|---|---|
| Invoice list/detail | Invoice, customer, owner, state and minor-unit amount | Owner-scoped repository loaders and canonical MoneyFormatter | Yes; seeded disposable fixture reaches mounted route; owner tests cover scope and state | ✓ FLOWING |
| Subscription list/detail | Subscription/customer, lifecycle, plan amount/period and related invoice facts | Owner-scoped repository queries and MoneyFormatter | Yes; fixture-backed tests and mounted subscription cross-check; absent plan/period remains explicit | ✓ FLOWING |
| Theme controls | Stored choice and effective CSS appearance | `accrue_theme` local preference plus OS/host precedence | Yes; browser tests independently inspect preference and computed style | ✓ FLOWING |
| Held action/reconnect state | Busy/result/disabled controls and dispatch count | Test-only fixture hold/release, actual LiveView and provider adapter | Yes; observed completion, state and audit/event counters | ✓ FLOWING |
| Evidence ledger and mounted assets | Route/component rows and asset digests | Compiled Phase 239 route authority, live component registry and actual package/host/served responses | Yes; valid ledger and missing-route rejection; hash equality and stale-asset negative | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command / recorded owner | Result | Status |
|---|---|---|---|
| Admin server state and authorization owners | `MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` | 618 tests, 0 failures | ✓ PASS |
| Hook, focus and baseline guard behaviors | `node --test test/js/*.mjs` | 41 tests, 0 failures; baseline-set owner contributes 12 controls | ✓ PASS |
| Responsive/list/detail and interaction browser owners | Desktop and mobile JUnit privacy copy | 89 passed, 19 incumbent skips, 0 failures/errors | ✓ PASS |
| Mounted Phase 237 invoice/subscription exemplar and asset provenance | Native privacy-copy JUnit | 1 test, 0 failures; digest mismatch negative then restored match | ✓ PASS |
| Host verification and existing acceptance paths | `MIX_ENV=test mix verify.full` recorded final result | Exit 0; bounded 64/0, full 223/0, dev boot pass, browser 37 pass/16 incumbent skips, checkout 14/0 | ✓ PASS |
| Route ledger negative control | `node scripts/ci/verify_phase240_evidence.mjs --self-test .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md` | `valid=1 missing-route-rejected=1`; normal CLI validates 21 routes | ✓ PASS |
| Complete expected baseline set | `node accrue_admin/e2e/visual-baseline-set.cjs accrue_admin/e2e/__screenshots__/visual-desktop` | 8 expected, 8 present; 12 focused controls pass | ✓ PASS |
| Package docs and contrast guard | `bash scripts/ci/verify_package_docs.sh` (recorded final result) | Passed | ✓ PASS |

## Probe Execution

No `probe-*.sh` is declared by the six plans or success criteria. The phase's evidence validator is a Node CLI and its positive/negative self-test is recorded above; no shell probe is missing.

## Requirements Coverage

| Requirement | Source plans | Description | Status | Evidence |
|---|---|---|---|---|
| DSN-01 | 01, 03, 06 | Shared identity/facts/action hierarchy | ✓ SATISFIED | Invoice list/detail/review and dense subscription owners plus mounted geometry evidence. |
| DSN-02 | 01, 03, 06 | Responsive access, long/missing data and enlargement | ✓ SATISFIED | Phase 196/198 and Phase 237 width/coarse-pointer/enlargement checks; actual zoom limitation is explicit. |
| DSN-03 | 04, 06 | Stored Light/Dark/System and effective theme/host force | ✓ SATISFIED | Theme ExUnit, Phase 199 and Phase 238 host-forced browser owners. |
| DSN-04 | 05, 06 | Accurate busy/completion/reconnect without replay | ✓ SATISFIED | Fixture-backed held action and Phase 191 repeated patch/reconnect/dispatch-count assertions. |
| DSN-05 | 04, 06 | Keyboard focus, validation and overlay lifecycle | ✓ SATISFIED | Node FocusTrap owner and Phase 199 mounted keyboard case. |
| UXC-02 | 01, 03, 05, 06 | Distinct uncertainty/outcome states and supported next steps | ✓ SATISFIED | Invoice/subscription outcome and unavailable-state owner tests. |
| EVR-01 | 06 | Current route/component/state evidence inventory | ✓ SATISFIED | Ledger CLI and current coverage report. |
| EVR-02 | 01–06 | Recurring checks and focused regression controls | ✓ SATISFIED | Existing acceptance owners plus guard negatives, package/host checks and asset provenance. |

No Phase 240 requirement mapped in `REQUIREMENTS.md` is absent from plan requirements. All eight required IDs are covered; no orphaned Phase 240 requirement was found.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker was found in the changed implementation/test owners. The scan matches for `return null`, empty returns and `console.log` are legitimate guard branches, test helpers, or explicit browser evidence output; none is a user-visible stub. The known subscription queue composition finding is handled in Deferred Items, consistent with the locked Phase 241 boundary.

## Human Verification Required

None. Phase policy requires zero maintainer UAT; automated mounted appearance, interaction and state owners exist, and subjective owner feedback remains optional. Linux pixel comparison is handled by the Phase 243 owner. Browser zoom was explicitly reported as unavailable rather than treated as verified by viewport or pinch emulation.

## Gaps Summary

No blocking or uncertain must-have remains. The current implementation delivers the invoice list → detail → staged action-review path and dense subscription view through the incumbent Admin system. Source, focused tests, mounted assertions and current served-asset evidence connect the behavior end to end. The UI review's remaining subscription global invoice-queue composition/destination work is explicitly assigned to Phase 241, and reviewed Linux golden closure is assigned to Phase 243; neither is pulled into this phase's contract. The original Phase 240-03 TDD RED timing deviation remains historical and is not represented by retrospective reports as timing proof.

---

_Verified: 2026-10-09T23:44:55Z_  
_Verifier: the agent (gsd-verifier)_
