---
phase: 233-shared-direction-portal-contract
verified: 2026-10-09T12:47:23Z
status: passed
score: 29/29 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/233-shared-direction-portal-contract/233-01-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-01-SUMMARY.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-02-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-02-SUMMARY.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-03-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-03-SUMMARY.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-04-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-04-SUMMARY.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-05-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-05-SUMMARY.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-06-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-06-SUMMARY.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-07-PLAN.md"
  - ".planning/phases/233-shared-direction-portal-contract/233-07-SUMMARY.md"
  - ".planning/phases/239-integrated-quality-handoff/239-COVERAGE.md"
  - ".planning/phases/239-integrated-quality-handoff/239-SERVED-PARITY.md"
  - "accrue/priv/accrue/templates/install/billing.ex.eex"
  - "accrue/priv/static/brand.css"
  - "accrue_admin/README.md"
  - "accrue_portal/README.md"
  - "accrue_portal/lib/accrue_portal/auth_hook.ex"
  - "accrue_portal/lib/accrue_portal/auth_plug.ex"
  - "accrue_portal/lib/accrue_portal/authorize.ex"
  - "accrue_portal/lib/accrue_portal/context.ex"
  - "accrue_portal/lib/accrue_portal/controllers/checkout_controller.ex"
  - "accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex"
  - "accrue_portal/lib/accrue_portal/copy.ex"
  - "accrue_portal/lib/accrue_portal/customer_session.ex"
  - "accrue_portal/lib/accrue_portal/layouts.ex"
  - "accrue_portal/lib/accrue_portal/live/add_payment_method_live.ex"
  - "accrue_portal/lib/accrue_portal/live/blocked_live.ex"
  - "accrue_portal/lib/accrue_portal/live/checkout_live.ex"
  - "accrue_portal/lib/accrue_portal/live/home_live.ex"
  - "accrue_portal/lib/accrue_portal/live/invoices_live.ex"
  - "accrue_portal/lib/accrue_portal/live/payment_methods_live.ex"
  - "accrue_portal/lib/accrue_portal/live/subscription_live.ex"
  - "accrue_portal/lib/accrue_portal/live/subscriptions_live.ex"
  - "accrue_portal/lib/accrue_portal/path.ex"
  - "accrue_portal/lib/accrue_portal/router.ex"
  - "accrue_portal/priv/static/accrue_portal.css"
  - "accrue_portal/priv/static/accrue_portal.js"
  - "accrue_portal/test/accrue_portal/auth_hook_test.exs"
  - "accrue_portal/test/accrue_portal/checkout_context_test.exs"
  - "accrue_portal/test/accrue_portal/context_contract_test.exs"
  - "accrue_portal/test/accrue_portal/context_live_test.exs"
  - "accrue_portal/test/accrue_portal/context_post_test.exs"
  - "accrue_portal/test/accrue_portal/live/checkout_live_discount_test.exs"
  - "accrue_portal/test/accrue_portal/live/checkout_live_test.exs"
  - "accrue_portal/test/accrue_portal/live/payment_methods_wrong_tenant_test.exs"
  - "accrue_portal/test/accrue_portal/live/subscription_live_test.exs"
  - "accrue_portal/test/accrue_portal/live/subscriptions_live_test.exs"
  - "accrue_portal/test/accrue_portal/readme_contract_test.exs"
  - "accrue_portal/test/accrue_portal/router_test.exs"
  - "accrue_portal/test/support/tap_formatter.ex"
  - "examples/accrue_host/README.md"
  - "examples/accrue_host/config/runtime.exs"
  - "examples/accrue_host/config/test.exs"
  - "examples/accrue_host/e2e/onboarding_and_billing.spec.js"
  - "examples/accrue_host/e2e/phase233-baseline.spec.js"
  - "examples/accrue_host/e2e/phase233-braintree-checkout.spec.js"
  - "examples/accrue_host/e2e/phase233-context.spec.js"
  - "examples/accrue_host/e2e/phase233-semantic.spec.js"
  - "examples/accrue_host/e2e/tap-reporter.js"
  - "examples/accrue_host/lib/accrue_host/billing.ex"
  - "examples/accrue_host/lib/accrue_host/portal_context_adapter.ex"
  - "examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex"
  - "examples/accrue_host/lib/accrue_host_web/router.ex"
  - "examples/accrue_host/package.json"
  - "examples/accrue_host/playwright.braintree.config.js"
  - "examples/accrue_host/playwright.config.js"
  - "examples/accrue_host/test/accrue_host_web/admin_mount_test.exs"
  - "examples/accrue_host/test/accrue_host_web/live/subscription_live_braintree_test.exs"
  - "examples/accrue_host/test/install_boundary_test.exs"
  - "scripts/ci/accrue_host_seed_e2e.exs"
  - "scripts/ci/accrue_host_verify_browser.sh"
