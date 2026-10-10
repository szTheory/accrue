---
phase: 241-billing-operator-journeys
verified: 2026-10-10T16:07:36Z
status: passed
score: 32/32 must-haves verified
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/241-billing-operator-journeys/241-01-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-01-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-02-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-02-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-03-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-03-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-04-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-04-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-05-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-05-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-06-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-06-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-07-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-07-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-08-PLAN.md
  - .planning/phases/241-billing-operator-journeys/241-08-SUMMARY.md
  - .planning/phases/241-billing-operator-journeys/241-CONTEXT.md
  - .planning/phases/241-billing-operator-journeys/241-PATTERNS.md
  - .planning/phases/241-billing-operator-journeys/241-PROBE-COVERAGE.md
  - .planning/phases/241-billing-operator-journeys/241-RESEARCH.md
  - .planning/phases/241-billing-operator-journeys/241-REVIEW.md
  - .planning/phases/241-billing-operator-journeys/241-SECURITY.md
  - .planning/phases/241-billing-operator-journeys/241-UI-FIX.md
  - .planning/phases/241-billing-operator-journeys/241-UI-REVIEW.md
  - .planning/phases/241-billing-operator-journeys/241-UI-SPEC.md
  - .planning/phases/241-billing-operator-journeys/241-VALIDATION.md
  - accrue_admin/assets/css/app.css
  - accrue_admin/test/accrue_admin/assets_test.exs
  - examples/accrue_host/_build/test/lib/accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/assets/js/app.js
  - accrue_admin/e2e/admin-interaction-overlay-phase199.spec.js
  - accrue_admin/e2e/admin-page-flow-phase191.spec.js
  - accrue_admin/lib/accrue_admin/components/at_risk_table.ex
  - accrue_admin/lib/accrue_admin/copy.ex
  - accrue_admin/lib/accrue_admin/copy/subscription.ex
  - accrue_admin/lib/accrue_admin/live/analytics/campaign_live.ex
  - accrue_admin/lib/accrue_admin/live/analytics/recovery_live.ex
  - accrue_admin/lib/accrue_admin/live/charge_live.ex
  - accrue_admin/lib/accrue_admin/live/customer_live.ex
  - accrue_admin/lib/accrue_admin/live/invoice_live.ex
  - accrue_admin/lib/accrue_admin/live/subscription_live.ex
  - accrue_admin/lib/accrue_admin/scoped_path.ex
  - accrue_admin/lib/mix/tasks/accrue_admin.export_copy_strings.ex
  - accrue_admin/priv/static/accrue_admin.css
  - accrue_admin/priv/static/accrue_admin.js
  - accrue_admin/test/accrue_admin/components/at_risk_table_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/campaign_live_test.exs
  - accrue_admin/test/accrue_admin/live/analytics/recovery_live_test.exs
  - accrue_admin/test/accrue_admin/live/charge_live_test.exs
  - accrue_admin/test/accrue_admin/live/customer_live_test.exs
  - accrue_admin/test/accrue_admin/live/invoice_live_test.exs
  - accrue_admin/test/accrue_admin/live/subscription_live_test.exs
  - accrue_admin/test/accrue_admin/queries/query_modules_test.exs
  - accrue_admin/test/accrue_admin/scoped_path_test.exs
  - accrue_admin/test/support/e2e_fixtures.ex
  - accrue_admin/test/support/e2e_plug.ex
  - examples/accrue_host/e2e/generated/copy_strings.json
  - examples/accrue_host/e2e/phase237-admin-billing.spec.js
  - examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
covered_digest: "v3:sha256:e315ca0b73c6e8d14783f434f2ed8e4b4224633273a6774138534ab924c0d1a6"
behavior_unverified: 0
re_verification:
  previous_status: gaps_found
  previous_score: 28/29
  gaps_closed:
    - "Action-control spacing now uses the approved 4px token, with current mounted assertions for invoice/subscription/dunning gaps."
  gaps_remaining: []
  regressions: []
overrides_applied: 0
---

