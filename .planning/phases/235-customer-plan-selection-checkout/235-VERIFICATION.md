---
phase: 235-customer-plan-selection-checkout
verified: 2026-10-08T15:46:35Z
status: passed
score: 43/43 must-haves verified
covered_files:
  - .planning/phases/235-customer-plan-selection-checkout/235-01-PLAN.md
  - .planning/phases/235-customer-plan-selection-checkout/235-01-SUMMARY.md
  - .planning/phases/235-customer-plan-selection-checkout/235-02-PLAN.md
  - .planning/phases/235-customer-plan-selection-checkout/235-02-SUMMARY.md
  - .planning/phases/235-customer-plan-selection-checkout/235-03-PLAN.md
  - .planning/phases/235-customer-plan-selection-checkout/235-03-SUMMARY.md
  - .planning/phases/235-customer-plan-selection-checkout/235-04-PLAN.md
  - .planning/phases/235-customer-plan-selection-checkout/235-04-SUMMARY.md
  - .planning/phases/235-customer-plan-selection-checkout/235-05-PLAN.md
  - .planning/phases/235-customer-plan-selection-checkout/235-05-SUMMARY.md
  - .planning/phases/235-customer-plan-selection-checkout/235-06-PLAN.md
  - .planning/phases/235-customer-plan-selection-checkout/235-06-SUMMARY.md
  - accrue/lib/accrue/checkout.ex
  - accrue/lib/accrue/checkout/local_session.ex
  - accrue/test/accrue/checkout/local_session_test.exs
  - accrue/test/accrue/checkout_test.exs
  - accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex
  - accrue_portal/lib/accrue_portal/live/checkout_live.ex
  - accrue_portal/priv/static/accrue_portal.css
  - accrue_portal/priv/static/accrue_portal.js
  - accrue_portal/test/accrue_portal/checkout_context_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs
  - accrue_portal/test/accrue_portal/live/checkout_live_test.exs
  - examples/accrue_host/e2e/phase233-braintree-checkout.spec.js
  - examples/accrue_host/lib/accrue_host/billing.ex
  - examples/accrue_host/lib/accrue_host_web/components/layouts/root.html.heex
  - examples/accrue_host/lib/accrue_host_web/controllers/page_controller.ex
  - examples/accrue_host/lib/accrue_host_web/controllers/user_session_controller.ex
  - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
  - examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs
  - examples/accrue_host/test/accrue_host_web/live/subscription_live_test.exs
  - scripts/ci/accrue_host_seed_e2e.exs
covered_digest: "v3:sha256:9867df2f9edc86a445830716822122070e85cae9f8f4931770099591110cc6b0"
behavior_unverified: 0
overrides_applied: 0
prohibitions_verified: 2
re_verification:
  previous_status: passed
  previous_score: 50/50
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 235: Customer Plan Selection & Checkout Verification Report

**Phase Goal:** Customers can understand a selected offer, complete supported checkout through its actual browser integration, or leave safely with an honest outcome.
**Verified:** 2026-10-08T15:46:35Z
**Status:** passed
**Re-verification:** Yes — independent refresh of the existing passing report.

## Goal Achievement

### Observable Truths

