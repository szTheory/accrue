---
phase: 233-shared-direction-portal-contract
plan: 05
subsystem: payments
tags: [phoenix, liveview, portal, billing, authorization, playwright]

requires:
  - phase: 233-03
    provides: Shared Portal context handling for page reads and actions.
  - phase: 233-07
    provides: Pinned checkout context and provider-token authorization.
provides:
  - Canonical host adapter and Billing policy for personal, organization, and mixed Portal contexts.
  - Independent Phoenix mount identities for multiple Portal mounts.
  - Adopter README contract with executable callback, option, and action checks.
affects: [portal-adoption, billing-authorization, phase-233-verification]

actuals:
  tokens: 17191
  tasks: 2
  commits: 10

commits: 10
plan_head_before: 5394f70ff09767767c9917bf95bbb867e096e601
plan_head_after: 7e6d8933acab8031c4e449db98be3803ae4d30a7

tech-stack:
  added: []
  patterns:
    - Host adapters resolve pinned owner identity again and authorize each action against fresh membership and target state.
    - Phoenix Portal pipelines, scopes, and LiveView sessions receive mount-specific names.

key-files:
  created:
    - examples/accrue_host/lib/accrue_host/portal_context_adapter.ex
    - accrue_portal/test/accrue_portal/readme_contract_test.exs
    - .planning/phases/233-shared-direction-portal-contract/233-05-T1-GAP-RED.json
  modified:
    - examples/accrue_host/lib/accrue_host/billing.ex
    - accrue/priv/accrue/templates/install/billing.ex.eex
    - examples/accrue_host/lib/accrue_host_web/router.ex
    - examples/accrue_host/e2e/phase233-context.spec.js
    - accrue_portal/README.md
    - accrue_admin/README.md
    - examples/accrue_host/README.md

key-decisions:
  - "A signed context pin locates the selected billable and exact Customer; each request still checks current host policy."
  - "Personal-only hosts retain no-adapter resolution: one existing Customer preserves its configured processor, no row may use existing personal provisioning, and multiple rows are ambiguous and blocked."
  - "Mixed hosts use explicit personal or organization selection."
  - "Only owner/admin membership can mutate an organization billable; Portal permissions remain separate from Admin operator access."

requirements-completed: [POR-08, SAFE-02, SAFE-03, SHIP-04]

coverage:
  - id: D1
    description: "The canonical host resolves personal and organization contexts, denies member card and checkout collection, and records an authorized organization's card mutation under a human actor."
    requirement: SAFE-02
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-context.spec.js#host-selected member context shows its billable and blocks payment collection"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-context.spec.js#host-selected member context shows its billable and blocks payment collection (organization-owned checkout denial)"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-context.spec.js#an authorized organization manager completes a real Portal payment method mutation"
        status: pass
      - kind: integration
        ref: "examples/accrue_host/e2e/phase233-context.spec.js: Portal payment-method POST followed by /admin/events persisted actor row"
        status: pass
    human_judgment: false
  - id: D2
    description: "The personal-only mount initializes the Hosted Fields SDK without an organization picker, and a second tab retains its pinned personal identity after host selection changes."
    requirement: POR-08
    verification:
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-context.spec.js#personal-only Portal mount needs no account picker and renders secure card entry"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-context.spec.js#host-selected member context shows its billable and blocks payment collection"
        status: pass
    human_judgment: false
  - id: D3
    description: "Portal, Admin, and example-host adopter documentation matches public adapter options, callbacks, named actions, and authorization boundaries."
    requirement: SHIP-04
    verification:
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/readme_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "A still-authenticated member whose selected organization membership is deleted sees generic blocked denial on stale-pin reload and POST, without personal or other billable fallback."
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/router_test.exs#blocked live session preserves host hooks without the customer resolver"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase233-context.spec.js#revoked organization pin blocks reload and submit without falling back"
        status: pass
      - kind: http
        ref: "examples/accrue_host/e2e/phase233-context.spec.js: stale pinned form POST redirects to /shared-billing/blocked"
        status: pass
    human_judgment: false
  - id: D5
    description: "Personal no-adapter checkout preserves its exact existing Braintree Customer when the configured new-customer processor is Fake; adapter-backed custom checkout remains processor strict."
    requirement: SAFE-02
    verification:
      - kind: unit
        ref: "accrue_portal/test/accrue_portal/checkout_context_test.exs#custom checkout stays disabled when the configured processor differs from its target"
        status: pass
      - kind: e2e
        ref: "examples/accrue_host/e2e/phase102-portal-checkout.spec.js#promo preview and checkout completion controls"
        status: pass
    human_judgment: false

