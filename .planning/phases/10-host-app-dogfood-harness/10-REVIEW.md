---
phase: 10-host-app-dogfood-harness
reviewed: 2026-04-16T17:11:00Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - accrue/lib/accrue/install/patches.ex
  - examples/accrue_host/README.md
  - examples/accrue_host/config/config.exs
  - examples/accrue_host/config/runtime.exs
  - examples/accrue_host/config/test.exs
  - examples/accrue_host/lib/accrue_host/accounts.ex
  - examples/accrue_host/lib/accrue_host/accounts/user.ex
  - examples/accrue_host/lib/accrue_host/application.ex
  - examples/accrue_host/lib/accrue_host/auth.ex
  - examples/accrue_host/lib/accrue_host/billing.ex
  - examples/accrue_host/lib/accrue_host/billing/plans.ex
  - examples/accrue_host/lib/accrue_host/billing_handler.ex
  - examples/accrue_host/lib/accrue_host/repo.ex
  - examples/accrue_host/lib/accrue_host_web/controllers/page_html/home.html.heex
  - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/lib/accrue_host_web/user_auth.ex
  - examples/accrue_host/mix.exs
  - examples/accrue_host/priv/repo/migrations/20260411000001_create_accrue_events.exs
  - examples/accrue_host/priv/repo/migrations/20260416000100_add_billing_admin_to_users.exs
  - examples/accrue_host/priv/repo/migrations/20260416163132_create_users_auth_tables.exs
  - examples/accrue_host/priv/repo/migrations/99999999999999_revoke_accrue_events_writes.exs
  - examples/accrue_host/test/accrue_host/billing_facade_test.exs
  - examples/accrue_host/test/accrue_host_web/admin_mount_test.exs
  - examples/accrue_host/test/accrue_host_web/admin_webhook_replay_test.exs
  - examples/accrue_host/test/accrue_host_web/subscription_flow_test.exs
  - examples/accrue_host/test/accrue_host_web/webhook_ingest_test.exs
  - examples/accrue_host/test/install_boundary_test.exs
  - examples/accrue_host/test/support/accrue_case.ex
  - examples/accrue_host/test/support/conn_case.ex
  - examples/accrue_host/test/support/data_case.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-04-16T17:11:00Z
**Depth:** standard
**Files Reviewed:** 31
**Status:** issues_found

## Summary

Reviewed the scoped host-app harness files in context, including runtime config, auth wiring, webhook routing, migrations, and the new billing LiveView. I also ran the focused host-app test set for the reviewed behavior (`billing_facade`, `subscription_flow`, `webhook_ingest`, `admin_mount`, `admin_webhook_replay`, and `install_boundary`); those tests passed, but the run emitted repeated `accrue: no operation_id` warnings during UI-driven billing actions.

The main problem is a production-secret fallback in runtime config that would let a prod deploy accept forged webhook requests if `STRIPE_WEBHOOK_SECRET` is unset. Separately, the billing LiveView is invoking Accrue actions without an explicit `operation_id`, so idempotency falls back to random UUIDs instead of stable request/action IDs.

## Critical Issues

### CR-01: Production webhook auth silently falls back to a known test secret

**File:** `examples/accrue_host/config/runtime.exs:29-31`
**Issue:** `STRIPE_WEBHOOK_SECRET` falls back to the hard-coded value `whsec_test_host` in every environment. In production, that makes webhook verification depend on a public, predictable secret whenever the env var is missing, which means forged requests can be accepted instead of failing closed.
**Fix:**
```elixir
webhook_secret =
  if config_env() == :prod do
    System.fetch_env!("STRIPE_WEBHOOK_SECRET")
  else
    System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")
  end

config :accrue, :webhook_signing_secrets, %{
  stripe: webhook_secret
}
```

## Warnings

### WR-01: LiveView billing actions run without a scoped operation ID

**File:** `examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex:27-30`
**Issue:** `Billing.subscribe/3` and `Billing.cancel/2` are called from LiveView event handlers without `opts[:operation_id]`. Accrue falls back to `Accrue.Actor.current_operation_id!/0`, and the test run shows that these calls currently generate random IDs with warnings. That weakens idempotency for UI-triggered billing actions and makes retries/nonces harder to reason about.
**Fix:**
```elixir
def handle_event("start_subscription", %{"plan" => plan_id, "operation_id" => op_id}, socket) do
  user = socket.assigns.current_scope.user

  case Billing.subscribe(user, plan_id, operation_id: op_id) do
    {:ok, _subscription} -> ...
    {:error, _reason} -> ...
  end
end
```

Generate a fresh hidden `operation_id` in the rendered form/button state and rotate it after each handled action. If retry-stable IDs are not needed in this harness, using the same explicit per-action UUID pattern as `accrue_admin` would at least remove the random fallback and warning path.

---

_Reviewed: 2026-04-16T17:11:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
