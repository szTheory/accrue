---
phase: 01-foundations
plan: 06
type: execute
wave: 3
depends_on: [01, 02, 03, 04, 05]
files_modified:
  - accrue/lib/accrue/application.ex
  - accrue/lib/accrue/integrations/sigra.ex
  - accrue/mix.exs
  - accrue/priv/static/brand.css
  - accrue/test/accrue/application_test.exs
  - accrue/test/accrue/integrations/sigra_test.exs
  - .github/workflows/ci.yml
  - scripts/ci/compile_matrix.sh
autonomous: true
requirements: [FND-05, FND-07]
security_enforcement: enabled
tags: [elixir, application, supervisor, conditional-compile, sigra, brand, ci]
must_haves:
  truths:
    - "Accrue.Application.start/2 calls Accrue.Auth.Default.boot_check!/0 BEFORE the supervisor starts"
    - "Accrue.Application.start/2 has an empty or near-empty child list — host owns Repo/Oban/ChromicPDF/Finch lifecycle (D-33, D-42, Pitfall #4)"
    - "mix compile --warnings-as-errors passes in BOTH the with_sigra and without_sigra matrices (Success Criterion #5)"
    - "When :sigra dep is absent, Accrue.Integrations.Sigra module is NOT DEFINED — Code.ensure_loaded?(Accrue.Integrations.Sigra) returns {:error, :nofile}"
    - "When :sigra dep is present, Accrue.Integrations.Sigra IS defined and implements Accrue.Auth (scaffolded; concrete callback bodies are deferred per CONTEXT.md)"
    - "accrue/priv/static/brand.css defines :root CSS variables --accrue-ink, --accrue-slate, --accrue-fog, --accrue-paper, --accrue-moss, --accrue-cobalt, --accrue-amber (FND-07)"
    - "GitHub Actions CI runs mix format check, mix compile --warnings-as-errors, mix test, mix credo --strict across Elixir 1.17/OTP27 and 1.18/OTP27 and 1.18/OTP28"
    - "CI matrix includes a sigra=on / sigra=off sub-matrix that exercises the conditional compile"
    - "Brand.css shipped in priv/static is accessible via :code.priv_dir(:accrue)"
  artifacts:
    - path: "accrue/lib/accrue/application.ex"
      provides: "OTP Application with near-empty supervisor + boot validation"
      contains: "use Application"
    - path: "accrue/lib/accrue/integrations/sigra.ex"
      provides: "Conditionally compiled Sigra auth adapter (scaffold)"
      contains: "Code.ensure_loaded?"
    - path: "accrue/priv/static/brand.css"
      provides: "Brand palette CSS variables"
      contains: ":root"
      min_lines: 10
    - path: ".github/workflows/ci.yml"
      provides: "CI matrix with with_sigra/without_sigra sub-matrix + Elixir/OTP versions + Dialyzer PLT cache"
      contains: "matrix:"
    - path: "scripts/ci/compile_matrix.sh"
      provides: "Local + CI helper that runs mix compile --warnings-as-errors twice (sigra on/off)"
      contains: "SIGRA"
  key_links:
    - from: "accrue/lib/accrue/application.ex"
      to: "Accrue.Auth.Default.boot_check!/0"
      via: "direct call in start/2 before Supervisor.start_link"
      pattern: "boot_check!"
    - from: "accrue/lib/accrue/integrations/sigra.ex"
      to: "Sigra.Auth"
      via: "conditional compile guard"
      pattern: "Code.ensure_loaded\\?\\(Sigra\\)"
    - from: ".github/workflows/ci.yml"
      to: "scripts/ci/compile_matrix.sh"
      via: "CI job invokes script"
      pattern: "compile_matrix\\.sh"
    - from: "accrue/mix.exs"
      to: "Accrue.Application"
      via: "mod: {Accrue.Application, []} added to application/0"
      pattern: "mod:"
---

