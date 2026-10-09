---
phase: 236-portal-billing-self-service
verified: 2026-10-09T13:07:22Z
status: passed
score: 21/21 must-haves verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/236-portal-billing-self-service/236-01-PLAN.md
  - .planning/phases/236-portal-billing-self-service/236-01-SUMMARY.md
  - .planning/phases/236-portal-billing-self-service/236-02-PLAN.md
  - .planning/phases/236-portal-billing-self-service/236-02-SUMMARY.md
  - .planning/phases/236-portal-billing-self-service/236-03-PLAN.md
  - .planning/phases/236-portal-billing-self-service/236-03-SUMMARY.md
  - .planning/phases/236-portal-billing-self-service/236-04-PLAN.md
  - .planning/phases/236-portal-billing-self-service/236-04-SUMMARY.md
  - .planning/phases/236-portal-billing-self-service/236-05-PLAN.md
  - .planning/phases/236-portal-billing-self-service/236-05-SUMMARY.md
  - .planning/phases/236-portal-billing-self-service/236-06-PLAN.md
  - .planning/phases/236-portal-billing-self-service/236-06-SUMMARY.md
  - accrue/lib/accrue/processor/braintree.ex
  - accrue/lib/accrue/processor/fake.ex
  - accrue/lib/accrue/processor/stripe.ex
  - accrue/test/accrue/processor/braintree_test.exs
  - accrue_portal/lib/accrue_portal/billing_read_model.ex
  - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
  - accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex
  - accrue_portal/lib/accrue_portal/copy.ex
  - accrue_portal/lib/accrue_portal/layouts.ex
  - accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex
  - accrue_portal/lib/accrue_portal/live/checkout_live.ex
  - accrue_portal/lib/accrue_portal/live/home_live.ex
  - accrue_portal/lib/accrue_portal/live/invoices_live.ex
  - accrue_portal/lib/accrue_portal/live/payment_methods_live.ex
  - accrue_portal/lib/accrue_portal/live/subscription_live.ex
  - accrue_portal/lib/accrue_portal/live/subscriptions_live.ex
  - accrue_portal/priv/static/accrue_portal.css
  - accrue_portal/priv/static/accrue_portal.js
  - accrue_portal/test/accrue_portal/checkout_context_test.exs
  - accrue_portal/test/accrue_portal/context_live_test.exs
  - accrue_portal/test/accrue_portal/context_post_test.exs
  - accrue_portal/test/accrue_portal/live/add_payment_method_live_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
  - accrue_portal/test/accrue_portal/live/home_live_test.exs
  - accrue_portal/test/accrue_portal/live/invoices_live_test.exs
  - accrue_portal/test/accrue_portal/live/invoices_wrong_tenant_test.exs
  - accrue_portal/test/accrue_portal/live/payment_methods_live_test.exs
  - accrue_portal/test/accrue_portal/live/subscription_live_test.exs
  - accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs
  - examples/accrue_host/config/test.exs
  - examples/accrue_host/e2e/phase236-portal-self-service.spec.js
  - examples/accrue_host/lib/accrue_host/billing.ex
  - scripts/ci/accrue_host_seed_e2e.exs
covered_digest: "v3:sha256:f2768c77f2f367ab22ed905e9ae6ae09acb2fa01390bc9f78bec849e360b14df"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 236: Portal Billing Self-Service Verification Report