duration: 59min
completed: 2026-10-07
status: complete
---

# Phase 233 Plan 05: Shared Portal Context Adapter Summary

**A host-owned Portal adapter now resolves personal, organization, and mixed billing identities with fresh action policy, pin-preserving routes, human actor evidence, and aligned adopter docs.**

## Performance

- **Duration:** 59 min
- **Started:** 2026-10-07T21:36:52Z
- **Completed:** 2026-10-07T22:36:00Z
- **Tasks:** 2
- **Files modified:** 26

## Accomplishments

- Added a canonical adapter mount alongside the unchanged personal-only Portal route; the host re-resolves organization membership and applies role policy to each action and target.
- Added real browser coverage for personal-only Hosted Fields, member read-only denial with no payment form submission, cross-tab pin retention, an authorized organization card mutation, and the persisted human `User` actor shown in the Admin event ledger.
- Kept the generated Billing facade and install template aligned through the existing fingerprint mechanism, and documented the optional contract across Portal, Admin, and the example host.
- Added an executable README contract test that checks mount options, callback signatures, and all documented action names.
- Preserved the sole existing personal Braintree Customer when the host's configured processor differs, while keeping adapter-backed custom processor matching strict.
- Preserved host-supplied LiveView hooks on the generic blocked route so membership revocation retains authenticated user identity through the socket mount.
- Added real revocation browser proof: deleting selected organization membership blocks the stale pin on reload and rejects its POST without falling back to the personal or another organization billable.
- Measured eligible Hosted Fields SDK initialization through deterministic client and Hosted Fields creation counters; authorized organization mutation and persisted human actor remain proven.

## Task Commits

1. **Task 1 RED:** `fe977ff4` — test(233-05): add host context browser contract regression
2. **Task 1 implementation:** `e4e97526` — feat(233-05): add host shared billing context adapter
3. **Task 2:** `29985659` — docs(233-05): align adopter docs with shared portal contract
4. **Task 1 browser actor proof:** `7e3380f2` — test(233-05): prove authorized organization mutation in browser
5. **Task 2 fallback clarification:** `db190385` — docs(233-05): clarify personal customer fallback semantics
6. **Revoked LiveView host-hook fix:** `e21cb7f9` — fix(233-05): preserve host hooks on blocked portal live view
7. **Checkout compatibility and revoked pin browser proof:** `7e6d8933` — fix(233-05): prove checkout targets and revoked context denial

The measured plan-ledger range contains 10 commits from `5394f70ff09767767c9917bf95bbb867e096e601` through `7e6d8933acab8031c4e449db98be3803ae4d30a7`. It includes sequential phase and validation commits in the shared checkout.

## Verification