# Phase 241: Billing Operator Journeys Verification Report

**Phase Goal:** Operators can move through existing customer, subscription, invoice, payment and recovery work with truthful scoped destinations, bounded returns and self-contained billing action reviews.
**Verified:** 2026-10-10T16:07:36Z
**Status:** passed
**Re-verification:** Yes — after Plan 08 closed the named action-gap spacing issue

## Goal Achievement

The four roadmap success criteria are the phase contract. They overlap the eight plans' 32 distinct observable truths, so those plan truths are enumerated below and the roadmap criteria are mapped to them. Plan artifact and link declarations are prose strings, so generic structured queries provide no evidence themselves.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Subscription facts and identity precede one secondary related-billing group. | ✓ VERIFIED | `SubscriptionLive` renders current lifecycle and confirmed facts before related resources; `subscription_live_test.exs` checks record-first structure and missing facts. |
| 2 | Customer open-invoice link and scoped open-invoice queue name and return different exact authorized sets; local counts are not attached to broader links. | ✓ VERIFIED | `SubscriptionLive.related_items/4` emits customer_id+status=open separately from owner-scoped status=open. `Invoices.decode_filter/1`, `Invoices.list/1`, and query test assert exact IDs and excluded-owner membership. |
| 3 | Subscription identity/actions remain reachable at narrow, intermediate, desktop, enlargement and text-spacing conditions. | ✓ VERIFIED | Phase 191/199 package browser owners and mounted host captures/current served-asset evidence; 320px and text-spacing assertions preserved in `241-EXECUTION-GATES.md`/`241-UI-FIX.md`. |
| 4 | Related invoice empty/loading/error/partial/populated and zero/one/many states preserve exact membership and accessible content. | ✓ VERIFIED | Subscription and invoice LiveView/query tests cover state distinctions, exact IDs, long identities and unavailable money; component/browser owners cover narrow stress. |
| 5 | Equal-value invoices remain distinct, absent money stays unavailable, Unicode search and query-owned ordering remain truthful. | ✓ VERIFIED | Query membership tests assert distinct invoice IDs; owner tests cover nil money and Unicode; `Invoices.list/1` applies deterministic inserted_at/id order, while unsupported sort/cursor are excluded from scoped returns. |
| 6 | ScopedPath is reused without adding router or UI dependencies. | ✓ VERIFIED | Current `ScopedPath` is the single bounded path owner used by detail LiveViews; no new router/UI dependency is in the implementation or lockfiles. |
| 7 | Return labels and paths derive from one validated route meaning; recognized query-free local lists remain valid. | ✓ VERIFIED | `return_destination/5` validates/decodes once then returns `{path,label}`; `scoped_path_test.exs` and consumer owners cover recognized query-free returns. |
| 8 | Return origins enforce the same mount, approved route, fresh owner and matching loaded customer; malformed/external/cross-mount origins fall back. | ✓ VERIFIED | `validate_return_path/2`, route allowlists, fresh `destination/4` owner rebuilding, and customer-ID equality are wired into invoice/payment/subscription/customer consumers; adversarial tests cover hostile origins and wrong customers. |
| 9 | Contextual returns preserve supported state, visible purpose and access under changed content/widths. | ✓ VERIFIED | Invoice/payment/subscription/customer owners assert destination labels and decoded values; Phase 191/199 browser coverage checks layout and text reflow. |
| 10 | List/detail/customer-tab returns retain only decoded supported filters/lens and fresh owner; ignored pagination/sort/scroll are not promised. | ✓ VERIFIED | `ScopedPath` route allowlists mirror list decoders; `customer_live.ex` and `customer_return_destination/2` enforce same-customer detail tabs; focused owner tests include Unicode, query-free and unsupported-key cases. |
| 11 | Same-customer tabs retain identity, exact rows and accessible empty/loading/error/populated states. | ✓ VERIFIED | Customer LiveView tabs query real invoices/payments/subscriptions for the loaded customer; `customer_live_test.exs` asserts identity, exact fixture rows and states. |
| 12 | Repeated navigation preserves return meaning and staged review cannot replay a billing action on reconnect or stale target. | ✓ VERIFIED | Subscription and charge owners exercise repeated confirmation, staged navigation, stale targets and reconnect with Fake dispatch counts; latest focused owner run passed. |
| 13 | Direct, absent, invalid and unrelated campaign origins return to scoped Recovery; valid 7d/30d/90d origins retain owner/window and matching breadcrumb. | ✓ VERIFIED | `CampaignLive.handle_params/3` accepts only validated Recovery destinations, otherwise builds scoped Recovery; `AtRiskTable` carries current window/owner; campaign and Recovery tests cover all windows and hostile origins. |
| 14 | Current subscription state is separate from unfiltered historical campaign timeline. | ✓ VERIFIED | Recovery and campaign modules load current subscription detail separately from historical `Dunning.campaign_timeline_grouped/1`; timeline and Recovery owners assert the distinction. |
| 15 | Recovery/campaign empty/loading/error/populated/partial states preserve explicit state, identity and accessible content. | ✓ VERIFIED | `recovery_live_test.exs`, `campaign_live_test.exs`, and `at_risk_table_test.exs` cover state branches and IDs; mounted/browser narrow evidence covers the table's scroll region/cards. |
| 16 | Recovery direct/encoded/unrelated returns fail safely; repeated navigation retains window and never dispatches billing actions. | ✓ VERIFIED | Recovery-only allowlist rejects malformed origins; round-trip tests assert current owner and supported window; read-only recovery/campaign paths have no billing dispatch. |
| 17 | Subscription action reviews identify exact target, customer/owner, state, known amount/currency, timing and supported preview. | ✓ VERIFIED | `SubscriptionLive` builds review facts and consequences from selected action/current subscription; owner tests cover each eligible review variant and unavailable preview/amount. |
| 18 | Review correction, Escape and back do not dispatch; confirmation revalidates actor, scope, target/state, step-up, capability and fingerprint; outcomes remain evidence-specific through patch/reconnect. | ✓ VERIFIED | `validate_review/2`, fresh reload and `review_fingerprint/2` guard dispatch; ExUnit controls test corrections, dismissal, stale and duplicate confirmation, timeout/APIError outcomes and reconnect. |
| 19 | Missing preview or amount remains unavailable; minor units/currency are exact and no estimate/default zero is introduced. | ✓ VERIFIED | Review formatting uses exact Money owner helpers; missing preview copy is explicit; subscription and charge owners test nil, large and zero-decimal values. |
| 20 | Subscription reviews/results preserve honest state, focus and access through empty/loading/error/partial/narrow/long text. | ✓ VERIFIED | Subscription review matrix and UI Phase 199 focus/reflow owners exercise variants and text stress; `241-EXECUTION-GATES.md` records final 1/1 matrix and current assets. |
| 21 | Refund review identifies payment/ID, customer/owner, exact selected refund amount/currency and remaining limit; method actions name exact method/customer and consequence. | ✓ VERIFIED | `ChargeLive.refund_review_fields/3` and `CustomerLive` payment-method review facts are rendered; owner tests assert exact money/targets and set-default/delete consequence. |
| 22 | Back/Escape dismiss only; fresh authorization, target/state, step-up/capability and duplicate checks remain at existing owners with evidence-specific result. | ✓ VERIFIED | Charge/customer confirm handlers reload current records and compare reviewed data before step-up/dispatch; dismissal/reconnect/repeat tests assert authoritative Fake counts and result distinctions. |
| 23 | Blank/stale intent cannot select a new target; repeated confirm/reconnect dispatches at most once. | ✓ VERIFIED | `charge_live_test.exs` and `customer_live_test.exs` use Fake callback counters for stale/duplicate/reconnect cases; security follow-up added HTTP500 regression. |
| 24 | Refund blank/zero/negative/remaining/over-remaining and zero-decimal inputs obey exact minor-unit contract without float conversion. | ✓ VERIFIED | Charge amount parser and remaining-balance guard operate on integer minor units; boundary and zero-decimal tests assert exact requests. |
| 25 | Changed consumers use incumbent hierarchy, effective theme, keyboard/focus/busy behavior and current served package assets. | ✓ VERIFIED | Current package asset checks pass; Plan 08 corrects both gaps to `--ax-space-xs`, and the named mounted assertion checks computed gaps. |
| 26 | Each changed consumer has viewport and content stress evidence. | ✓ VERIFIED | Existing package and mounted owners record narrow/desktop, intermediate, text enlargement/text-spacing and long-content checks; Plan 08 adds current computed-spacing and narrow-width assertions. |
| 27 | Changed read/action states remain distinct under patch/reconnect. | ✓ VERIFIED | LiveView owners assert state branches; action owners exercise reconnect and no replay; focused final Phase 191 review matrix and Phase 199 text/reflow cases passed. |
| 28 | Browser focus and authoritative no-replay proof cover changed action consumers. | ✓ VERIFIED | Keyboard/focus owners exercise dismissal/restoration; action ExUnit Fake boundaries count dispatches. Mounted host measured invoice action 0→0 on Escape. |
| 29 | Mounted served-asset proof applies to the existing Admin package and host mount without claiming Portal equivalence. | ✓ VERIFIED | The named host browser owner asserted package/compiled/HTTP/browser byte identity and /admin scope. Current host compile's package CSS equals the updated tracked asset (129,813 bytes, SHA-256 `089878ed…`). The host HTTP assertion was not rerun after Plan08's CSS rebuild; `/billing` Portal remains separate. |
| 30 | Invoice/subscription action bands and active subscription dunning row use the approved 4px spacing token. | ✓ VERIFIED | Plan 08 mounted owner records prior 2px/2px/3px RED and current 4px/4px/4px GREEN against computed `--ax-space-xs`; source uses the token. |
| 31 | Narrow billing views avoid overflow and primary subscription actions are 44 CSS px, including coarse-pointer emulation. | ✓ VERIFIED | Final Phase 199 owner asserts nonempty subscription/coarse-pointer target measurements at 44px and no overflow at 320px. Invoice height was measured, but no threshold assertion is claimed. |
| 32 | Corrected package CSS is rebuilt and package-served bytes match compiled package bytes. | ✓ VERIFIED | Current assets owner passed 4/0; Plan 08 records source, tracked, compiled and package-served CSS provenance. Host-served identity remains unobserved. |

