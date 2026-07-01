---
phase: 197-propagate-list
verified: 2026-06-28T19:13:40Z
status: passed
score: 28/28 must-haves verified
behavior_unverified: 0
overrides_applied: 0
known_unrelated_failures:
  - command: "cd accrue_admin && mix test test/accrue_admin/live/dashboard_live_test.exs --max-failures 1"
    result: "1 failure at test/accrue_admin/live/dashboard_live_test.exs:119 asserting \"$42.50\""
    classification: "not Phase 197 blocking"
    reason: "Dashboard source/test files were not touched by Phase 197; Phase 197 copy.ex diff adds LIST helper functions and does not change dashboard copy functions."
---

# Phase 197: Propagate LIST Verification Report

**Phase Goal:** Every remaining list page is internally consistent with the locked list spec and adopts the shared `PageHeader`.
**Verified:** 2026-06-28T19:13:40Z
**Status:** passed
**Re-verification:** No - initial verification; no prior `197-VERIFICATION.md` existed.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | All 8 remaining list pages conform to SPEC-LIST: table-first, chips/count/clear-all, work-queue default, row-to-card degradation. | VERIFIED | All eight target LiveViews render `DataTable` with `list_id`, `list_state`, `empty_reason`, `render_filter_toolbar={false}`, and `FilterChipBar` in `:list_status`; `npm run e2e:phase197` passed 15/15 executed browser checks, including desktop all-page smoke and mobile card checks. |
| 2 | Every page adopts `PageHeader` and renders exactly one `<h1>`. | VERIFIED | All eight LiveViews render `PageHeader.page_header`; focused LiveView tests parse rendered HTML and assert exactly one `h1`. Eight-page LiveView suite passed: 63 tests, 0 failures. |
| 3 | Each page carries per-page JTBD microcopy and covers populated, first-run-empty, filtered-empty, and loading states. | VERIFIED | `AccrueAdmin.Copy` exposes page-specific list helper functions; `AccrueAdmin.ListContracts` contains state copy for all eight pages; LiveView tests exercise populated/first-run/filtered/queue/loading states. |
| 4 | Wave 0 creates executable LIST propagation contracts before runtime changes. | VERIFIED | `accrue_admin/test/support/list_contracts.ex`, focused LiveView tests, query tests, and `e2e:phase197` exist and are wired. |
| 5 | All eight target routes have test-only contract entries with route, list id, default lens, all target, state copy, and loading fixture expectations. | VERIFIED | `AccrueAdmin.ListContracts.all/0` defines customers, invoices, payments, coupons, promotion codes, webhooks, events, and connect contracts. |
| 6 | The Phase 197 Playwright command exists and targets all-page smoke plus representative deep coverage. | VERIFIED | `package.json` script is `env -u NO_COLOR playwright test e2e/admin-spec-list-phase197.spec.js --timeout=60000 --workers=1`; Node syntax check passed. |
| 7 | Each target LiveView has focused tests for PageHeader, one h1, chips/count/clear-all, default lens, clear-all scope, and states. | VERIFIED | `rg` found these assertions across all eight LiveView test files; eight-page LiveView suite passed. |
| 8 | Tests capture page-specific default lenses from the phase decisions. | VERIFIED | Tests assert all/default/queue lenses: customers all, invoices needs collection, payments failed, coupons valid, promotion codes active, webhooks needs replay, events all ledger/admin changes, connect needs attention. |
| 9 | Verification remains focused rather than becoming a full browser matrix. | VERIFIED | Playwright spec runs desktop all-page/deep checks and mobile card smoke with project skips; result was 15 passed, 15 skipped. |
| 10 | Per-page JTBD and four-state copy is available through `AccrueAdmin.Copy`. | VERIFIED | Copy helper tests passed in the query/copy/component gate: 64 tests, 0 failures. |
| 11 | Webhooks represents Needs replay as a real failed/dead filter, not UI-only copy. | VERIFIED | `Queries.Webhooks.decode_filter/1` allowlists comma-separated statuses and filters failed/dead; query tests passed. |
| 12 | Connect represents Needs attention as a named OR lens, not AND-ed readiness booleans. | VERIFIED | `Queries.ConnectAccounts` applies `needs_attention` as an OR predicate over deauthorized/onboarding/charges/payouts readiness; query tests passed. |
| 13 | Payments/Charges owner scope is explicit before Payments adopts filter links. | VERIFIED | `Queries.Charges` joins customers and scopes before filtering/counting; query tests passed. |
| 14 | Customers, Coupons, and Promotion codes adopt `PageHeader` and one h1. | VERIFIED | Source renders `PageHeader`; focused tests passed for those three pages. |
| 15 | Customers defaults to All customers with a Missing payment method quick lens. | VERIFIED | `CustomersLive.customer_lens_chips/2` renders All and Missing payment method; focused and browser checks passed. |
| 16 | Coupons defaults to Valid coupons; Promotion codes defaults to Active codes. | VERIFIED | Both LiveViews push/assign default params and expose `view=all`; focused tests and browser smoke passed. |
| 17 | Customers/Coupons/Promotion codes render chips/count/clear-all, row-card DataTable behavior, and four states. | VERIFIED | LiveView tests passed; browser smoke includes these pages and mobile card checks. |
| 18 | Invoices defaults to Needs collection with All invoices one chip away. | VERIFIED | `InvoicesLive` defaults to `status=open,uncollectible`; focused tests and browser deep check passed. |
| 19 | Payments defaults to Failed payments on `/payments` through `ChargesLive` without `/charges` UI/test copy. | VERIFIED | `ChargesLive` uses `list_id="payments"` and payment copy while keeping `query_module={Charges}`; focused tests passed. |
| 20 | Invoices and Payments adopt PageHeader, URL filters, FilterChipBar, states, owner-safe clear-all, and row-card degradation. | VERIFIED | Source wiring and focused tests passed; clear-all links preserve `org` and route to `view=all`. |
| 21 | Webhooks defaults to Needs replay backed by `status=failed,dead` and preserves bulk retry behavior. | VERIFIED | `WebhooksLive` default params, selection confirmation, scoped replay filtering, and browser bulk replay check passed. |
| 22 | Events defaults to All ledger and keeps Admin changes as a quick lens. | VERIFIED | `EventsLive` all-ledger/admin chip code present; focused and browser checks passed. |
| 23 | Connect defaults to Needs attention backed by the named OR query lens. | VERIFIED | `ConnectAccountsLive` defaults to `needs_attention=true`; `ConnectAccounts` query and LiveView owner-scope tests passed after blocker fix. |
| 24 | Webhooks/Events/Connect adopt PageHeader, one h1, FilterChipBar, states, owner-safe clear-all, and row-card degradation. | VERIFIED | Source wiring and focused tests passed; browser smoke covers all three. |
| 25 | The Phase 197 browser smoke passes across all eight target list routes. | VERIFIED | `npm run e2e:phase197` passed: 15 passed, 15 skipped, 0 failed. |
| 26 | Representative deep browser coverage proves reference, status queue, bulk replay queue, ledger, and OR attention states. | VERIFIED | Browser spec executed customers, invoices, webhooks, events, connect, loading fixture, and mobile row-card checks. |
| 27 | Focused LiveView, query, copy, and component tests pass for the Phase 197 surface. | VERIFIED | LiveView suite passed 63 tests; query/copy/component suite passed 64 tests; compile passed with warnings as errors. |
| 28 | No Phase 197 plan relies on an exhaustive browser matrix or Phase 200 final sign-off. | VERIFIED | Phase-specific Playwright is representative and green; Phase 199/200 own cross-cutting fixture stress, overlay sweep, and final photographic/sign-off gates. |