covered_digest: "v3:sha256:c931675baef6e0fa0f2d4d6d88982c81c1063fa91c637bda6bfb9a1553d0d2db"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 29/29 roadmap and plan truths verified
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 233: Shared Direction & Portal Contract Verification Report

**Phase Goal:** Maintainers and adopters can see a current, coherent Admin and Portal baseline, while hosts can select a billed entity and authorize its actions through one bounded Portal contract.
**Verified:** 2026-10-09T12:47:23Z
**Status:** passed
**Re-verification:** Yes — refreshed because `init.manager` marked the prior report stale.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Maintainers can inspect the current served route, flow, component, and state inventory and distinguish it from historical captures. | ✓ VERIFIED | `233-INVENTORY.md` dates and pins its source tree and explicitly disclaims served proof; `233-BASELINE.md` separately records the phase-era served routes, screenshots, source revision, and asset hashes. I inspected all five current worktree captures. Phase 239 recognizes the old inventory as dated evidence and supplies a refreshed current route ledger in `239-COVERAGE.md`; its asset parity checks were rerun below. |
| 2 | Operators and customers see shared semantic visual roles while Admin identity, host customer branding, and audience-specific layouts remain recognizable in real consumers. | ✓ VERIFIED | Package-owned `--ax-*` and `--accrue-*` styles remain separate and are consumed by real Admin and Portal views. Current mounted asset response tests passed (Admin 4/4, Portal CSP/asset/checkout 19/19). I inspected the 320px Admin and dark Portal captures: branding/shells remain distinct, controls reflow, focus is visible, and statuses include text/glyph cues. |
| 3 | Personal-only hosts retain existing Portal behavior without a company model or picker; mixed hosts resolve personal and custom billables while actor, billable, Customer, and processor remain distinct. | ✓ VERIFIED | `CustomerSession`, `Context`, and the canonical host adapter preserve the no-adapter personal path and resolve exact custom owner type/ID/processor identities. Focused context, HTTP, LiveView, checkout, and docs tests passed 45/0; the current Braintree host test passed 8/0. Positive and denied cases assert exact targets and human actor attribution. |
| 4 | Initial requests, LiveView events/reconnects, and protected actions freshly authorize selected context; invalid selection cannot provision, fall back, retarget, or mutate. | ✓ VERIFIED | AuthPlug/AuthHook, signed context pins, server-loaded targets, and named-action checks connect the rendered producers to POST, event, reconnect, and mutation paths. The 45 focused Portal tests exercise allowed and denied transitions, including zero-write/zero-token denials, revoked context, switched tabs, forged targets, and successful actor-attributed actions. |
| 5 | The canonical example and adopter guidance show personal defaults plus organization/custom and mixed resolution without a new auth or runtime dependency. | ✓ VERIFIED | The host adapter and router implement the optional contract; Portal/Admin/host docs and executable README contract tests align with its callbacks and named actions. The focused README contract is part of the 45/0 Portal run. Dependency manifests show no new auth/runtime dependency for this integration. |

**Score:** 29/29 truths verified (5 roadmap truths + 24 plan truths; 0 behavior-unverified).

### Plan-Specific Truths

All 24 plan truths were checked against current source and focused behavioral tests:

