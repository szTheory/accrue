---
phase: 08-install-polish-testing
reviewed: 2026-04-15T22:33:14Z
depth: standard
files_reviewed: 35
files_reviewed_list:
  - accrue/guides/auth_adapters.md
  - accrue/guides/testing.md
  - accrue/lib/accrue/billing.ex
  - accrue/lib/accrue/install/fingerprints.ex
  - accrue/lib/accrue/install/options.ex
  - accrue/lib/accrue/install/patches.ex
  - accrue/lib/accrue/install/project.ex
  - accrue/lib/accrue/install/templates.ex
  - accrue/lib/accrue/telemetry.ex
  - accrue/lib/accrue/telemetry/otel.ex
  - accrue/lib/accrue/test.ex
  - accrue/lib/accrue/test/clock.ex
  - accrue/lib/accrue/test/event_assertions.ex
  - accrue/lib/accrue/test/mailer_assertions.ex
  - accrue/lib/accrue/test/pdf_assertions.ex
  - accrue/lib/accrue/test/webhooks.ex
  - accrue/lib/mix/tasks/accrue.gen.handler.ex
  - accrue/lib/mix/tasks/accrue.install.ex
  - accrue/mix.exs
  - accrue/priv/accrue/templates/install/billing.ex.eex
  - accrue/priv/accrue/templates/install/billing_handler.ex.eex
  - accrue/priv/accrue/templates/install/revoke_accrue_events_writes.exs.eex
  - accrue/priv/accrue/templates/install/runtime_config.exs.eex
  - accrue/test/accrue/docs/community_auth_test.exs
  - accrue/test/accrue/docs/testing_guide_test.exs
  - accrue/test/accrue/install/sigra_detection_test.exs
  - accrue/test/accrue/telemetry/billing_span_coverage_test.exs
  - accrue/test/accrue/telemetry/otel_test.exs
  - accrue/test/accrue/test/clock_test.exs
  - accrue/test/accrue/test/event_assertions_test.exs
  - accrue/test/accrue/test/facade_test.exs
  - accrue/test/accrue/test/webhooks_test.exs
  - accrue/test/mix/tasks/accrue_gen_handler_test.exs
  - accrue/test/mix/tasks/accrue_install_test.exs
  - accrue/test/support/install_fixture.ex
excluded_files:
  - accrue/mix.lock
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 08: Code Review Report

**Reviewed:** 2026-04-15T22:33:14Z
**Depth:** standard
**Files Reviewed:** 35
**Status:** issues_found

## Summary

Reviewed the installer, generated templates, telemetry helpers, public test facade, guides, and focused tests. `accrue/mix.lock` was provided in the workflow scope but excluded from review per lock-file filtering rules.

The main concerns are test-helper regressions: one documented `advance_clock/2` call shape is broken, the installed test-support snippet configures the wrong mailer layer, and synthetic webhook tests can report success even when the default handler fails.

## Warnings

### WR-01: `advance_clock(subject, days: n)` Treats The Subject As The Duration

**File:** `accrue/lib/accrue/test/clock.ex:28`
**Issue:** The two-argument clause `def advance(duration, opts) when is_list(opts)` catches calls like `Accrue.Test.advance_clock(subscription, days: 14)`, which the testing guide documents at `accrue/guides/testing.md:63`. Because the first argument is then normalized as the duration, the helper returns `{:error, {:invalid_duration, subscription}}` instead of advancing the subscription clock. I confirmed this with `MIX_ENV=test mix run`: `Accrue.Test.Clock.advance_clock(%{processor_id: "sub_fake"}, days: 14)` returns `{:error, {:invalid_duration, %{processor_id: "sub_fake"}}}`.
**Fix:**
```elixir
@duration_keys [:months, :days, :hours, :minutes, :seconds]

def advance(subject_or_duration, opts) when is_list(opts) do
  cond do
    duration_keyword?(subject_or_duration) ->
      do_advance(nil, subject_or_duration, opts)

    duration_keyword?(opts) ->
      do_advance(subject_or_duration, opts, [])

    true ->
      do_advance(nil, subject_or_duration, opts)
  end
end

defp duration_keyword?(value) do
  Keyword.keyword?(value) and Enum.all?(value, fn {key, _value} -> key in @duration_keys end)
end
```

Add a regression test for `Accrue.Test.advance_clock(subscription, days: 14)` or change the guide if subject-plus-keyword duration is not intended to be public API.

### WR-02: Installer Test Support Snippet Wires `Accrue.Mailer.Test` To The Wrong Config Key

**File:** `accrue/lib/accrue/install/patches.ex:135`
**Issue:** The generated `test/support/accrue_case.ex` snippet says `config :accrue, :mailer_adapter, Accrue.Mailer.Test`, but `Accrue.Mailer.deliver/2` dispatches through `Application.get_env(:accrue, :mailer, Accrue.Mailer.Default)`. `Accrue.Mailer.Test` is the top-level `Accrue.Mailer` behaviour adapter, not the Swoosh delivery adapter, so host apps following the installer snippet will still enqueue through `Accrue.Mailer.Default` and `assert_email_sent/2` will not observe the mailbox tuple.
**Fix:**
```elixir
config :accrue, :processor, Accrue.Processor.Fake
config :accrue, :mailer, Accrue.Mailer.Test
config :accrue, :pdf_adapter, Accrue.PDF.Test
```

Add an installer test that reads the generated `test/support/accrue_case.ex` and asserts it contains `config :accrue, :mailer, Accrue.Mailer.Test`.

### WR-03: Synthetic Webhook Helper Swallows Handler Failures

**File:** `accrue/lib/accrue/test/webhooks.ex:107`
**Issue:** `dispatch_default/1` converts `{:error, _}` and any unknown return value from `Accrue.Webhook.DefaultHandler.handle_event/3` into `:ok`. That makes `Accrue.Test.trigger_event/2` return success and mark the row as following the normal path even when the reducer or handler failed. Host tests can pass while billing state was not actually reduced.
**Fix:**
```elixir
case DefaultHandler.handle_event(event.type, event, %{webhook_event_id: row.id}) do
  :ok -> :ok
  {:ok, _} -> :ok
  {:error, reason} -> {:error, reason}
  other -> {:error, {:unexpected_handler_result, other}}
end
```

Keep only explicitly ignorable event types on an allowlist if some synthetic events are intentionally unsupported.

## Info

### IN-01: Billing Span Coverage Test Cannot Detect Unspanned Public Functions

**File:** `accrue/test/accrue/telemetry/billing_span_coverage_test.exs:28`
**Issue:** `spanned?/2` checks that the source contains `Accrue.Telemetry.span` anywhere and that the function definition name appears anywhere. Because `billing.ex` has at least one span call, every public function with a `def` line satisfies the test even if its own body is not wrapped. This weakens the observability invariant called out in project guidance.
**Fix:** Replace the source substring check with AST-based inspection or targeted tests that attach telemetry handlers and exercise representative public entry points, including any newly added public Billing function.

---

_Reviewed: 2026-04-15T22:33:14Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
