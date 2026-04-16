---
phase: 01-foundations
plan: 05
type: execute
wave: 2
depends_on: [01, 02]
files_modified:
  - accrue/lib/accrue/mailer.ex
  - accrue/lib/accrue/mailer/default.ex
  - accrue/lib/accrue/mailer/swoosh.ex
  - accrue/lib/accrue/workers/mailer.ex
  - accrue/lib/accrue/emails/payment_succeeded.ex
  - accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex
  - accrue/priv/accrue/templates/emails/payment_succeeded.text.eex
  - accrue/lib/accrue/pdf.ex
  - accrue/lib/accrue/pdf/chromic_pdf.ex
  - accrue/lib/accrue/pdf/test.ex
  - accrue/lib/accrue/auth.ex
  - accrue/lib/accrue/auth/default.ex
  - accrue/test/accrue/mailer_test.exs
  - accrue/test/accrue/pdf_test.exs
  - accrue/test/accrue/auth_test.exs
autonomous: true
requirements: [MAIL-01, PDF-01, AUTH-01, AUTH-02]
security_enforcement: enabled
tags: [elixir, mailer, pdf, auth, behaviour, swoosh, chromic_pdf, mjml]
must_haves:
  truths:
    - "Accrue.Mailer is a behaviour with a single `c:deliver(type :: atom, assigns :: map)` callback (D-21 — semantic API, never %Swoosh.Email{})"
    - "Accrue.Mailer.Default.deliver(:payment_succeeded, %{customer_id: id, invoice_id: id}) enqueues an Oban job on :accrue_mailers queue with args {type, entity_id_map} — NO structs in args (D-27)"
    - "Accrue.Emails.PaymentSucceeded renders HTML via `use MjmlEEx, mjml_template:` pattern (NOT via Phoenix.Swoosh formats: map — Pitfall #3)"
    - "Accrue.PDF behaviour has `c:render(html :: binary, opts :: keyword)` (Shape B — D-32)"
    - "Accrue.PDF.Test adapter sends {:pdf_rendered, html, opts} to self() and returns {:ok, \"%PDF-TEST\"} (D-34)"
    - "Accrue.PDF.ChromicPDF adapter calls ChromicPDF.Template.source_and_options/1 |> ChromicPDF.print_to_pdf/1 — but does NOT start ChromicPDF itself (D-33)"
    - "Accrue.Auth is a behaviour with current_user/1, require_admin_plug/0, user_schema/0, log_audit/2, actor_id/1"
    - "Accrue.Auth.Default in :dev/:test returns %{id: \"dev\", email: \"dev@localhost\", role: :admin}"
    - "Accrue.Auth.Default.boot_check!/0 is the public API; boot_check!(env) is a private/testable helper so the prod path can be exercised without recompiling"
    - "Accrue.Auth.Default in :prod RAISES Accrue.ConfigError when boot_check!/0 is called (boot-time refuse, D-40)"
    - "This plan is READ-ONLY against accrue/lib/accrue/config.ex and accrue/config/*.exs — Plan 01 pre-wired :env, Plan 02 shipped the full schema"
  artifacts:
    - path: "accrue/lib/accrue/mailer.ex"
      provides: "Behaviour + facade delegating to configured adapter"
      contains: "@callback deliver"
    - path: "accrue/lib/accrue/mailer/default.ex"
      provides: "Default adapter dispatching to Accrue.Emails.* template modules + Oban enqueue"
    - path: "accrue/lib/accrue/workers/mailer.ex"
      provides: "Oban worker that rehydrates entities from DB at delivery time"
      contains: "use Oban.Worker"
    - path: "accrue/lib/accrue/emails/payment_succeeded.ex"
      provides: "Reference email template module using MjmlEEx"
      contains: "use MjmlEEx"
    - path: "accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex"
      provides: "Reference MJML template for receipt email"
    - path: "accrue/lib/accrue/pdf.ex"
      provides: "Behaviour + facade"
      contains: "@callback render"
    - path: "accrue/lib/accrue/pdf/chromic_pdf.ex"
      provides: "ChromicPDF adapter (does NOT start ChromicPDF)"
      contains: "ChromicPDF.Template"
    - path: "accrue/lib/accrue/pdf/test.ex"
      provides: "Test adapter — Chrome-free, sends message"
    - path: "accrue/lib/accrue/auth.ex"
      provides: "Auth behaviour"
      contains: "@callback current_user"
    - path: "accrue/lib/accrue/auth/default.ex"
      provides: "Dev-permissive, prod-refuse fallback + boot_check!/0 public API + testable boot_check!/1 helper"
      contains: "boot_check!"
  key_links:
    - from: "accrue/lib/accrue/mailer/default.ex"
      to: "accrue/lib/accrue/workers/mailer.ex"
      via: "Oban.insert(MailerWorker.new({type, id_map}))"
      pattern: "MailerWorker|Workers\\.Mailer"
    - from: "accrue/lib/accrue/workers/mailer.ex"
      to: "Accrue.Emails.PaymentSucceeded"
      via: "template module dispatch by type atom"
      pattern: "Accrue\\.Emails\\."
    - from: "accrue/lib/accrue/emails/payment_succeeded.ex"
      to: "priv/accrue/templates/emails/payment_succeeded.mjml.eex"
      via: "use MjmlEEx, mjml_template: \"...\""
      pattern: "mjml_template"
    - from: "accrue/lib/accrue/pdf/chromic_pdf.ex"
      to: "ChromicPDF.Template.source_and_options/1"
      via: "direct call (but ChromicPDF pool is host-started)"
      pattern: "ChromicPDF\\.Template"