<objective>
Wire everything together. Add `Accrue.Application` (D-05 empty-supervisor pattern) with the boot-time Auth refuse-to-boot check. Ship the Sigra integration scaffold using CLAUDE.md's 4-pattern conditional compile (FND-05 adjacent; AUTH-03 is Phase 7 but the scaffold must prove it compiles clean in both matrices per Success Criterion #5). Drop the brand palette CSS (FND-07). Stand up CI with an Elixir/OTP matrix and a `with_sigra`/`without_sigra` sub-matrix that proves the conditional compile works.

Purpose: Success Criterion #5 from ROADMAP.md is the single hard gate on Phase 1 declaring "done": **mix compile --warnings-as-errors succeeds in both with_sigra and without_sigra builds**. This plan delivers that gate, plus the empty-supervisor application boot that Plan 02's Config schema requires, plus the brand.css file required by FND-07.
Output: A booting OTP app, a CI matrix that catches conditional-compile regressions on every PR, a working Sigra scaffold that vanishes gracefully when the dep is absent, and the brand CSS file at `accrue/priv/static/brand.css`.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/01-foundations/01-CONTEXT.md
@.planning/phases/01-foundations/01-RESEARCH.md
@CLAUDE.md
@accrue/lib/accrue/auth/default.ex
@accrue/lib/accrue/config.ex
@accrue/mix.exs

<interfaces>
<!-- Contracts this plan CREATES. -->

From accrue/lib/accrue/application.ex:
```elixir
defmodule Accrue.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    :ok = Accrue.Config.validate_at_boot!()
    :ok = Accrue.Auth.Default.boot_check!()

    children = [
      # Registry for Fake processor instances, if needed for Phase 3 parallel test isolation.
      # Per RESEARCH.md Assumption A3, the Fake is a singleton GenServer in Phase 1; Registry
      # can be added if test isolation problems surface. For now, empty list.
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Accrue.Supervisor)
  end
end
```

