---
phase: 01-foundations
plan: 05-mailer-pdf-auth
subsystem: foundations
tags: [elixir, mailer, pdf, auth, behaviour, swoosh, chromic_pdf, mjml, oban]
requirements: [MAIL-01, PDF-01, AUTH-01, AUTH-02]
dependency_graph:
  requires:
    - "01-01 bootstrap (mix.exs deps, Accrue.MoxSetup guard, config/test.exs Swoosh.Adapters.Test wiring)"
    - "01-02 Accrue.Telemetry.span/3, Accrue.ConfigError, Accrue.Config full Phase 1 schema"
    - "01-03 Accrue.TestRepo (for Oban.Testing repo + sandbox checkout)"
  provides:
    - "Accrue.Mailer behaviour — semantic deliver(type, assigns) API (D-21)"
    - "Accrue.Mailer.Default — Oban-enqueue adapter with only_scalars!/1 guard + :emails kill switch"
    - "Accrue.Mailer.Swoosh — thin Swoosh shim for actual delivery"
    - "Accrue.Workers.Mailer — Oban.Worker on :accrue_mailers queue, atomizes known keys for Phoenix.HTML"
    - "Accrue.Emails.PaymentSucceeded — reference mjml_eex template (CORRECTED D-22 pattern)"
    - "Reference MJML + text templates in priv/accrue/templates/emails/"
    - "Accrue.PDF behaviour — render(html, opts) callback (D-32 Shape B)"
    - "Accrue.PDF.ChromicPDF — host-pool-dependent adapter (does NOT start ChromicPDF — D-33)"
    - "Accrue.PDF.Test — Chrome-free adapter (D-34)"
    - "Accrue.Auth behaviour — current_user/1 + require_admin_plug/0 + user_schema/0 + log_audit/2 + actor_id/1"
    - "Accrue.Auth.Default — dev-permissive, prod-refuse-to-boot (D-40) with boot_check!/0 public API + do_boot_check!/1 test seam"
    - "Oban migration for Accrue.TestRepo (test-only; host apps own their Oban setup)"
    - "test_helper.exs Oban :manual testing mode wiring"
  affects:
    - "Phase 6 can add the 13+ remaining email templates by writing new Accrue.Emails.* modules following PaymentSucceeded's pattern"
    - "Phase 6 Accrue.Billing.invoice_pdf/2 can call Accrue.PDF.render/2 with rendered HEEx output"
    - "Phase 7 Admin UI can wire a real :auth_adapter (e.g., Accrue.Integrations.Sigra) without touching the behaviour"
    - "Plan 06 Accrue.Application.start/2 calls Accrue.Auth.Default.boot_check!/0 before supervisor boot"
tech_stack:
  added: []
  patterns:
    - "Behaviour + runtime-dispatch facade wrapping each public call in Accrue.Telemetry.span/3 with PII-safe metadata"
    - "mjml_eex's `use MjmlEEx, mjml_template: \"../...\"` compile-time pattern with relative path from lib/ to priv/"
    - "Oban.Worker with unique: [period: 60] + scalar-only assigns guard (T-MAIL-01)"
    - "Oban in :manual testing mode from test_helper.exs, per-test sandbox checkout via Ecto.Adapters.SQL.Sandbox.start_owner!/2"
    - "Public boot_check!/0 + @doc false do_boot_check!/1 test seam pattern for env-scoped refusal"
    - "Dev-permissive / prod-refuse adapter pattern (D-40)"
    - "Adapter file + behaviour + default + test adapter quad-pattern (shared across Mailer, PDF, Auth)"
key_files:
  created:
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
    - accrue/priv/repo/migrations/20260412000001_create_oban_jobs.exs
  modified:
    - accrue/test/test_helper.exs