- RED gate: `gsd_run check tdd-red-evidence .planning/phases/233-shared-direction-portal-contract/233-05-T1-RED.json` returned `RED_EVIDENCE_OK` (2 browser tests, personal control passed, named shared-mount route returned 404 before implementation).
- Final browser contract: `npm_config_cache=/tmp/accrue-233-npm-cache ACCRUE_HOST_E2E_FIXTURE=/private/tmp/phase233-context-fixture.json npm run e2e -- e2e/phase233-context.spec.js --workers=1` — 6 passed, 0 failed.
- Browser regression: Phase233 baseline and semantic specs plus Phase102 checkout — 4 passed, 0 failed.
- Portal regression: `HEX_HOME=/tmp/accrue-233-hex mix test --warnings-as-errors` — 70 passed, 0 failed.
- Host Billing facade: `HEX_HOME=/tmp/accrue-233-hex mix test test/accrue_host/billing_facade_test.exs --warnings-as-errors` — 18 passed, 0 failed.
- README contract: `HEX_HOME=/tmp/accrue-233-hex mix test test/accrue_portal/readme_contract_test.exs --warnings-as-errors` — 2 passed, 0 failed.
- Full host regression: `HEX_HOME=/tmp/accrue-233-hex mix test` — 219 tests, 0 failures. The earlier AdminMount headline assertion was corrected in the subsequent validation audit.

## TDD Gate Compliance

- **RED:** The host-selected route assertion failed because `/shared-billing` did not exist; the personal-only control passed. Machine validation and semantic inspection confirmed the failure was the missing planned mount.
- **GREEN:** The current browser suites pass personal-only Hosted Fields SDK initialization, selected member denial, cross-tab pin retention, membership-revoked pin denial, authorized organization mutation, and persisted human actor display. Portal and full host suites also pass.
- **REFACTOR:** No separate refactor commit was needed; the router mount identity fix and redirect pin preservation were included in the implementation commit.

## Decisions Made

- Treat the signed owner and Customer/processor locator as routing context only; reload membership and authorize the current action and server-loaded target.
- Leave the simple no-adapter personal mount available without an organization model or picker. For the adapter mount, personal selection is explicit when an organization is active.
- Use host owner/admin roles for organization writes, allow current members to read, and keep Admin operator authorization independent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Give multiple Portal mounts independent router identities**
- **Found during:** Task 1
- **Issue:** Repeated mount macros reused pipeline, scope, and LiveView session names, producing conflicting routes and LiveView sessions.
- **Fix:** Derive deterministic names from each mount path while preserving the legacy `/billing` names.
- **Files modified:** `accrue_portal/lib/accrue_portal/router.ex`
- **Verification:** Host browser suite (3/3) and Portal suite (68/68).
- **Committed in:** `e4e97526`

**2. [Rule 1 - Bug] Load adapter modules before checking optional callback exports**
- **Found during:** Task 1
- **Issue:** A configured adapter atom could be treated as missing when not loaded yet, causing valid host context to fail closed.
- **Fix:** Ensure the adapter module is loaded before `function_exported?/3` checks.
- **Files modified:** `accrue_portal/lib/accrue_portal/context.ex`
- **Verification:** Host browser suite (3/3) and Portal suite (68/68).
- **Committed in:** `e4e97526`

**3. [Rule 1 - Bug] Keep mutation redirects attached to the submitted context pin**
- **Found during:** Task 1
- **Issue:** Payment-method POSTs redirected without the pin, so the next page could resolve the changed session selection instead of the billable the form represented.
- **Fix:** Append the validated submitted pin to payment-method success and error destinations and assert it in regression tests.
- **Files modified:** `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex`, `accrue_portal/test/accrue_portal/context_post_test.exs`
- **Verification:** Portal suite (68/68) and cross-tab browser assertion.
- **Committed in:** `e4e97526`

**4. [Rule 3 - Blocking] Keep isolated custom Phoenix test endpoints alive for the full suite**
- **Found during:** Task 1 regression verification
- **Issue:** Test endpoints linked to short-lived setup processes lost their ETS configuration tables intermittently during the full Portal suite.
- **Fix:** Unlink each endpoint after startup so it remains available across tests.
- **Files modified:** `accrue_portal/test/accrue_portal/context_post_test.exs`, `accrue_portal/test/accrue_portal/checkout_context_test.exs`
- **Verification:** Full Portal suite (68/68).
- **Committed in:** `e4e97526`

