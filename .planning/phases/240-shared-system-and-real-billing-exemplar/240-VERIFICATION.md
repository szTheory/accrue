---
phase: 240-shared-system-and-real-billing-exemplar
verified: 2026-10-10T23:09:13Z
status: passed
score: 47/47 must-haves verified
covered_files:
  - .github/workflows/accrue_admin_browser.yml
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
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
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-CONTEXT.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-RESEARCH.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-REVIEW-DELTA.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-REVIEW.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-SECURITY.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-UI-REVIEW.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-VALIDATION.md
  - .planning/phases/240-shared-system-and-real-billing-exemplar/deferred-items.md
  - accrue/lib/accrue/billing/invoice_actions.ex
  - accrue/test/accrue/billing/invoice_item_actions_test.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/hooks/accrue_theme.js
  - accrue_admin/assets/js/hooks/connection_state.js
  - accrue_admin/assets/js/hooks/focus_trap.js
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
covered_digest: "v3:sha256:1951f17532c6c1d841cd318393bc1923fcd53dc7670d1bef6f6abb8363c0528f"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 47/47
  gaps_closed: []
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Final reviewed Linux visual comparisons for selected goldens are outside Phase 240's local macOS run."
    addressed_in: "Phase 243"
    evidence: "Phase 243 owns the final reviewed Linux baselines and separate milestone-wide Linux Browser UAT evidence; it does not replace the local Phase 240 compile and test runs recorded here."
---

# Phase 240: Shared System and Real Billing Exemplar Verification Report

**Phase Goal:** Operators can use a coherent, truthful invoice list → detail → action review flow and a dense subscription view through the incumbent Admin system, with shared interaction and evidence patterns ready for other existing routes.
**Verified:** 2026-10-10T23:09:13Z
**Status:** passed
**Re-verification:** Yes — current regression fixes and full local package suites

## Goal Achievement

### Observable Truths

The five roadmap success criteria are the outcome contract; all 47 distinct plan truths were also checked against current source, test owners and the supplied fresh regression runs. Plans add detail but do not reduce roadmap scope.

| # | Roadmap truth | Status | Evidence |
|---|---|---|---|
| 1 | Invoice list/detail/review and dense subscription retain identity, scope, exact current facts, supported action and evidence through the required responsive/content cases. | ✓ VERIFIED | Current `invoices_live.ex`, `invoice_live.ex`, subscription LiveViews and MoneyFormatter render scoped repository data. Owner tests and mounted Phase 196/198/237 checks exercise target, money, facts, width, coarse-pointer and enlargement behavior. Shared spacing retains the deliberate 2px dense and 1px structural roles. |
| 2 | Light, Dark and System selection persists, effective styles track OS preference, and host force takes precedence. | ✓ VERIFIED | Theme hook, ThemePicker/Theme tests and Phase 199/238 mounted owners assert selection separately from computed style, patch/reload behavior and host-forced precedence. |
| 3 | Keyboard review, busy state and reconnect preserve focus, truthful controls and exactly-once behavior. | ✓ VERIFIED | Phase 199 and FocusTrap owners exercise containment, correction, submit, dismissal and replacement focus. Phase 191 uses a server-held disposable action and fixture dispatch/audit counts to prove busy completion, reconnect readiness and no replay. |
| 4 | Empty, no-match, unavailable, partial, unsupported, denied, pending, failed and unknown states state uncertainty and only supported next steps. | ✓ VERIFIED | Current invoice/subscription state branches and copy are backed by LiveView owner tests for unavailable/partial facts, unsupported recovery, stale/foreign rejection, exact amounts and distinct pending, failure, unknown and completion outcomes. |
| 5 | Current route/component/state coverage and source-to-served provenance are inspectable, and recurring acceptance owners exercise the exemplar and guards. | ✓ VERIFIED | `240-COVERAGE.md` and its verifier validate 21 routes, eight requirements, incumbent registry counts 30/42/8 and 43 source modules. Mounted manifest/Phase 237 owner compares package, host-compiled and served CSS/JS/fonts and records route, fixture and diagnostics. Expected baseline preflight is wired before the blocking visual command. |

**Score:** 47/47 truths verified (0 present, behavior-unverified).

### Plan-Specific Truth Coverage

