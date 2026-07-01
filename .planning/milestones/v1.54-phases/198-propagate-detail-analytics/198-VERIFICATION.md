---
phase: 198-propagate-detail-analytics
verified: 2026-06-29T18:26:54Z
status: passed
score: 3/3 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 198: Propagate DETAIL + Analytics Verification Report

**Phase Goal:** Every remaining detail and analytics page is internally consistent with the locked detail/overview specs.
**Verified:** 2026-06-29T18:26:54Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | All remaining detail pages (customer, invoice, charge, coupon, promotion-code, connect-account, webhook, event) conform to SPEC-DETAIL: summary-then-drill, <=2 primary actions plus overflow, side-drawer actions, one related strip, lazy timeline/JSON. | VERIFIED | The detail LiveViews render `Detail.summary_card`, `Detail.summary_list`, one `data-ax-related-resources` region, and lazy activity/JSON markers. Invoice, charge, connect account, and webhook action flows use `Detail.action_band`/`DetailDrawer` plus `StepUp` for sensitive confirmations; read-only coupon, promotion-code, and event details omit action bands. Contract tests cover each surface and the phase E2E spec enumerates all eight detail targets. |
| 2 | Recovery and Campaign analytics pages conform to the locked overview spec: work-queue first, no chart wall. | VERIFIED | `RecoveryLive` renders the overview root, compact hero metrics, work queue, then supporting funnel; `CampaignLive` gates drill-downs through scoped subscription detail loading and renders summary plus campaign timeline without KPI grid or `AnalyticsPage`. Recovery, Campaign, AtRiskTable, and phase E2E tests cover ordering, scope preservation, and forbidden KPI/chart-wall regressions. |
| 3 | Tabs appear only for peer record sets (Customer-360 Subscriptions/Invoices/Payments), never hiding primary state/actions behind horizontal tabs. | VERIFIED | `CustomerLive` peer navigation is limited to Subscriptions, Invoices, and Payments, with scoped links. Tests assert the exact peer labels, reject `More`/non-peer labels, and source checks confirm no horizontal tab abstraction was introduced for primary state/actions. |