**Score:** 28/28 truths verified, 0 behavior-unverified.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/test/support/list_contracts.ex` | Test-only manifest for all eight target pages | VERIFIED | Exists, substantive, used by LiveView tests. |
| `accrue_admin/e2e/admin-spec-list-phase197.spec.js` | Phase browser LIST contract | VERIFIED | Syntax check passed; browser command passed. |
| `accrue_admin/package.json` | `e2e:phase197` script | VERIFIED | Script points at the Phase 197 Playwright spec. |
| Eight target LiveViews | LIST propagation implementation | VERIFIED | All render `PageHeader`, `DataTable`, and `FilterChipBar`; focused tests passed. |
| Copy/query modules | JTBD copy, default lenses, owner-scope filters | VERIFIED | Copy/query/component tests passed; query code uses real `Repo`/Ecto data flow. |
| Focused LiveView/query/copy/component tests | Behavioral contracts | VERIFIED | 127 focused ExUnit tests passed across the two verifier commands. |

Artifact verifier results across plan frontmatter: 20/20 passed. Key-link verifier results: 16/16 verified.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `package.json` | Phase 197 Playwright spec | `e2e:phase197` script | VERIFIED | GSD key-link verifier found the pattern; command passed. |
| `ListContracts` | LiveView tests | Shared contract import | VERIFIED | Tests import and use `AccrueAdmin.ListContracts`. |
| LiveViews | `PageHeader` / `DataTable` / `FilterChipBar` | Rendered component chain | VERIFIED | Source and focused tests confirm markers and exactly one h1. |
| LiveViews | Copy helpers | `AccrueAdmin.Copy.*_list_*` calls | VERIFIED | Per-page headings, subtitles, state text, labels, and result labels are wired. |
| Invoices/Payments/Webhooks/Connect | Query modules | `query_module={...}` plus default URL params | VERIFIED | Query modules implement real default-lens semantics and owner scope. |
| Playwright spec | all eight routes | `/billing/customers`, invoices, payments, coupons, promotion-codes, webhooks, events, connect | VERIFIED | Browser run passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Target LiveViews | `@params`, `@summary`, DataTable rows | LiveView params + summary queries + DataTable `query_module` | Yes | VERIFIED |
| `DataTable` | `@rows`, `@list_state`, `@filter_params` | Calls each query module with decoded filters and `current_owner_scope` | Yes | VERIFIED |
| `Queries.Charges` | payments rows/counts | Ecto query joining `Charge` and `Customer` | Yes | VERIFIED |
| `Queries.ConnectAccounts` | connect rows/counts | Ecto query over `Account`, scoped before filters | Yes | VERIFIED |
| `Queries.Webhooks` | webhook rows/counts | Ecto query + owner-scope row proof | Yes | VERIFIED |
| Copy helpers | page copy/state labels | `AccrueAdmin.Copy` and resource copy modules | Yes | VERIFIED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| All eight list LiveViews satisfy PageHeader, default lens, chip/count/clear-all, scope, and state contracts | `mix test test/accrue_admin/live/customers_live_test.exs ... test/accrue_admin/live/connect_accounts_live_test.exs --max-failures 3` | 63 tests, 0 failures | PASS |
| Query/copy/component contracts | `mix test test/accrue_admin/queries/query_modules_test.exs test/accrue_admin/copy_test.exs test/accrue_admin/components/page_header_test.exs test/accrue_admin/components/data_table_test.exs test/accrue_admin/components/filter_chip_bar_test.exs --max-failures 3` | 64 tests, 0 failures | PASS |
| Compile warnings gate | `mix compile --warnings-as-errors` | Exit 0 | PASS |
| Phase browser contract | `npm run e2e:phase197` | 15 passed, 15 skipped, 0 failed | PASS |
| Browser spec syntax | `node --check e2e/admin-spec-list-phase197.spec.js` | Exit 0 | PASS |
| Package documentation guard | `bash scripts/ci/verify_package_docs.sh` | Package docs verified for all packages | PASS |
| Known Dashboard broad-suite blocker boundary | `mix test test/accrue_admin/live/dashboard_live_test.exs --max-failures 1` | Failed at `dashboard_live_test.exs:119` on `$42.50` | NON-BLOCKING |

### Probe Execution

| Probe | Command | Result | Status |
|---|---|---|---|
| No `scripts/**/tests/probe-*.sh` probes declared or discovered for Phase 197 | Not applicable | No probes found | SKIPPED |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| PRP-01 | All seven Phase 197 plans | All 8 remaining list pages conform to SPEC-LIST, adopt `PageHeader`, and carry per-page JTBD microcopy plus four-state coverage. | SATISFIED | Roadmap success criteria verified; all focused ExUnit and Phase 197 Playwright gates passed. |

No orphaned Phase 197 requirements were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| None | - | No unresolved `TBD`/`FIXME`/`XXX`; no stubs found | - | Placeholder scan hits were legitimate form placeholder attributes or existing package-script text, not incomplete implementations. |

### Human Verification Required

None for Phase 197. The phase-specific browser contract passed. The later milestone phases explicitly own the broader visual/interaction/microcopy sweep and final maintainer photographic sign-off.

### Known Unrelated Broad-Suite Failure

The broad `cd accrue_admin && mix test --warnings-as-errors` suite is still blocked by the Dashboard assertion already documented in `197-07-SUMMARY.md`. I verified the current failure with the focused command:

`mix test test/accrue_admin/live/dashboard_live_test.exs --max-failures 1`

It fails at `test/accrue_admin/live/dashboard_live_test.exs:119` on `assert html =~ "$42.50"`. This is not a Phase 197 blocker:

- Phase 197 did not modify `accrue_admin/lib/accrue_admin/live/dashboard_live.ex` or `accrue_admin/test/accrue_admin/live/dashboard_live_test.exs`.
- The Phase 197 diff to `accrue_admin/lib/accrue_admin/copy.ex` adds LIST helper functions/delegates and does not change the Dashboard copy functions used by that assertion.
- All Phase 197 focused LiveView/query/copy/component/browser gates passed after the Connect owner-scope fix.

### Gaps Summary

No Phase 197 gaps found. The Connect owner-scope review blocker is closed in code and tests. The phase goal is achieved.

---

_Verified: 2026-06-28T19:13:40Z_
_Verifier: the agent (gsd-verifier)_