From accrue/lib/accrue/integrations/sigra.ex (the 4-pattern conditional compile from CLAUDE.md):
```elixir
# File always exists. The defmodule is conditionally expanded.
if Code.ensure_loaded?(Sigra) do
  defmodule Accrue.Integrations.Sigra do
    @moduledoc """
    First-party Sigra auth adapter. Auto-activated when :sigra is in the host's deps.
    Phase 1 ships the scaffold; concrete callback bodies fill in during Phase 7
    (Admin UI) when Sigra APIs are exercised end-to-end.
    """

    @behaviour Accrue.Auth
    @compile {:no_warn_undefined, [Sigra.Auth, Sigra.Audit]}

    @impl true
    def current_user(conn), do: Sigra.Auth.current_user(conn)

    @impl true
    def require_admin_plug, do: fn conn, _opts -> conn end  # placeholder — Phase 7 wires real check

    @impl true
    def user_schema, do: nil  # host-owned

    @impl true
    def log_audit(user, event), do: Sigra.Audit.log(user, event)

    @impl true
    def actor_id(user), do: user[:id] || user["id"]
  end
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Accrue.Application + brand.css + mix.exs mod wiring</name>
  <read_first>
    - .planning/phases/01-foundations/01-CONTEXT.md D-05 (empty supervisor pattern), D-33 (ChromicPDF not started here), D-40 (boot_check!)
    - .planning/phases/01-foundations/01-RESEARCH.md §Pattern 5 (Empty-Supervisor Library Application)
    - .planning/phases/01-foundations/01-RESEARCH.md §Pitfall 4 (NO ChromicPDF children)
    - CLAUDE.md §Monorepo Layout — brand palette tokens (Ink/Slate/Fog/Paper + Moss/Cobalt/Amber)
  </read_first>
  <files>
    accrue/lib/accrue/application.ex
    accrue/mix.exs
    accrue/priv/static/brand.css
    accrue/lib/accrue/config.ex
    accrue/test/accrue/application_test.exs
  </files>
  <behavior>
    - `Accrue.Application.start(:normal, [])` returns `{:ok, pid}` when config is valid and env is :test
    - Calling `start/2` in a simulated :prod env WITHOUT a custom auth adapter raises `Accrue.ConfigError` via `Accrue.Auth.Default.boot_check!/0` BEFORE `Supervisor.start_link` is called
    - `:application.get_key(:accrue, :mod) == {:ok, {Accrue.Application, []}}` — the Application module is wired in mix.exs
    - `grep -q "ChromicPDF\\|Oban.start\\|Finch" accrue/lib/accrue/application.ex` returns nothing (Pitfall #4 — host owns those)
    - `accrue/priv/static/brand.css` exists and defines 7 CSS variables in `:root` for Ink/Slate/Fog/Paper/Moss/Cobalt/Amber
    - `:code.priv_dir(:accrue)` points at the priv directory and `File.exists?(Path.join(:code.priv_dir(:accrue), "static/brand.css"))` is true
    - `Accrue.Config.validate_at_boot!/0` exists and validates the current `:accrue` env against the NimbleOptions schema, raising `Accrue.ConfigError` on failure
  </behavior>
  <action>
1. **Amend `accrue/mix.exs`**: add `mod: {Accrue.Application, []}` to the `application/0` function. This is the delta from Plan 01's scaffold (which deliberately omitted it):
   ```elixir
   def application do
     [
       extra_applications: [:logger],
       mod: {Accrue.Application, []}
     ]
   end
   ```

2. `accrue/lib/accrue/application.ex`: exactly as in the `<interfaces>` block. Key points:
   - `@moduledoc false` — internal.
   - `Accrue.Config.validate_at_boot!/0` called FIRST — fail on misconfig before anything else.
   - `Accrue.Auth.Default.boot_check!/0` called SECOND — prod + Default adapter = refuse to boot.
   - Empty (or near-empty) children list. Per A3 (RESEARCH.md), NO Registry for Fake in Phase 1; the singleton GenServer is sufficient.
   - No ChromicPDF, no Oban, no Finch, no Repo children — those are host-owned (D-33, D-10, Pitfall #4).

3. **Amend `accrue/lib/accrue/config.ex`** — add `validate_at_boot!/0`:
   ```elixir
   @spec validate_at_boot!() :: :ok
   def validate_at_boot! do
     opts = Application.get_all_env(:accrue) |> Keyword.take(Keyword.keys(@schema))
     _ = NimbleOptions.validate!(opts, @schema)
     :ok
   end
   ```
   This reads the current `:accrue` env at boot time, validates against the schema, and raises NimbleOptions' ValidationError on misconfig. Test env should pass cleanly if Plan 01's `config/test.exs` sets `config :accrue, :repo, Accrue.TestRepo`.

4. `accrue/priv/static/brand.css`:
   ```css
   /*
    * Accrue brand palette — Phase 1 foundational tokens.
    * Consumed by accrue_admin (Phase 7) and any host app that wants to align with
    * Accrue's visual language. Variable names are stable public API at v1.0.
    */
   :root {
     /* Neutrals */
     --accrue-ink:    #111827;  /* primary text, headings */
     --accrue-slate:  #374151;  /* secondary text */
     --accrue-fog:    #9CA3AF;  /* muted text, borders */
     --accrue-paper:  #F9FAFB;  /* backgrounds */

     /* Accents */
     --accrue-moss:   #059669;  /* success, active subscription */
     --accrue-cobalt: #3B82F6;  /* primary actions, links */
     --accrue-amber:  #F59E0B;  /* warning, grace period, dunning */
   }
   ```
   The hex values above are placeholders matching the Ink/Slate/Fog/Paper/Moss/Cobalt/Amber naming; the planner/implementer may adjust to match any visual guide in PROJECT.md if one exists. Key constraint is that all 7 variables are DEFINED with `--accrue-*` prefix.

5. `test/accrue/application_test.exs`:
   - Test 1: `Application.stop(:accrue) ; {:ok, _pid} = Application.ensure_all_started(:accrue) ; assert Process.whereis(Accrue.Supervisor)` — app boots.
   - Test 2: `assert {:ok, {Accrue.Application, []}} = :application.get_key(:accrue, :mod)`.
   - Test 3: Brand CSS file exists at priv path.
   - Test 4: Config.validate_at_boot!/0 returns :ok with the current test config.
   - Test 5: Simulate :prod auth misconfig — inject `:env, :prod` into a sub-process test. This is tricky because `@env` is compile_env. Use the `Accrue.Auth.Default.boot_check!/1` arity from Plan 05 Task 3 (which accepts env as arg) to directly simulate: `assert_raise Accrue.ConfigError, fn -> Accrue.Auth.Default.boot_check!(:prod) end`. This is actually a duplicate of a test from Plan 05; keep it here too for the integration perspective.
   - Test 6: Pitfall #4 assertion — `refute File.read!("lib/accrue/application.ex") =~ "ChromicPDF"` and same for "Oban.start" and "Finch".
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix test test/accrue/application_test.exs && mix compile --warnings-as-errors && test -f priv/static/brand.css && grep -c "^  --accrue-" priv/static/brand.css</automated>
  </verify>
  <acceptance_criteria>
    - `mix test test/accrue/application_test.exs` reports all passing
    - `grep -q "mod: {Accrue.Application" accrue/mix.exs`
    - `grep -q "validate_at_boot" accrue/lib/accrue/config.ex`
    - `grep -q "boot_check!" accrue/lib/accrue/application.ex`
    - `grep -c "^  --accrue-" accrue/priv/static/brand.css` returns 7 (Ink, Slate, Fog, Paper, Moss, Cobalt, Amber)
    - `grep -q "ChromicPDF\\|Oban\\|Finch" accrue/lib/accrue/application.ex` returns nothing (Pitfall #4)
    - `mix compile --warnings-as-errors` passes
  </acceptance_criteria>
  <done>Accrue.Application boots cleanly, brand.css ships at priv/static/brand.css, the empty-supervisor pattern is locked in, and no host-owned deps are started.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Conditional-compile Sigra scaffold + CI matrix + compile_matrix.sh</name>
  <read_first>
    - CLAUDE.md §Conditional Compilation for Optional Deps (the 4-pattern)
    - CLAUDE.md §Dialyzer PLT Caching Pattern (GitHub Actions)
    - CLAUDE.md §CI Matrix (Elixir/OTP/Phoenix versions)
    - .planning/phases/01-foundations/01-CONTEXT.md D-41, D-45
    - .planning/phases/01-foundations/01-RESEARCH.md §Pattern 6 (conditional compile example)
  </read_first>
  <files>
    accrue/lib/accrue/integrations/sigra.ex
    accrue/test/accrue/integrations/sigra_test.exs
    .github/workflows/ci.yml
    scripts/ci/compile_matrix.sh
  </files>
  <behavior>
    - With `:sigra` in deps: `Code.ensure_loaded(Accrue.Integrations.Sigra)` returns `{:module, Accrue.Integrations.Sigra}`
    - Without `:sigra` in deps: `Code.ensure_loaded(Accrue.Integrations.Sigra)` returns `{:error, :nofile}`
    - `mix compile --warnings-as-errors` passes in BOTH conditions (Success Criterion #5)
    - `scripts/ci/compile_matrix.sh` runs the compile twice: once with `MIX_SIGRA=1` (if we add sigra to deps conditionally via an env var) and once without
    - GitHub Actions workflow runs on push/PR with a matrix:
      - elixir: [1.17.x, 1.18.x]
      - otp: [27, 28]  (with exclusions for 1.17/28 since it's not supported)
      - sigra: [on, off]
    - Each matrix cell runs: `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer`
    - PLT cache keyed on `${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ hashFiles('**/mix.lock') }}` (CLAUDE.md recipe)
  </behavior>
  <action>
1. `accrue/lib/accrue/integrations/sigra.ex`: the file always exists, but the module is conditionally defined per CLAUDE.md Pattern 6 / RESEARCH.md Pattern 6. Exact body in the `<interfaces>` block above.

   Important: in the `without_sigra` matrix, `Code.ensure_loaded?(Sigra)` is false and the defmodule never expands — the file compiles to a no-op. The `@compile {:no_warn_undefined, ...}` is required INSIDE the `defmodule` block (only active when sigra is loaded) to silence warnings about `Sigra.Audit` and `Sigra.Auth` references whose resolution is deferred to runtime.

2. `test/accrue/integrations/sigra_test.exs`:
   - Test 1: `case Code.ensure_loaded(Accrue.Integrations.Sigra) do {:module, _} -> :ok ; {:error, :nofile} -> :ok end` — accept either outcome; the test should pass in BOTH matrices. This is a "sanity test" — the real verification is that the compile succeeds, not that a specific module is present.
   - Test 2 (conditional, only when Sigra IS loaded): check that the module implements `Accrue.Auth` via `function_exported?(Accrue.Integrations.Sigra, :current_user, 1)`. Skip via `@moduletag :sigra` or runtime `if Code.ensure_loaded?(Sigra) do ... else ... end`.

3. **How to toggle sigra on/off for the matrix**: Sigra is a sibling library (hex or path?). For Phase 1, the simplest approach is a `mix.exs` env-var gate:
   ```elixir
   defp deps do
     base_deps() ++ optional_sigra()
   end

   defp optional_sigra do
     if System.get_env("ACCRUE_WITH_SIGRA") == "1" do
       [{:sigra, "~> 0.1", optional: true}]
     else
       []
     end
   end
   ```
   **However**, per D-45 and CLAUDE.md, `:sigra` is supposed to be declared `optional: true` unconditionally in deps — the matrix toggle is supposed to be whether the host app (or CI) includes sigra at all. Since Accrue itself is the library under test here, the env-var gate is the pragmatic way to simulate "host has sigra" vs "host does not have sigra" on a single codebase.

   **Decision**: declare `{:sigra, "~> 0.1", optional: true}` unconditionally in `mix.exs` (matches D-45 and what Plan 01 already shipped), and in the CI matrix toggle sigra presence by running `mix deps.get` with/without `:sigra` in the lockfile. The simpler approach for CI: run `mix deps.clean --all && mix deps.get` once WITH sigra on the PATH (mix will fetch it since optional deps are still considered), and another time where sigra is explicitly unfetched.

   Actually, the cleanest approach for Accrue Phase 1: since `optional: true` already means "don't fetch unless someone asks for it," the `with_sigra` matrix cell must add sigra explicitly via an override file, and the `without_sigra` matrix cell uses the default mix.exs. Use a `mix.exs` `env` gate via `Mix.env()` is wrong because env is set by mix not by CI matrix. **Simplest working approach**: a CI-side env var `ACCRUE_CI_SIGRA=1` reads into mix.exs deps/0 and flips between `{:sigra, "~> 0.1", optional: true}` and `[]`. Plan 01's mix.exs declared the dep unconditionally; amend here to use the env gate, OR keep Plan 01's unconditional declaration and drive the matrix via `mix deps.unlock --all && mix deps.get --only sigra` style commands.

   **Final recommendation**: amend Plan 01's `optional_sigra` to be env-gated at the matrix level. Document this clearly at the top of mix.exs. The env gate is ONLY for CI matrix simulation; in a real host app, the host's mix.exs controls whether sigra is present.

4. `scripts/ci/compile_matrix.sh`:
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail

   cd "$(dirname "$0")/../.."

   echo "=== Compiling without sigra ==="
   unset ACCRUE_CI_SIGRA
   (cd accrue && mix deps.clean --all --quiet && mix deps.get && mix compile --warnings-as-errors)

   echo "=== Compiling with sigra ==="
   export ACCRUE_CI_SIGRA=1
   (cd accrue && mix deps.clean --all --quiet && mix deps.get && mix compile --warnings-as-errors)

   echo "=== Both matrix cells compiled clean ==="
   ```
   `chmod +x scripts/ci/compile_matrix.sh`.

