---
phase: 213-stripe-native-advisory-entitlements-sync-observational-only
plan: "03"
subsystem: stripe-native-advisory-entitlements-sync
status: complete
tags:
  - stripe
  - entitlements
  - advisory-sync
  - isolation-guard
dependency_graph:
  requires:
    - "213-01 Fake-backed refresh primitive and shared Reconcile writer"
    - "213-02 LatticeStripe active-entitlement adapter and refresh worker"
  provides:
    - "Static isolation guard coverage for list_active_entitlements and Reconcile"
    - "Runtime grant-invariance proof for no, empty, stale, and contradictory advisory cache rows"
    - "Closed fetch_entitled/2 will-not-build decision in admin docs and guide"
  affects:
    - scripts/ci/verify_entitlement_sync_isolation.sh
    - scripts/ci/verify_package_docs.sh
    - accrue/lib/accrue/entitlements/admin.ex
    - accrue/guides/entitlements.md
tech_stack:
  added: []
  patterns:
    - "ROOT_DIR-backed hermetic shell-script negative fixtures"
    - "Advisory-cache rows inserted directly for grant-boundary invariance tests"
key_files:
  created:
    - accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs
  modified:
    - scripts/ci/verify_entitlement_sync_isolation.sh
    - accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs
    - accrue/lib/accrue/entitlements/admin.ex
    - accrue/guides/entitlements.md
    - accrue/test/accrue/docs/package_docs_verifier_test.exs
    - scripts/ci/verify_package_docs.sh
key_decisions:
  - "The static gate blocks executable list_active_entitlements and Reconcile references in grant-path files while allowing explanatory comments and moduledocs."
  - "Grant APIs remain byte-for-byte local with no row, empty row, stale row, and directly contradictory fresh advisory row even when stripe_native_sync is :advisory."
  - "fetch_entitled/2 is closed and will-not-build because a Stripe-backed authorization predicate can fail open under network partition; diagnostics use StripeSync.summary_for_customer/1 and Admin.resolve_for_customer/1."
requirements_completed:
  - SYNC-02
  - SYNC-03
  - SYNC-04
  - SYNC-05
coverage:
  - id: D1
    description: "Executable gate-path references to list_active_entitlements and Reconcile fail the isolation guard while clean/comment-only fixtures pass."
    requirement: SYNC-03
    verification:
      - kind: unit
        ref: "mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs"
        status: pass
      - kind: other
        ref: "bash scripts/ci/verify_entitlement_sync_isolation.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "No, empty, stale, and contradictory advisory cache states cannot alter the local grant surface."
    requirement: SYNC-02
    verification:
      - kind: integration
        ref: "mix test test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "fetch_entitled/2 is explicitly closed in code docs and guide, and verifier tests reject renewed ambiguity or predicate reintroduction."
    requirement: SYNC-04
    verification:
      - kind: unit
        ref: "mix test test/accrue/docs/package_docs_verifier_test.exs"
        status: pass
      - kind: other
        ref: "! rg -n 'def(p)? fetch_entitled' lib test"
        status: pass
    human_judgment: false
metrics:
  started_at: 2026-07-30T21:23:22Z
  completed_at: 2026-07-30T21:29:09Z
  duration: "6 min"
  tasks_completed: 2
  commits: 4
---

# Phase 213 Plan 03: Isolation Guard and Grant Boundary Summary

Static and runtime guardrails now independently prove Stripe-native advisory data cannot enter entitlement grant decisions, and the Stripe-backed `fetch_entitled/2` predicate is explicitly closed as will-not-build.

## Performance

