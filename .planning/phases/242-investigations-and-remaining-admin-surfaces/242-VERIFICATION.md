---
phase: 242-investigations-and-remaining-admin-surfaces
verified: 2026-10-10T14:33:13Z
status: passed
score: 80/80 must-haves verified
covered_files:
  - .github/workflows/accrue_admin_browser.yml
  - .planning/phases/240-shared-system-and-real-billing-exemplar/240-COVERAGE.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-01-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-01-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-02-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-02-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-03-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-03-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-04-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-04-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-05-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-05-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-06-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-06-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-07-PLAN.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-07-SUMMARY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-CONTEXT.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-EXECUTION-GATES.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-PATTERNS.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-PROBE-COVERAGE.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-REGRESSION.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-RESEARCH.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-REVIEW-DISPOSITION.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-REVIEW-FIX.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-REVIEW.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-SECURITY.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-UI-FIX.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-UI-REVIEW.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-UI-SPEC.md
  - .planning/phases/242-investigations-and-remaining-admin-surfaces/242-VALIDATION.md
  - accrue_admin/assets/css/app.css
  - accrue_admin/assets/css/theme.css
  - accrue_admin/assets/js/hooks/command_palette.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase191.spec.js
  - accrue_admin/lib/accrue_admin/components/global_search.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/connect.ex
  - accrue_admin/lib/accrue_admin/copy/coupon.ex
  - accrue_admin/lib/accrue_admin/copy/invoice.ex
  - accrue_admin/lib/accrue_admin/copy/promotion_code.ex
  - accrue_admin/lib/accrue_admin/live/connect_account_live.ex
  - accrue_admin/lib/accrue_admin/live/connect_accounts_live.ex
  - accrue_admin/lib/accrue_admin/live/coupon_live.ex
  - accrue_admin/lib/accrue_admin/live/coupons_live.ex
  - accrue_admin/lib/accrue_admin/live/dashboard_live.ex
  - accrue_admin/lib/accrue_admin/live/event_live.ex
  - accrue_admin/lib/accrue_admin/live/events_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/invoices_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_code_live.ex
  - accrue_admin/lib/accrue_admin/live/promotion_codes_live.ex
  - accrue_admin/lib/accrue_admin/live/webhook_live.ex
  - accrue_admin/lib/accrue_admin/live/webhooks_live.ex
  - accrue_admin/lib/accrue_admin/scoped_path.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/app_shell_test.exs
  - accrue_admin/test/accrue_admin/components/global_search_test.exs
  - accrue_admin/test/accrue_admin/copy/billing_event_test.exs
  - accrue_admin/test/accrue_admin/copy/connect_test.exs
  - accrue_admin/test/accrue_admin/copy_test.exs
  - accrue_admin/test/accrue_admin/live/connect_account_live_test.exs
  - accrue_admin/test/accrue_admin/live/connect_accounts_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupon_live_test.exs
  - accrue_admin/test/accrue_admin/live/coupons_live_test.exs
  - accrue_admin/test/accrue_admin/live/dashboard_live_test.exs
  - accrue_admin/test/accrue_admin/live/event_live_test.exs
  - accrue_admin/test/accrue_admin/live/events_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoices_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_code_live_test.exs
  - accrue_admin/test/accrue_admin/live/promotion_codes_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_live_test.exs
  - accrue_admin/test/accrue_admin/live/webhook_replay_test.exs
  - accrue_admin/test/accrue_admin/live/webhooks_live_test.exs
  - accrue_admin/test/accrue_admin/queries/events_test.exs
  - accrue_admin/test/accrue_admin/scoped_path_test.exs
  - accrue_admin/test/js/command_palette_test.mjs
  - accrue_admin/test/support/list_contracts.ex
  - examples/accrue_host/e2e/phase234-search-completion.spec.js
  - examples/accrue_host/e2e/phase238-admin-events-webhooks.spec.js
  - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
covered_digest: "v3:sha256:e1f5a6b7d383057a2869a039e98d65188ea8559643d14cee126ddcb56e74c855"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 242: Investigations and Remaining Admin Surfaces — Verification Report