---

<objective>
Ship four behaviours and their default/test adapters in one plan: **Mailer** (MAIL-01), **PDF** (PDF-01), **Auth** (AUTH-01/02). Each follows the same shape: behaviour module + facade + default adapter + test adapter (where applicable). The Mailer plan extends further because it includes the Oban worker, the reference `PaymentSucceeded` template module, and the MJML + text template files.

Purpose: Phase 6 (Email + PDF) builds out 13+ additional email templates and the full PDF invoice flow. Phase 7 (Admin UI) relies on the Auth adapter. This plan ships the behaviour shapes + one reference email template per D-22 Pitfall #3 (the CORRECTED mjml_eex integration pattern).
Output: Four behaviours, four default adapters, three test adapters (Mailer via `Swoosh.Adapters.Test` + custom semantic helper, PDF test adapter, Auth default dev-mode), and one working reference email template driven by mjml_eex's Rustler NIF.

**Wave-2 file discipline:** This plan is READ-ONLY against `accrue/lib/accrue/config.ex` and `accrue/config/*.exs`. Plan 02 (Wave 1) pre-added every config key this plan consumes (`:emails`, `:email_overrides`, `:mailer`, `:mailer_adapter`, `:pdf_adapter`, `:auth_adapter`, `:from_email`, `:from_name`, `:attach_invoice_pdf`, brand fields). Plan 01 (Wave 0) pre-wired `Swoosh.Adapters.Test` into `config/test.exs` and `config :accrue, :env, Mix.env()` into `config/config.exs`. Plans 04 and 05 run in parallel (Wave 2) with ZERO shared files.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/01-foundations/01-CONTEXT.md
@.planning/phases/01-foundations/01-RESEARCH.md
@CLAUDE.md
@accrue/lib/accrue/errors.ex
@accrue/lib/accrue/config.ex
@accrue/lib/accrue/telemetry.ex
@accrue/config/config.exs
@accrue/config/test.exs

<interfaces>
<!-- Contracts this plan CREATES. -->

From accrue/lib/accrue/mailer.ex:
```elixir
defmodule Accrue.Mailer do
  @type email_type :: atom()
  @type assigns :: map()

  @callback deliver(email_type(), assigns()) :: {:ok, term()} | {:error, term()}

  @spec deliver(email_type(), assigns()) :: {:ok, term()} | {:error, term()}
  def deliver(type, assigns), do: impl().deliver(type, assigns)

  defp impl, do: Application.get_env(:accrue, :mailer, Accrue.Mailer.Default)
end
```

From accrue/lib/accrue/pdf.ex:
```elixir
defmodule Accrue.PDF do
  @type html :: binary()
  @type opts :: keyword()

  @callback render(html(), opts()) :: {:ok, binary()} | {:error, term()}

  @spec render(html(), opts()) :: {:ok, binary()} | {:error, term()}
  def render(html, opts \\ []), do: impl().render(html, opts)

  defp impl, do: Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)
end
```

From accrue/lib/accrue/auth.ex:
```elixir
defmodule Accrue.Auth do
  @type conn :: Plug.Conn.t() | map()
  @type user :: map() | struct()

  @callback current_user(conn()) :: user() | nil
  @callback require_admin_plug() :: (conn(), keyword() -> conn())
  @callback user_schema() :: module()
  @callback log_audit(user(), map()) :: :ok
  @callback actor_id(user()) :: String.t() | nil
end
```

