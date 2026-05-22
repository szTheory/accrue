---
phase: 123-config-core-gate-api-foundation
plan: 02
subsystem: observability
tags: [opentelemetry, telemetry, entitlements, otel, allowlist]

# Dependency graph
requires:
  - phase: 123-config-core-gate-api-foundation (P01)
    provides: ":entitlements config schema + D-18/D-19 entitlement metadata contract"
provides:
  - "OTel @allowed_attributes extended with the 6 D-19 entitlement keys (atom + accrue.* string forms)"
  - "Entitlement OTel spans retain :feature/:result/:resolver/:reason/:subject_type/:subject_id instead of silently dropping them"
  - "Retention assertion in otel_test.exs proving sanitize_attributes/1 keeps all six (ENT-05 OTel half)"
affects: [124-plug-liveview-guards, 125-resolver-behaviour-capability-matrix, 126-admin-entitlements-docs, entitlements-telemetry, otel]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Strict OTel allowlist: any key not in @allowed_attributes is dropped by sanitize_attributes/1; new span attributes MUST be added in both atom and accrue.* string form"
    - ":result is a distinct entitlement decision key, never folded into :status (D-19)"

key-files:
  created: []
  modified:
    - "accrue/lib/accrue/telemetry/otel.ex"
    - "accrue/test/accrue/telemetry/otel_test.exs"

key-decisions:
  - "Added :result as its own allowlist key (atom + accrue.result) rather than reusing :status/accrue.status, per D-19."
  - "Test asserts result: true crosses the bridge as the string \"true\" because sanitize_value/1 stringifies atoms and true/false are atoms — matching the established sanitize contract rather than changing it."

patterns-established:
  - "OTel allowlist additions: extend @allowed_attributes with BOTH atom and accrue.<key> string entries; the string-keyed half lets pre-namespaced metadata pass through unchanged."

requirements-completed: [ENT-05]

# Metrics
duration: 1min
completed: 2026-05-22
---

# Phase 123 Plan 02: OTel Entitlement Attribute Retention Summary

**Extended the strict OTel `@allowed_attributes` allowlist with the six D-19 entitlement keys (`:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id`) so entitlement spans carry their decision metadata across the OTel bridge instead of being silently dropped.**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-05-22T22:30:46Z
- **Completed:** 2026-05-22T22:31:25Z
- **Tasks:** 1
- **Files modified:** 2

## Accomplishments
- Added the 6 D-19 entitlement keys to `@allowed_attributes` in both atom and `accrue.<key>` string form (12 new map entries total) so `sanitize_attributes/1` forwards them.
- Kept `:result` distinct from `:status` per D-19 (no key reuse).
- Left `@prohibited_keys` untouched, so the D-18 PII rule (`:email`/`:address`/etc. blocked) stays intact.
- Added a retention test asserting all six entitlement keys survive `sanitize_attributes/1` (ENT-05 OTel half, VALIDATION.md ENT-05 OTel row).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the 6 entitlement keys to @allowed_attributes and assert retention** - `264b525` (feat)

**Plan metadata:** committed separately with SUMMARY + STATE/ROADMAP/REQUIREMENTS updates.

## Files Created/Modified
- `accrue/lib/accrue/telemetry/otel.ex` - Extended `@allowed_attributes` with `:feature`, `:result`, `:resolver`, `:reason`, `:subject_type`, `:subject_id` (atom + `accrue.*` string forms).
- `accrue/test/accrue/telemetry/otel_test.exs` - Added "retains the six entitlement (D-19) attributes" test calling `sanitize_attributes/1` with all six keys and asserting none are dropped.

## Decisions Made
- **`:result` is its own allowlist key**, not a reuse of `:status` — D-19/RESEARCH mandate a distinct `:result` for entitlement decisions.
- **Test expects `result: true` → `"true"`** (string). `sanitize_value/1` matches `is_atom/1` before `is_boolean/1`, and `true`/`false` are atoms, so booleans stringify. The test was written to match the existing, unchanged `sanitize_value/1` contract rather than alter sanitization behavior (out of scope for this plan, which only touches the allowlist).

## Deviations from Plan

None - plan executed exactly as written. The allowlist and test were added precisely as the plan's `<action>` specified. The single mid-task correction (test expectation `true` → `"true"`) was alignment with the pre-existing `sanitize_value/1` stringification behavior discovered when the first test run failed; no source-of-truth behavior was changed, so it is a test-assertion correction within the planned task, not an unplanned deviation.

## Issues Encountered
- Initial test asserted the raw boolean `true` for `:result`; the existing `sanitize_value/1` stringifies atoms (and `true`/`false` are atoms in Elixir), so the actual sanitized value is `"true"`. Resolved by correcting the test expectation to `"true"`, matching the established sanitize contract. Test green afterward.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- ENT-05 OTel half is complete: entitlement decision metadata now survives the OTel bridge with bounded cardinality and no PII leakage (T-123-04 / T-123-05 mitigations satisfied).
- Downstream phases (124 Plug/LiveView guards, 125 resolver behaviour) can emit these six attributes on entitlement spans and rely on them being retained.
- No new external dependency added; `@prohibited_keys` PII rule preserved.

## Self-Check: PASSED

- FOUND: accrue/lib/accrue/telemetry/otel.ex (modified)
- FOUND: accrue/test/accrue/telemetry/otel_test.exs (modified)
- FOUND: commit 264b525
- `mix test test/accrue/telemetry/otel_test.exs` — 4 tests, 0 failures (1 excluded :compile_matrix)
- `mix compile --warnings-as-errors` — clean
- Allowlist string-form grep count = 12 (>= 6 required)

---
*Phase: 123-config-core-gate-api-foundation*
*Completed: 2026-05-22*
