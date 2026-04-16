---
phase: 12-first-user-dx-stabilization
reviewed: 2026-04-16T22:27:00Z
depth: standard
files_reviewed: 37
files_reviewed_list:
  - .github/workflows/ci.yml
  - accrue/README.md
  - accrue/guides/first_hour.md
  - accrue/guides/quickstart.md
  - accrue/guides/troubleshooting.md
  - accrue/guides/upgrade.md
  - accrue/guides/webhooks.md
  - accrue/lib/accrue/auth/default.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/errors.ex
  - accrue/lib/accrue/install/fingerprints.ex
  - accrue/lib/accrue/install/options.ex
  - accrue/lib/accrue/install/patches.ex
  - accrue/lib/accrue/repo.ex
  - accrue/lib/accrue/setup_diagnostic.ex
  - accrue/lib/accrue/webhook/plug.ex
  - accrue/lib/mix/tasks/accrue.gen.handler.ex
  - accrue/lib/mix/tasks/accrue.install.ex
  - accrue/test/accrue/auth_test.exs
  - accrue/test/accrue/config_test.exs
  - accrue/test/accrue/docs/first_hour_guide_test.exs
  - accrue/test/accrue/docs/package_docs_verifier_test.exs
  - accrue/test/accrue/docs/troubleshooting_guide_test.exs
  - accrue/test/accrue/webhook/plug_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/mix/tasks/accrue_install_uat_test.exs
  - accrue_admin/README.md
  - accrue_admin/guides/admin_ui.md
  - examples/accrue_host/README.md
  - examples/accrue_host/lib/accrue_host/billing.ex
  - examples/accrue_host/lib/accrue_host_web/live/subscription_live.ex
  - examples/accrue_host/lib/accrue_host_web/router.ex
  - examples/accrue_host/mix.exs
  - examples/accrue_host/test/accrue_host/billing_facade_test.exs
  - examples/accrue_host/test/install_boundary_test.exs
  - scripts/ci/accrue_host_hex_smoke.sh
  - scripts/ci/verify_package_docs.sh
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---
# Phase 12: Code Review Report

**Reviewed:** 2026-04-16T22:27:00Z
**Depth:** standard
**Files Reviewed:** 37
**Status:** issues_found

## Summary

I reviewed the first-user DX surface across the package docs, installer, webhook setup, and the example host app. The main problems are not style issues: one published setup guide tells users to set the wrong runtime key, one installer preflight check will misclassify valid Phoenix routers as broken, and one boot-validation path swallows migration lookup failures instead of failing loud.

## Warnings

### WR-01: First-hour docs point users at a config key the runtime never reads

**File:** `accrue/guides/first_hour.md:45`
**Issue:** The guide tells hosts to configure `webhook_signing_secret`, but the runtime only reads `:webhook_signing_secrets` via `Accrue.Config.webhook_signing_secrets/1` ([`accrue/lib/accrue/config.ex:409`](../accrue/lib/accrue/config.ex), [`accrue/lib/accrue/webhook/plug.ex:89`](../accrue/lib/accrue/webhook/plug.ex)). The troubleshooting matrix repeats the singular key at [`accrue/guides/troubleshooting.md:13`](../accrue/guides/troubleshooting.md). A user following the published guide will hit `ACCRUE-DX-WEBHOOK-SECRET-MISSING` even though they copied the documented config.
**Fix:**
```elixir
config :accrue, :webhook_signing_secrets, %{
  stripe: System.get_env("STRIPE_WEBHOOK_SECRET", "whsec_test_host")
}
```
Also add a docs verifier assertion so the published guides cannot drift back to the singular key.

### WR-02: Installer preflight flags valid routers as using the wrong webhook pipeline

**File:** `accrue/lib/mix/tasks/accrue.install.ex:309`
**Issue:** `webhook_pipeline_misused?/1` ([`accrue/lib/mix/tasks/accrue.install.ex:362`](../accrue/lib/mix/tasks/accrue.install.ex)) returns true whenever the router contains any `accrue_webhook` call and also contains strings like `protect_from_forgery` or `require_authenticated_user` anywhere in the file. That matches normal Phoenix routers, including the example host router at [`examples/accrue_host/lib/accrue_host_web/router.ex:8`](../examples/accrue_host/lib/accrue_host_web/router.ex) and [`examples/accrue_host/lib/accrue_host_web/router.ex:81`](../examples/accrue_host/lib/accrue_host_web/router.ex), even though the webhook route is correctly isolated under `:accrue_webhook_raw_body`.
**Fix:**
```elixir
defp webhook_pipeline_misused?(router, webhook_path) do
  {scope_path, endpoint_path} = webhook_scope(webhook_path)

  case Regex.run(~r/scope\s+"#{Regex.escape(scope_path)}".*?end/s, router) do
    [scope_block] ->
      scope_block =~ ~s(pipe_through(:accrue_webhook_raw_body)) and
        scope_block =~ ~s(accrue_webhook "#{endpoint_path}", :stripe)
        |> Kernel.not()

    _ ->
      false
  end
end
```
The check needs to inspect the enclosing webhook scope or parsed router structure, not unrelated browser pipelines elsewhere in the file.

### WR-03: Boot validation silently ignores migration lookup failures

**File:** `accrue/lib/accrue/config.ex:491`
**Issue:** `ensure_migrations_current!/1` rescues every exception raised by `Ecto.Migrator.migrations/0` and returns `:ok` ([`accrue/lib/accrue/config.ex:494`](../accrue/lib/accrue/config.ex)). That means boot validation in [`accrue/lib/accrue/application.ex:34`](../accrue/lib/accrue/application.ex) can succeed even when the Repo cannot query migration state, which is the opposite of the module’s “fail loud” contract.
**Fix:**
```elixir
def ensure_migrations_current!(nil) do
  repo = Accrue.Repo.repo()

  repo
  |> Ecto.Migrator.migrations()
  |> ensure_migrations_current!()
rescue
  e in DBConnection.ConnectionError ->
    raise Accrue.ConfigError,
      key: :repo,
      diagnostic: Accrue.SetupDiagnostic.migrations_pending(details: Exception.message(e))
end
```
At minimum, do not swallow all exceptions. Convert expected repo/database failures into a shared diagnostic and let unexpected exceptions bubble.

---

_Reviewed: 2026-04-16T22:27:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
