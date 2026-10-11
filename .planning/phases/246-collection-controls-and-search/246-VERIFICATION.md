---
phase: 246-collection-controls-and-search
verified: 2026-10-11T19:37:17Z
status: gaps_found
score: 9/10 must-haves verified
covered_files:
  - .planning/phases/246-collection-controls-and-search/246-01-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-01-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-02-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-02-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-03-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-03-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-04-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-04-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-IDENTITY-GAP-SUMMARY.md
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/js/hooks/command_palette.js
  - accrue_admin/lib/accrue_admin/components/data_table.ex
  - accrue_admin/lib/accrue_admin/components/empty_state.ex
  - accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/components/topbar.ex
  - accrue_admin/lib/accrue_admin/live/charges_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
  - accrue_admin/lib/accrue_admin/live/coupons_live.ex
  - accrue_admin/lib/accrue_admin/live/customers_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
  - accrue_admin/lib/accrue_admin/live/subscriptions_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/queries/invoices.ex
  - accrue_admin/lib/accrue_admin/queries/subscriptions.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/data_table_test.exs
  - accrue_admin/test/accrue_admin/components/empty_state_test.exs
  - accrue_admin/test/accrue_admin/components/filter_chip_bar_test.exs
  - accrue_admin/test/accrue_admin/components/global_search_test.exs
  - accrue_admin/test/accrue_admin/live/charges_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
  - accrue_admin/test/accrue_admin/live/customers_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscriptions_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - examples/accrue_host/e2e/phase246-collection-filters.spec.js
  - examples/accrue_host/e2e/phase246-global-search.spec.js
  - examples/accrue_host/e2e/phase246-invoice-filters.spec.js
  - examples/accrue_host/e2e/phase246-table-reading.spec.js
  - examples/accrue_host/lib/accrue_host/ordinary_seed_boundary.ex
  - examples/accrue_host/lib/accrue_host_web/live/phase246_states_live.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/playwright.phase246.config.js
  - examples/accrue_host/priv/repo/seeds/ordinary.exs
  - examples/accrue_host/test/ordinary_preview_seed_test.exs
covered_digest: "v3:sha256:df8be79cee3a88e425ee762c89709a5331d607d723b72eb65a8fd23c10cd34ce"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Current changed source and served assets are bound to wide/narrow, light/dark mounted evidence for the collection toolbar and final identity-cell consumers."
    status: failed
    reason: "The existing Phase 246 manifests bind captures to earlier source revisions; they do not include the final collection toolbar or the five identity-cell consumers added at d1840677."
    artifacts:
      - path: ".planning/phases/246-collection-controls-and-search/captures/phase246-table-reading/manifest.json"
        issue: "Its source revision predates d1840677 and its four captures do not exercise the final identity renderers in charges, Connect, coupons, events, and webhooks."
      - path: ".planning/phases/246-collection-controls-and-search/captures/phase246-global-search/manifest.json"
        issue: "Its capture set does not provide current-source collection-toolbar states or bind the final served assets to that rendered proof."
    missing:
      - "Capture the final collection toolbar plus the five late identity-cell consumers at wide and 320px narrow viewports in light and dark themes."
      - "Record screenshots, current source revision, served CSS/JS digests, and PNG digests in Phase 246 manifests; verify every digest against the retained files."
---

# Phase 246: Collection Controls and Search Verification Report