**Phase Goal:** Operators can investigate existing events and deliveries, understand catalog and Connect relationships, and find the correct scoped record through a consistent Admin shell and domain language.
**Verified:** 2026-10-10T14:33:13Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Operators can follow filtered event and webhook worklists into related evidence and supported replay review, then return with bounded supported context; material failure, uncertainty and exact diagnostic details remain discoverable. (JRN-05) | ✓ VERIFIED | `ScopedPath` has finite event/delivery route keys and rebuilds using current mount/owner; event query and LiveView tests assert exact filter membership and authorized source/subject links. Replay LiveView/domain tests assert unique captured delivery IDs, fresh eligibility/scope, queue/job/audit outcomes, dismissal/no-dispatch, and pre/post-acceptance read failures. Host Phase 238 exercised the mounted relationship/replay route. |
| 2 | Operators can inspect existing discounts, promotion-code relationships and Connect facts, preserve bounded list/relationship context, and use supported actions with a clear distinction between stored provider facts and local policy. (JRN-06) | ✓ VERIFIED | Coupon/code route tests assert returned filters, exact parent FK identity, missing parent and unknown limits. Coupon/PromotionCode schemas have no owner fields; no tenant-filtered membership is claimed. Connect source and tests keep stored provider observations separate from local fee policy and verify preview/save boundaries, validation, fresh policy/actor and dismissal. Phase 191 mounted catalog/fee review assertions ran. |
| 3 | Operators can find the correct scoped record from Home, navigation and search, with visible selection that agrees across pointer and keyboard input. (JRN-07) | ✓ VERIFIED | Home/shell LiveView tests assert current owner/path/active link. Search test owners cover five-result bounds, group retry preservation and query/generation/current-owner guards; Node tests exercise pointer/Arrow/Enter and replacement selection; host Phase 234 exercises mounted scoped link activation. |
| 4 | Across changed lists, details, filters and reviews, operators encounter coherent resource, collection-method and action language while diagnostic terms and locked audit/legal meaning stay exact. (UXC-01) | ✓ VERIFIED | Copy and rendered route assertions distinguish event/delivery, coupon/discount definition/promotion code, routine Payments from diagnostic Charge, and human collection labels from raw enums. `Copy.Locked` remains byte-identical; Phase 191/238 browser assertions ran against served assets. |

**Score:** 80/80 plan must-have truths verified (28 explicit edge predicates, 44 UI predicates, six plan decision contracts, and two mounted-consumer acceptance truths). This is not a universal route × state × viewport coverage claim: predicate owners are the named semantic and browser assertions below, and a state is credited only where that owner asserts it.

### Plan Must-Have Predicate Owners

The 28 resolved edge predicates and 44 resolved UI predicates from `242-PROBE-COVERAGE.md` are mapped to plan owners as follows. The executed combined suites prove registered tests ran; feature credit comes from the specific named assertions, not aggregate totals alone.

| Plan | Truths | Evidence owners and verified behaviors |
|---|---:|---|
| 242-01 | 11 | `scoped_path_test.exs`, `queries/events_test.exs`, `events_live_test.exs`, `event_live_test.exs`; event filter decoder/encoder parity, actual membership, safe returns, exact related identities, unavailable/empty states. |
| 242-02 | 15 | `webhooks_live_test.exs`, `webhook_replay_test.exs`, `webhook_live_test.exs`, host replay domain owner; exact selected set, fresh checks, no-dispatch controls, actual per-delivery outcomes, and pre-dispatch versus accepted-enqueue read failure. |
| 242-03 | 14 | Coupon and promotion-code list/detail owners plus `scoped_path_test.exs`; actual parent/filter membership, missing/foreign parent, exact identities, zero versus unrecorded limits and distinct collection states. |
| 242-04 | 12 | Connect list/detail, fee review and Copy owners; provider snapshot versus local policy, exact preview and validation, current account/policy/actor checks, duplicate/dismissal behavior. |
| 242-05 | 17 | `global_search_test.exs`, `command_palette_test.mjs`, host Phase 234; bounded groups, partial retry preservation, stale query/owner guards, authoritative active-result pointer/Arrow/Enter behavior. |
| 242-06 | 9 | Home/shell, invoice list/detail and Copy owners; scoped route/active owner, collection labels, unknown/empty distinctions and protected wording. |
| 242-07 | 2 | Package Phase 191/199 and host Phase 238/234 assertions, source-to-built-to-compiled-to-served asset identity, existing CI Node step update and combined regression gate. |

Plan frontmatter `key_links` are prose acceptance statements rather than machine-checkable path pairs. `verify.key-links` returned zero structured links for Plan 01, so no helper output is presented as proof; the concrete source-to-caller relationships were checked in `ScopedPath`, the route LiveViews, search hook/component and named behavioral tests.

## Required Artifacts