- **Duration:** 6 min
- **Started:** 2026-07-30T21:23:22Z
- **Completed:** 2026-07-30T21:29:09Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Extended `verify_entitlement_sync_isolation.sh` to reject executable `list_active_entitlements` and `Reconcile` references from always-on gate files.
- Added hermetic guard fixtures that prove clean files pass, executable new-token edges fail, comment/moduledoc mentions pass, and missing files still fail.
- Added advisory-enabled grant-invariance coverage proving no row, empty row, stale row, and directly contradictory fresh row all leave `entitled?/2`, `features_for/1`, `has_active_plan?/2`, and `entitlement_quantity/2` unchanged.
- Closed `fetch_entitled/2` in `Admin` moduledoc and the entitlements guide, with docs-verifier protection against renewed ambiguous wording or predicate reintroduction.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: entitlement sync isolation guard red paths** - `870fba9c` (test)
2. **Task 1 GREEN: extended isolation guard** - `a7b96057` (feat)
3. **Task 2 RED: grant invariance and fetch closure red paths** - `58a4fc0a` (test)
4. **Task 2 GREEN: fetch closure and grant invariance** - `52303d8a` (feat)

## Files Created/Modified

- `accrue/test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs` - New hermetic shell-script guard tests using `ROOT_DIR` fixtures.
- `scripts/ci/verify_entitlement_sync_isolation.sh` - Added forbidden `list_active_entitlements` and `Reconcile` symbols plus comment/moduledoc filtering.
- `accrue/test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs` - Added advisory-enabled no/empty/stale/contradictory cache invariance coverage.
- `accrue/lib/accrue/entitlements/admin.ex` - Replaced deferred `fetch_entitled/2` wording with a closed will-not-build decision.
- `accrue/guides/entitlements.md` - Added the guide-level `fetch_entitled/2` closure rationale.
- `accrue/test/accrue/docs/package_docs_verifier_test.exs` - Added verifier red paths for ambiguous fetch wording and predicate reintroduction.
- `scripts/ci/verify_package_docs.sh` - Added fixed/absent checks for the fetch closure and forbidden predicate.

## Decisions Made

- `fetch_entitled/2` is not deferred; it is closed. The diagnostic value is covered by `StripeSync.summary_for_customer/1` and `Admin.resolve_for_customer/1`, while the authorization-shaped name would invite a fail-open network gate.
- The isolation script now skips Elixir triple-quoted doc blocks in addition to shell-style comment suffixes so architecture prose can name forbidden seams without weakening executable-code detection.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The RED grant-invariance test initially used `Accrue.Repo.delete_all/1`, but the public repo wrapper does not expose `delete_all/1`; the fixture setup was corrected to use `Accrue.TestRepo` for direct test rows before the RED commit.
- The docs negative fixture initially contained a literal `def fetch_entitled` in tracked test source, which correctly tripped the plan-level repository grep. The fixture now builds the forbidden function name at runtime so the temp-file verifier path remains tested without violating the repository invariant.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Threat Flags

None. The plan adds tests, shell/doc verifiers, and documentation closure only; it introduces no new network endpoint, auth path, file access path, scheduler, schema, or grant-authority surface.

## Verification

- `cd accrue && mix test test/accrue/entitlements/entitlement_sync_isolation_guard_test.exs && cd .. && bash scripts/ci/verify_entitlement_sync_isolation.sh` - passed, 5 tests.
- `cd accrue && mix test test/accrue/entitlements/stripe_sync_disabled_isolation_test.exs test/accrue/docs/package_docs_verifier_test.exs && ! rg -n 'def(p)? fetch_entitled' lib test` - passed, 38 tests.
- `bash scripts/ci/verify_entitlement_sync_isolation.sh && cd accrue && mix test test/accrue/entitlements test/accrue/docs/package_docs_verifier_test.exs` - passed, 123 tests.

## Next Phase Readiness

Ready for Phase 214. Phase 213 now has a client-backed advisory sync, static gate enforcement around the new fetch/shared-writer symbols, runtime proof that advisory rows do not influence grants, and a closed `fetch_entitled/2` decision for docs reconciliation.

## Self-Check: PASSED

- Found summary file and all key created/modified files.
- Found task commits `870fba9c`, `a7b96057`, `58a4fc0a`, and `52303d8a` in git history.
- No known stubs, skipped tests, or unrun verification items were left behind.

---
*Phase: 213-stripe-native-advisory-entitlements-sync-observational-only*
*Completed: 2026-07-30*
