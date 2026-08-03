---
phase: 218-apple-observation-and-repair
reviewed: 2026-08-03T16:10:00Z
depth: deep
files_reviewed: 14
files_reviewed_list:
  - accrue/lib/accrue/entitlements/apple/client.ex
  - accrue/lib/accrue/entitlements/apple/intake.ex
  - accrue/lib/accrue/entitlements/apple/lineage.ex
  - accrue/lib/accrue/entitlements/apple/reconcile_worker.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation/admission.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup.ex
  - accrue/lib/accrue/entitlements/apple/reconciliation_wakeup_worker.ex
  - accrue/lib/accrue/entitlements/apple/verifier.ex
  - accrue/lib/accrue/entitlements/apple/verifier/production.ex
  - accrue/test/accrue/entitlements/apple_reconciliation_test.exs
  - accrue/test/property/apple_convergence_property_test.exs
  - accrue/priv/repo/migrations/20260803030000_create_accrue_apple_lineages_and_intakes.exs
  - accrue/priv/repo/migrations/20260803031000_create_accrue_apple_reconciliation_checkpoints.exs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 218: Code Re-Review Report (Iteration 3)

**Reviewed:** 2026-08-03T16:10:00Z
**Depth:** deep
**Files Reviewed:** 14
**Status:** issues_found

## Summary

The second-fix commits add a real dispatch seam and put raw reconciliation evidence through signature verification, bound lineage/account lookup, intake, and projection. That admission path is no longer caller-bypassable. However, the production adapter sends sandbox requests to the production App Store host, and reconciliation failures remain terminal in practice: the code records a retry timestamp but creates no future job and no worker consumes due retry checkpoints. The focused Apple gate passes, but its queue property drives synthetic worker calls rather than the jobs actually persisted by the outbox and continuation paths.

Verification executed:

- `mix test test/accrue/entitlements/apple_*_test.exs test/property/apple_convergence_property_test.exs` — **32 tests, 1 property, 0 failures**.
- Broader entitlement regression command executed in this worktree — **234 tests, 12 properties, 0 failures (3 excluded)**. It does not correspond to the requested historical 166-test/4-property scope, whose exact command is not recorded in Phase 217/218 artifacts.

## Critical Issues

### CR-01: Sandbox reconciliation is sent to Apple's production API — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/client.ex:100-119`

**Issue:** `Client.Production` stores only the production base URL, and both `subscription_statuses/3` and `transaction_history/4` ignore their `environment` argument. A configured sandbox lineage therefore calls `https://api.storekit.itunes.apple.com` rather than `https://api.storekit-sandbox.itunes.apple.com`. Apple will reject or fail to find valid sandbox transactions, so a supported sandbox entitlement can never reconcile in production.

**Fix:** Choose the Apple base host from the validated environment at each request (or configure distinct validated production and sandbox URLs), and add an adapter-level test asserting the exact sandbox URL for both endpoints.

```elixir
defp base_url(%__MODULE__{} = client, :sandbox),
  do: client.sandbox_base_url

defp base_url(%__MODULE__{} = client, :production),
  do: client.production_base_url
```

### CR-02: Retry checkpoints are never dispatched again — BLOCKER

**File:** `accrue/lib/accrue/entitlements/apple/reconciliation.ex:275-278,365-376`

**Issue:** On a provider or admission failure, `schedule_retry/4` only updates `run_state` and `retry_after_at`. `run/2` then wraps that checkpoint in `{:ok, checkpoint}`, which makes `ReconcileWorker` return `:ok` at `reconcile_worker.ex:34`. No code queries `retry_after_at`, invokes `Reconciliation.due/2`, enqueues a delayed job, or writes a wakeup for that checkpoint. The original wakeup was already deleted by `drain_wakeups/2`, so transient outages and invalid-verifier/configuration corrections leave a durable-looking `:retrying` row that never runs again.

**Fix:** In the same transaction that persists `:retrying`, insert a `ReconcileWorker` job scheduled at `retry_after_at` (and roll back the checkpoint update if insertion fails), or implement and host-wire a durable sweeper that selects due retry checkpoints with locking. Test a failing first attempt, consume the persisted scheduled job, and prove it resumes the saved cursor and reaches `:idle` or `:needs_repair`.

## Warnings

### WR-01: The claimed queued-convergence property bypasses persisted queue dispatch — WARNING

**File:** `accrue/test/property/apple_convergence_property_test.exs:93-113`

**Issue:** The property enqueues a wakeup and lets it insert a continuation, but it never fetches or executes either resulting `Oban.Job`. Instead it calls `perform_job/2` with handcrafted worker arguments, including the continuation's lineage/environment. Thus a missing/wrong job class, argument, schedule, uniqueness rule, or transactional insertion still produces a passing property. It also covers only two fixed event orders and two fixed page shapes, not generated delivery/page permutations.

**Fix:** Query the jobs produced by the wakeup outbox and continuation insertion, execute their persisted args in order, and generate arbitrary bounded event/page partitions. Assert the terminal snapshot, grants, checkpoint, and absence of pending jobs/wakeups converge across each permutation.

### WR-02: A valid non-numeric Retry-After header crashes the production client — WARNING

**File:** `accrue/lib/accrue/entitlements/apple/client.ex:165-171`

**Issue:** HTTP `Retry-After` may be an HTTP-date, and a provider can also send an invalid value. `String.to_integer/1` raises for either form, escaping the intended bounded provider-error mapping. The checkpoint update is then skipped and retry handling is delegated accidentally to Oban's generic crash path.

**Fix:** Parse only a non-negative integer safely, support the HTTP-date form if needed, and fall back to the documented bounded default.

```elixir
case Integer.parse(to_string(value)) do
  {seconds, ""} when seconds >= 0 -> seconds
  _ -> 60
end
```

---

_Reviewed: 2026-08-03T16:10:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