5. `.github/workflows/ci.yml`:
   ```yaml
   name: CI

   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]

   jobs:
     test:
       name: Test (${{ matrix.elixir }} / OTP ${{ matrix.otp }} / sigra=${{ matrix.sigra }})
       runs-on: ubuntu-24.04
       services:
         postgres:
           image: postgres:15
           env:
             POSTGRES_PASSWORD: postgres
           ports: ['5432:5432']
           options: >-
             --health-cmd pg_isready
             --health-interval 10s
             --health-timeout 5s
             --health-retries 5
       strategy:
         fail-fast: false
         matrix:
           include:
             - elixir: '1.17.3'
               otp: '27.0'
               sigra: 'off'
             - elixir: '1.18.0'
               otp: '27.0'
               sigra: 'off'
             - elixir: '1.18.0'
               otp: '28.0'
               sigra: 'off'
             - elixir: '1.18.0'
               otp: '27.0'
               sigra: 'on'
       env:
         MIX_ENV: test
         PGUSER: postgres
         PGPASSWORD: postgres
         PGHOST: localhost
         ACCRUE_CI_SIGRA: ${{ matrix.sigra == 'on' && '1' || '' }}
       steps:
         - uses: actions/checkout@v4
         - uses: erlef/setup-beam@v1
           with:
             otp-version: ${{ matrix.otp }}
             elixir-version: ${{ matrix.elixir }}
         - name: Restore deps cache
           uses: actions/cache@v4
           with:
             path: accrue/deps
             key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ matrix.sigra }}-deps-${{ hashFiles('accrue/mix.lock') }}
         - name: Restore PLT cache
           id: plt_cache
           uses: actions/cache/restore@v4
           with:
             path: accrue/priv/plts
             key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ matrix.sigra }}-plt-${{ hashFiles('accrue/mix.lock') }}
         - run: cd accrue && mix deps.get
         - run: cd accrue && mix format --check-formatted
         - run: cd accrue && mix compile --warnings-as-errors
         - run: cd accrue && mix test --warnings-as-errors
         - run: cd accrue && mix credo --strict
         - name: Create PLTs
           if: steps.plt_cache.outputs.cache-hit != 'true'
           run: cd accrue && mix dialyzer --plt
         - name: Save PLT cache
           if: steps.plt_cache.outputs.cache-hit != 'true'
           uses: actions/cache/save@v4
           with:
             path: accrue/priv/plts
             key: ${{ runner.os }}-${{ matrix.otp }}-${{ matrix.elixir }}-${{ matrix.sigra }}-plt-${{ hashFiles('accrue/mix.lock') }}
         - run: cd accrue && mix dialyzer --format github
   ```

   Note: 1.17.3/OTP 27 and 1.18.0/OTP 27/28 combinations come from CLAUDE.md §CI Matrix. Exclude 1.17/OTP 28 (not supported). The sigra sub-matrix only runs ONE cell (`1.18.0 / OTP 27 / sigra=on`) to keep CI fast — the critical signal is "conditional compile works on at least one modern combination" rather than exhaustive coverage.

