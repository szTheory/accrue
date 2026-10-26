---
phase: 246-collection-controls-and-search
verified: 2026-10-11T20:12:00Z
status: passed
score: 10/10 must-haves verified
covered_files:
  - .planning/phases/246-collection-controls-and-search/246-01-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-01-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-02-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-02-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-03-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-03-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-04-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-04-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-05-PLAN.md
  - .planning/phases/246-collection-controls-and-search/246-05-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/246-IDENTITY-GAP-SUMMARY.md
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/VISUAL-REVIEW.md
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-connect-accounts-narrow-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-connect-accounts-narrow-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-connect-accounts-wide-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-connect-accounts-wide-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-webhooks-narrow-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-webhooks-narrow-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-webhooks-wide-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/heldout-webhooks-wide-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/manifest.json
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/montage.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-coupons-narrow-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-coupons-narrow-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-coupons-wide-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-coupons-wide-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-events-narrow-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-events-narrow-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-events-wide-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-events-wide-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-invoices-toolbar-narrow-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-invoices-toolbar-narrow-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-invoices-toolbar-wide-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-invoices-toolbar-wide-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-payments-narrow-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-payments-narrow-light.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-payments-wide-dark.png
  - .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/ordinary-payments-wide-light.png
  - examples/accrue_host/e2e/phase246-current-proof.spec.js
  - scripts/ci/verify_phase246_render_proof.mjs
covered_digest: "v3:sha256:53bc29277fb71539c9d38a9b0fa64f06fa7d8f11b137e15175bda1b72beb0fd2"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/10
  gaps_closed:
    - "Current changed source and served assets are bound to wide/narrow, light/dark mounted evidence for the collection toolbar and final identity-cell consumers."
  gaps_remaining: []
  regressions: []
---

# Phase 246: Collection Controls and Search Verification Report

**Phase Goal:** Operators can find and scan existing billing records through coherent controls whose visible state matches the results.
**Verified:** 2026-10-11T20:12:00Z
**Status:** passed
**Re-verification:** Yes — after D-13 evidence gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Operators can distinguish views from applied constraints, remove one chip or reset, and see URL, controls, count and rows agree. | ✓ VERIFIED | Shared controls and owner-scoped mounted filter assertions cover URL/control/result agreement. |
| 2 | Invoice status defaults and direct status sets agree with selected controls and scoped rows. | ✓ VERIFIED | Canonical status normalization and mounted invoice assertions verify selection, URL, count, rows and scope. |
| 3 | Subscription status combinations and Coupons All/Valid preserve selected state and query agreement. | ✓ VERIFIED | LiveView tests and mounted checks cover defaults, direct transitions and scoped predicates. |
| 4 | General search guidance matches predicates, with exact relationship filters separately labeled. | ✓ VERIFIED | Collection owners expose named exact fields; query and collection tests cover those predicates. |
| 5 | Global billing search presents grouped results and one active pointer/keyboard result with truthful async states. | ✓ VERIFIED | Search component, hook, current Admin tests and mounted checks cover active selection, partial failure, retry and validation. |
| 6 | Table rows separate primary identity from exact copyable IDs, preserve useful field order and distinguish empty/error states. | ✓ VERIFIED | Shared table/empty-state components are wired; five consumer identity regressions pass in the final Admin run (718 tests, 0 failures/warnings). |
| 7 | Controls, search and table content remain usable at wide and 320px narrow sizes, including long values and partial states. | ✓ VERIFIED | Existing mounted behavior/geometry assertions plus the current proof's four viewport/theme combinations cover the updated consumers. |
| 8 | Ordinary preview seeding fails closed outside its isolated test/development database boundary. | ✓ VERIFIED | Seed guard checks database, role and resolved server address; named boundary checks reject unsafe settings (13 host tests passed). |
| 9 | Overlong global-search input is not presented as a completed no-results search. | ✓ VERIFIED | Regression asserts validation copy and absence of no-results state; stale results are invalidated before validation renders. |
| 10 | Current changed source and served assets are bound to wide/narrow, light/dark mounted evidence for the collection toolbar and final identity-cell consumers. | ✓ VERIFIED | The current-proof manifest validates 24 PNGs across four ordinary routes and two held-out routes, with CSS/JS served digests matching built assets. Product and fixture source hashes match captured commit `39a52efed8fc3a1016f0c636740f5a41bc45540a` and current files. Visual review inspected the montage and full-page captures. |