| Plan | Truths | Status | Evidence inspected |
|---|---:|---|---|
| 240-01 invoice tracer, hierarchy, action authority and subscription cross-check | 7 | ✓ VERIFIED | Scoped LiveView loaders, canonical formatting, review validation and owner tests; mounted host assertion. |
| 240-02 expected Linux baseline set and blocking ordering | 4 | ✓ VERIFIED | Explicit expected-set validator, Node negative controls, workflow guard before the unchanged blocking pixel comparison. |
| 240-03 truthful states, responsive/content boundaries and zoom limits | 13 | ✓ VERIFIED | Invoice copy/branches, ExUnit and Phase 196/198 owners; browser report correctly labels the unavailable faithful 400% browser zoom method rather than treating CSS or pinch scale as zoom. |
| 240-04 theme, keyboard review and focus lifecycle | 10 | ✓ VERIFIED | Theme and FocusTrap tests plus Phase 199 and Phase 238 mounted owners. |
| 240-05 controlled busy completion and reconnect without replay | 6 | ✓ VERIFIED | Test-only hold/release seam, production readiness lock and Phase 191 authoritative dispatch/audit assertions. |
| 240-06 current inventory and asset/execution provenance | 7 | ✓ VERIFIED | Route evidence CLI and self-test, current coverage ledger, mounted asset manifest and served-byte assertions. |

### Current Regression Runs

These are the fresh local results supplied for this verification and were considered alongside source inspection; the earlier SUMMARY counts were not used as proof.

| Owner | Result |
|---|---|
| Core | `MIX_ENV=test mix compile --warnings-as-errors` passed; full `MIX_ENV=test mix test`: 2,081 tests, 0 failures (11 excluded). |
| Admin | Warnings-as-errors compile passed; full suite: 683 tests, 0 failures. |
| Host | Warnings-as-errors compile passed; full suite: 223 tests, 0 failures. |
| Admin JavaScript | `node --test test/js/*.mjs`: 49 tests, 0 failures. |
| Package-doc verifier | Focused suite: 46 tests, 0 failures. |

The first broad Core attempt's 45 failures all came from the stale Phase 239 fixture path. The fixture now uses the canonical v1.63 archive path, and the rerun passed. The two acknowledged non-failing notices are the package asset build's missing Storybook-only CSS/JS paths and ExMoney's automatic exchange-rate startup deprecation notice. Neither prevented compilation or tests.

The remote Phase 243 Browser UAT run is separate milestone-wide Linux evidence. It is not used as a substitute for any local Phase 240 compile or test result. The existing UI audit is reused because the current regression fixes did not change rendered layout; no new layout capture was needed.

### Required Artifacts

| Artifact | Status | Evidence |
|---|---|---|
| Invoice collection/detail/review: `accrue_admin/lib/accrue_admin/live/{invoices_live,invoice_live}.ex` | ✓ VERIFIED | Substantive scoped queries/rendering, canonical money, target/scope review, fresh actor/scope/eligibility/fingerprint checks and duplicate dispatch guard. |
| Dense subscription list/detail: `accrue_admin/lib/accrue_admin/live/{subscriptions_live,subscription_live}.ex` | ✓ VERIFIED | Scoped database-backed facts, explicit unavailable values, action eligibility and fresh server validation; tests exercise zero/one/many and action outcomes. |
| Billing action guard: `accrue/lib/accrue/billing/invoice_actions.ex` | ✓ VERIFIED | Current add/remove paths lock/recheck persisted draft status and item ownership/eligibility before mutation; invoice-item tests cover stale state and forged/stale targets. |
| Baseline guard and CI workflow | ✓ VERIFIED | Named expected set rejects missing paths/non-files, and CI invokes guard before the blocking pixel run. |
| Theme, focus and reconnect hooks | ✓ VERIFIED | Hook code is wired into recurring browser owners; supplied Node suite passes 49/0 and Admin suite passes 683/0. |
| Evidence ledger | ✓ VERIFIED | Current CLI validates route/requirement inventory and rejects a missing-route fixture. |
| Package-doc verifier archive fixture | ✓ VERIFIED | Test fixture references canonical archived Phase 239 documents; focused 46/0 run confirms the regression fix. |

### Key Link Verification

| From | To | Via | Status | Evidence |
|---|---|---|---|---|
| Invoice collection | Scoped invoice detail | Row navigation carries current owner scope | ✓ WIRED | LiveView uses scoped path construction; mounted list/detail owner opens the seeded invoice. |
| Invoice review | Billing mutation | Submit → fresh actor/scope/target/state/money checks → server action | ✓ WIRED | Review handler and billing action owners preserve independent validation and duplicate protection. |
| LiveView/component classes | Served Admin styling | `--ax-*` roles → rebuilt package assets → host response | ✓ WIRED | Phase 198/237 owners compare built, compiled and served asset bytes. |
| Theme preference | Effective theme | Stored choice → hook/media query → host force | ✓ WIRED | Theme browser owners verify preference, computed styles and host precedence. |
| Overlay opener | Review completion/focus return | Focus trap → form feedback → dismissal/replacement fallback | ✓ WIRED | Phase 199 browser owner and FocusTrap Node owner exercise transitions. |
| Held fixture action | Busy/completion UI | Hold/release → LiveView state → fixture dispatch/audit oracle | ✓ WIRED | Phase 191 browser owner proves completion and no replay from authoritative counters. |
| Network reconnect | Fresh action eligibility | `connection_state.js` waits for LiveView readiness | ✓ WIRED | Browser owner covers online-before-ready, patches and replacement controls. |
| Expected snapshot set | Linux pixel gate | Exact-set preflight → existing pixel regression command | ✓ WIRED | Workflow has unconditional guard and blocking pixel command; missing-set tests are focused. |