6. Run `bash scripts/ci/compile_matrix.sh` locally as the verify step. If `:sigra` is not available on the user's machine (no local path, not on Hex yet), the `with_sigra` branch will fail with `dependency not available` — that's acceptable; document in the task acceptance that either `sigra=off` succeeds alone OR the script runs both. The CI job is what actually enforces both.
  </action>
  <verify>
    <automated>cd /Users/jon/projects/accrue/accrue && mix compile --warnings-as-errors && mix test test/accrue/integrations/sigra_test.exs && test -x /Users/jon/projects/accrue/scripts/ci/compile_matrix.sh && test -f /Users/jon/projects/accrue/.github/workflows/ci.yml</automated>
  </verify>
  <acceptance_criteria>
    - `mix compile --warnings-as-errors` passes in the current (default, sigra=off) build
    - `test -f .github/workflows/ci.yml`
    - `grep -q "matrix:" .github/workflows/ci.yml`
    - `grep -q "sigra" .github/workflows/ci.yml`
    - `grep -q "actions/cache/restore" .github/workflows/ci.yml` (PLT split restore/save)
    - `grep -q "1.17" .github/workflows/ci.yml` (floor in matrix)
    - `test -x scripts/ci/compile_matrix.sh`
    - `grep -q "Code.ensure_loaded?(Sigra)" accrue/lib/accrue/integrations/sigra.ex`
    - `grep -q "@compile {:no_warn_undefined" accrue/lib/accrue/integrations/sigra.ex`
    - `mix test test/accrue/integrations/sigra_test.exs` passes
  </acceptance_criteria>
  <done>Success Criterion #5 is proven: mix compile --warnings-as-errors passes cleanly with the Sigra scaffold (without_sigra branch). CI workflow is in place to enforce both matrices on every PR. The with_sigra branch is validated in CI, not locally, since the sibling library may not yet be available on the dev machine.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| BEAM boot → prod environment | Must refuse to start with dev-only auth adapter |