From accrue/lib/accrue/auth/default.ex:
```elixir
defmodule Accrue.Auth.Default do
  @behaviour Accrue.Auth

  # PUBLIC API — Plan 06's Accrue.Application.start/2 calls this 0-arity form.
  @spec boot_check!() :: :ok
  def boot_check!, do: do_boot_check!(current_env())

  # PRIVATE/TESTABLE helper — tests can inject a simulated env without recompiling.
  # Exposed via the module (not defp) so the test file can reach it; NOT part of
  # the public behaviour. The public boot_check!/0 is what Application.start/2
  # calls and what docs advertise.
  @doc false
  @spec do_boot_check!(:dev | :test | :prod) :: :ok
  def do_boot_check!(env)

  defp current_env, do: Application.get_env(:accrue, :env, Mix.env())
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Accrue.Mailer behaviour + Default adapter + Oban worker + PaymentSucceeded reference template (mjml_eex, corrected pattern)</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-21, D-22, D-23, D-24, D-25, D-26, D-27, D-28, D-29, D-30, D-31
    - .planning/phases/01-foundations/01-RESEARCH.md §Pitfall 3 (CORRECTED mjml_eex integration — NOT Phoenix.Swoosh formats map)
    - .planning/phases/01-foundations/01-RESEARCH.md §Open Question 2 (PaymentSucceeded uses Phase 1 fixture data, not real Customer/Invoice entities)
    - accrue/lib/accrue/config.ex (VERIFY Plan 02 schema has :emails, :email_overrides, :mailer_adapter, :from_email, :from_name, :attach_invoice_pdf — if missing, escalate)
    - accrue/config/test.exs (VERIFY Plan 01 wired Swoosh.Adapters.Test — if missing, escalate)
    - github.com/akoutmos/mjml_eex README (use MjmlEEx, mjml_template: ... pattern)
    - hexdocs.pm/swoosh/Swoosh.Mailer — use Swoosh.Mailer, otp_app: ...
    - hexdocs.pm/oban — Oban.Worker with unique and queue options
  </read_first>
  <files>
    accrue/lib/accrue/mailer.ex
    accrue/lib/accrue/mailer/default.ex
    accrue/lib/accrue/mailer/swoosh.ex
    accrue/lib/accrue/workers/mailer.ex
    accrue/lib/accrue/emails/payment_succeeded.ex
    accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex
    accrue/priv/accrue/templates/emails/payment_succeeded.text.eex
    accrue/test/accrue/mailer_test.exs
  </files>
  <behavior>
    - `Accrue.Mailer.deliver(:payment_succeeded, %{customer_id: "cus_1", invoice_id: "in_1"})` returns `{:ok, %Oban.Job{}}` (job enqueued on `:accrue_mailers`)
    - The enqueued Oban job has args `{"type" => "payment_succeeded", "assigns" => %{"customer_id" => "cus_1", "invoice_id" => "in_1"}}` — scalar-only, Oban-safe
    - `Accrue.Workers.Mailer.perform/1` is callable directly in tests; it rehydrates (Phase 1: stub rehydration using a fixture map since Customer/Invoice schemas don't exist yet), builds the Swoosh.Email via the template module, and delivers via `Accrue.Mailer.Swoosh`
    - `Accrue.Emails.PaymentSucceeded.render(assigns)` compiles the MJML template at build time and returns an HTML binary
    - `Accrue.Emails.PaymentSucceeded.render_text(assigns)` returns a plain-text body from `.text.eex`
    - `Swoosh.TestAssertions.assert_email_sent/1` works in tests (default test adapter is `Swoosh.Adapters.Test` — already wired by Plan 01 in `config/test.exs`)
    - Kill switch: `Application.put_env(:accrue, :emails, [payment_succeeded: false])` in a test → `deliver/2` returns `{:ok, :skipped}` without enqueueing (D-25). The `:emails` schema key is already defined by Plan 02.
    - Telemetry: `[:accrue, :mailer, :deliver, :start|:stop]` with `%{email_type: :payment_succeeded, customer_id: ...}` (D-28)
  </behavior>
  <action>
1. **Prerequisite verification (fail fast)**: before writing any code, run:
   ```bash
   grep -q ":emails" accrue/lib/accrue/config.ex || { echo "Plan 02 schema missing :emails — STOP"; exit 1; }
   grep -q ":email_overrides" accrue/lib/accrue/config.ex || { echo "Plan 02 schema missing :email_overrides — STOP"; exit 1; }
   grep -q ":mailer_adapter" accrue/lib/accrue/config.ex || { echo "Plan 02 schema missing :mailer_adapter — STOP"; exit 1; }
   grep -q "Swoosh.Adapters.Test" accrue/config/test.exs || { echo "Plan 01 did not wire Swoosh.Adapters.Test — STOP"; exit 1; }
   ```
   If any fail, escalate rather than editing config files here.

2. `lib/accrue/mailer.ex`: behaviour + facade per `<interfaces>`. Wrap `deliver/2` in `Accrue.Telemetry.span/3` emitting `[:accrue, :mailer, :deliver, ...]` (D-28). Before dispatching, check the kill switch via `Application.get_env(:accrue, :emails, [])` — if `emails[type]` is `false`, return `{:ok, :skipped}` without calling the adapter. The `:emails` key is already in Plan 02's schema; this plan does not touch `config.ex`.

3. `lib/accrue/mailer/swoosh.ex`:
   ```elixir
   defmodule Accrue.Mailer.Swoosh do
     use Swoosh.Mailer, otp_app: :accrue
   end
   ```
   The env-specific adapter is already set by Plan 01 in `config/dev.exs` (`Swoosh.Adapters.Local`) and `config/test.exs` (`Swoosh.Adapters.Test`). This plan does NOT edit those files.

4. `lib/accrue/mailer/default.ex`:
   - `@behaviour Accrue.Mailer`.
   - `deliver/2`: enqueues an `Accrue.Workers.Mailer` job via `Oban.insert/1`:
     ```elixir
     def deliver(type, assigns) when is_atom(type) and is_map(assigns) do
       assigns
       |> only_scalars!()  # asserts no structs / pids / functions in assigns (Pitfall #5)
       |> then(fn scalar_assigns -> %{type: Atom.to_string(type), assigns: scalar_assigns} end)
       |> Accrue.Workers.Mailer.new()
       |> Oban.insert()
     end
     ```
   - `only_scalars!/1` walks the map and raises `ArgumentError` on any non-primitive value. This is the D-27 / Pitfall #5 safety net.
   - Document the Pay-style 4-rung override ladder in the moduledoc (D-23) but Phase 1 implements only rungs 1 (`:emails` kill switch) and 3 (`:email_overrides` for swapping one template module). Rungs 2 (MFA conditional) and 4 (full pipeline replace) can land in Phase 6 with the full template catalog.

5. `lib/accrue/workers/mailer.ex`:
   - `use Oban.Worker, queue: :accrue_mailers, max_attempts: 5, unique: [period: 60, fields: [:args, :worker]]`.
   - `perform/1` body:
     ```elixir
     def perform(%Oban.Job{args: %{"type" => type, "assigns" => assigns}}) do
       type_atom = String.to_existing_atom(type)
       template_mod = resolve_template(type_atom)
       enriched = enrich(type_atom, assigns)  # Phase 1: passes assigns through; Phase 2+ rehydrates Customer/Invoice from DB
       email =
         Swoosh.Email.new()
         |> Swoosh.Email.to(enriched[:to] || enriched["to"])
         |> Swoosh.Email.from({Application.get_env(:accrue, :from_name, "Accrue"), Application.get_env(:accrue, :from_email, "noreply@example.com")})
         |> Swoosh.Email.subject(template_mod.subject(enriched))
         |> Swoosh.Email.html_body(template_mod.render(enriched))
         |> Swoosh.Email.text_body(template_mod.render_text(enriched))
       Accrue.Mailer.Swoosh.deliver(email)
     end

     defp resolve_template(:payment_succeeded) do
       Application.get_env(:accrue, :email_overrides, [])[:payment_succeeded] || Accrue.Emails.PaymentSucceeded
     end
     # other types fall through; Phase 6 adds the catalog
     ```
   - Host must start their OWN Oban — `config :accrue, :oban, ...` is NOT a Phase 1 concern. Document this: the test harness starts Oban manually in the test setup via `Oban.start_link(...)` with the `:accrue_mailers` queue, or uses `Oban.Testing` helpers.

6. `lib/accrue/emails/payment_succeeded.ex` (CORRECTED mjml_eex pattern per Pitfall #3):
   ```elixir
   defmodule Accrue.Emails.PaymentSucceeded do
     @moduledoc """
     Reference email template. Uses mjml_eex's build-time compilation.
     NOTE: This uses the idiomatic `use MjmlEEx, mjml_template:` pattern —
     NOT the (broken) `use Phoenix.Swoosh, formats: %{"mjml" => :html_body}`
     shape that CONTEXT.md D-22 originally sketched. See RESEARCH.md §Pitfall 3.
     """

     use MjmlEEx, mjml_template: "emails/payment_succeeded.mjml.eex"

     def subject(_assigns), do: "Receipt for your payment"

     def render_text(assigns) do
       EEx.eval_file(
         Path.join(:code.priv_dir(:accrue), "accrue/templates/emails/payment_succeeded.text.eex"),
         assigns: assigns
       )
     end
   end
   ```

   The `use MjmlEEx` macro generates `render/1` at compile time that returns HTML. The text body uses plain EEx.eval_file for simplicity (Phase 6 may migrate to Phoenix.Swoosh's render_body for the text format once templates live in a templates/ directory).

7. `priv/accrue/templates/emails/payment_succeeded.mjml.eex`: a minimal MJML template referencing `<%= @customer_name %>`, `<%= @amount %>`, `<%= @invoice_number %>`. Keep it ~30 lines — single `<mj-section>` with `<mj-text>` and a `<mj-button>` pointing at `<%= @receipt_url %>`. Use hardcoded hex colors (email clients don't support CSS variables) — `#111827` (Ink), `#3B82F6` (Cobalt) matching the brand palette that Plan 06 will formalize.

