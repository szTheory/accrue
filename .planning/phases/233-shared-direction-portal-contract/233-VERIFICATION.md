---
phase: 233-shared-direction-portal-contract
verified: 2026-10-09T02:22:10Z
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
  - "examples/accrue_host/test/install_boundary_test.exs"
  - "scripts/ci/accrue_host_seed_e2e.exs"
  - "scripts/ci/accrue_host_verify_browser.sh"
covered_digest: "v3:sha256:4257749be37567e5dcf734ef95f64b17922620ec76082127e64d891781959319"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 5/5 roadmap truths verified
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 233: Shared Direction & Portal Contract Verification Report

**Phase Goal:** Maintainers and adopters can see a current, coherent Admin and Portal baseline, while hosts can select a billed entity and authorize its actions through one bounded Portal contract.
**Verified:** 2026-10-09T02:22:10Z
**Status:** passed
**Re-verification:** Yes — refreshed after the prior passed report became stale.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Maintainers can inspect the current served route, flow, component, and state inventory and distinguish it from historical captures. | ✓ VERIFIED | `233-INVENTORY.md` and `233-BASELINE.md` separate current source and served route/asset provenance from historical evidence. Current desktop baseline browser checks passed; baseline asserts served hashed assets against source bytes. |
| 2 | Operators and customers see shared semantic visual roles while Admin identity, host customer branding, and audience-specific layouts remain recognizable in real consumers. | ✓ VERIFIED | `DESIGN.md`, package token ownership, Admin and Portal CSS, and served semantic browser checks establish distinct `--ax-*` and `--accrue-*` APIs, text/glyph status cues, focus, accent contrast, and 320px reflow. Current baseline/semantic browser checks passed 8/8 in this refresh. |
| 3 | A personal-only host retains existing Portal behavior without a company model or picker; mixed hosts resolve personal and custom billables while actor, billable, Customer, and processor remain distinct. | ✓ VERIFIED | `CustomerSession`, `Context`, and the host adapter resolve exact owner type/ID/processor Customer separately from authenticated actor. Contract tests cover personal fallback, explicit custom selection, identity collisions, and no first-record choice. Current context and host browser checks passed; Phase 233 dedicated Braintree browser lane passed 12 checks and Phase 236 lane passed 14. |
| 4 | Initial requests, LiveView events/reconnects, and protected actions freshly authorize selected context; invalid selection cannot provision, fall back, retarget, or mutate. | ✓ VERIFIED | AuthPlug/AuthHook and payment, checkout, subscription, and invoice paths verify signed locators, re-resolve host policy and server-load exact targets before protected operations. Tests cover denial, revocation, changed tabs, reconnect, replay, foreign targets, zero provisioning/token/write, and allowed mutations. Current Portal suite: 110 tests, 0 failures; Host suite: 222, 0 failures. |
| 5 | Canonical example and adopter guidance cover personal, custom/organization, and mixed resolution without new auth/runtime dependency. | ✓ VERIFIED | Canonical host adapter/router, generated install template, package READMEs, and executable README contract tests agree on the optional adapter and named-action API. Core tests: 2,077, 0 failures; docs verifier: 46, 0 failures. No phase dependency was added. |

**Score:** 29/29 must-haves verified (0 present, behavior-unverified).

### Plan Must-Haves