**5. [Rule 2 - Missing Critical] Make mixed-host personal selection explicit and seed a deterministic read-only member**
- **Found during:** Task 1
- **Issue:** The host selection route did not represent an explicit personal selection while an organization was active, and the browser fixture had no deterministic read-only membership.
- **Fix:** Add a `personal` selection marker to the existing organization-scope route and seed the normal browser user as an organization member.
- **Files modified:** `examples/accrue_host/lib/accrue_host_web/controllers/organization_scope_controller.ex`, `scripts/ci/accrue_host_seed_e2e.exs`
- **Verification:** Final browser suite (3/3).
- **Committed in:** `e4e97526`

**Total deviations:** 5 auto-fixed (2 Rule 1, 1 Rule 2, 2 Rule 3).
**Impact on plan:** Each fix was needed for correct multi-mount operation, context retention, deterministic regression coverage, or the plan's required positive authorization and actor proof. No new package or runtime dependency was added.

## Follow-up RED/GREEN Evidence

- **Checkout target regression RED:** `checkout_context_test.exs` now exercises a custom context whose stored checkout processor differs from the configured processor; it asserts generic denial, no Hosted Fields, no form, and zero client-token calls. The no-adapter personal Braintree positive control is exercised in the browser while the host processor is Fake.
- **Blocked host hooks RED:** `233-05-T1-GAP-RED.json` records the failing Router contract test: only `AuthHook.ensure_user` existed in the blocked session, and the host hook assertion failed. The GREEN implementation forwards supplied host hooks before `ensure_user` and explicitly omits `ensure_customer`; the browser then confirmed the valid identity reaches the accessible blocked state after membership deletion.
- **Browser proof:** Phase233 context 6/6 passed, including an authenticated membership deletion, stale-pin reload to `/shared-billing/blocked`, no Hosted Fields/submit control, and stale-pin POST redirected to the same generic blocked route.
- **Mutation proof:** Browser payment-method POST returned success and the Admin event ledger showed the authenticated human `User` as actor for the organization-owned mutation. A separate manager case remained unable to access `/admin`.

## Issues Encountered

- Historical validation first found one stale Admin dashboard headline assertion; the later audit updated it, and the full host suite now passes 219/219.
- The roadmap progress helper returned `missing_phase_details` despite the existing Phase 233 checklist and progress row; those entries are updated directly during close-out, while Phase 233 remains in progress for root-owned review and UAT.
- No authorization approval gate occurred. Existing pinned asset tooling and restored Hex cache were used; lockfiles were not changed.

## Files Created/Modified

- `examples/accrue_host/lib/accrue_host/portal_context_adapter.ex` — host-owned personal and organization selection resolution.
- `examples/accrue_host/lib/accrue_host/billing.ex` and `accrue/priv/accrue/templates/install/billing.ex.eex` — current host membership/action/target policy and aligned install template.
- `accrue_portal/lib/accrue_portal/router.ex` — isolated identities for multiple Portal mounts.
- `accrue_portal/lib/accrue_portal/controllers/payment_method_controller.ex` — pin-preserving mutation redirects.
- `examples/accrue_host/e2e/phase233-context.spec.js` — personal, denied member, cross-tab, and authorized organization mutation/actor browser proofs.
- `accrue_portal/README.md`, `accrue_admin/README.md`, and `examples/accrue_host/README.md` — adopter contract and boundary documentation.
- `accrue_portal/test/accrue_portal/readme_contract_test.exs` — executable documentation contract.
- `.planning/phases/233-shared-direction-portal-contract/233-05-T1-RED.json` — machine-validated TDD RED evidence.

## Self-Check: PASSED

- Summary file exists at the requested phase path.
- All seven plan task/follow-up commits are ancestors of `HEAD`.
- The persisted shared-checkout plan ledger count is 10, matching `actuals.commits`, `commits`, and the recorded plan head range at this summary update.

---
*Phase: 233-shared-direction-portal-contract*
*Completed: 2026-10-07*