| Plan | Truths | Status | Evidence |
|---|---:|---|---|
| 233-01 | 6 | ✓ VERIFIED | Optional adapter/personal fallback, denied and unavailable selection, fresh HTTP/LiveView/reconnect authorization, owner identity separation, invalid selection, and no implicit first-record choice; covered by `context_contract_test`, `auth_hook_test`, and the combined 45-test run. |
| 233-02 | 4 | ✓ VERIFIED | Payment POST pins, exact target identity, no replay after denial, and token gating; covered by `context_post_test` and current asset/action source inspection. |
| 233-03 | 3 | ✓ VERIFIED | Home/subscription/invoice navigation, pinned previews, and fresh event/reconnect authorization; covered by `context_live_test`. |
| 233-04 | 3 | ✓ VERIFIED | Dated source/served inventory, bounded semantic contract, and observable status/focus/reflow/contrast criteria; doc marker checks passed and current captures were inspected. |
| 233-05 | 3 | ✓ VERIFIED | Personal/custom/mixed adoption, fresh host policy with actor attribution, and safe local recovery; adapter source and current Braintree host tests confirm exact organization scope and authorization. |
| 233-06 | 2 | ✓ VERIFIED | Separate semantic token APIs/brands/shells and representative status/focus/accent/reflow assertions; served asset tests and inspected captures support the current consumer contract. |
| 233-07 | 3 | ✓ VERIFIED | Checkout mount/reconnect/event/POST use the pinned server-loaded session, deny token issuance absent completion authority, and require the rendered pin for both transports; `checkout_context_test` passed within the focused run. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `233-INVENTORY.md`, `233-BASELINE.md`, `DESIGN.md` | Dated source/served baseline and bounded semantic design | ✓ VERIFIED | Substantive documents distinguish source inventory from served captures and record source revision/hash provenance. Phase 239 subsequently refreshes the live route/resource ledger as later phases changed consumers. |
| `captures/*` | Representative Admin and Portal evidence | ✓ VERIFIED | All five files exist and were visually inspected in the current worktree. Existing user edits were preserved. |
| Portal Context/auth/session/router | Optional resolution, identity separation, fresh authorization | ✓ VERIFIED | Substantive implementations flow from router session/pin through `CustomerSession` and adapter policy into AuthPlug/AuthHook and exact Customer-scoped reads. |
| Payment and checkout forms/controllers/LiveViews | Rendered pins consumed by protected actions | ✓ VERIFIED | Pin mint/verify, current policy re-resolution, target reload, token gating, denial clearing, and successful mutation paths are covered in passing focused tests. |
| Canonical host adapter, billing facade, router | Host-owned billable and action policy | ✓ VERIFIED | Adapter resolves personal and organization identities, and delegates each action to fresh host billing authorization. The modified host Braintree test passed 8/8. |
| Phase 233 browser specs | Current served baseline, semantic roles, and mixed context | ✓ VERIFIED | Specs contain live route, current asset hash/body, focus/status/contrast/reflow, and context controls. Their capture-writing Playwright lane was not rerun because it writes into user-modified capture files; the current asset response contracts and persisted captures were independently checked. |
| Portal/Admin/host docs and install template | Public contract matches implementation | ✓ VERIFIED | Executable README contract test passed; docs and adapter callback/action vocabulary agree. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Host router/session | `CustomerSession` / `Context` | Optional adapter and declared session keys | ✓ WIRED | Router passes adapter settings into Portal mounts; session selection is a locator, then host policy and exact Customer identity are resolved. |
| Signed payment context pin | Payment-method POST actions | `Context.mint_pin/verify_pin` and fresh authorization | ✓ WIRED | Rendered default/delete/create forms supply a pin; controllers re-resolve policy and reload exact targets before billing calls. |
| `AuthHook` | Home/subscription/invoice LiveViews | Context assigns and target-scoped reads/actions | ✓ WIRED | Pin survives navigation; events and reconnects reauthorize under current host policy. |
| Host adapter | Membership and billing facade | Resolve and authorize callbacks | ✓ WIRED | Host organization membership and action grants are delegated to host billing checks; actor remains separate from billable. |
| Semantic role definitions | Package-owned CSS and served assets | Admin build / Portal asset Plug | ✓ WIRED | Current Admin and Portal mounted response tests passed and compare returned bodies with source package files. |
| Public API | Adopter documentation | README contract tests | ✓ WIRED | Executable docs test checks documented options, callbacks, and named actions against exported symbols. |
| Checkout LiveView form | Hosted Fields event and POST controller | Rendered `context_pin` → verify → pinned target/action → subscription | ✓ WIRED | Both transport paths consume the same rendered pin and server-load the exact LocalSession and Customer before provider work. |