**Phase Goal:** Customers can understand their billing identity and manage supported existing payment, subscription, and invoice tasks in the branded Portal.
**Verified:** 2026-10-09T13:07:22Z
**Status:** passed
**Re-verification:** No — refreshed against completed phase artifacts and current code

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Customers can use all seven existing Portal pages with legible, responsive content scoped to the selected billed entity and consistent with host branding. | ✓ VERIFIED | Served route tests cover all seven routes, billed identity, host wordmark, 320px overflow, theme/contrast, focus, and reduced motion (`phase236-portal-self-service.spec.js:486-532`; `579-657`). UI-REVIEW explicitly records visual polish as outside this phase's acceptance gate. |
| 2 | Supported payment-method and subscription actions honor capability and ownership; list and detail entry points disclose matching consequences before confirmation. | ✓ VERIFIED | `PaymentMethodsLive`, `SubscriptionsLive`, and `SubscriptionLive` gate actions and re-resolve the exact owner/provider target. Their active LiveView and POST tests cover supported and denied targets, consequence parity, and mutation outcomes. |
| 3 | Customers reach only their existing invoice records and hosted invoice access; missing or unauthorized records fail safely. | ✓ VERIFIED | `BillingReadModel.invoices/1` scopes reads to the selected Customer; invoice LiveView and wrong-tenant tests assert owned rows/hosted URLs and safe absence. Served two-owner browser assertions cover personal/workspace isolation. |
| 4 | LiveView and POST/redirect actions announce visible success or failure, failed reads do not look empty, and checkout failure does not assert a charge. | ✓ VERIFIED | Portal LiveViews expose status/alert outcomes; payment and checkout controllers use actual mutation/session results for flashes and safe returns. Active tests cover unavailable reads and uncertain/failed checkout outcomes. |
| 5 | Direct add-card initializes supported secure fields and supplies readable, contrast-checked styles across effective themes; known subscription states, safe returns, and keyboard/mobile/focus/motion behavior are truthful. | ✓ VERIFIED | Served tests passed default, forced-light, and forced-dark themes, including field/placeholder/invalid/label/help contrast and lifecycle behavior. This verifies the application style handoff, not live iframe rendering. |
| 6 | Authorized customers see the selected billed entity and only that Customer's invoices, and can follow an existing hosted invoice URL. | ✓ VERIFIED | Customer-scoped query and route wiring feed invoice rows and hosted URLs; the isolated two-owner browser fixture verifies both scopes. |
| 7 | Empty and unavailable invoice reads have distinct announced results; missing and foreign records disclose nothing. | ✓ VERIFIED | Invoice read-result tests distinguish success-empty from failure, assert announced unavailable state, and cover absent URL and foreign records. |
| 8 | Invoice copy states that the displayed list is bounded without promising retention or complete history. | ✓ VERIFIED | The invoice query remains bounded to 20, and the rendered copy/test assertions avoid retention and completeness claims. |
| 9 | Supported card actions identify the selected card and consequence before submission and freshly authorize the exact owner/provider target. | ✓ VERIFIED | Card action forms route through action-specific POST handlers; controller resolves the current context and Customer-owned record, authorizes before mutation, and reports the observed result. |
| 10 | Authorized direct add-card navigation initializes Hosted Fields and clears the one-time nonce on failure, denial, patch, or abandonment. | ✓ VERIFIED | Direct-route tests and served browser assertions cover initialization, nonce clearing, lifecycle update/teardown, and failed cleanup. The provider iframe rendering boundary is separately routed to human verification. |
| 11 | Payment POST outcomes are announced, unsupported actions are hidden, and failed card reads are not shown as empty. | ✓ VERIFIED | Payment LiveView/controller tests cover success/failure feedback, capability gating, unavailable reads, forged/stale targets, and denial without mutation. |
| 12 | Subscription list/detail show matching processor-specific consequences before confirmation; ineligible actions are unavailable. | ✓ VERIFIED | List and detail use shared consequence copy and provider/state eligibility checks; paired tests assert parity and ineligible-action absence. |
| 13 | Stale, foreign, denied, or switched-billable subscription events cannot mutate another target. | ✓ VERIFIED | Events reload the current pinned context and exact owned subscription before authorization/mutation; context and LiveView tests assert denied events do not mutate. |
| 14 | Known subscription lifecycle states use observed values; missing facts remain unknown/unavailable and copy avoids unsupported access/history claims. | ✓ VERIFIED | The lifecycle tests cover trialing, incomplete, unpaid, past-due, active, canceled, partial, unknown, and failed-read states. |
| 15 | Checkout failures and uncertain results do not assert an unsupported charge or invite blind replay; leaving checkout is not cancellation. | ✓ VERIFIED | Signed session/provider outcomes drive checkout copy; tests cover declines, uncertain outcomes, query-only markers, and neutral exit behavior. |
| 16 | Checkout return destinations allow only local or configured HTTPS targets, with a safe fallback. | ✓ VERIFIED | Shared destination validation rejects malformed/unapproved targets and accepts configured safe targets; table-driven controller/LiveView tests cover the cases. |
| 17 | Checkout reauthorizes the pinned displayed billable and exact operation; query parameters grant no authority or success. | ✓ VERIFIED | Controller and LiveView validate the pin, session target, provider, and operation before mutation. Tests cover stale pins and query-only status markers. |
| 18 | The branded shell shows the selected billed identity on all seven existing Portal pages. | ✓ VERIFIED | Served route browser test asserts the selected identity and host wordmark on Home, subscription list/detail, payment list/add, invoice, and checkout. |
| 19 | Served browser fixtures cover empty/loading/error/populated/partial/overflow/zero-one-many/long-text, keyboard/focus, themes/contrast, and reduced motion. | ✓ VERIFIED | Current Phase 236 Playwright assertions cover these states and are registered in the blocking Braintree lane; focused theme matrices are additionally registered as blocking steps. |
| 20 | The application supplies contrast-checked field, label/help/error styles and clears one-time state on failure or abandonment. | ✓ VERIFIED | Playwright verifies style values against actual field surfaces, minimum 4.5:1 contrast, nonce clearing, patch refresh, and teardown with a deterministic SDK mock. |
| 21 | Visible and announced feedback survives redirects and LiveView patches without unsupported payment/access claims. | ✓ VERIFIED | POST result copy and checkout return tests assert flashes; LiveView action tests assert status/alert semantics and focus restoration. |