**Score:** 3/3 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `accrue_admin/e2e/admin-spec-detail-phase198.spec.js` | Browser contract covering all Phase 198 detail and analytics targets. | VERIFIED | Imports shared page-flow helpers, defines eight detail targets, Recovery/Campaign analytics targets, drawer flow targets, customer peer-nav assertions, Recovery ordering assertions, Campaign drill-down assertions, and drawer/StepUp behavior checks. |
| `accrue_admin/package.json` | Runnable Phase 198 E2E command. | VERIFIED | `e2e:phase198` is wired to `playwright test e2e/admin-spec-detail-phase198.spec.js --timeout=60000 --workers=1`; verified with `node` package-script check. |
| Detail LiveViews | SPEC-DETAIL implementation across all target detail surfaces. | VERIFIED | Customer, invoice, charge, coupon, promotion-code, connect-account, webhook, and event LiveViews contain substantive summary/list/related/lazy implementations and scoped drill-down links. |
| Analytics LiveViews and AtRiskTable | Locked overview grammar and scoped analytics links. | VERIFIED | Recovery uses scoped `Dunning` queries and AtRiskTable before funnel; Campaign uses scoped subscription detail gating and `CampaignTimeline`; AtRiskTable preserves owner scope in row and pagination links. |
| Focused ExUnit and E2E tests | Regression coverage for grammar, scope, drawer, and analytics behavior. | VERIFIED | Focused tests exist for each target LiveView, analytics page, AtRiskTable, and scoped event queries; representative named tests passed during verifier spot-checks. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `package.json` | Phase 198 E2E browser contract | `npm run e2e:phase198` | WIRED | Script resolves to the phase E2E spec and was syntax-checked. |
| Phase 198 E2E spec | Shared seeded route helpers | `require("./support/phase191-page-flow-helpers.js")` | WIRED | Browser contract uses shared fixture/navigation helpers instead of isolated placeholder routes. |
| Detail LiveViews | DETAIL components and drawer contracts | `Detail.*`, `RelatedResources`, `Timeline`, `JsonViewer`, `DetailDrawer`, `StepUp` | WIRED | Implementations render shared detail primitives and route sensitive actions through drawer intent plus StepUp confirmation where applicable. |
| Detail drill-downs and breadcrumbs | Owner/organization scope | `AccrueAdmin.ScopedPath.build/3` | WIRED | Customer, invoice, charge, coupon, promotion-code, connect-account, webhook, event, Campaign, and AtRiskTable links preserve active organization scope. |
| Recovery analytics | Scoped analytics data | `AccrueAdmin.Queries.Dunning` and `AtRiskTable` | WIRED | Recovery computes metrics, funnel, and at-risk rows through the scoped query wrapper. |
| Campaign analytics | Scoped drill-down data | `Subscriptions.detail/2` and `CampaignTimeline` | WIRED | Direct routes deny out-of-scope subscriptions before rendering campaign detail content. |
| Event feed/detail | Owner-scoped events | `AccrueAdmin.Queries.Events.scope_query/1` | WIRED | Event list, counts, and detail paths share scoped base queries, including Charge-subject ownership coverage. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Customer, invoice, charge, webhook, and event details | Assigns rendered by summary/drill/related/lazy sections | Scoped query modules: `Customers.detail/2`, `Invoices.detail/2`, `Charges.detail/2`, `Webhooks.detail/2`, `Events.detail/2` | Yes - DB-backed scoped detail queries feed the LiveViews, and refresh/replay/action paths re-load through owner scope. | FLOWING |
| Coupon and promotion-code details | Coupon/promotion code assigns and related links | `Repo.get` schema rows plus scoped navigation links | Yes - these records are schema-global in the current domain model; owner scope is preserved through breadcrumbs and drill-down links. | FLOWING |
| Recovery analytics | Hero metrics, work queue rows, funnel data | `AccrueAdmin.Queries.Dunning` scoped wrapper | Yes - global and organization-scoped query paths feed metrics, rows, and funnel content. | FLOWING |
| Campaign analytics | Subscription/campaign assigns | `Subscriptions.detail/2` gate plus Dunning campaign data | Yes - route rendering depends on scoped subscription detail access and real campaign timeline data. | FLOWING |
| Events overview and event detail | Event rows, counts, and detail records | `AccrueAdmin.Queries.Events.scoped_base_query/1` | Yes - scoped base query and organization SQL include Customer, Subscription, Invoice, and Charge subject ownership. | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 198 browser spec is syntactically valid and package script is wired. | `cd accrue_admin && node --check e2e/admin-spec-detail-phase198.spec.js && node --check e2e/admin-spec-overview-phase194.spec.js && node -e "...check package script..."` | Script syntax and exact `e2e:phase198` command verified. | PASS |
| Representative detail/analytics contracts pass by target file and line. | `cd accrue_admin && mix test test/accrue_admin/live/customer_live_test.exs:160 ... test/accrue_admin/queries/events_test.exs:55 --max-failures 1` | 12 tests, 0 failures; 100 excluded. | PASS |
| Workspace patch has no whitespace conflict markers. | `git diff --check` | No issues reported. | PASS |
| Final orchestrator gates after review fixes. | `mix compile --warnings-as-errors && mix test ...`, `npm run e2e:phase198`, `verify_package_docs.sh`, `npm run e2e:phase194`, `npm run e2e:phase195` | Reported passed by orchestrator: focused ExUnit 123 tests/0 failures, Phase 198 E2E 24 passed/4 skipped, package docs passed, Phase 194 and Phase 195 E2E passed. | PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| None declared | `find scripts -path '*/tests/probe-*.sh'` and phase artifact probe scan | No Phase 198 probe scripts or probe declarations found. | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PRP-02 | Phase 198 plans 01-09 | All remaining detail/analytics pages (customer, invoice, charge, coupon, promotion-code, connect-account, webhook, event detail, Recovery, Campaign) conform to SPEC-DETAIL / overview spec. | SATISFIED | `.planning/REQUIREMENTS.md` marks PRP-02 complete and traces it to Phase 198; code/test evidence verifies all named surfaces, scope preservation, action drawer contracts, analytics ordering, and Customer peer navigation. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| Phase 198 source/test/E2E files | N/A | No unreferenced `TBD`, `FIXME`, `XXX`, blocking placeholders, stub returns, or orphaned phase artifacts found. | None | No blocker. |
| `accrue_admin/e2e/admin-spec-overview-phase194.spec.js` | helper branches | `return {}` in optional JS test helper paths. | Info | Benign test helper fallback, not user-visible data. |
| `accrue_admin/lib/accrue_admin/live/charge_live.ex` | refund drawer inputs | HTML `placeholder` attributes. | Info | Normal form UX text, not a placeholder implementation. |

### Human Verification Required

None. No PLAN `<human-check>` blocks were present, and the phase must-haves are covered by structural checks, focused ExUnit tests, and browser E2E contracts.

### Gaps Summary

No gaps found. Phase 198 satisfies PRP-02 and the roadmap success criteria. The remaining detail and analytics surfaces are wired to real data sources, preserve owner/organization scope through links and action paths, and maintain the prior Phase 194/195 overlay/action drawer behavior.

---

_Verified: 2026-06-29T18:26:54Z_
_Verifier: the agent (gsd-verifier)_
