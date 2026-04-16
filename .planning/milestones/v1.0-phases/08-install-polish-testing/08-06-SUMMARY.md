---
phase: 08-install-polish-testing
plan: 06
subsystem: observability
tags: [opentelemetry, telemetry, privacy, billing, spans]

requires:
  - phase: 08-install-polish-testing
    provides: "Wave 0 OBS-02 contract tests from 08-01"
provides:
  - "Optional Accrue.Telemetry.OTel bridge with no-op fallback"
  - "Allowlisted and sanitized OpenTelemetry span attributes"
  - "Billing public API span coverage through Accrue.Telemetry.span/3"
affects: [08-install-polish-testing, telemetry, billing, observability]

tech-stack:
  added: []
  patterns:
    - "Optional OTel integration uses Code.ensure_loaded?/1 plus no_warn_undefined"
    - "OTel spans are invoked from Accrue.Telemetry.span/3 without replacing :telemetry"
    - "Billing facade spans pass explicit allowlisted business metadata"

key-files:
  created:
    - accrue/lib/accrue/telemetry/otel.ex
  modified:
    - accrue/lib/accrue/telemetry.ex
    - accrue/lib/accrue/billing.ex

key-decisions:
  - "Plan 08-06 uses the Wave 0 RED tests from 08-01 as the TDD red gate; this plan contributes the GREEN implementation commits."
  - "OTel spans are nested inside the existing :telemetry.span/3 work function so Elixir telemetry handlers remain the stable event surface."
  - "Billing context instrumentation is explicit at public call sites and uses private helpers only for repeated sanitized metadata assembly."

patterns-established:
  - "Accrue.Telemetry.OTel.span/3 always exists and no-ops when OpenTelemetry.Tracer is unavailable."
  - "Span names are derived by joining normalized telemetry event segments with dots."
  - "OTel attributes are limited to processor, customer_id, subscription_id, invoice_id, event_type, operation, and status."

requirements-completed: [OBS-02]

duration: 8min
completed: 2026-04-15T22:10:02Z
---

# Phase 08 Plan 06: Optional OpenTelemetry Span Bridge Summary

**Optional OpenTelemetry spans for Accrue telemetry and Billing APIs with strict privacy allowlists**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-15T22:01:53Z
- **Completed:** 2026-04-15T22:10:02Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added `Accrue.Telemetry.OTel`, an optional OpenTelemetry bridge that compiles cleanly with or without the optional dependency and no-ops when unavailable.
- Routed `Accrue.Telemetry.span/3` through the OTel bridge while preserving `:telemetry.span/3` as the primary event surface.
- Wrapped Billing public facade functions in explicit telemetry spans with sanitized business metadata and coverage-test enforcement.

## Task Commits

1. **Task 1: Implement optional OTel adapter with allowlisted attributes** - `b774b59` (feat)
2. **Task 2: Route `Accrue.Telemetry.span/3` through OTel without replacing telemetry** - `552f39d` (feat)
3. **Task 3: Audit and cover Billing public function spans** - `9153082` (feat)

## Files Created/Modified

- `accrue/lib/accrue/telemetry/otel.ex` - Optional OTel adapter, span naming, attribute sanitization, denylist, and status mapping.
- `accrue/lib/accrue/telemetry.ex` - Central telemetry span path now wraps work in the optional OTel bridge and normalizes span suffixes.
- `accrue/lib/accrue/billing.ex` - Billing public facade functions now emit explicit `[:accrue, :billing, ...]` spans with sanitized metadata.

## Decisions Made

- Used the already-committed Wave 0 OBS-02 tests as the RED gate instead of adding duplicate test commits in this plan.
- Kept `:telemetry.span/3` as the outer wrapper so existing handlers, measurements, and exception behavior are unchanged.
- Used private helper functions only for repeated metadata assembly; individual Billing entry points remain explicit wrappers rather than broad macro-generated instrumentation.

## Verification

- `cd accrue && mix test test/accrue/telemetry/otel_test.exs`
- `cd accrue && mix test test/accrue/telemetry/otel_test.exs test/accrue/telemetry_test.exs`
- `cd accrue && mix compile --warnings-as-errors`
- `cd accrue && mix test test/accrue/telemetry/billing_span_coverage_test.exs test/accrue/telemetry/otel_test.exs`
- `cd accrue && mix test test/accrue/telemetry/otel_test.exs test/accrue/telemetry/billing_span_coverage_test.exs test/accrue/telemetry_test.exs`
- `cd accrue && MIX_ENV=test ACCRUE_OTEL_MATRIX=without_opentelemetry mix compile --warnings-as-errors --force`
- `cd accrue && MIX_ENV=test ACCRUE_OTEL_MATRIX=with_opentelemetry mix compile --warnings-as-errors --force`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Required the OpenTelemetry.Tracer macro in the optional branch**
- **Found during:** Task 2
- **Issue:** `OpenTelemetry.Tracer.with_span/2` is a macro; without `require OpenTelemetry.Tracer`, runtime calls raised `UndefinedFunctionError`.
- **Fix:** Added `require OpenTelemetry.Tracer` inside the compile-time branch where `OpenTelemetry.Tracer` is loaded.
- **Files modified:** `accrue/lib/accrue/telemetry/otel.ex`
- **Verification:** `cd accrue && mix test test/accrue/telemetry/otel_test.exs test/accrue/telemetry_test.exs`
- **Committed in:** `552f39d`

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for true OTel span execution and did not change scope.

## Known Stubs

None. No placeholder or mock production behavior was introduced.

## Threat Flags

None. The new telemetry-to-OTel export boundary was already covered by the plan threat model and mitigated with allowlisted attributes plus prohibited-key tests.

## Issues Encountered

- The OTel test run logs warnings about the optional `opentelemetry_exporter` module not being present. Tests and warnings-as-errors compilation still pass; the warning is emitted by the installed OTel app runtime, not by Accrue code.

## User Setup Required

None.

## Next Phase Readiness

OBS-02 is complete for Phase 8. Plan 08-07 can reference the OTel span behavior and privacy guardrails in the testing and auth adapter guides.

## Self-Check: PASSED

- Verified created/modified files exist: `accrue/lib/accrue/telemetry/otel.ex`, `accrue/lib/accrue/telemetry.ex`, `accrue/lib/accrue/billing.ex`, and this summary.
- Verified task commits `b774b59`, `552f39d`, and `9153082` exist in git history.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