**Score:** 21/21 truths verified (0 behavior-unverified)

### Deferred Items

None. Later roadmap phases do not own any remaining Phase 236 acceptance check.

### Advisory (New Scope, Unevidenced)

None. Re-verification found no new-scope issue requiring advisory treatment.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_portal/lib/accrue_portal/billing_read_model.ex` | Customer-scoped real reads and explicit failure outcomes | ✓ VERIFIED | Repo reads use the currently authorized Customer and return distinct success/unavailable outcomes to consumers. |
| `accrue_portal/lib/accrue_portal/live/invoices_live.ex` | Invoice identity, owned hosted actions, empty/unavailable states | ✓ VERIFIED | Mounted route consumes the read model and renders only scoped rows/hosted links with distinct status. |
| `accrue_portal/lib/accrue_portal/live/payment_methods_live.ex` | Capability-gated card actions and read states | ✓ VERIFIED | Current Customer's card records flow to eligible action forms and visible result states. |
| `accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex` | Direct secure card entry | ✓ VERIFIED | Direct authorized route creates the SDK client token and renders nonce-only submission through the served hook. |
| `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` | Freshly authorized exact-target card mutation | ✓ VERIFIED | Each POST reloads the selected context and owned card, authorizes the requested action, then reports the result. |
| `accrue_portal/priv/static/accrue_portal.js` | Served Hosted Fields integration and theme/lifecycle handling | ✓ VERIFIED (app-side contract) | Theme-derived styles, normalized readable fallbacks, contrast logic, lifecycle guards, and teardown/recreation are substantive and consumed by direct add-card. Live iframe rendering is outside the deterministic claim. |
| `accrue_portal/lib/accrue_portal/live/subscriptions_live.ex` | Subscription list and action flow | ✓ VERIFIED | Scoped reads, capability checks, consequence confirmation, fresh authorization, and outcome announcement are wired. |
| `accrue_portal/lib/accrue_portal/live/subscription_live.ex` | Subscription detail and action parity | ✓ VERIFIED | Detail action uses the same consequence, authorization, and mutation-result contract as the list. |
| `accrue_portal/lib/accrue_portal/copy.ex` | Accurate state, consequence, and outcome copy | ✓ VERIFIED | Shared copy reflects provider/action observations and avoids unsupported retention/access guarantees. |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | Checkout return/outcome flow | ✓ VERIFIED | Renders state from signed local session and actual completion outcome. |
| `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | Safe checkout completion and return | ✓ VERIFIED | Validates exact pinned operation and destination; query parameters do not assert a charge or success. |
| `accrue_portal/lib/accrue_portal/live/home_live.ex` | Scoped dashboard and read states | ✓ VERIFIED | Loads real Customer-scoped data and distinguishes unavailable from empty. |
| `accrue_portal/lib/accrue_portal/layouts.ex` and `accrue_portal/priv/static/accrue_portal.css` | Shared host-branded shell and responsive semantic styling | ✓ VERIFIED | All routes consume the shared shell and semantic theme styles; browser checks assert route identity, contrast, and narrow-screen overflow. Subjective visual hierarchy is outside this phase's automated acceptance criteria. |
| `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` | Served route, actions, themes, and Hosted Fields contract | ✓ VERIFIED (mock scope) | Tests are substantive and wired into CI; Hosted Fields mock scope is clearly labeled and does not claim Braintree iframe fidelity. |
| `.github/workflows/ci.yml` | Recurring blocking default/light/dark browser proof | ✓ VERIFIED | Registers the default Phase 236 suite and forced-light/forced-dark Hosted Fields suites as blocking steps. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Selected AuthHook context | `BillingReadModel.invoices/1` | Resolved Customer ID | ✓ WIRED | Query scope supplies invoice render and hosted URL. |
| Card row | Payment-method controller | Action-specific POST | ✓ WIRED | Controller reloads/authorizes exact Customer-owned target before mutation. |
| Add-card LiveView | Served `BraintreeHostedFields` hook | Hashed Portal JS asset | ✓ WIRED | Router/layout serve the asset; direct-route browser contract observes initialization. |
| Hosted Fields hook | Payment-method POST | Single-use nonce field | ✓ WIRED | Only nonce reaches app form; failure, refresh, denial, and teardown clear it. |
| Subscription list/detail | Current owner/action authorization | LiveView event handlers | ✓ WIRED | Reloaded exact target and named action are authorized at event time. |
| Checkout form | Controller/LiveView completion | Signed pin and LocalSession | ✓ WIRED | Exact operation and destination are validated before the provider mutation. |
| Phase 236 Playwright spec | Blocking CI lane | Default plus forced-theme Braintree runs | ✓ WIRED | Workflow enables the Braintree fixture and host-theme policy for the registered browser steps. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Home LiveView | Counts and recent subscriptions | BillingReadModel → Customer-scoped Repo queries | Yes | ✓ FLOWING |
| Invoice LiveView | Rows and `hosted_url` | Repo query by authorized Customer, bounded to 20 | Yes | ✓ FLOWING |
| Payment-method LiveView | Card list/default metadata | Current Customer billing read | Yes | ✓ FLOWING |
| Subscription list/detail | Lifecycle and action target | Repo query by current Customer and subscription ID | Yes | ✓ FLOWING |
| Add-card hook | Client token and nonce | Server token provisioning → SDK hook → nonce POST | App-side values flow; SDK rendering mocked | ✓ FLOWING (mock scope) |
| Checkout | Terms and completion state | Signed LocalSession metadata plus provider/DB result | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Portal package tests and compile/format/audit gate | `cd accrue_portal && mix test.ci` | 111 tests, 0 failures; no retired packages. | ✓ PASS (rerun) |
| Default Hosted Fields contrast/lifecycle matrix | Focused served Playwright `--grep 'Hosted Fields'` | 10 passed. | ✓ PASS (rerun) |
| Host-forced light Hosted Fields matrix | Same command with `ACCRUE_HOST_PORTAL_THEME=light` | 7 passed. | ✓ PASS (rerun) |
| Host-forced dark Hosted Fields matrix | Same command with `ACCRUE_HOST_PORTAL_THEME=dark` | 7 passed. | ✓ PASS (rerun) |
| Full Phase 236 served route/action contract | Playwright spec without grep | 14 passed (12.5s), including route identity and owner isolation. | ✓ PASS (rerun) |
| Shared hook Phase 235 checkout regression | Current `236-VALIDATION.md` reports served Braintree browser run | 12/12 passed. | ✓ PASS (recorded current evidence) |
| Workflow syntax and browser CI registration | `236-VALIDATION.md`, `236-05-SUMMARY.md`, and workflow inspection | `actionlint` pass recorded; default/light/dark runs are blocking lane steps. | ✓ PASS |