### Prohibitions

| Must-not | Status | Evidence |
|---|---|---|
| Billing manager must not be described as an Admin operator or gain operator navigation through selection. | ✓ VERIFIED | Portal context selection feeds billing-only layouts/actions; Admin route access remains separately guarded. Host context and docs tests preserve this separation. |
| Unavailable custom selection must not be labeled personal. | ✓ VERIFIED | Explicit invalid selections return unavailable/blocked; no adapter alone selects personal. Focused context tests exercise invalid-selection recovery. |
| A form must not silently switch payer after another tab changes selection. | ✓ VERIFIED | Signed pin carries owner, Customer, and processor identity; focused POST tests cover switched-tab/mismatched targets. |
| Cached action/preview must not authorize a charge or subscription change. | ✓ VERIFIED | Events and mutations re-resolve the host action grant; LiveView tests cover revoked authorization and no replay. |
| Historical screenshots/pass counts must not be presented as proof of today’s served tree. | ✓ VERIFIED | Baseline explicitly timestamps and hashes its phase-era assets; Phase 239 refreshes the current route and served-resource evidence. |
| Semantic alignment must not erase host brand or make Portal imply operator powers. | ✓ VERIFIED | Separate package token namespaces and shells remain; inspected captures show distinct Admin and customer Portal brands. |
| Canonical guidance must not require organizations, roles, or an account picker. | ✓ VERIFIED | Optional adapter and personal fallback are described in docs; README contract test passes. |
| Shared semantic styling must not imply operator powers in Portal copy or visuals. | ✓ VERIFIED | Customer-specific shell/actions remain distinct in source and captures; host role model stays inside the host adapter. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Portal Home/subscription/invoice views | Customer and billing read models | Exact Customer and Customer-scoped billing queries | Yes | ✓ FLOWING |
| Payment-method forms | Context pin and payment methods | Resolved display context plus server pin verification/target reload | Yes | ✓ FLOWING |
| Checkout | LocalSession, Customer, processor result | Persisted LocalSession and configured provider operation | Yes | ✓ FLOWING |
| Host adapter | Actor, selected billable, membership | Authenticated actor and current host membership query | Yes | ✓ FLOWING |
| Admin/Portal package assets | CSS/JS/font response | Package source served through mounted asset routes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Context, POST pin, LiveView authorization/reconnect, checkout event/POST, README contract | `mix test test/accrue_portal/auth_hook_test.exs test/accrue_portal/context_contract_test.exs test/accrue_portal/context_post_test.exs test/accrue_portal/context_live_test.exs test/accrue_portal/checkout_context_test.exs test/accrue_portal/readme_contract_test.exs` | 45 tests, 0 failures | ✓ PASS |
| Current changed host Braintree checkout/status/selection tests | `ACCRUE_HOST_BROWSER_USE_BRAINTREE=1 mix test test/accrue_host_web/live/subscription_live_braintree_test.exs` | 8 tests, 0 failures | ✓ PASS |
| Admin mounted CSS/JS/font responses | `mix test test/accrue_admin/assets_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Portal mounted assets, CSP, and checkout SRI | `mix test test/accrue_portal/csp_plug_test.exs test/accrue_portal/live/checkout_live_test.exs` | 19 tests, 0 failures | ✓ PASS |
| Inventory and design acceptance markers | Two plan-declared `node -e` checks | Both exited 0 | ✓ PASS |
| Current narrow Admin/Portal appearance | Read-only inspection of five current capture images | Brand/shell identity, text/glyph states, visible focus, and narrow reflow observed | ✓ PASS |

The baseline and semantic Playwright specs were not rerun: the runner starts a server and writes new PNGs over the five user-modified capture files. Current mounted asset routes were instead tested directly without modifying captures. The saved captures were inspected, and the later Phase 239 report supplies the refreshed route/resource inventory and mounted resource parity contracts. No provider or remote CI outcome is claimed.

### Probe Execution

No phase-declared or conventional probes apply; Phase 233 is an application contract/design phase, not a migration or tooling phase.

### Test Quality Audit

| Test File | Linked requirement | Active/disabled | Circular | Assertion level | Verdict |
|---|---|---|---|---|---|
| Portal context/POST/LiveView/checkout contract suites | POR-08, SAFE-02, SAFE-03 | Active; no disabled test found in linked suites | None found | Behavioral, including persisted state and provider-call counters | ✓ SUFFICIENT |
| `readme_contract_test.exs` | SHIP-04 | Active | None found | Value/contract comparison to exported symbols | ✓ SUFFICIENT |
| Host Braintree subscription test | POR-08, SAFE-02, SAFE-03 | 8 active tests under explicit Braintree test config | None found | Behavioral; status, foreign-target denial, revocation, persisted actor | ✓ SUFFICIENT |
| Admin/Portal mounted resource tests | BASE-01, SYS-01, SYS-02 | Active | None found | Exact response body, content type, and mounted resource behavior | ✓ SUFFICIENT |

No disabled requirement-linked tests or circular expected-value generators were found in the reviewed files.

### Requirements Coverage

| Requirement | Source plans | Status | Evidence |
|---|---|---|---|
| BASE-01 | 233-04 | ✓ SATISFIED | Dated current source inventory and distinct served baseline with provenance; Phase 239 refreshes current route/resource evidence. |
| SYS-01 | 233-04, 233-06 | ✓ SATISFIED | Shared semantic roles are wired in package consumers; served resource tests passed; status/focus/reflow assertions and inspected captures agree. |
| SYS-02 | 233-04, 233-06 | ✓ SATISFIED | Separate Admin and Portal token/brand/shell ownership; no new UI dependency. |
| POR-08 | 233-01, 233-02, 233-03, 233-05, 233-07 | ✓ SATISFIED | Personal and custom resolution, actor/billable distinction, and protected action behavior passed focused contracts. |
| SAFE-02 | 233-01, 233-02, 233-03, 233-05, 233-07 | ✓ SATISFIED | Fresh authorization, invalid-selection blocking, no unauthorized provisioning/writes, and denial tests passed. |
| SAFE-03 | 233-02, 233-03, 233-05, 233-07 | ✓ SATISFIED | Signed form/checkout pins bind the displayed billable, Customer, and processor across target lookup and action. |
| SHIP-04 | 233-05 | ✓ SATISFIED | Canonical example, optional adapter, executable docs contract, and no new auth/runtime dependency. |

All seven Phase 233 requirements are claimed by plans; no orphaned requirement is mapped to Phase 233.

### Decision Coverage

The decision-coverage gate returned 17/17 honored, 0 not honored. This is non-blocking and records no decision drift.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `accrue_admin/assets/css/app.css` | 4777 | `placeholder` selector | Info | Expected input placeholder styling, not an implementation stub. No unresolved TBD/FIXME/XXX/TODO/HACK markers or empty implementations were found in the reviewed phase implementation paths. |

### Human Verification Required

None. The narrow visual evidence was inspected from the current captures; state transitions and action invariants have focused automated test coverage. The automated Playwright lane was not rerun because it would overwrite current user-modified captures; mounted-resource tests ran directly instead.

### Deferred Items

None. The later Phase 239 current route and served-resource evidence has already been produced and is included as corroborating evidence, not an open gap.

### Gaps Summary

No unresolved gaps. The current worktree passes focused Portal context/action/checkout/docs checks, the modified Braintree host test, and Admin/Portal mounted resource contracts. Phase 233’s dated baseline remains explicit about its source revision; later source changes are covered by Phase 239’s refreshed route and served-resource evidence. All roadmap truths, plan truths, prohibitions, and requirements are satisfied.

---

_Verified: 2026-10-09T12:47:23Z_
_Verifier: the agent (gsd-verifier)_