The five roadmap success criteria and all 38 distinct plan truths were checked. Plan counts below follow the six current plan frontmatters (5 + 8 + 7 + 11 + 3 + 4); the roadmap contract remains included and is not reduced by plan scope.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The visible checkout form reaches the supported payment hook and accurately represents valid, invalid, provider-failure, cancellation, and retry results. | ✓ VERIFIED | `checkout_live.ex` mounts `BraintreeHostedFields` on `#checkout-form`; served JS creates official Braintree client/Hosted Fields, tokenizes, submits the nonce using the form's configured transport, prevents concurrent submit, clears/reinitializes fields on failure, and tears down on navigation. The served-browser lane tests one nonce POST, error/retry, cancellation, and interruption paths. Injected SDK is explicitly mock evidence, not provider parity. |
| 2 | Hosted and mounted checkout handoffs are distinct and capability-aware; return navigation and Fake evidence cannot alone claim live payment. | ✓ VERIFIED | `subscription_live.ex` keeps Stripe's `cs_` provider session fetch/reconcile path separate from Braintree's plan/selection locator and persisted LocalSession lookup. Braintree completion requires current scope and matching customer, organization, processor, plan, and selection; Stripe requires a fetched matching paid session. Host tests cover completed/pending/forged/foreign/revoked cases. |
| 3 | Expired/completed sessions, stale promotions, repeated submissions, and missing prices follow the contract without false payment claims or missing-price-as-zero. | ✓ VERIFIED | Portal POST and LiveView reload the persisted session and revalidate promotion, terms, target, and authorization before claiming. LocalSession provides atomic claim/status transitions. Tests cover strict expiry, stale promo, completed replay, repeated/concurrent claim, trusted zero, absent/invalid amount, and accepted-provider/local-persistence uncertainty. |
| 4 | Plan selection survives sign-in and return; charge terms come only from trusted metadata; unknown terms/outcomes recover safely without blind retry. | ✓ VERIFIED | Host selection routes validate the exact plan and preserve a validated login return. Host server resolves and persists name, integer minor amount, currency, and interval; Portal renders those persisted terms and disables payment when they do not validate. Uncertain outcomes state not to resubmit and provide a safe billing destination. |
| 5 | Keyboard, narrow-screen, theme, secure SDK, pending/error, and served asset behavior is checked with the changed checkout and handoff. | ✓ VERIFIED | The 14-test Braintree Playwright lane checks served JS/CSS, secure Hosted Fields boundary, focus/status behavior, host theme tokens, narrow viewport/long text without page overflow, loading/error/recovery and return flows. The phase UI review's screenshot capture was unavailable and records visual-polish recommendations; those do not contradict the automated roadmap assertions. |
| 6 | Plan 01: visible secure form tokenizes and submits once; repeated/interrupted actions do not replay and status/retry remain honest. | ✓ VERIFIED | `phase233-braintree-checkout.spec.js` covers visible submit, nonce count, double action, interrupted transport, teardown, invalid-card retry, SDK failure, and abandonment; checkout ExUnit tests cover server completion and replay. |
| 7 | Plan 02: exact selected offer, customer, and processor survive login/resume; persisted terms are trusted and invalid/missing terms fail closed. | ✓ VERIFIED | Host LiveView tests cover exact-plan handoff/login return and persisted metadata; Portal populated/empty/partial/zero-one-many tests assert only verified terms render and invalid terms cannot submit. |
| 8 | Plan 03: both transports enforce expiry, completion, stale promotion, authorization, at-most-one claim, and honest uncertain outcomes. | ✓ VERIFIED | Focused Portal tests exercise actual POST and LiveView event, provider call counts, stale/expired/replay cases, and completion persistence failure. `LocalSession` tests cover expiry boundary and parallel claim. |
| 9 | Plan 04: Stripe hosted and Braintree mounted paths and their returns remain separate and idempotent; loading/error and responsive states are checked. | ✓ VERIFIED | Host provider-specific return tests and checkout Playwright cases exercise each path; CI's `playwright-e2e` job runs the configured Braintree lane. Return navigation itself performs only read/reconcile behavior; no query flag alone creates completion. |
| 10 | Plan 05: a trusted explicit zero survives POST validation; invalid amount stays ineligible; expired checkout offers safe recovery without payment or nonce reuse. | ✓ VERIFIED | `checkout_context_test.exs` includes “explicit trusted zero-priced checkout POST completes exactly once” with one billing operation and persisted completion, and invalid amount checks. `checkout_live_test.exs` and the browser lane assert expired recovery destination and no payment action. |
| 11 | Plan 06: Braintree host result requires the matching authorized completed LocalSession; all other states remain non-complete; Stripe keeps fetched evidence. | ✓ VERIFIED | Source path checks current authorization and exact operation identity before accepting `completed`; focused Braintree tests cover non-complete, foreign, forged, permission and repeated-read cases. Browser path returns from mounted checkout into the fixture-backed host outcome. |

**Score:** 43/43 must-haves verified (0 present, behavior-unverified).

### Negative Must-Haves (Prohibitions)