**Phase Goal:** Operators can find and scan existing billing records through coherent controls whose visible state matches the results.
**Verified:** 2026-10-11T19:37:17Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Operators can distinguish views from applied constraints, use visible labels, remove one chip or reset, and see URL, controls, count and rows agree. | ✓ VERIFIED | `DataTable` and `FilterChipBar` render labeled criteria, separate view state, real removable chips and one scoped reset. Invoice and collection LiveView tests plus mounted filter specs cover URL/control/result agreement, Unicode criteria, history and retained owner/query scope. |
| 2 | Invoice status defaults and direct status sets agree with selected controls and scoped result rows. | ✓ VERIFIED | `InvoicesLive` canonicalizes supported comma-delimited statuses and supplies them to the existing OR query; mounted invoice proof asserts selection, URL, count, rows and owner scope. |
| 3 | Subscription status combinations, including Past due + Canceling defaults, preserve scope and match query rows; Coupons All/Valid have one selected state. | ✓ VERIFIED | The subscription and coupon LiveViews/tests cover default/direct/All transitions and selected-view state. Existing scoped predicates and `DataTableNav` remain the query/navigation path. |
| 4 | General search guidance matches implemented predicates, with exact relationship filters separately labeled and discoverable. | ✓ VERIFIED | Current collection owners expose named exact fields and predicate-specific q guidance. Existing query modules retain exact filters and owner scoping; the collection tests cover custom event values and known matching/nonmatching records. |
| 5 | Global billing search presents customer, invoice and subscription groups with one active pointer/keyboard result and truthful current loading, retry and validation states. | ✓ VERIFIED | `GlobalSearch` keeps generation/query/owner checks, retains successful groups on partial failure, scopes retry, and renders a distinct 100-character validation message. `CommandPalette.activeIndex` drives paint, ARIA and Enter; current Admin tests and mounted search evidence cover pointer/keyboard and async states. |
| 6 | Table rows separate primary identity from exact copyable IDs, keep significant state/money/time in useful order, and preserve distinct zero, first-run, partial and unavailable states. | ✓ VERIFIED | Shared `DataTable.identity_cell` and `EmptyState` are wired to representative consumers. The five later consumers now also render exact copy actions: payment, connected-account, coupon, event-type and webhook-event identity. Focused identity regression assertions were added in `d1840677`; the final Admin test result reported by the orchestrator is 718 tests, zero failures and zero warnings. |
| 7 | Responsive behavior keeps current controls, search and table content usable at wide and 320px narrow sizes, including long values and partial states. | ✓ VERIFIED | Mounted phase specs and the Phase 04 summary record 320px geometry, long-text, zero/one/many, loading/error/partial and wide/narrow search assertions. The shared identity/card and wrapping code is present and connected. This verifies the asserted behavior and geometry; it does not establish fresh visual acceptance for the late source changes (see truth 10). |
| 8 | The ordinary preview seed fails closed outside its isolated test/development database boundary. | ✓ VERIFIED | `ordinary.exs` reads `current_database`, role and actual server address from the connected Repo before mutation. `OrdinarySeedBoundary` requires test DB name, `postgres` role and IPv4/IPv6 loopback; dev mode requires the resolved Compose address. The named boundary test rejects public/missing addresses and wrong DB/role; the current host test result reported by the orchestrator was 13 tests, zero failures. |
| 9 | Overlong global-search input is not presented as a completed no-results search. | ✓ VERIFIED | The 101-character regression test asserts the validation message and absence of ordinary no-results copy. `d1c467cd` invalidates previous in-flight results before setting validation state. |
| 10 | Current changed source and served assets are bound to wide/narrow, light/dark mounted evidence for the collection toolbar and final identity-cell consumers. | ✗ FAILED | The six retained Phase 246 images are revision-bound to earlier Plan 03/table-reading sources. `246-UI-REVIEW.md` confirms they do not show the current collection toolbar or five late identity consumers. This is missing required proof, not a claim that the UI failed visually. The Phase 245 manifest remains unchanged; current source is `7ca825a6bd4cae2c6153a71fdc1b21e05c48174c`. |