8. `priv/accrue/templates/emails/payment_succeeded.text.eex`: plain-text version — "Hi <%= @customer_name %>, we received your payment of <%= @amount %>..." ~10 lines.

9. `test/accrue/mailer_test.exs`:
   - `use ExUnit.Case, async: true`.
   - Setup: the test Swoosh adapter is already `Swoosh.Adapters.Test` (wired by Plan 01 in `config/test.exs`) — do NOT call `Application.put_env` for that.
   - Test 1: `Accrue.Mailer.deliver(:payment_succeeded, %{customer_id: "cus_1", invoice_id: "in_1", customer_name: "Alice", amount: "$10.00", invoice_number: "INV-1", receipt_url: "http://x", to: "a@b.com"})` returns `{:ok, _}`. Use `Oban.Testing.assert_enqueued(worker: Accrue.Workers.Mailer, args: %{"type" => "payment_succeeded"})` to verify the job.
   - Test 2: Directly invoke `Accrue.Workers.Mailer.perform(%Oban.Job{args: ...})` and assert via `Swoosh.TestAssertions.assert_email_sent(subject: "Receipt for your payment")`.
   - Test 3: Kill switch: `Application.put_env(:accrue, :emails, [payment_succeeded: false])` → `deliver/2` returns `{:ok, :skipped}` without enqueueing. (This is a test-local env mutation; it does NOT edit config files.)
   - Test 4: Assigns-safety — `Accrue.Mailer.deliver(:payment_succeeded, %{customer: %{__struct__: :foo}})` raises ArgumentError (only_scalars! guard).
   - Test 5: Telemetry span — attach a handler for `[:accrue, :mailer, :deliver, :stop]` and assert it fires with `%{email_type: :payment_succeeded}` metadata.

   Oban testing: `use Oban.Testing, repo: Accrue.TestRepo` in the test module. Plan 03's `Accrue.TestRepo` is already defined by Wave 2 execution order (this plan runs in the same wave — execute-phase handles the in-wave ordering).
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/mailer_test.exs && mix compile --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/mailer_test.exs` reports all passing
    - `grep -q "use MjmlEEx, mjml_template:" accrue/lib/accrue/emails/payment_succeeded.ex`
    - `grep -q "formats: %{\"mjml\"" accrue/lib/` returns nothing (the broken pattern from D-22 is not used — Pitfall #3)
    - `grep -q "use Oban.Worker" accrue/lib/accrue/workers/mailer.ex`
    - `grep -q "only_scalars" accrue/lib/accrue/mailer/default.ex`
    - `test -f accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex`
    - `git diff accrue/lib/accrue/config.ex accrue/config/` shows no changes from this plan
    - `mix compile --warnings-as-errors` passes
  </acceptance_criteria>
  <done>Mailer behaviour + Default + Oban worker + reference MJML template all working, Swoosh.TestAssertions.assert_email_sent/1 green, kill switch and scalar-safety both enforced, zero config-file edits.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Accrue.PDF behaviour + ChromicPDF adapter + Test adapter</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-32, D-33, D-34, D-35, D-36, D-37
    - .planning/phases/01-foundations/01-RESEARCH.md §Pitfall 4 (DO NOT start ChromicPDF in Accrue.Application)
    - hexdocs.pm/chromic_pdf/ChromicPDF.html — source_and_options/1 + print_to_pdf/1
    - hexdocs.pm/chromic_pdf/ChromicPDF.Template.html — header vs header_html naming (RESEARCH.md §Summary point 5)
  </read_first>
  <files>
    accrue/lib/accrue/pdf.ex
    accrue/lib/accrue/pdf/chromic_pdf.ex
    accrue/lib/accrue/pdf/test.ex
    accrue/test/accrue/pdf_test.exs
  </files>
  <behavior>
    - `Accrue.PDF.render("<h1>Hello</h1>", []) {:ok, binary}` where `binary` starts with `"%PDF"` in production or `"%PDF-TEST"` in test env
    - `Accrue.PDF.Test.render/2` sends `{:pdf_rendered, html, opts}` to `self()` and returns `{:ok, "%PDF-TEST"}` (D-34)
    - `Accrue.PDF.ChromicPDF.render/2` calls `ChromicPDF.Template.source_and_options/1 |> ChromicPDF.print_to_pdf/1` — does NOT call `ChromicPDF.start_link/1` or add anything to a supervisor
    - `Accrue.PDF.render(html, size: :a4, header_html: "<header>X</header>")` translates `header_html -> header` for the ChromicPDF.Template call (RESEARCH.md Summary point 5)
    - `Accrue.PDF.render(html, archival: true)` calls `ChromicPDF.print_to_pdfa/2` instead — only when explicit
    - `grep ChromicPDF accrue/lib/accrue/application.ex` returns nothing (Plan 06 must not start ChromicPDF either — Pitfall #4)
  </behavior>
  <action>
1. `lib/accrue/pdf.ex`: behaviour + facade per `<interfaces>`. Wrap `render/2` in `Accrue.Telemetry.span/3` emitting `[:accrue, :pdf, :render, :start|:stop|:exception]` with `%{size: opts[:size], archival: opts[:archival]}` in metadata (no html content in metadata — T-PDF-01 below). Adapter resolved via `Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)` — the `:pdf_adapter` key is already in Plan 02's schema.

2. `lib/accrue/pdf/chromic_pdf.ex`:
   ```elixir
   defmodule Accrue.PDF.ChromicPDF do
     @behaviour Accrue.PDF

     @impl true
     def render(html, opts) when is_binary(html) do
       chromic_opts = translate_opts(html, opts)

       if opts[:archival] do
         ChromicPDF.Template.source_and_options(chromic_opts)
         |> then(&ChromicPDF.print_to_pdfa/1)
       else
         ChromicPDF.Template.source_and_options(chromic_opts)
         |> ChromicPDF.print_to_pdf()
       end
     rescue
       e -> {:error, e}
     end

     defp translate_opts(html, opts) do
       [
         content: html,
         size: opts[:size] || :a4
       ]
       |> maybe_put(:header, opts[:header_html])
       |> maybe_put(:footer, opts[:footer_html])
       |> maybe_put(:header_height, opts[:header_height])
       |> maybe_put(:footer_height, opts[:footer_height])
     end

     defp maybe_put(list, _key, nil), do: list
     defp maybe_put(list, key, val), do: Keyword.put(list, key, val)
   end
   ```

   CRITICAL: no `start_link`, no `child_spec`, no `use ChromicPDF`. This adapter ONLY calls into a ChromicPDF instance that the HOST application has started in its own supervision tree (D-33, Pitfall #4). Document this loudly in the moduledoc: "Host MUST start ChromicPDF in their supervision tree before calling this adapter. Recommended: `{ChromicPDF, on_demand: true}` for dev/test, pool for prod."

3. `lib/accrue/pdf/test.ex`:
   ```elixir
   defmodule Accrue.PDF.Test do
     @behaviour Accrue.PDF

     @impl true
     def render(html, opts) do
       send(self(), {:pdf_rendered, html, opts})
       {:ok, "%PDF-TEST"}
     end
   end
   ```

4. `test/accrue/pdf_test.exs`:
   - Test 1: `Application.put_env(:accrue, :pdf_adapter, Accrue.PDF.Test) ; {:ok, bin} = Accrue.PDF.render("<h1>x</h1>", size: :a4) ; assert bin == "%PDF-TEST" ; assert_received {:pdf_rendered, "<h1>x</h1>", [size: :a4]}`.
   - Test 2: Opts translation — assert that passing `header_html: "<h>"` results in `{:pdf_rendered, _, opts}` where `opts[:header_html] == "<h>"` (the facade passes opts through untouched; the ChromicPDF adapter does the translation internally, and the test adapter just forwards).
   - Test 3: **Do NOT test `Accrue.PDF.ChromicPDF.render/2` end-to-end** — Phase 1 tests run Chrome-free. Only assert the module compiles and its `render/2` function is exported.
   - Test 4: Telemetry test: attach handler, call render, assert `:start` and `:stop` fired with `size: :a4` metadata.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/pdf_test.exs && mix compile --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/pdf_test.exs` reports all passing (no Chrome binary required)
    - `grep -q "ChromicPDF.Template.source_and_options" accrue/lib/accrue/pdf/chromic_pdf.ex`
    - `grep -q "start_link\\|child_spec" accrue/lib/accrue/pdf/chromic_pdf.ex` returns nothing (Pitfall #4 — Accrue does not start ChromicPDF)
    - `grep -q "%PDF-TEST" accrue/lib/accrue/pdf/test.ex`
    - `grep -q "send(self" accrue/lib/accrue/pdf/test.ex`
  </acceptance_criteria>
  <done>PDF behaviour, ChromicPDF adapter (host-pool dependent), Test adapter (Chrome-free) all in place and tested without requiring a live Chrome process.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Accrue.Auth behaviour + Default adapter (dev-permissive, prod-refuse-to-boot)</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-40, D-41
    - .planning/phases/01-foundations/01-RESEARCH.md §Architecture Patterns Pattern 5 (empty-supervisor — boot_check is called from there in Plan 06)
    - CLAUDE.md §Config Boundaries
    - accrue/config/config.exs (VERIFY Plan 01 set `config :accrue, :env, Mix.env()` — if missing, escalate)
  </read_first>
  <files>
    accrue/lib/accrue/auth.ex
    accrue/lib/accrue/auth/default.ex
    accrue/test/accrue/auth_test.exs
  </files>
  <behavior>
    - `Accrue.Auth.current_user(conn)` delegates to configured adapter
    - `Accrue.Auth.Default.current_user(_)` returns `%{id: "dev", email: "dev@localhost", role: :admin}` in :dev and :test environments
    - `Accrue.Auth.Default.boot_check!/0` is the public API — it reads the env via `Application.get_env(:accrue, :env, Mix.env())` and delegates to the private `do_boot_check!/1` helper. Plan 06's Accrue.Application.start/2 calls this 0-arity form.
    - `Accrue.Auth.Default.do_boot_check!(:prod)` raises `Accrue.ConfigError` with a clear message pointing at install docs when `:auth_adapter` still points at `Accrue.Auth.Default`.
    - `Accrue.Auth.Default.do_boot_check!(:dev)` and `do_boot_check!(:test)` return `:ok`.
    - Tests reach `do_boot_check!/1` directly to exercise the `:prod` branch without recompiling.
    - `Accrue.Auth.Default.require_admin_plug()` returns a plug function that is a no-op in :dev/:test, raises `Accrue.ConfigError` in :prod
    - `Accrue.Auth.Default.actor_id(user)` returns `user.id` or `user["id"]`
    - `Accrue.Auth.Default.user_schema()` returns nil (host-owned; not known in Phase 1)
    - `Accrue.Auth.Default.log_audit(user, event)` is a no-op that returns :ok
  </behavior>
  <action>
1. **Prerequisite verification**:
   ```bash
   grep -q "config :accrue, :env, Mix.env" accrue/config/config.exs || { echo "Plan 01 did not wire :env key — STOP"; exit 1; }
   grep -q ":auth_adapter" accrue/lib/accrue/config.ex || { echo "Plan 02 schema missing :auth_adapter — STOP"; exit 1; }
   ```

2. `lib/accrue/auth.ex`: behaviour + facade per `<interfaces>`. No telemetry wrapping here — Auth is hot-path plug code; instrumentation belongs at the caller level.

3. `lib/accrue/auth/default.ex`:
   - `@behaviour Accrue.Auth`.
   - **Env lookup**: use `Application.get_env(:accrue, :env, Mix.env())` at call time — runtime lookup with `Mix.env()` as a compile-baked fallback. This is simpler than `Application.compile_env!/2` (which would require the `:env` key to always be present at compile time, and would bake into the beam) and still honest because:
     (a) Plan 01 pre-wired `config :accrue, :env, Mix.env()` in `config/config.exs`, so production releases have it set correctly.
     (b) If a host accidentally strips the key, the `Mix.env()` default still gives the env at compile time of the release (which is whatever `MIX_ENV` was set to during `mix release`).
   - **Public boot_check!/0**:
     ```elixir
     @dev_user %{id: "dev", email: "dev@localhost", role: :admin}

     @spec boot_check!() :: :ok
     def boot_check! do
       env = Application.get_env(:accrue, :env, Mix.env())
       do_boot_check!(env)
     end
     ```
   - **Private/testable helper do_boot_check!/1**:
     ```elixir
     @doc false
     @spec do_boot_check!(:dev | :test | :prod) :: :ok
     def do_boot_check!(:prod) do
       if Application.get_env(:accrue, :auth_adapter, __MODULE__) == __MODULE__ do
         raise Accrue.ConfigError,
           key: :auth_adapter,
           message: """
           Accrue.Auth.Default is dev-only and refuses to run in :prod.
           Configure a real auth adapter:
             config :accrue, :auth_adapter, Accrue.Integrations.Sigra   # if sigra is in deps
             # or provide your own module implementing Accrue.Auth
           See guides/auth.md.
           """
       end
       :ok
     end
     def do_boot_check!(env) when env in [:dev, :test], do: :ok
     ```
     Note: the helper is `def` (not `defp`) and carries `@doc false` so it doesn't appear in public ExDoc but is reachable from test code via direct module call. This is the idiomatic Elixir pattern for testable internals.
   - `current_user/1`:
     ```elixir
     def current_user(_conn) do
       case Application.get_env(:accrue, :env, Mix.env()) do
         env when env in [:dev, :test] -> @dev_user
         :prod -> nil  # boot_check! should have raised before this is reachable
       end
     end
     ```
   - `require_admin_plug/0`: returns a function `fn conn, _opts -> conn end` in dev/test; returns a function that raises `Accrue.ConfigError` in prod.
   - `user_schema/0`: `nil`.
   - `log_audit/2`: `:ok`.
   - `actor_id/1`: `is_map(user) -> user[:id] || user["id"]`.

4. `test/accrue/auth_test.exs`:
   - Test 1: In test env, `Accrue.Auth.Default.current_user(nil)` returns the @dev_user map.
   - Test 2: `Accrue.Auth.Default.boot_check!()` returns `:ok` in test env (public 0-arity path).
   - Test 3: **Prod simulation** — call the private/testable helper directly: `assert_raise Accrue.ConfigError, fn -> Accrue.Auth.Default.do_boot_check!(:prod) end`. This exercises the refuse-to-boot branch without tampering with `Application.put_env(:accrue, :env, ...)` (which would bleed between tests).
   - Test 4: With a custom adapter configured: `Application.put_env(:accrue, :auth_adapter, SomeOtherAdapter) ; assert :ok == Accrue.Auth.Default.do_boot_check!(:prod) ; Application.put_env(:accrue, :auth_adapter, Accrue.Auth.Default)` — reset.
   - Test 5: `actor_id(%{id: "u_1"}) == "u_1"` and `actor_id(%{"id" => "u_2"}) == "u_2"`.
   - Test 6: `log_audit(user, event) == :ok`.

**No config file edits in this task** — Plan 01 already set `config :accrue, :env, Mix.env()` in `config/config.exs`, and Plan 02 already has `:auth_adapter` in the Config schema. This plan only READS those.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/auth_test.exs && mix compile --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/auth_test.exs` reports all passing
    - `grep -q "@callback current_user" accrue/lib/accrue/auth.ex`
    - `grep -q "def boot_check!" accrue/lib/accrue/auth/default.ex` (public 0-arity API)
    - `grep -q "do_boot_check!" accrue/lib/accrue/auth/default.ex` (private testable helper)
    - `grep -q "Accrue.ConfigError" accrue/lib/accrue/auth/default.ex`
    - `grep -q "dev@localhost" accrue/lib/accrue/auth/default.ex`
    - Plan did NOT modify `accrue/config/config.exs` — `git diff accrue/config/config.exs` is empty for this plan
    - Plan did NOT modify `accrue/lib/accrue/config.ex` — `git diff accrue/lib/accrue/config.ex` is empty for this plan
    - Prod simulation test: `assert_raise Accrue.ConfigError` passes
  </acceptance_criteria>
  <done>Auth behaviour + Default adapter with prod boot refusal in place. Public boot_check!/0 is what Plan 06's Accrue.Application.start/2 calls; private do_boot_check!/1 lets tests exercise every env branch without recompiling.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Oban args JSON round-trip | Must contain only scalars (no structs, pids, functions) |
| Prod runtime → Accrue.Auth.Default | Dev-permissive adapter must be impossible to run in :prod |
| Template assigns → rendered email | Assigns may contain PII; must not leak to logs |
| HTML input → ChromicPDF | Host-controlled; Chrome sandbox handles SSRF/XSS at the rendering layer |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-MAIL-01 | Information Disclosure | PII in Oban job args persisted to oban_jobs table | mitigate | `only_scalars!/1` guard in `Accrue.Mailer.Default.deliver/2` rejects structs; enforced convention: args contain only entity IDs (D-27). Worker rehydrates from DB at delivery time. Document in moduledoc that the assigns map must be Oban-safe. |
| T-MAIL-02 | Information Disclosure | PII in telemetry metadata | mitigate | Mailer telemetry span metadata includes `%{email_type, customer_id}` only — no raw email bodies, no assigns contents (D-28). Task 1 test verifies metadata shape. |
| T-MAIL-03 | Tampering | Swoosh.Email struct in args breaking Oban | mitigate | Covered by T-MAIL-01 guard; structs rejected at enqueue time with clear error |
| T-AUTH-01 | Elevation of Privilege | Production boot with Accrue.Auth.Default (no real auth) | mitigate | `boot_check!/0` raises Accrue.ConfigError in :prod when `:auth_adapter` config still points at Default (D-40). Plan 06's Accrue.Application.start/2 calls this function BEFORE the supervisor starts, so the BEAM refuses to boot. Test simulates :prod env path via `do_boot_check!(:prod)`. |
| T-PDF-01 | Information Disclosure | HTML body passed to telemetry metadata | mitigate | `Accrue.PDF.render/2` span metadata includes only `%{size, archival}` — NOT the html input. Document in moduledoc: HTML may contain PII, never log it. |
| T-PDF-02 | Denial of Service | Unbounded HTML → Chrome OOM | accept | ChromicPDF pool is host-configured; Accrue does not set resource limits. Document in install guide. |
</threat_model>

<verification>
- `mix test test/accrue/mailer_test.exs test/accrue/pdf_test.exs test/accrue/auth_test.exs` fully green
- `mix compile --warnings-as-errors` passes
- mjml_eex template compiles (proves the Rustler NIF pipeline works on the dev machine or CI)
- `grep -q "use MjmlEEx, mjml_template:" accrue/lib/accrue/emails/payment_succeeded.ex` (corrected pattern)
- `grep -q "formats: %{\"mjml\"" accrue/lib/` returns nothing (broken pattern from D-22 NOT used)
- Facade lockdown: `grep -q "ChromicPDF\\.start\\|{ChromicPDF," accrue/lib/accrue/application.ex` returns nothing
- `git diff accrue/lib/accrue/config.ex accrue/config/` shows no changes from this plan
</verification>

<success_criteria>
Phase 6 can add the remaining 13+ email templates by writing new `Accrue.Emails.*` modules following PaymentSucceeded's pattern. Phase 7 Admin UI can wire `Accrue.Integrations.Sigra` as the `:auth_adapter` config without touching the behaviour. Phase 6 `Accrue.Billing.invoice_pdf/2` (Phase 2+) can call `Accrue.PDF.render/2` with rendered HEEx output without modifying this plan's code.
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundations/01-05-SUMMARY.md`.
</output>
