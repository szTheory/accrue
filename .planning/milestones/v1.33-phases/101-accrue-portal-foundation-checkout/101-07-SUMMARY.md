---
phase: 101-accrue-portal-foundation-checkout
plan: 07
subsystem: testing
tags: [braintree, phoenix_live_view, csp, auth, mix]
requires:
  - phase: 101-02
    provides: portal router/auth/csp shell and public namespace
provides:
  - explicit accrue_portal runtime dependency contract for the D-04 surface
  - package-local router/auth/CSP regression tests for the portal shell
  - shared Braintree client-token test seam for later portal suites
affects: [101-08, 101-09, 101-10, accrue_portal]
tech-stack:
  added: [none]
  patterns: [package-local shell regression tests, session-backed auth test adapter, shared portal Braintree client-token stub]
key-files:
  created: [accrue_portal/config/config.exs, accrue_portal/config/test.exs, accrue_portal/test/support/braintree_mox.ex, accrue_portal/test/accrue_portal/router_test.exs, accrue_portal/test/accrue_portal/auth_hook_test.exs, accrue_portal/test/accrue_portal/csp_plug_test.exs]
  modified: [accrue_portal/mix.exs, accrue_portal/lib/accrue_portal/assets.ex, accrue_portal/lib/accrue_portal/router.ex, accrue_portal/lib/accrue_portal/brand_plug.ex, accrue_portal/test/test_helper.exs]
key-decisions:
  - "Verified the D-04 dependency contract at the direct dependency boundary because :accrue legitimately brings transitive :braintree and :lattice_stripe deps."
  - "Mirrored accrue_admin's package-owned config/test boot pattern so accrue_portal can start :accrue and its test repo under mix test."
  - "Used a session-backed auth adapter in portal tests so LiveView auth coverage remains deterministic across processes."
patterns-established:
  - "Portal shell tests assert LiveView route metadata directly from __routes__/0."
  - "Later portal suites can stub Braintree client tokens via AccruePortal.BraintreeMox without live credentials."
requirements-completed: [BT-01]
duration: 11min
completed: 2026-05-01
---

# Phase 101 Plan 07: Portal shell dependency contract and regression proof Summary

**Accrue Portal now publishes its explicit Phoenix/Plug/JSON runtime surface and ships package-local router/auth/CSP regression proof with a reusable Braintree client-token stub.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-05-02T02:16:00Z
- **Completed:** 2026-05-02T02:26:41Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments

- Locked `accrue_portal` to the D-04 direct runtime contract by adding explicit `:plug` and `:jason` deps and pinning Hex releases to an exact `:accrue` version match.
- Added focused package-local router, auth-hook, and CSP regression tests plus a shared `AccruePortal.BraintreeMox` seam for later Hosted Fields suites.
- Fixed shell-support issues surfaced by RED so the portal package can compile and test independently: asset hash accessors, router macro compile shape, cookie-backed theme lookup, and package-owned config/test boot wiring.

## Task Commits

Each task was committed atomically:

1. **Task 1: Publish the exact D-04 runtime dependency contract** - `9495f88` (feat)
2. **Task 2 RED: Add failing shell regression tests** - `7182379` (test)
3. **Task 2 GREEN: Add shared Braintree mocks and make the shell proof pass** - `403deba` (feat)

## Files Created/Modified

- `accrue_portal/mix.exs` - explicit prod dependency surface and exact Hex `:accrue` pin.
- `accrue_portal/config/config.exs` - package-owned baseline test config for `:accrue`.
- `accrue_portal/config/test.exs` - portal repo and endpoint settings for package-local tests.
- `accrue_portal/config/dev.exs` - empty env config so non-test Mix commands still boot.
- `accrue_portal/config/prod.exs` - empty env config so non-test Mix commands still boot.
- `accrue_portal/lib/accrue_portal/assets.ex` - public asset hash accessors required by the router macro.
- `accrue_portal/lib/accrue_portal/router.ex` - browser pipeline compile fix for host routers.
- `accrue_portal/lib/accrue_portal/brand_plug.ex` - fetched-cookie theme lookup matching the admin pattern.
- `accrue_portal/test/support/braintree_mox.ex` - reusable client-token generator stub for later portal suites.
- `accrue_portal/test/accrue_portal/router_test.exs` - route metadata and session-threading coverage.
- `accrue_portal/test/accrue_portal/auth_hook_test.exs` - authenticated, unauthenticated, and no-create auth-hook coverage.
- `accrue_portal/test/accrue_portal/csp_plug_test.exs` - D-22 Braintree allowlist assertions.
- `accrue_portal/test/test_helper.exs` - LiveView signing salt fix for package-local endpoint boot.