### Data-Flow Trace (Level 4)

| Artifact | Data | Source | Status |
|---|---|---|---|
| Invoice list/detail | Invoice/customer/owner/state/minor-unit amount | Owner-scoped repository loaders and canonical formatter | ✓ FLOWING |
| Subscription list/detail | Subscription/customer/status/plan/period/actions | Owner-scoped subscription query and formatter | ✓ FLOWING |
| Theme controls | Stored preference and computed colors | Browser storage, OS media preference and host override | ✓ FLOWING |
| Busy/reconnect controls | Busy/result/disabled state and dispatch count | Test-only hold fixture and real LiveView/provider adapter | ✓ FLOWING |
| Evidence ledger | Route and owner rows | Phase 239 route authority and live component registry | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/result | Status |
|---|---|---|
| Core compilation and tests | Warnings-as-errors compile passed; 2,081 tests, 0 failures (11 excluded) | ✓ PASS |
| Admin compilation and tests | Warnings-as-errors compile passed; 683 tests, 0 failures | ✓ PASS |
| Host compilation and tests | Warnings-as-errors compile passed; 223 tests, 0 failures | ✓ PASS |
| Admin JavaScript tests | `node --test test/js/*.mjs`: 49/0 | ✓ PASS |
| Package-doc verifier | Focused suite: 46/0 | ✓ PASS |
| Phase 240 ledger/negative control | Existing self-test requires valid ledger and rejects omitted route; 21 routes and eight requirements checked | ✓ PASS |
| Faithful 400% browser zoom | Installed headless browser did not expose a faithful browser-zoom control; CSS/pinch scaling is documented separately | ? LIMIT RECORDED |
| Final reviewed Linux pixel run | Owned separately by Phase 243; not inferred from local/macOS evidence | Deferred to Phase 243 |

### Probe Execution

No `probe-*.sh` is declared by the six plans or roadmap criteria; no shell probe was required. The Node evidence validator and its positive/negative self-test are recorded above.

### Requirements Coverage

| Requirement | Source | Status | Evidence |
|---|---|---|---|
| DSN-01 | Plans 01/03/06 | ✓ SATISFIED | Invoice and subscription identity/facts/action hierarchy, owner tests and mounted exemplar. |
| DSN-02 | Plan 03 | ✓ SATISFIED | Width/content/coarse-pointer/enlargement owners and zoom-method limits recorded truthfully. |
| DSN-03 | Plan 04 | ✓ SATISFIED | Stored/effective theme tests and host-forced mounted check. |
| DSN-04 | Plan 05 | ✓ SATISFIED | Held completion, reconnect readiness and exactly-once assertions. |
| DSN-05 | Plan 04 | ✓ SATISFIED | Focus containment, validation, dismissal and replacement focus owners. |
| UXC-02 | Plans 01/03/05 | ✓ SATISFIED | Distinct state copy and safe next-step assertions across real branches. |
| EVR-01 | Plan 06 | ✓ SATISFIED | Current route/component/evidence inventory and served asset provenance. |
| EVR-02 | Plans 01–06 | ✓ SATISFIED | Recurring local owners, focused negative controls, and current full regression runs. |

All requirement IDs assigned by the roadmap are present in plan frontmatter; no phase-owned requirement is orphaned. CONTEXT decision coverage query: 14/14 honored, 0 unhonored.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|---|---|---|---|
| — | No unresolved implementation debt marker or stub found in the audited phase owners. | — | The two acknowledged notices above are build/test environment notices, not unimplemented code. |

### Human Verification Required

None. Actual browser zoom limitations are explicitly recorded and are not represented as a successful zoom observation. Visual audit reuse follows the agreed no-rendered-layout-change decision.

### Gaps Summary

No blocking gap remains. Phase 243 owns the final reviewed Linux visual comparison and separate milestone-wide Linux Browser UAT; this does not weaken or replace Phase 240's local regression evidence. Historical Core failures were confined to the stale archived-fixture path and passed after correction.

---

_Verified: 2026-10-10T23:09:13Z_  
_Verifier: the agent (gsd-verifier)_