| Prohibition | Status | Evidence |
|---|---|---|
| Checkout must not present a browser nonce or navigation as proof that a customer was charged. | ✓ VERIFIED | The browser spec labels injected SDK evidence as mock-only and asserts the visible form's authoritative server disposition. Host return tests require Stripe fetched paid-session evidence or a matching completed Braintree LocalSession; URL data alone cannot establish completion. |
| Checkout must not silently switch the named payer or selected offer after sign-in or a host account change. | ✓ VERIFIED | Host tests verify the exact plan/login return and fresh scope; selected plan and operation identity are persisted server-side, and Portal/host tests reject mismatched payer, plan, or selection. |

Both PLAN entries omit the `verification` tier and remain marked `status: unresolved`; I assessed the concrete negative-test evidence above. Neither prohibition is silently omitted from this report.

Behavior-dependent claims are backed by the supplied completed evidence: Portal full suite 84/84, focused checkout 28/28, Braintree browser lane 14/14, core 2,076/2,076, Admin 551/551, and host 222/222. The browser Braintree success remains deterministic fixture evidence, not live-provider evidence; no live parity claim is made. Security audit reports 21/21 mitigations closed, zero open threats; validation audit reports zero new gaps; incremental code review reports zero findings/open items.

## Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `accrue_portal/priv/static/accrue_portal.js` | Secure Hosted Fields lifecycle and one-time nonce transport | ✓ VERIFIED | Substantive hook mounted by checkout form, and invoked by real visible form. |
| `accrue_portal/lib/accrue_portal/live/checkout_live.ex` | Trusted offer rendering, eligibility, recovery and LiveView result | ✓ VERIFIED | Renders metadata-derived summary, mounts hook, and routes expired/uncertain/completed states. |
| `accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex` | Authorized POST completion and evidence-specific results | ✓ VERIFIED | Reloads and validates persisted checkout, claims once, calls billing, and separates uncertain persistence. |
| `accrue/lib/accrue/checkout/local_session.ex` | Persisted offer operation, atomic claim and outcome transitions | ✓ VERIFIED | Shared by Portal completion and host return lookup; exercised by concurrency/expiry tests. |
| `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex` | Plan handoff, trusted terms and distinct provider return | ✓ VERIFIED | Uses server-resolved plan and provider-specific evidence paths; visible outcomes use assigned result state. |
| `examples/accrue_host/e2e/phase233-braintree-checkout.spec.js` | Served-browser flow and recovery proof | ✓ VERIFIED | Substantive suite, invoked by package script and existing CI job; 14 cases pass per supplied run. |
| `accrue_portal/priv/static/accrue_portal.css` | Responsive, readable mounted checkout | ✓ VERIFIED | Served asset and viewport/layout assertions are wired in browser lane. |
| `examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs` | Scoped Braintree outcome coverage | ✓ VERIFIED | Tests completion, pending/non-complete, foreign/forged and revoked authorization. |

## Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Pricing selection | Authenticated checkout session | Validated plan GET return preserved by host login; fresh host context resolves the selection | WIRED | Host page/session controllers and host selection tests confirm the flow. |
| Persisted host plan | Portal summary and payment eligibility | Host writes trusted plan terms into session metadata; Portal validates metadata against its line item | WIRED | Portal renders the persisted terms; browser verifies selected plan after login. |
| `#checkout-form` | Braintree Hosted Fields | `BraintreeHostedFields` JS hook tokenizes, inserts nonce, submits actual form | WIRED | Visible browser submit observes one nonce-bearing POST; server tests confirm outcome. |
| Portal POST / LiveView event | Billing operation | Reload session, reauthorize, validate offer, atomic LocalSession claim, then provider operation | WIRED | Both independent transports have focused tests and call-count/replay assertions. |
| Provider return | Customer-visible host outcome | Stripe session fetch/reconcile or Braintree scoped LocalSession read | WIRED | Return tests verify source-specific evidence and deny forged/non-complete outcomes. |
| Portal JS/CSS package assets | Host rendered browser | Served assets -> Playwright lane -> existing `playwright-e2e` CI job | WIRED | Package script includes phase browser spec; CI invokes that script with Braintree fixture setup. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Host checkout handoff | selected plan / selection ID | Validated host route plus `Plans.get/1` and current organization | Yes; current server-side plan and billing scope | ✓ FLOWING |
| Portal offer summary | name, amount, currency, interval, billable | Persisted checkout session metadata plus exact line item | Yes; metadata is validated against session line item; absent terms disable payment | ✓ FLOWING |
| Checkout outcome | completion / uncertainty | Billing operation result and persisted LocalSession state | Yes; not inferred from query string or UI-only state | ✓ FLOWING |
| Host return | status | Stripe fetched provider session or matching Braintree LocalSession | Yes; distinct authoritative source per provider | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Evidence | Result | Status |
|---|---|---|---|
| Visible Braintree form reaches server once and renders disposition | Supplied Playwright lane; named test `mock SDK visible submit sends one nonce and renders the server disposition` | Covered in 14/14 passing browser cases | ✓ PASS |
| Trusted zero amount POST completes once | Supplied Portal full/focused checkout run; named ExUnit test `explicit trusted zero-priced checkout POST completes exactly once` | One billing operation and persisted completion asserted | ✓ PASS |
| Expired checkout cannot pay and presents recovery | Supplied browser lane and Portal tests | Recovery link visible; no payment/tokenize action | ✓ PASS |
| Braintree host result only reflects matching persisted outcome | Supplied host suite and browser lane; named test `completed scoped Braintree LocalSession renders an honest completion` | Matching completion accepted; pending and forged cases denied | ✓ PASS |

## Probe Execution

Not applicable. This phase is an application checkout/UI change; its plans and success criteria do not declare probe scripts or probe-based checks.

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CKO-01 | 235-01, 235-03, 235-05, 235-06 | Actual browser checkout hook, truthful outcomes, safe recovery | ✓ SATISFIED | Served Playwright path plus Portal tests for POST/event, retry, failure and uncertainty. |
| CKO-02 | 235-01, 235-04, 235-06 | Distinct capability-aware handoffs and evidenced returns | ✓ SATISFIED | Stripe fetched session vs scoped Braintree LocalSession; host tests and browser return proof. |
| CKO-03 | 235-02, 235-03, 235-04, 235-05, 235-06 | Expiry, stale promotion, repeat submission and price handling | ✓ SATISFIED | Portal POST/LiveView and LocalSession focused coverage, including explicit zero and failure ambiguity. |
| CKO-04 | 235-02, 235-03, 235-04, 235-05, 235-06 | Preserve selection and trusted terms; recover safely on unknowns | ✓ SATISFIED | Host login/handoff tests and Portal metadata eligibility/rendering tests. |

All four requirements mapped to Phase 235 in `REQUIREMENTS.md` appear in plan frontmatter; no orphaned Phase 235 requirement was found.

## Advisory (New Scope, Unevidenced)

| # | Finding | Category | Why Advisory |
|---|---|---|---|
| — | None | — | No new-scope concern without deterministic evidence was found. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| — | — | No actionable TBD/FIXME/XXX, placeholder implementation, empty result stub, or console-only behavior found in the phase's implementation files. Grep hits were test descriptions, UI placeholder attributes, or unrelated layout text. | — | None |

## Human Verification Required

None. The required user-visible checkout, recovery, handoff, served-asset, viewport, keyboard/status, and return behaviors have repeatable automated coverage. Screenshot capture was unavailable during the advisory visual review, but that review's remaining findings concern visual polish and copy refinements rather than an unresolved roadmap truth; Braintree fixture proof is clearly bounded from live-provider evidence.

## Gaps Summary

No goal-blocking gap remains. The host selection flows into trusted persisted session terms; the visible mounted form uses the actual Hosted Fields hook and one-time nonce transport; server paths enforce freshness, authorization and replay protection; provider returns use provider-specific evidence; and uncertain/expired cases stop safely with recovery guidance. Phase 235's current ROADMAP plan count is stale (it reports four plans while six 235 plans exist); verification included all six on-disk plans and their 38 truth assertions.

---

_Verified: 2026-10-08T15:46:35Z_
_Verifier: the agent (gsd-verifier)_
