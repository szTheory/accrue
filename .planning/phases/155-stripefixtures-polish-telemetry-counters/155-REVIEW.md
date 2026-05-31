---
phase: 155-stripefixtures-polish-telemetry-counters
reviewed: 2026-05-31T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - accrue/lib/accrue/telemetry/metrics.ex
  - accrue/test/accrue/telemetry/metrics_test.exs
  - accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs
  - accrue/test/support/stripe_fixtures.ex
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 155: Code Review Report

**Reviewed:** 2026-05-31T00:00:00Z  
**Depth:** standard  
**Files Reviewed:** 4  
**Status:** issues_found

## Summary

Reviewed all scoped Phase 155 source files at standard depth. No critical security defects were found, but there are correctness/reliability issues: one counter name likely breaks metric consistency and two test defects reduce regression detection reliability.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Counter name deviates from `.count` convention and likely breaks expected metric key

**File:** `accrue/lib/accrue/telemetry/metrics.ex:73`  
**Issue:** `counter("accrue.ops.webhook_dlq.prune.dead_deleted")` is the only counter in this module without the `.count` suffix. This is likely a typo/regression (`...dead_deleted.count`) and can silently break dashboards/alerts keyed to the existing naming contract.

**Fix:**
```elixir
# before
counter("accrue.ops.webhook_dlq.prune.dead_deleted"),

# after
counter("accrue.ops.webhook_dlq.prune.dead_deleted.count"),
```

### WR-02: Telemetry handlers are attached globally in tests and never detached

**File:** `accrue/test/accrue/webhook/default_handler_entitlement_summary_test.exs:165`  
**Issue:** Tests attach handlers via `:telemetry.attach/4` (also at line 218) but never call `:telemetry.detach/1`. Telemetry handlers are process-global; leaked handlers can accumulate and introduce cross-test side effects or flaky mailbox assertions in longer suites.

**Fix:**
```elixir
handler_id = "test-ent-stale-#{System.unique_integer([:positive])}"

:ok =
  :telemetry.attach(
    handler_id,
    [:accrue, :webhooks, :stale_event],
    fn evt, meas, meta, _ -> send(test_pid, {:stale, evt, meas, meta}) end,
    nil
  )

on_exit(fn -> :telemetry.detach(handler_id) end)
```

Apply the same pattern to the orphan-handler attachment.

### WR-03: Metric-count assertion is too weak to detect deletions/regressions

**File:** `accrue/test/accrue/telemetry/metrics_test.exs:7-10`  
**Issue:** The test only asserts `length(defs) >= 19`. The current defaults list is much larger, so accidental metric removals can pass undetected as long as count remains above 19. This weakens regression protection for telemetry contracts.

**Fix:** Assert exact expected metric names (or exact count + explicit required set), e.g.:
```elixir
expected = MapSet.new([
  "accrue.billing.subscription.create.count",
  "accrue.ops.webhook_dlq.prune.dead_deleted.count"
  # ...all expected metric keys...
])

actual =
  M.defaults()
  |> Enum.map(&metric_name_to_string(&1.name))
  |> MapSet.new()

assert expected == actual
```

---

_Reviewed: 2026-05-31T00:00:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