decisions:
  - "MJML template path resolved relative to the calling module file (mjml_eex's requirement), so `use MjmlEEx, mjml_template: \"../../../priv/accrue/templates/emails/payment_succeeded.mjml.eex\"`. This keeps the actual template under priv/ where the plan specified AND satisfies mjml_eex's resolution semantics. Phase 6 can colocate templates next to modules if preferred."
  - "Accrue.Workers.Mailer.atomize_known_keys/1 converts string-keyed Oban args to atom-keyed assigns via String.to_existing_atom/1 (safe against atom-table exhaustion) — required because Phoenix.HTML.Engine inside mjml_eex fetches atom keys from the assigns map."
  - "test_helper.exs starts Oban in :manual testing mode with `queues: false, plugins: false, notifier: Oban.Notifiers.PG`. Host apps ship their own Oban config — Accrue only starts Oban for its OWN test suite (D-27)."
  - "Accrue.TestRepo migration 20260412000001_create_oban_jobs.exs lives under accrue/priv/repo/migrations/ alongside the event-ledger migration. Calls `Oban.Migration.up()` to get the oban_jobs table into the test DB. This is test-repo-only — host apps run their own `mix oban.gen.migration`."
  - "Mailer test uses `use ExUnit.Case, async: false` and `use Oban.Testing, repo: Accrue.TestRepo` together with a per-test sandbox checkout. Async false because Oban.insert goes through the shared Accrue.TestRepo and we want shared-mode sandbox for determinism."
  - "PDF facade-lockdown test scans the source with an @moduledoc stripper regex rather than raw string match — the moduledoc contains `{ChromicPDF, on_demand: true}` as host-wiring documentation, which is NOT a code coupling. The test enforces the actual invariant (no start_link/child_spec/use ChromicPDF in the code section)."
  - "Accrue.Auth.Default uses public boot_check!/0 + @doc false do_boot_check!/1 seam so :prod refusal is testable without Application.put_env(:env, :prod) tampering. Plan 06 calls the 0-arity public form."
metrics:
  duration_seconds: 720
  tasks_completed: 3
  files_created: 16
  files_modified: 1
  commits: 3
  tests: 28
  full_suite_tests: 145
  full_suite_properties: 6
completed_date: 2026-04-11
---

# Phase 01 Plan 05: Mailer + PDF + Auth Summary

**One-liner:** Four behaviours (Mailer, PDF, Auth) with their default adapters, one test adapter per suitable subsystem, and the reference `Accrue.Emails.PaymentSucceeded` mjml_eex template wired through a `:accrue_mailers` Oban queue — 28 new tests (145 full-suite), Oban brought up in `:manual` testing mode in `test_helper.exs`, zero edits to `config.ex` or `config/*.exs`.

## What Shipped

### Task 1 — Mailer behaviour + Default adapter + Oban worker + PaymentSucceeded reference template (commit `6422ada`)