The package suite rerun completed with 111 tests, 0 failures, and no retired packages. Focused served runs passed 10/10 default, 7/7 forced-light, and 7/7 forced-dark; the full served contract passed 14/14. Chromium required execution outside the sandbox after its sandboxed launch failed before test execution. The browser runs exercise a deterministic SDK mock and prove application style handoff/lifecycle only; no live-provider iframe rendering or transaction is claimed.

### Probe Execution

Not applicable. No Phase 236 plan/summary declares a probe script, and this is not a migration/tooling phase.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| POR-01 | 01, 02, 03, 04, 05 | Seven Portal pages and supported actions are responsive, legible, scoped, and host-branded. | ✓ SATISFIED | Served tests cover seven routes, identity, contrast, focus, theme, and 320px overflow; UI review states subjective polish is not a Phase 236 acceptance gate. |
| POR-02 | 02, 03 | Supported card and subscription actions respect capability/ownership and disclose matching consequences. | ✓ SATISFIED | Exact-target authorization, capability gates, consequence parity, and result tests are active. |
| POR-03 | 01 | Existing invoices and hosted access are Customer-scoped; missing/foreign records fail safely. | ✓ SATISFIED | Scoped query, wrong-tenant tests, and served two-owner isolation evidence. |
| POR-04 | 01, 02, 03, 04, 05 | Actions announce outcomes, failed reads remain distinct, and checkout failures do not claim charges. | ✓ SATISFIED | LiveView/controller tests and served result assertions. |
| POR-05 | 02, 05, 06 | Direct add-card uses supported Hosted Fields and remains readable across themes and LiveView patches. | ✓ SATISFIED (application contract) | App-supplied style values, labels/help/error contrast, theme refresh, nonce clearing, and teardown are verified in default/light/dark served tests. Live-provider iframe rendering is not asserted by this deterministic evidence. |
| POR-06 | 01, 03, 05 | Known subscription states are factual; no unsupported access/history/document guarantees. | ✓ SATISFIED | Lifecycle, missing-observation, invoice bounded-copy, and unavailable tests. |
| POR-07 | 04, 05 | Returns are validated; query parameters do not prove payment; leaving checkout is not cancellation. | ✓ SATISFIED | Safe-destination table tests and checkout outcome/exit tests. |