| Accrue.Application supervisor children | Must not own host-lifecycle components |
| CI build artifacts → hex publish | Must not leak dev secrets or with-sigra-only code paths |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-FND-07 | Elevation of Privilege | Prod boot with Accrue.Auth.Default | mitigate | Accrue.Application.start/2 calls `Accrue.Auth.Default.boot_check!/0` before Supervisor.start_link. Plan 05 Task 3 tests the raise path; Plan 06 Task 1 tests that it's actually invoked from the Application boot sequence. |
| T-FND-08 | Tampering | Undefined Sigra symbols at compile time (without_sigra build) | mitigate | CLAUDE.md 4-pattern conditional compile + `@compile {:no_warn_undefined, ...}` silences compiler warnings so `--warnings-as-errors` passes in both matrices. CI enforces this on every PR. |
| T-FND-09 | Denial of Service | Host starting ChromicPDF/Oban twice (once by Accrue, once by host) | mitigate | Explicit ban in Accrue.Application (Task 1 test asserts no ChromicPDF/Oban/Finch references in application.ex). |
| T-OSS-01 | Information Disclosure | CI leaking secrets via Dialyzer output or deps cache | accept | Phase 1 CI only runs test-mode; no deploy secrets; PGUSER/PGPASSWORD are hardcoded as `postgres/postgres` for the service container. Real secrets land in Phase 9 release workflow. |
</threat_model>

<verification>
- `mix compile --warnings-as-errors && mix test` fully green (default without_sigra)
- `Accrue.Application` module exists, boots via `Application.ensure_all_started(:accrue)`, calls `boot_check!/0`
- Brand palette CSS has 7 `--accrue-*` variables
- `.github/workflows/ci.yml` and `scripts/ci/compile_matrix.sh` both exist and are syntactically valid (YAML parses, bash script is +x)
- The ROADMAP.md Phase 1 Success Criterion #5 is satisfied: conditional-compile pattern works
</verification>

<success_criteria>
After this plan:
1. Phase 1 is complete. All 23 requirement IDs are implemented across Plans 01-06.
2. CI catches any conditional-compile regression on every PR automatically.
3. Phase 2 can start immediately — the test harness, behaviours, and ledger are all in place and tested.
4. Phase 7 can later flip `:auth` config to `Accrue.Integrations.Sigra` without touching anything in Plan 05 or Plan 06.
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundations/01-06-SUMMARY.md`.
</output>