## Decisions Made

- The portal dependency contract is enforced at the direct-dependency boundary, not by pretending transitive gateway SDKs disappear from `mix deps.tree` once `:accrue` is present.
- Portal tests use their own auth adapter keyed off `user_token`, because the process-local mock is not reliable across LiveView mount processes.
- `accrue_portal` now owns the same config/test bootstrap shape as `accrue_admin`, which is the sustainable pattern for later package-local LiveView suites.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed missing shell support functions and cookie handling**
- **Found during:** Task 2
- **Issue:** The portal shell could not compile or run honestly under package-local tests because the router macro depended on missing `Assets.*_hash/0` functions and `BrandPlug` read unfetched cookies.
- **Fix:** Added public asset hash accessors and switched `BrandPlug` to fetch cookies before reading the theme cookie.
- **Files modified:** `accrue_portal/lib/accrue_portal/assets.ex`, `accrue_portal/lib/accrue_portal/brand_plug.ex`
- **Verification:** `cd accrue_portal && mix test test/accrue_portal/router_test.exs test/accrue_portal/auth_hook_test.exs test/accrue_portal/csp_plug_test.exs --trace`
- **Committed in:** `403deba`

**2. [Rule 3 - Blocking] Added package-owned config/test boot wiring for accrue_portal**
- **Found during:** Task 2
- **Issue:** `mix test` could not start `:accrue` or the portal repo/endpoint from inside `accrue_portal` because the package had no config files for CLDR, repo, endpoint, or LiveView signing salt.
- **Fix:** Added `config/config.exs`, `config/test.exs`, empty `dev.exs`/`prod.exs`, and aligned the test endpoint setup with the admin package pattern.
- **Files modified:** `accrue_portal/config/config.exs`, `accrue_portal/config/test.exs`, `accrue_portal/config/dev.exs`, `accrue_portal/config/prod.exs`, `accrue_portal/test/test_helper.exs`
- **Verification:** `cd accrue_portal && mix test test/accrue_portal/router_test.exs test/accrue_portal/auth_hook_test.exs test/accrue_portal/csp_plug_test.exs --trace`
- **Committed in:** `403deba`

**3. [Rule 3 - Blocking] Adjusted plan verification commands to match the actual package boundary**
- **Found during:** Tasks 1 and 2
- **Issue:** The plan's `mix test ... -x` flag is unsupported on this Mix version, and `! mix deps.tree --only prod | rg ' braintree$| lattice_stripe$'` cannot pass because those SDKs are valid transitive dependencies of the required `:accrue` path dependency.
- **Fix:** Verified the same shell tests with standard `mix test --trace`, and verified the D-04 contract at the direct top-level dependency boundary instead of the full transitive tree.
- **Files modified:** none
- **Verification:** `cd accrue_portal && mix deps.tree --only prod | rg '^├── (jason|phoenix|phoenix_html|phoenix_live_view|plug) ' && mix deps.tree --only prod | rg '^├── accrue ' && ! mix deps.tree --only prod | rg '^├── (braintree|lattice_stripe) '`
- **Committed in:** `9495f88`, `403deba`

---

**Total deviations:** 3 auto-fixed (1 bug, 2 blocking)
**Impact on plan:** All deviations were required to make the package-local shell proof real and reusable. No scope creep beyond the portal package boundary.

## Issues Encountered

- A stale `.git/index.lock` briefly blocked the GREEN commit attempt; retrying after confirming there was no active Git process resolved it without any repo changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Later portal checkout and payment-method plans can reuse `AccruePortal.BraintreeMox` and the package-local auth/router/CSP shell tests directly.
- The portal package now boots its own test repo and endpoint consistently, so follow-on LiveView suites do not need to re-solve package-level config drift.

## Self-Check: PASSED

- Confirmed `.planning/phases/101-accrue-portal-foundation-checkout/101-07-SUMMARY.md` exists.
- Confirmed task commits `9495f88`, `7182379`, and `403deba` exist in git history.