All 24 plan-specific truths are verified in source and their focused tests: optional adapter and personal compatibility; generic blocked recovery and no provisioning; no implicit first billable; exact Customer identity; signed payment and checkout pins; fresh action authorization for POSTs, LiveView events, reconnects, and server-loaded targets; state clearing/no replay on denial; provider token gating; actor attribution; current baseline provenance; separate semantic token/brand/shell ownership; and canonical host/docs alignment. Corresponding artifact and wiring evidence appears in the tables below. No plan truth failed or remains uncertain.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `233-INVENTORY.md`, `233-BASELINE.md`, `DESIGN.md` | Current source/served baseline and bounded semantic contract | ✓ VERIFIED | Substantive route/state ownership and provenance docs; baseline and semantic browser specs assert real served asset bytes and hashes. |
| `captures/*` (five representative images) | Current Admin/Portal renders documented by baseline | ✓ VERIFIED | Evidence files were present and provenance is documented. Their pre-existing worktree edits were backed up and restored byte-for-byte around the browser run; no capture file was modified by this verification. |
| `accrue_portal/lib/accrue_portal/{context,customer_session,auth_hook,auth_plug}.ex` | Optional host resolution, actor/billable distinction, pinning, fresh authorization | ✓ VERIFIED | Implementations connect router session data through policy resolution and exact Customer identity into HTTP/LiveView mounts. |
| Portal payment, checkout, subscription, and invoice controllers/LiveViews | Protected rendered forms and pinned actions | ✓ VERIFIED | Rendered pin producers feed real POST/event paths; consumers re-resolve and authorize before provider/billing operations. Focused contract tests cover positive and denial transitions. |
| `examples/accrue_host/lib/accrue_host/portal_context_adapter.ex` and host billing/router | Host-owned personal/custom selection and action policy | ✓ VERIFIED | Membership and target checks remain host-owned; personal, mixed, manager, revocation, and actor paths are exercised in integration/browser coverage. |
| `examples/accrue_host/e2e/phase233-*.spec.js` | Current baseline, semantic, context, and processor browser proof | ✓ VERIFIED | Current refresh passed 8/8 baseline/context/semantic checks; supplied current evidence records Phase 233 Braintree lane 12 passes and Phase 236 lane 14 passes. |
| Portal/Admin/host README and install template | Adopter guidance aligned with public API | ✓ VERIFIED | Executable docs contract validates router option, callbacks, and action names. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Host router/session | `CustomerSession` / `Context` | Declared session subset and optional adapter | ✓ WIRED | Router passes host options into mounts; resolver uses host policy before custom Customer provisioning. |
| Signed context pin | Payment/checkout actions | Phoenix.Token mint/verify plus current adapter authorization | ✓ WIRED | Rendered default/delete/create and checkout forms carry pins through HTTP or LiveView; targets are reloaded under exact Customer before action. |
| AuthHook | Home/subscription/invoice LiveViews | Resolved context assign and target-scoped reads/actions | ✓ WIRED | Pinned navigation/reconnect and subscription/invoice controls call fresh authorization paths. |
| Host adapter | Host membership and billing facade | Resolve and authorize callbacks | ✓ WIRED | Adapter delegates live membership/action/target checks to host billing policy and keeps Admin operator authorization separate. |
| Semantic roles | Package CSS and served assets | Admin build and Portal recompilation | ✓ WIRED | Served checks verify source/body and URL digests plus status, focus, contrast, and narrow reflow. |
| Public API | Adopter documentation | Executable README contract test | ✓ WIRED | Docs examples and named action list are checked against current code symbols. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Portal Home, subscription, invoice views | Customer and billing read models | Exact DB Customer and Customer-scoped billing queries | Yes | ✓ FLOWING |
| Payment-method forms | Context pin and payment methods | Displayed resolved context; server-side pin verification and Customer-scoped target reload | Yes | ✓ FLOWING |
| Checkout | LocalSession, Customer, processor result | Persisted LocalSession and configured provider operation | Yes | ✓ FLOWING |
| Host adapter | Actor, selected billable, membership | Authenticated host session and current membership query | Yes | ✓ FLOWING |
| Admin/Portal baseline | CSS/JS | Package source compiled/embedded and served at hashed URL | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Evidence | Result | Status |
|---|---|---|---|
| Portal identity, authorization, pin, denial, and action transitions | Current Portal suite; 110 tests, 0 failures | Passed | ✓ PASS |
| Host adoption and actor attribution | Current host suite; 222 tests, 0 failures | Passed | ✓ PASS |
| Core and generated docs contracts | Core 2,077 tests, 0 failures; docs verifier 46, 0 failures | Passed | ✓ PASS |
| Current Admin/Portal baseline, context, semantic contracts | Browser refresh, 8/8 | Passed | ✓ PASS |
| Braintree browser contracts | Phase 233 lane 12 passed; Phase 236 lane 14 passed | Passed | ✓ PASS |
| Later-phase adjacent detail/recovery coverage | Phase 234 subscription detail 1/1; Phase 237 billing/recovery 1/1 | Passed | ✓ PASS |