**Score:** 9/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | Shared filter/identity/table renderer | ✓ VERIFIED | Substantive shared controls, identity cells and responsive card behavior; used by collection LiveViews. |
| `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | Real constraint chips and reset | ✓ VERIFIED | Renders active constraints and scoped remove/reset links; wired from `DataTable`. |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | Search groups and async states | ✓ VERIFIED | Real owner-scoped billing queries, generation guards, partial failure retry and overlong-query validation. |
| `accrue_admin/assets/js/hooks/command_palette.js` | Single active result and focus behavior | ✓ VERIFIED | One active index controls pointer/keyboard selection and activation; registered from the top bar. |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | Canonical invoice criteria and result rows | ✓ VERIFIED | Connects query params, shared controls, scoped query and rendered rows. |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | Canonical subscription criteria and result rows | ✓ VERIFIED | Connects default status set, controls and existing scoped query. |
| `accrue_admin/lib/accrue_admin/components/empty_state.ex` | Distinct list absence/error presentation | ✓ VERIFIED | Shared and used across affected collection pages. |
| `.planning/phases/246-collection-controls-and-search/captures/phase246-table-reading/manifest.json` | Revision-bound current-source render evidence | ✗ FAILED | Manifest and images validate against historical source/asset hashes, but do not cover the final five-consumer identity adoption or toolbar. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Invoice status params | `DataTable` checkbox values and `Queries.Invoices` rows | Canonical status normalization and scoped query | ✓ WIRED | Source and mounted proof tie selected status, URL and result rows together. |
| Chip remove/reset | Current page navigation and owner scope | `DataTableNav` merge | ✓ WIRED | Scope and unrelated criteria are preserved by the page patch/clear paths and exercised in tests. |
| Collection controls | Existing per-page `Queries.*` predicates | LiveView params -> filter assigns -> query | ✓ WIRED | No new search predicate is introduced; exact relationship fields remain separate from q. |
| Search result index | Painted result, ARIA active descendant and Enter target | `CommandPalette.activeIndex` | ✓ WIRED | Node and mounted browser checks cover pointer-to-keyboard selection and activation. |
| Search component | Scoped customer/invoice/subscription data | Existing billing query functions | ✓ WIRED | Query calls receive current owner scope; generation/query/owner checks gate result updates. |
| Current source and served assets | Current-revision rendered proof | Captured PNG plus source/CSS/JS digest manifest | ✗ MISSING | Historical manifests validate, but do not bind the final source revision or depict the collection toolbar and five late identity renderers. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Collection LiveViews | rows and result counts | Existing owner-scoped `Queries.*` and summaries | Yes; query output is rendered in `DataTable` and count wording uses supplied summary/page values | ✓ FLOWING |
| Invoice/subscription status controls | selected status and row set | URL params -> canonical filter state -> scoped query | Yes; query status predicates are applied before rendering | ✓ FLOWING |
| Global billing search | customer, invoice and subscription groups | Existing billing search APIs with current owner scope | Yes; results and partial errors flow to the rendered groups | ✓ FLOWING |
| Identity cells | primary labels and exact IDs | Real row fields in each collection LiveView | Yes; separate secondary copy values are passed to `IdBadge`/clipboard hooks | ✓ FLOWING |
| Retained screenshots | rendered pixels | Browser captures named in manifests | Yes for each historical source revision; no current-source capture for the late changes | ⚠️ HISTORICAL |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Full current Admin regression | Current result reported by orchestrator; no rerun in this verification | 718 tests, 0 failures, 0 warnings/errors | ✓ PASS |
| Prior host seed boundary and regression checks | Current result reported by orchestrator; no rerun in this verification | 13 tests, 0 failures | ✓ PASS |
| Route inventory and verifier self-test | Current result reported by orchestrator; no rerun in this verification | Both passed | ✓ PASS |
| Invoice/collection mounted filter transitions, Unicode URL and history | Plan 01/02 recorded mounted Playwright results | URL, controls, scope and rows agreed | ✓ PASS |
| Global search pointer/keyboard and partial/held-out states | Plan 03 recorded Node and mounted Playwright results | Single selection, truthful pending state and scoped retry passed | ✓ PASS |
| Table zero/one/many, long identity and 320px geometry | Plan 04 recorded held-out Playwright results | State and geometry assertions passed; current-source visual review remains outstanding | ✓ PASS |

### Probe Execution

No phase-declared `probe-*.sh` or conventional project probe was found. The phase's browser and route inventory checks are reported above; they were not substituted for a declared probe.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| FILTER-01 | 01, 02, 04 | View/constraint distinction, labeled controls, removable chips and scoped reset | ✓ SATISFIED | Shared controls plus owner-scoped mounted assertions. |
| FILTER-02 | 01, 02, 04 | Multi-status defaults and URL/query/result agreement | ✓ SATISFIED | Invoice and subscription canonical status paths and mounted checks. |
| FILTER-03 | 02, 04 | Truthful general q and explicit exact relationship criteria | ✓ SATISFIED | Current field labels match existing query predicates; collection tests cover exact and custom values. |
| SEARCH-01 | 03, 04 | Compact global search with one active result and truthful async state | ✓ SATISFIED | Current component, hook, CSS, component/Node tests and mounted search checks. |
| TABLE-01 | 04 | Readable identity, state/money/time order, exact IDs and responsive priorities | ⚠️ BLOCKED ON CURRENT-REVISION EVIDENCE | Functional assertions and source are present; the late five identity renderers lack the required current-source rendered proof. |

No Phase 246 requirement mapped in `REQUIREMENTS.md` was orphaned from the plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | 322 | Partial-failure wording differs from UI-SPEC's literal retry sentence | ℹ️ INFO | The text truthfully says successful groups remain available and a scoped retry button is provided; UI review found no task-completion defect. |
| `accrue_admin/assets/css/app.css` | 1036 | Existing 2px/3px segmented-control geometry conflicts with UI-SPEC's 4px spacing scale | ℹ️ INFO | UI review records a minor existing contract mismatch; no functional failure, and the phase did not revise this control. |

No code anti-patterns were found: no unresolved `TBD`, `FIXME`, or `XXX` debt markers, empty user-visible implementations, or disconnected data paths were found in the inspected phase implementation. The missing D-13 evidence is recorded as a gap above, not as a code anti-pattern.

### Gaps Summary

The functional goal is implemented: collection filters, status sets, exact relationship criteria, global billing search, scoped query flows, and responsive table behavior have concrete source and test evidence. The phase has one blocking contract gap: final current-source rendered evidence is missing for the collection toolbar and five identity-cell consumers. Closure requires wide and 320px narrow captures in light and dark, plus manifests that verify the current source, served CSS/JS and screenshot digests. Phase 246 remains `gaps_found` until that evidence exists; Phase 248's follow-up cannot satisfy this phase's D-13 contract retroactively.

---

_Verified: 2026-10-11T19:37:17Z_  
_Verifier: the agent (gsd-verifier)_