- **`Accrue.Mailer`** (`lib/accrue/mailer.ex`) — behaviour + facade. `deliver/2` wraps the adapter call in `Accrue.Telemetry.span([:accrue, :mailer, :deliver], ...)` with metadata `%{email_type, customer_id}` (T-MAIL-02 — never raw assigns or bodies). Kill switch (`enabled?/1`) reads `Application.get_env(:accrue, :emails, [])` and returns `{:ok, :skipped}` when the per-type value is `false` (D-25).
- **`Accrue.Mailer.Swoosh`** (`lib/accrue/mailer/swoosh.ex`) — `use Swoosh.Mailer, otp_app: :accrue`. The env-specific adapter is already wired by Plan 01 (`Swoosh.Adapters.Test` in `config/test.exs`, `Swoosh.Adapters.Local` in `config/dev.exs`). This plan does NOT edit those files.
- **`Accrue.Mailer.Default`** (`lib/accrue/mailer/default.ex`) — `@behaviour Accrue.Mailer`. `deliver/2` routes through `only_scalars!/1` (walks the assigns map and raises `ArgumentError` on any struct, pid, function, ref — Pitfall #5 / T-MAIL-01), stringifies atom keys for Oban's JSON round-trip, and enqueues `Accrue.Workers.Mailer.new(%{type, assigns})` via `Oban.insert/1`. Moduledoc documents the Pay-style 4-rung override ladder; Phase 1 implements rungs 1 (kill switch) and 3 (`:email_overrides`).
- **`Accrue.Workers.Mailer`** (`lib/accrue/workers/mailer.ex`) — `use Oban.Worker, queue: :accrue_mailers, max_attempts: 5, unique: [period: 60, fields: [:args, :worker]]`. `perform/1`:
  1. Decodes `type_str` via `String.to_existing_atom/1` (safe).
  2. `resolve_template/1` honors `:email_overrides` (D-23 rung 3) for per-type template swapping.
  3. `atomize_known_keys/1` converts string-keyed Oban args to atom-keyed assigns via `String.to_existing_atom/1` (safe against atom-table exhaustion) — **required because Phoenix.HTML.Engine inside mjml_eex fetches atom keys from the assigns map**.
  4. Builds `%Swoosh.Email{}` via `Swoosh.Email.new |> to |> from |> subject |> html_body |> text_body`.
  5. Delivers via `Accrue.Mailer.Swoosh.deliver/1`.
- **`Accrue.Emails.PaymentSucceeded`** (`lib/accrue/emails/payment_succeeded.ex`) — uses the CORRECTED mjml_eex pattern (`use MjmlEEx, mjml_template: "../../../priv/accrue/templates/emails/payment_succeeded.mjml.eex"`), NOT the broken `use Phoenix.Swoosh, formats: %{"mjml" => :html_body}` shape D-22 originally sketched (RESEARCH Pitfall #3). The moduledoc loudly documents the corrected pattern. `subject/1`, `render/1` (generated by the macro), and `render_text/1` (plain `EEx.eval_file` against the sibling `.text.eex`).
- **`priv/accrue/templates/emails/payment_succeeded.mjml.eex`** — ~30-line reference template with `mj-section`, `mj-text`, `mj-button`. Hardcoded hex colors `#111827` (Ink), `#3B82F6` (Cobalt), `#F3F4F6` (background), `#6B7280` (muted) — email clients don't support CSS variables.
- **`priv/accrue/templates/emails/payment_succeeded.text.eex`** — plain-text sibling with the same `@customer_name`, `@amount`, `@invoice_number`, `@receipt_url` assigns.
- **`priv/repo/migrations/20260412000001_create_oban_jobs.exs`** — calls `Oban.Migration.up()` / `Oban.Migration.down(version: 1)`. Test-repo-only; hosts ship their own via `mix oban.gen.migration`. Lives alongside Plan 03's event-ledger migration under `accrue/priv/repo/migrations/`.
- **`test/test_helper.exs`** — added `Oban.start_link(repo: Accrue.TestRepo, testing: :manual, queues: false, plugins: false, notifier: Oban.Notifiers.PG)` between the `Accrue.TestRepo.start_link/1` and `ExUnit.start/0` lines. Accrue never starts Oban outside of its own test suite (D-27).
- **`test/accrue/mailer_test.exs`** — 8 tests, `async: false`, `use Oban.Testing, repo: Accrue.TestRepo`. Per-test sandbox checkout via `Ecto.Adapters.SQL.Sandbox.start_owner!/2` shared-mode. Covers: enqueue path (`assert_enqueued` / `all_enqueued`), `:emails` kill switch, struct rejection via `only_scalars!/1`, telemetry metadata shape (T-MAIL-02), worker perform delivering a real `%Swoosh.Email{}` asserted via `Swoosh.TestAssertions.assert_email_sent/1`, `:email_overrides` resolving to a stub template, MJML render producing HTML containing the assigns, text render doing the same.

Verification: `mix test test/accrue/mailer_test.exs` → 8 tests, 0 failures. `mix compile --warnings-as-errors` → clean.

### Task 2 — PDF behaviour + ChromicPDF adapter + Test adapter (commit `35402c0`)

- **`Accrue.PDF`** (`lib/accrue/pdf.ex`) — behaviour + facade with `render(html, opts \\ [])`. Wraps adapter call in `Accrue.Telemetry.span([:accrue, :pdf, :render], %{size, archival, adapter}, ...)`. **HTML body is NEVER in metadata** (T-PDF-01 — may contain PII); this is asserted by a test that passes `<html>SENSITIVE</html>` and refutes `inspect(metadata) =~ "SENSITIVE"`. Adapter resolved via `Application.get_env(:accrue, :pdf_adapter, Accrue.PDF.ChromicPDF)` (key already in Plan 02's schema).
- **`Accrue.PDF.ChromicPDF`** (`lib/accrue/pdf/chromic_pdf.ex`) — `@behaviour Accrue.PDF`. `render/2`:
  1. `translate_opts/2` builds `[content: html, size: :a4 | ...]` and maps `:header_html → :header`, `:footer_html → :footer`, `:header_height`, `:footer_height` via `maybe_put/3` (RESEARCH Summary point 5).
  2. Passes to `ChromicPDF.Template.source_and_options/1`.
  3. Routes to `ChromicPDF.print_to_pdfa/1` when `opts[:archival] == true`, else `ChromicPDF.print_to_pdf/1`.
  4. `rescue e -> {:error, e}` wraps any unexpected throw.
- **CRITICAL**: this module **does NOT** call `ChromicPDF.start_link/1`, `use ChromicPDF`, or define a `child_spec/1`. A facade-lockdown test in `pdf_test.exs` strips the moduledoc (which contains `{ChromicPDF, on_demand: true}` as host-wiring documentation) and scans the code section for these patterns — asserts none exist. Host apps are responsible for starting ChromicPDF in their own supervision tree (D-33, Pitfall #4).
- **`Accrue.PDF.Test`** (`lib/accrue/pdf/test.ex`) — `@behaviour Accrue.PDF`. `render(html, opts) → send(self(), {:pdf_rendered, html, opts}); {:ok, "%PDF-TEST"}` (D-34). Lets Phase 1 tests exercise the full PDF plumbing without a Chrome binary.
- **`test/accrue/pdf_test.exs`** — 6 tests, `async: false` (mutates `:pdf_adapter`). Covers: Test adapter round-trip + assert_received, opts passthrough (`:header_html` preserved), default opts `[]`, telemetry metadata shape + no HTML leak, ChromicPDF module compiles + declares `@behaviour Accrue.PDF`, ChromicPDF source-scan facade lockdown.

Verification: `mix test test/accrue/pdf_test.exs` → 6 tests, 0 failures. No Chrome binary required.

### Task 3 — Auth behaviour + Default adapter (dev-permissive, prod-refuse) (commit `f32c570`)

- **`Accrue.Auth`** (`lib/accrue/auth.ex`) — behaviour + facade. Five callbacks: `current_user/1`, `require_admin_plug/0`, `user_schema/0`, `log_audit/2`, `actor_id/1`. No telemetry wrapping — auth is hot-path plug code; instrumentation belongs at the caller level (Phase 7 Admin UI). Adapter resolved via `Application.get_env(:accrue, :auth_adapter, Accrue.Auth.Default)`.
- **`Accrue.Auth.Default`** (`lib/accrue/auth/default.ex`) — `@behaviour Accrue.Auth`. All five callbacks:
  - `current_user/1`: returns `%{id: "dev", email: "dev@localhost", role: :admin}` in `:dev`/`:test`; `nil` in `:prod` (unreachable in practice because `boot_check!/0` raises before).
  - `require_admin_plug/0`: returns a pass-through `fn conn, _opts -> conn end` in dev/test; returns a function that raises `Accrue.ConfigError` otherwise.
  - `user_schema/0`: `nil` (host-owned).
  - `log_audit/2`: `:ok` (no-op).
  - `actor_id/1`: reads `:id` or `"id"` from a map, else `nil`.
- **`boot_check!/0`** — public API. Reads `Application.get_env(:accrue, :env, Mix.env())` at call time and delegates to `do_boot_check!/1`. Plan 06's `Accrue.Application.start/2` will call this 0-arity form BEFORE any supervisor starts.
- **`do_boot_check!/1`** — `@doc false` test seam. `def` (not `defp`) so tests can simulate the `:prod` branch by calling it directly, without `Application.put_env(:accrue, :env, :prod)` which bleeds between async tests. The `:prod` clause checks whether `:auth_adapter` still points at `__MODULE__` — if it does, raises `Accrue.ConfigError` with a message pointing at install docs; if a real adapter is configured, returns `:ok`. `:dev`/`:test` both return `:ok` unconditionally.
- **Env lookup strategy**: `Application.get_env(:accrue, :env, Mix.env())` — runtime lookup with `Mix.env()` as the compile-baked fallback. Plan 01 pre-wired `config :accrue, :env, Mix.env()` in `config/config.exs`, so production releases have it set correctly. Simpler than `Application.compile_env!/2` and still honest — this plan never edits `config.exs`.
- **`test/accrue/auth_test.exs`** — 14 tests, `async: true`. Covers: facade delegation, dev-user shape, public `boot_check!/0`, all three `do_boot_check!/1` env branches, prod-with-custom-adapter escape hatch, `require_admin_plug/0` pass-through, `user_schema/0`, `log_audit/2` no-op, `actor_id/1` with atom-keyed + string-keyed maps + nil input.

Verification: `mix test test/accrue/auth_test.exs` → 14 tests, 0 failures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Phoenix.HTML.Engine inside mjml_eex fetches atom keys from assigns**

- **Found during:** Task 1 first run of `mix test test/accrue/mailer_test.exs`.
- **Issue:** The worker `perform/1` initially passed the Oban args' string-keyed `assigns` map straight to `Accrue.Emails.PaymentSucceeded.render/1`. MjmlEEx's generated `render/1` feeds the map through `Phoenix.HTML.Engine`, which calls `Phoenix.HTML.Engine.fetch_assign!(assigns, :customer_name)` with atom keys. With string-keyed assigns, every template var lookup raised `(KeyError) key :customer_name not found`.
- **Fix:** Added `atomize_known_keys/1` in the worker that walks the map and converts string keys to atoms via `String.to_existing_atom/1` (safe against atom-table exhaustion — unknown strings are dropped from the atom-keyed view). The worker then calls `template_mod.render(atomized)` and `template_mod.render_text(atomized)`. The original map is still used to read `"to"` for the Swoosh email recipient in case that key wasn't atomized.
- **Files modified:** `accrue/lib/accrue/workers/mailer.ex`
- **Commit:** `6422ada`

**2. [Rule 3 - Blocker] Oban insert path needs a sandbox-checkout connection per test**

- **Found during:** Task 1 — telemetry test failure with `(DBConnection.OwnershipError) cannot find ownership process for #PID<...>`.
- **Issue:** The mailer test initially only had an env-cleanup setup block. But every `Accrue.Mailer.deliver/2` call goes through `Oban.insert/1` which transacts against `Accrue.TestRepo`, and in `:manual` sandbox mode the test process must check out a connection explicitly.
- **Fix:** Added `Ecto.Adapters.SQL.Sandbox.start_owner!(Accrue.TestRepo, shared: not tags[:async])` + `stop_owner` on_exit in the setup. Because the test module is `async: false`, shared-mode is active and the Oban worker process (if it ever ran out-of-band) can reach the same connection.
- **Files modified:** `accrue/test/accrue/mailer_test.exs`
- **Commit:** `6422ada`

**3. [Rule 3 - Blocker] Oban needs a migration for accrue_events test DB**

- **Found during:** Task 1 planning — before writing any test, I realized that `Oban.insert/1` inside `Accrue.TestRepo` requires the `oban_jobs` table. Plan 03 shipped the `accrue_events` migration but not Oban's. A bare `Oban.start_link` without the table would crash on first insert.
- **Fix:** Added `priv/repo/migrations/20260412000001_create_oban_jobs.exs` that calls `Oban.Migration.up()` / `Oban.Migration.down(version: 1)`. This is a test-repo-only migration — hosts ship their own via `mix oban.gen.migration`, and Accrue never owns Oban wiring in production (D-27). The migration lives alongside Plan 03's event-ledger migration under `accrue/priv/repo/migrations/`.
- **Files created:** `accrue/priv/repo/migrations/20260412000001_create_oban_jobs.exs`
- **Commit:** `6422ada`
- **Note:** The migration file itself is arguably Phase 6 territory, but Phase 1's test suite cannot enqueue Oban jobs without the table, and the plan explicitly calls for `Oban.Testing.assert_enqueued` assertions. This deviation is scoped to `priv/repo/migrations/` which is not part of the plan's "frozen files" list (`config.ex`, `config/*.exs`).

**4. [Rule 1 - Bug] PDF facade-lockdown false-positive on moduledoc host-wiring example**

- **Found during:** Task 2 first run of `mix test test/accrue/pdf_test.exs`.
- **Issue:** The initial facade-lockdown test used `source =~ ~r/\{ChromicPDF,/` to detect supervisor-start patterns. But `Accrue.PDF.ChromicPDF`'s moduledoc contains `{ChromicPDF, on_demand: true}` as DOCUMENTATION for how hosts should wire ChromicPDF — that's the intent, not a violation. Same shape as Plan 04's Pitfall #2 (`:lattice_stripe` in a docstring tripping the facade-lockdown regex).
- **Fix:** Strip the moduledoc block via `Regex.replace(~r/@moduledoc\s+"""[\s\S]*?"""/m, source, "@moduledoc false")` before scanning. The real invariant D-33 enforces is "no module calls into `ChromicPDF.start_link` / `child_spec` / `use ChromicPDF`", and the code-section regex captures that precisely.
- **Files modified:** `accrue/test/accrue/pdf_test.exs`
- **Commit:** `35402c0`

### Rule 4 — Architectural changes

None. All four deviations are mechanical fixes — no plan decisions (D-21..D-34, D-40) touched.

## Threat Register Status

- **T-MAIL-01 (Information Disclosure — PII in Oban args persisted to oban_jobs):** mitigated. `only_scalars!/1` in `Accrue.Mailer.Default.deliver/2` rejects structs, pids, functions, refs with a clear `ArgumentError`. Convention: pass entity IDs, worker rehydrates from DB. Mailer test asserts this contract with a `URI.parse/1` struct that triggers the raise.
- **T-MAIL-02 (Information Disclosure — PII in telemetry metadata):** mitigated. `Accrue.Mailer.deliver/2` span metadata is `%{email_type, customer_id}` only — no raw assigns, no email body. Test attaches a `:telemetry` handler and asserts `refute Map.has_key?(start_meta, :assigns)` + `refute Map.has_key?(start_meta, :body)`.
- **T-MAIL-03 (Tampering — Swoosh.Email struct breaking Oban):** mitigated by T-MAIL-01 guard (structs rejected at enqueue time).
- **T-PDF-01 (Information Disclosure — HTML body in telemetry metadata):** mitigated. `Accrue.PDF.render/2` span metadata is `%{size, archival, adapter}` only. Test passes `<html>SENSITIVE</html>` and asserts `refute inspect(start_meta) =~ "SENSITIVE"` — the literal HTML never appears in any part of the metadata map.
- **T-PDF-02 (DoS — Unbounded HTML → Chrome OOM):** accepted. ChromicPDF pool is host-configured; Accrue does not set resource limits. Documented in `Accrue.PDF.ChromicPDF` moduledoc as host responsibility.
- **T-AUTH-01 (Elevation of Privilege — production boot with Accrue.Auth.Default):** mitigated. `boot_check!/0` public API + `do_boot_check!/1` testable seam. The `:prod` branch checks `:auth_adapter` and raises `Accrue.ConfigError` with a pointer at install docs if it's still the Default. Plan 06's `Accrue.Application.start/2` will call this 0-arity public form BEFORE the supervisor starts. Test exercises the prod branch via `do_boot_check!(:prod)` directly (no env tampering) and asserts the message matches `~r/dev-only and refuses to run in :prod/`. The escape-hatch test flips `:auth_adapter` to a stub module and asserts `do_boot_check!(:prod)` returns `:ok` — the refusal is specifically about running with NO auth configured.

## Verification Results

```
cd accrue && mix compile --warnings-as-errors                        # clean
cd accrue && mix test test/accrue/mailer_test.exs                    # 8 tests, 0 failures
cd accrue && mix test test/accrue/pdf_test.exs                       # 6 tests, 0 failures
cd accrue && mix test test/accrue/auth_test.exs                      # 14 tests, 0 failures
cd accrue && mix test                                                # 145 tests, 6 properties, 0 failures

grep -q "use MjmlEEx, mjml_template:" accrue/lib/accrue/emails/payment_succeeded.ex       # present (CORRECTED pattern)
grep -rn 'formats: %{"mjml"' accrue/lib/ | grep -v "NOT the broken"                       # empty (broken D-22 pattern not used in code)
grep -q "use Oban.Worker" accrue/lib/accrue/workers/mailer.ex                             # present
grep -q "only_scalars" accrue/lib/accrue/mailer/default.ex                                # present
test -f accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex                    # present
test -f accrue/priv/accrue/templates/emails/payment_succeeded.text.eex                    # present

grep -q "ChromicPDF.Template.source_and_options" accrue/lib/accrue/pdf/chromic_pdf.ex     # present
grep -q "%PDF-TEST" accrue/lib/accrue/pdf/test.ex                                         # present
grep -q "send(self" accrue/lib/accrue/pdf/test.ex                                         # present

grep -q "@callback current_user" accrue/lib/accrue/auth.ex                                # present
grep -q "def boot_check!" accrue/lib/accrue/auth/default.ex                               # present (public 0-arity)
grep -q "do_boot_check!" accrue/lib/accrue/auth/default.ex                                # present (private/testable helper)
grep -q "Accrue.ConfigError" accrue/lib/accrue/auth/default.ex                            # present
grep -q "dev@localhost" accrue/lib/accrue/auth/default.ex                                 # present

git diff 85b8370 -- accrue/lib/accrue/config.ex accrue/config/                            # empty (frozen files untouched)
```

All green.

## Success Criteria Met

Phase 6 can now:

- Add the remaining 13+ email templates by writing new `Accrue.Emails.*` modules following `PaymentSucceeded`'s pattern (`use MjmlEEx, mjml_template: "..."`, `subject/1`, `render_text/1`). The Oban worker already resolves types via `resolve_template/1` — Phase 6 just extends the default table.
- Call `Accrue.PDF.render/2` with rendered HEEx output from `Accrue.Billing.invoice_pdf/2` without modifying this plan's code. The ChromicPDF adapter handles `:archival` and header/footer translation transparently.

Phase 7 Admin UI can:

- Wire `Accrue.Integrations.Sigra` (or any host adapter) as `:auth_adapter` via a one-line config — the `Accrue.Auth` behaviour surface is stable.
- Mount `Accrue.Auth.require_admin_plug/0` at the admin router without touching the Default adapter.

Plan 06 can:

- Call `Accrue.Auth.Default.boot_check!/0` from `Accrue.Application.start/2` before any supervisor boots — production deploys with no auth configured will raise before any state is touched.

## Known Stubs

None. Every shipped module is fully functional and exercised by tests:

- `Accrue.Mailer` facade enqueues real Oban jobs verified via `Oban.Testing.assert_enqueued/1`.
- `Accrue.Workers.Mailer.perform/1` builds and delivers a real `%Swoosh.Email{}` verified via `Swoosh.TestAssertions.assert_email_sent/1`.
- `Accrue.Emails.PaymentSucceeded.render/1` compiles MJML through the mjml_eex Rustler NIF at build time and returns real HTML containing the assigns — the test asserts substring matches on `"Alice"`, `"INV-1"`, `"$10.00"`, and the receipt URL.
- `Accrue.PDF.Test.render/2` exercises the full behaviour contract; `Accrue.PDF.ChromicPDF.render/2` is compile-and-conformance-only per the plan (real Chrome calls deferred to Phase 6+ integration testing).
- `Accrue.Auth.Default` all five callbacks have real implementations covered by unit tests.

The `enrich/2` hook in `Accrue.Workers.Mailer` is a documented Phase 2+ extension point (Phase 1 passes assigns through; Phase 2+ rehydrates `Customer`/`Invoice` from the DB by ID). This is the Phase 2 entity-handoff point, not a stub.

## Self-Check: PASSED

- `accrue/lib/accrue/mailer.ex` — FOUND
- `accrue/lib/accrue/mailer/default.ex` — FOUND
- `accrue/lib/accrue/mailer/swoosh.ex` — FOUND
- `accrue/lib/accrue/workers/mailer.ex` — FOUND
- `accrue/lib/accrue/emails/payment_succeeded.ex` — FOUND
- `accrue/priv/accrue/templates/emails/payment_succeeded.mjml.eex` — FOUND
- `accrue/priv/accrue/templates/emails/payment_succeeded.text.eex` — FOUND
- `accrue/lib/accrue/pdf.ex` — FOUND
- `accrue/lib/accrue/pdf/chromic_pdf.ex` — FOUND
- `accrue/lib/accrue/pdf/test.ex` — FOUND
- `accrue/lib/accrue/auth.ex` — FOUND
- `accrue/lib/accrue/auth/default.ex` — FOUND
- `accrue/test/accrue/mailer_test.exs` — FOUND
- `accrue/test/accrue/pdf_test.exs` — FOUND
- `accrue/test/accrue/auth_test.exs` — FOUND
- `accrue/priv/repo/migrations/20260412000001_create_oban_jobs.exs` — FOUND
- `accrue/test/test_helper.exs` — MODIFIED (Oban :manual testing-mode wiring)
- Commit `6422ada` — FOUND (feat(01-05): Mailer + Oban worker + PaymentSucceeded)
- Commit `35402c0` — FOUND (feat(01-05): PDF behaviour + ChromicPDF adapter + Test adapter)
- Commit `f32c570` — FOUND (feat(01-05): Auth behaviour + Default adapter)
- `mix compile --warnings-as-errors` — green
- `mix test test/accrue/mailer_test.exs` — 8 tests, 0 failures
- `mix test test/accrue/pdf_test.exs` — 6 tests, 0 failures
- `mix test test/accrue/auth_test.exs` — 14 tests, 0 failures
- `mix test` (full suite) — 145 tests + 6 properties, 0 failures
- Plan frozen files (`accrue/lib/accrue/config.ex`, `accrue/config/*.exs`) — unchanged since commit `85b8370`