All declared plan artifacts passed `verify.artifacts`: Plan 01 8/8, Plan 02 6/6, Plan 03 10/10, Plan 04 6/6, Plan 05 4/4, Plan 06 9/9, Plan 07 6/6 (49/49 total). Files are substantive and consumed by the relevant router, LiveView/component, query, Copy module, tests or browser owner. Dynamic collections flow through existing Ecto queries with owner scope where the data model supports it. Global Coupon and PromotionCode are incumbent global records, with exact FK relationship identity and route/session context only.

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ScopedPath` | Events/Webhooks/Coupons/PromotionCodes/Connect list lenses | finite return map + destination decoder/encoder + fresh owner rebuild | WIRED | `scoped_path.ex` route entries are used by detail/list LiveViews; tests assert decoder parity, label/path pairing, fallback, rejected malformed/duplicate values and actual rows. |
| Events list/detail | event query and source/subject records | scoped query, identity checks, rendered related hrefs | WIRED | Event query and detail tests assert q/type/actor/subject/source membership plus exact authorized links; inaccessible/missing relations do not link to substitutes. |
| Webhook review | scoped deliveries → DLQ enqueue → job/audit result | captured IDs, fresh checks, StepUp, transaction/domain owners | WIRED | Replay owner tests assert queued/skipped/denied/failed/unknown distinctions and job/audit/domain state; dismissal and denied step-up do not dispatch. |
| Coupon/code details | catalog queries and parent relation | exact FK identity and filtered route context | WIRED | LiveView assertions check exact coupon parent and constrained child results. Catalog scope is global by incumbent schema. |
| Connect fee form | validated domain preview and persisted local policy | review event → fresh target/policy/actor → existing policy/domain path | WIRED | Connect tests verify exact validated values and persisted results; provider-readiness fields remain stored observations. |
| GlobalSearch | scoped query groups and CommandPalette hook | bounded Ecto lookups + JS active item state | WIRED | Component and Node owners verify current owner/generation, partial retry and pointer/keyboard activation on the active real link. |
| Home and shell | `ScopedPath` plus owner banner/active route | resolved current mount and owner | WIRED | Dashboard and app-shell tests assert active link/path and owner identity. |
| Assets | package sources → committed bundle → host HTTP/browser resources | package build and host Phase 238 identity assertions | FLOWING | Package and host bundle digests agree; host owner compared package, host-compiled, served HTTP and browser resource bytes. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Real data | Status |
|---|---|---|---|---|
| Events/Webhooks list and detail | event/delivery records and evidence | scoped Ecto queries, exact relation lookups | Yes | FLOWING |
| Coupon/PromotionCode lists/details | global catalog rows and coupon FK | existing catalog Ecto queries and exact FK checks | Yes; no owner fields | FLOWING |
| Connect list/detail | connected-account snapshot and local fee policy | account query and persisted local policy | Yes; snapshot freshness not claimed | FLOWING |
| Global search | Customer/Invoice/Subscription groups | existing scoped query modules, limit 5 each | Yes | FLOWING |
| Home/shell | route and owner labels | resolved Admin mount/session scope | Yes | FLOWING |
| Browser assets | CSS/JS | package build artifacts and served resource bytes | Yes | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Combined Admin, hook, and host regression | `cd accrue_admin && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test && node --test test/js/*.mjs && cd ../examples/accrue_host && MIX_ENV=test mix compile --warnings-as-errors && MIX_ENV=test mix test` | Exit 0; Admin 679/0, Node 44/44, host 223/0; both warnings-as-errors compiles passed. Executed by the parent verification runner; log `/private/tmp/accrue242-final-regression.log`. | ✓ PASS |
| Package browser consumers | `CI=1 npm --prefix accrue_admin run e2e:phase191` and `... run e2e:phase199` | 29 passed/1 incumbent applicability skip; 27 passed/15 incumbent applicability skips. No acceptance assertion or threshold was relaxed. | ✓ PASS |
| Mounted host consumers and served asset identity | `cd examples/accrue_host && CI=1 npx playwright test e2e/phase238-admin-events-webhooks.spec.js e2e/phase234-search-completion.spec.js --project=chromium-desktop --workers=1` | 2 passed; package/compiled/HTTP/browser CSS and JS identity checks passed. | ✓ PASS |
| Prior Phase 240/241 browser regressions | Phase 196 14/0; Phase 198 28 passed/4 incumbent skips; Phase 237 1/0 | Permitted runner passed; `/private/tmp/accrue242-prior-browser-regression-permitted.log`. | ✓ PASS |
| Retry behavior after WR-01 | `MIX_ENV=test mix test test/accrue_admin/components/global_search_test.exs` | 16 tests, 0 failures; existing successful group survives successful and failed retried groups; ordinary query still starts empty. | ✓ PASS |
| Corrective UI assertions and source syntax | Focused Events/GlobalSearch ExUnit (29/0); `node -c` on both changed package specs | Passed; current exact Events empty copy, Body token and Home 44px coarse-pointer geometry assertion included. | ✓ PASS |

Behavior-dependent search, replay and fee-save transitions have named passing semantic or mounted tests; `behavior_unverified: 0`. Node hook tests use a controlled DOM harness and are not themselves mounted-browser evidence. The separate mounted owners supply that evidence only for their asserted workflows.

## Probe Execution

No phase-declared `probe-*.sh` exists in the PLAN/SUMMARY files, and no conventional `scripts/*/tests/probe-*.sh` file was found. This UI/application phase has no separate probe command to execute.

## Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|---|---|---|---|---|
| JRN-05 | 242-01, 242-02, 242-07 | Trace event/delivery evidence and supported replay without hiding uncertainty or diagnostics. | ✓ SATISFIED | Event query/detail membership assertions; replay semantic/domain controls; mounted host Phase 238. |
| JRN-06 | 242-01, 242-03, 242-04, 242-07 | Inspect discounts, exact promotion-code relationships and Connect facts/actions with provider/local-policy separation. | ✓ SATISFIED | Catalog/Connect semantic owners and mounted Phase 191 review; global catalog model preserved. |
| JRN-07 | 242-05, 242-06, 242-07 | Find the scoped record from Home/navigation/search with consistent pointer and keyboard selection. | ✓ SATISFIED | Home/shell tests, GlobalSearch and hook tests, mounted host Phase 234. |
| UXC-01 | 242-02, 242-03, 242-06, 242-07 | Coherent domain language while exact diagnostics and locked copy remain intact. | ✓ SATISFIED | Copy and rendered LiveView assertions; `Copy.Locked` unchanged; mounted route assertions. |

Every requirement listed by all seven PLAN frontmatters resolves to REQUIREMENTS.md. The four Phase 242 requirement IDs are the roadmap-mapped requirements; there is no additional requirement mapped to Phase 242 without a claiming plan.

## Closure Artifacts and Anti-Patterns

- Validation audit: `validated`, Nyquist compliant, wave 0 complete; all 16 task owners have nonzero accepted evidence.
- Security audit: `verified`, ASVS L1, 8/8 threats closed, 0 open; planned existing-dependency risk is recorded as accepted.
- Code review: WR-01 fixed; specific semantic retry regression passed; disposition records `open: 0`.
- UI review: 16/24 initially; one bounded corrective batch addressed body 16px/400/1.4, Home 44px coarse-pointer geometry, exact filtered-Events title and dark table token usage. CSS/JS acceptance and compiled/served identity passed.
- Debt/stub scan on changed implementation and owner-test files found no unreferenced `TBD`, `FIXME`, or `XXX`, no user-visible placeholders, and no empty-return implementation feeding rendered output. Matches in tests, intentional input placeholders and safety guard branches are not stubs.
- Anti-patterns blocking the phase: none.

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None found in changed source/test owners. | — | — |

## Evidence Boundaries

- **Source evidence:** implementations, schemas, filter decoders/encoders, query flows, copy modules, asset sources and theme tokens were inspected.
- **Semantic ExUnit/Node evidence:** tests exercised exact database/query membership, state/result distinctions, owner and generation guards, retries, validation, jobs/audit effects, and hook selection using the owning test harnesses.
- **Mounted browser evidence:** Playwright exercised named package and host paths on current built and served assets; host assertions verified resource identity. This does not imply every route/state combination ran in a browser.
- **Emulated checks:** viewport widths, effective themes, coarse-pointer media and text-spacing/enlargement stress are browser emulations. They are not physical device, native zoom, host-forced theme or speech-only screen-reader tests.
- **Visual observation:** one historical Connect screenshot was inspected before the single corrective batch; zero confirming inspections followed. No image from the later incidental regression capture batch was inspected. No new capture/scan was made during this verification.
- **Unobserved external claims:** no remote CI result, live-provider result, Linux golden review, physical device/native browser zoom or screen-reader speech is claimed. Phase 243 owns Linux goldens and the stable Fake preview; these limits are not confirmation-only human UAT tasks for this phase.

### Decision Coverage

The CONTEXT D-01–D-21 decisions are carried into the seven plans and concrete source/test owners. The security, validation and UI closure checks independently inspected their applicable controls. No decision was identified as missing from shipped artifacts.

### Human Verification Required

None. The requested phase acceptance is decided by repeatable semantic and mounted checks; the explicitly unobserved external/device claims are outside this phase and are not presented as remaining user actions.

### Gaps Summary

No blocking gap found. All four roadmap success criteria and all seven plans' 80 frontmatter truths are supported by substantive, wired code and their named executed owners. The 28 edge and 44 UI predicates retain their individual owners; aggregate suite totals are not treated as proof of universal coverage. No UAT file was generated here because the canonical handoff assigns executable UAT generation and contract execution after this verification report to the phase-completion owner.

---

_Verified: 2026-10-10T14:33:13Z_  
_Verifier: the agent (gsd-verifier)_