Tests were not rerun in this verification; the behavioral results above are the current execution evidence supplied for this refresh. Source wiring and named test cases were inspected independently.

### Probe Execution

No phase-declared or conventional phase probes apply; Phase 233 is not a migration or tooling phase.

### Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| BASE-01 | 233-04 | Current route/flow/component/state inventory and provenance-separated served baseline | ✓ SATISFIED | Current inventory, baseline, captures, asset provenance assertions; browser refresh passed. |
| SYS-01 | 233-04, 233-06 | Shared semantic roles and observable state/focus/contrast/reflow | ✓ SATISFIED | Package CSS and served browser assertions cover text/glyph status, visible focus, contrast, and 320px reflow. |
| SYS-02 | 233-04, 233-06 | Shared roles preserve Admin identity, host brand, distinct shells/tokens, and no new UI dependency | ✓ SATISFIED | Separate token namespaces and consumer shells verified in source/browser; manifests show no added dependency. |
| POR-08 | 233-01, 233-02, 233-03, 233-05, 233-07 | Personal, custom, and mixed Portal context without operator-role bleed | ✓ SATISFIED | Exact identity, personal/mixed selection, manager/Admin boundary and host browser controls. |
| SAFE-02 | 233-01, 233-02, 233-03, 233-05, 233-07 | Fresh authorization, safe invalid selection, no unauthorized provisioning or writes | ✓ SATISFIED | Denial/revocation/reconnect/no-provision/no-token/no-write cases in focused suites and browser controls. |
| SAFE-03 | 233-02, 233-03, 233-05, 233-07 | Forms and checkout pinned to displayed billable, Customer, and processor | ✓ SATISFIED | Rendered form pins, exact target checks, mismatched processor and replay controls. |
| SHIP-04 | 233-05 | Adopter docs and canonical example cover personal/custom/mixed use without new auth/runtime dependency | ✓ SATISFIED | Canonical adapter, host example, install template, and executable docs contract; no dependency additions. |

No Phase 233 requirement is orphaned from the plans.

### Decision Coverage

The current validation record reports 17/17 trackable context decisions honored. This is non-blocking; no decision drift is identified.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No unresolved TODO/FIXME/XXX markers, empty implementations, or disconnected data paths found in reviewed phase implementation files. | — | — |

The few `placeholder` matches are expected secure-field input hints and CSS `::placeholder` styling, not implementation stubs. The UI review’s inherited spacing/type/theme-size and dense Admin observations have explicit dispositions in `233-UI-DISPOSITION.md`; they are outside this bounded semantic-contract goal and are not unresolved Phase 233 gaps.

### Human Verification Required

None. The phase’s stable behavior and current served baseline contracts have deterministic integration and browser evidence. No recurring manual UAT is required by the validation strategy.

### Gaps Summary

No unresolved gaps. The prior report’s scope and fingerprint were stale; current source, plans, requirements, and fresh execution evidence support all five roadmap truths, all 24 plan-specific truths, and all seven Phase 233 requirements. Security review records 16/16 threats closed, code review reports no findings, and the UI audit’s observations are explicitly dispositioned.

---

_Verified: 2026-10-09T02:22:10Z_
_Verifier: the agent (gsd-verifier)_