**Roadmap criteria:** (1) truths 1–5; (2) truths 6–12; (3) truths 13–16; (4) truths 17–24. Each criterion is VERIFIED.

**Score:** 32/32 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_admin/lib/accrue_admin/live/subscription_live.ex` | Subscription facts, links and staged reviews | ✓ VERIFIED | Substantive LiveView; routed from subscription detail, uses real scoped queries and existing action owner. |
| `accrue_admin/lib/accrue_admin/scoped_path.ex` | Bounded path/label validation | ✓ VERIFIED | Route/query allowlists, origin validation, fresh-scope rebuild and label pair. |
| `accrue_admin/lib/accrue_admin/live/{invoice,charge,customer}_live.ex` | Contextual returns and review/action owners | ✓ VERIFIED | All call `return_destination`; relevant actions retain existing fresh authorization and provider boundaries. |
| `accrue_admin/lib/accrue_admin/live/analytics/{campaign,recovery}_live.ex` | Campaign-to-Recovery return and scoped current Recovery | ✓ VERIFIED | Campaign uses validated Recovery-only destination; Recovery decodes window and obtains live data. |
| `accrue_admin/lib/accrue_admin/components/at_risk_table.ex` | Recovery rows and scoped campaign links | ✓ VERIFIED | Rendered from recovery query data; row links preserve owner/window. |
| Phase owner ExUnit/query tests | Behavioral assertions for destination, membership, action and state invariants | ✓ VERIFIED | Prior named semantic owners and full-suite run remain executed evidence; this refresh ran targeted asset, Node, host compile and mount checks below. |
| Existing package/host browser tests and built assets | Mounted interactions, responsive/theme/focus and served-byte provenance | ✓ VERIFIED | Evidence and final corrected focused browser outcomes are recorded in `241-EXECUTION-GATES.md`; no source dependency is orphaned. |

The generic artifact query returned `total: 0` because plan artifact declarations are scalar strings, not its expected structured artifact objects. The table above is based on direct source/test inspection.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Subscription detail | Customer invoices and scoped open-invoice queue | `ScopedPath.build` with distinct filters → `InvoicesLive` decoder → `Invoices.list` | ✓ WIRED | Customer link supplies `customer_id` + `status=open`; queue supplies `status=open`; DB query joins/scopes by current owner and applies filters. Exact result IDs asserted. |
| List/detail callers | Supported return destination | `return_destination/5` → path allowlist/query decoder parity → returned `{path,label}` | ✓ WIRED | Four detail owners use shared helper; only consumed keys survive, current owner is rebuilt, wrong customer/mount/origin falls back. |
| Recovery rows | Campaign detail | scoped subscription href with `window` | ✓ WIRED | `AtRiskTable.subscription_href/4` uses current owner scope/window; campaign detail is owner-scoped. |
| Campaign detail | Recovery | validated `return_to` or scoped Recovery fallback | ✓ WIRED | Breadcrumb and explicit link share the same destination; valid window survives. |
| Review UI | Existing mutation/provider boundary | staged intent → fresh record/scope/actor validation → step-up/capability → existing API | ✓ WIRED | Invoice, subscription, refund and payment-method owners retain action-specific gates and provider calls. Dismiss/back paths only clear state. |
| Action provider result | User-visible outcome | response classification → owner state/copy | ✓ WIRED | Accepted/pending/completed/failure/unknown and APIError/timeout remain differentiated; unknown outcomes do not offer blind mutation retry. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Subscription detail | subscription and related invoice rows | `Subscriptions.detail`, `Invoices.list` with decoded customer/status and owner scope | Yes; schema-backed Repo queries, exact fixture membership tests | ✓ FLOWING |
| Invoice/payment/customer lists | decoded filter and rows | each incumbent list decoder → scoped query module → Repo | Yes; query owners exercise distinct fixtures, Unicode and scopes | ✓ FLOWING |
| Recovery | window bounds, at-risk rows | `RecoveryLive` window parser → `Dunning.at_risk_subscriptions` and scoped query | Yes; test fixtures and exact rendered rows | ✓ FLOWING |
| Campaign | arcs and invoice map | `Dunning.campaign_timeline_grouped` and `Dunning.invoices_for_campaign` after scoped subscription lookup | Yes; event/invoice-backed timeline | ✓ FLOWING |
| Billing action review | selected intent and target fields | current loaded record, user selection and supported preview API | Yes; unavailable preview stays unavailable; no zero default | ✓ FLOWING |
| Action outcome | accepted/pending/failed/unknown state | existing provider result handlers and Fake/provider boundary | Yes; tests assert result class and dispatch count | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Current targeted regression gate | GSD bounded command: Admin warnings-as-errors compile + asset ExUnit + all Node `.mjs`; host warnings-as-errors compile + `admin_mount_test.exs` | Exit 0: package assets 4/0, Node 44/0, host mount 5/0; both compiles passed in this refresh. | ✓ PASS |
| Plan 08 mounted correction | Existing Phase 199 selected desktop/mobile owner | Prior red measured 2px/2px/3px against 4px token; final green 2/0 with current gaps at 4px, nonempty subscription/coarse-pointer targets at 44px, and no overflow at 320px. Three post-fix batches ran (6 project passes total). | ✓ PASS |
| Prior broad Admin and browser regression | `/private/tmp/accrue242-final-regression.log`, `/private/tmp/accrue242-prior-browser-regression-permitted.log` | Admin 679/0, Node 44/0, host 223/0 and historical browser matrices passed before final CSS correction. | ✓ PASS (historical for final CSS) |
| Generated executable UAT contract | `node scripts/ci/verify_executable_uat_contract.mjs --phase 241 --write` | PASS; generated UAT contains 19 executable coverage tests from seven summaries | ✓ PASS |

The contract self-test also passed via `node scripts/ci/verify_executable_uat_contract.mjs --self-test`.

### Probe Execution

Not applicable. None of the seven plans or summaries declares a runnable probe path or probe/PASS-marker acceptance contract; this is an Admin application phase. `241-PROBE-COVERAGE.md` is a planning artifact, not an executable probe.

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| JRN-01 | 241-01 | Subscription invoice links target the exact customer or owner set named by the visible label. | ✓ SATISFIED | Observable truth 2; query and LiveView owners assert filters and exact result IDs. |
| JRN-02 | 241-02, 241-03 | Filtered list/detail returns preserve only supported owner/filter/lens/customer-tab context through local validated destinations. | ✓ SATISFIED | Observable truths 6–12; shared helper and each caller tested. |
| JRN-03 | 241-04 | Direct campaign returns to scoped Recovery; navigated campaign retains supported recovery window and scope. | ✓ SATISFIED | Observable truths 13–16; campaign/Recovery owner tests. |
| JRN-04 | 241-05, 241-06 | Billing reviews are self-contained, exact, freshly authorized, dismiss-safe and show evidence-specific action outcomes. | ✓ SATISFIED | Observable truths 17–24; action owners, security controls and mounted no-dispatch proof. |

No additional Phase 241 requirement mapping was found in REQUIREMENTS.md; no orphaned requirements. JRN-01 through JRN-04 remain satisfied by current behavior and fresh owner evidence.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|

No in-scope production stub or untracked debt marker found. Exact grep-style declarations/empty initial state are populated by the real read/query or event path and are not stubs. The final standard-depth review reports 30 files clean; current source paths were independently traced above.

### Evidence Limits

The local deterministic evidence does not claim remote CI completion, physical-device behavior, actual browser 400% zoom controls, assistive-technology speech output or live-provider outcomes. Text enlargement, text-spacing overrides, narrow viewport simulation and Fake provider boundaries were exercised. Phase 243 retains final reviewed Linux visual goldens. These are scoped observation limits, not unresolved phase behaviors or a manual UAT checkpoint.

### Current-source regeneration (2026-10-10)

This report was stale after later shared Admin changes and the Phase 241 plan08 closure. The original 29 truths plus the three plan08 truths were checked against current source and named evidence. JRN-01 through JRN-04 remain satisfied; current requirements map only these four IDs to Phase 241. Plan08 closes the prior spacing deviation.

This refresh ran warnings-as-errors compiles, asset tests (4/0), Node owners (44/0), and the host mount owner (5/0), all passing. Prior broad runs and browser matrices remain executed evidence from before the 4px correction. Plan08's selected desktop/mobile owner passed 2/0 after explicit nonempty guards. Security re-audit covers T-241-17 and records one accepted low supply-chain risk; zero blocking threats remain at ASVS L1. Nyquist covers all 17 task owners. UI review stays at its scoped score and does not certify all 24 pillars.

The corrected CSS values and current invoice/subscription callers are confirmed in source and by the named Plan08 computed-style test. No screenshot was captured or inspected during this refresh. Physical zoom, screen-reader speech, live-provider behavior, remote CI, host-served identity for Plan08, and reviewed Linux goldens remain unclaimed; Phase243 owns final Linux goldens. These limits do not create human UAT items.

### Gaps Summary

No gaps remain. The earlier spacing gap is closed by the tokenized source correction and the executed mounted computed-style assertions. Scope, authorization, exact-money, navigation and action-outcome truths remain supported by their named owners. Historical test failures and incumbent skips remain recorded and are not recast as passing runs.

---

_Verified: 2026-10-10T16:07:36Z_\
_Verifier: the agent (gsd-verifier)_