**Score:** 10/10 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/lib/accrue_admin/components/data_table.ex` | Shared filter/identity/table renderer | ✓ VERIFIED | Substantive and wired to collection LiveViews. |
| `accrue_admin/lib/accrue_admin/components/filter_chip_bar.ex` | Removable constraint chips and reset | ✓ VERIFIED | Rendered through DataTable with scoped navigation. |
| `accrue_admin/lib/accrue_admin/components/global_search.ex` | Search groups and async states | ✓ VERIFIED | Real owner-scoped query flow, generation guards and retry handling. |
| `accrue_admin/assets/js/hooks/command_palette.js` | Active result and keyboard behavior | ✓ VERIFIED | Shared active index drives pointer/keyboard selection and activation. |
| `accrue_admin/lib/accrue_admin/live/invoices_live.ex` | Canonical criteria and result rows | ✓ VERIFIED | Connects URL parameters, shared controls and scoped query. |
| `accrue_admin/lib/accrue_admin/live/subscriptions_live.ex` | Status criteria and result rows | ✓ VERIFIED | Connects defaults, controls and existing scoped query. |
| `accrue_admin/lib/accrue_admin/components/empty_state.ex` | Distinct absence/error presentation | ✓ VERIFIED | Shared component is used by affected collection pages. |
| `examples/accrue_host/e2e/phase246-current-proof.spec.js` | Mounted current-source render evidence | ✓ VERIFIED | Captures actual routes in ordinary and held-out lanes at required viewports/themes. |
| `scripts/ci/verify_phase246_render_proof.mjs` | Evidence integrity validator | ✓ VERIFIED | Independently validates manifest, PNGs, route matrix, source and served assets. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Invoice status params | DataTable controls and invoice rows | Canonical normalization and scoped query | ✓ WIRED | Mounted assertions verify URL, selection and visible rows agree. |
| Chip remove/reset | Current page navigation and owner scope | DataTableNav merge | ✓ WIRED | Existing criteria and scope persist through targeted remove/reset paths. |
| Collection controls | Existing query predicates | LiveView params to filter assigns to query | ✓ WIRED | Exact relationship filters remain separate from general q. |
| Search result index | Painted result, ARIA and Enter target | CommandPalette activeIndex | ✓ WIRED | Pointer and keyboard paths share the active selection. |
| Search component | Owner-scoped billing data | Existing billing queries | ✓ FLOWING | Query outputs and partial failures flow into rendered groups. |
| Mounted routes | Current source and served assets | Current-proof manifest and validator | ✓ VERIFIED | 24 images and asset/source hashes validate against captured and current product inputs. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Collection LiveViews | Rows and counts | Existing owner-scoped queries and summaries | Yes | ✓ FLOWING |
| Status controls | Selected status and row set | URL params to canonical state to scoped query | Yes | ✓ FLOWING |
| Global search | Customer, invoice and subscription groups | Existing scoped billing search functions | Yes | ✓ FLOWING |
| Identity cells | Primary labels and exact IDs | Real row fields passed to IdBadge/clipboard hook | Yes | ✓ FLOWING |
| Current-proof screenshots | Rendered pixels | Mounted browser capture bound by manifest digests | Yes, current captured revision | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Evidence | Result | Status |
|---|---|---|---|
| Final Admin regression | Orchestrator's just-run current result | 718 tests, 0 failures, 0 warnings/errors | ✓ PASS |
| Prior host seed boundary tests | Orchestrator's current result | 13 tests, 0 failures | ✓ PASS |
| Route inventory and verifier self-test | Orchestrator's current result | Both passed | ✓ PASS |
| Current render proof | `node scripts/ci/verify_phase246_render_proof.mjs --manifest .planning/phases/246-collection-controls-and-search/captures/phase246-current-proof/manifest.json` | Validated 24 PNGs across four ordinary and two held-out routes; served asset digests matched built assets | ✓ PASS |
| Focused identity suites | Plan 05 recorded result | 60 tests, 0 failures | ✓ PASS |

### Probe Execution

No phase-declared or conventional `probe-*.sh` was found.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| FILTER-01 | 01, 02, 04 | View/constraint distinction, labels, removable chips and scoped reset | ✓ SATISFIED | Shared controls and mounted assertions. |
| FILTER-02 | 01, 02, 04 | Multi-status defaults and URL/query/result agreement | ✓ SATISFIED | Invoice/subscription canonical status paths and mounted checks. |
| FILTER-03 | 02, 04 | Truthful general q and explicit relationship criteria | ✓ SATISFIED | Labels, predicates and collection tests. |
| SEARCH-01 | 03, 04 | Compact global search with one active result and truthful async state | ✓ SATISFIED | Component/hook and tests for pointer, keyboard, validation and partial states. |
| TABLE-01 | 04 | Readable identity, exact IDs, useful ordering and responsive priorities | ✓ SATISFIED | Five consumer identity tests and current wide/narrow light/dark mounted proof. Copy interaction shows existing visible copied-state feedback (`data-copied`); it is not a toast. |

No Phase 246 requirement mapped in REQUIREMENTS.md was orphaned from the plans.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|---|---|---|---|
| `global_search.ex` | Partial-failure wording differs slightly from UI-SPEC's literal retry sentence | ℹ️ INFO | Copy remains accurate about retained successful groups and scoped retry. |
| `app.css` | Existing segmented-control spacing differs from the UI-SPEC spacing scale | ℹ️ INFO | Minor visual-contract mismatch; no functional blocker. |

No unresolved debt markers or empty user-visible implementations were found in the previously inspected implementation. The sole carried evidence gap is closed; no regressions were found.

### Gaps Summary

The prior D-13 evidence gap is closed. The current committed revision's product, fixture and asset inputs match the captured source hashes, and the validator confirms all 24 required mounted captures, their dimensions and served CSS/JS digests. The report records copied-state feedback accurately; toast behavior is not claimed. No remaining unverified behaviors or blockers were identified.

---

_Verified: 2026-10-11T20:12:00Z_  
_Verifier: the agent (gsd-verifier)_