All seven requirement IDs in the six PLAN files are accounted for; all seven requirements mapped to Phase 236 in REQUIREMENTS.md are claimed by at least one plan. No orphaned Phase 236 requirement was found.

### Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| Portal ExUnit/LiveView tests mapped in plans 01–04 | POR-01–POR-07 | Yes | 0 detected | 0 file-generation patterns detected | Behavioral/value | Pass based on current validation record |
| `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` | POR-01, POR-04–POR-07 | Yes in CI Braintree lane | Conditional skip only when fixture mode is off; CI enables it | 0 file-generation patterns detected | Behavioral | Pass; provider iframe fidelity is outside mock scope |

The validation artifact records the current package and browser run results. The tests exercise scoped reads, authorization, action results, return safety, and application-side Hosted Fields state. The conditional browser skip is bypassed by the blocking CI configuration. No requirement is supported only by a disabled test.

### Decision Coverage

All trackable CONTEXT.md decisions are honored by shipped artifacts (8/8; non-blocking gate).

### API Coverage Pre-Gate

`COVERAGE.md` enumerates 19 Hosted Fields capabilities: 4 integrated calls and 15 reasoned opt-outs. It preserves the existing integration surface, and explicitly limits evidence to deterministic fixtures and served-browser behavior; no provider capability or live transaction is claimed. The required API coverage pre-gate passed.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `examples/accrue_host/e2e/phase236-portal-self-service.spec.js` | 6 | Conditional `test.skip` unless Braintree fixture mode is enabled | ℹ️ Info | The Phase 236 workflow sets `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1`; the intended CI checks therefore execute rather than skip. |
| `examples/accrue_host/config/test.exs` | 44 | “PLACEHOLDER ONLY” environment warning | ℹ️ Info | Test configuration explicitly labels a production setup warning; it is not an unfinished implementation marker. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers or user-visible empty stubs were found in the audited implementation. `return null` matches in the browser color parser represent invalid-color handling, not UI output.

### Human Verification Required

None for phase acceptance. The manual-only external fidelity boundary is live Braintree iframe rendering; it is explicitly outside the deterministic acceptance claim and has not been represented as verified.

### Gaps Summary

The phase goal is achieved by the implemented Portal flows, scoped data paths, authorization checks, accurate result states, responsive host-branded routes, and supported Hosted Fields style/lifecycle contract. Current reruns passed the package suite (111 tests), the full served browser contract (14 tests), and focused default/light/dark Hosted Fields suites (10/7/7 tests). The API coverage pre-gate passes for all 19 declared capabilities (4 integrated, 15 explicit opt-outs). The deterministic SDK mock does not observe Braintree's cross-origin iframe pixels, so this report makes no live-provider rendering claim. Subjective visual-polish findings remain outside this phase's acceptance criteria.

---

_Verified: 2026-10-09T13:07:22Z_
_Verifier: the agent (gsd-verifier)_
