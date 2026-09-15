---
phase: quick-260915-dpd
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - accrue/lib/accrue/env.ex
  - accrue/lib/accrue/auth/default.ex
  - accrue/lib/accrue/auth/mock.ex
  - accrue/lib/accrue/config.ex
  - accrue/lib/accrue/application.ex
  - accrue/test/accrue/env_test.exs
  - accrue/test/fixtures/release_boot_probe.exs
  - accrue/test/accrue/release_boot_regression_test.exs
autonomous: true
requirements: [QT-260915-DPD]

estimate:
  tokens: 55000
  raw_tokens: 55000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "A host running `accrue` as an OTP release (no `:mix` application present) boots without an UndefinedFunctionError from the Accrue auth boot path."
    - "An explicitly configured `config :accrue, :env` value still wins over the build-tool fallback (unchanged precedence)."
    - "When no `:env` is configured and the build tool is absent, Accrue resolves `:prod` and the existing prod refuse-to-boot guard still raises `Accrue.ConfigError`."
    - "There is exactly one implementation of the safe environment lookup in the `accrue` package."
  artifacts:
    - accrue/lib/accrue/env.ex
    - accrue/test/accrue/env_test.exs
    - accrue/test/fixtures/release_boot_probe.exs
    - accrue/test/accrue/release_boot_regression_test.exs
  key_links:
    - "Accrue.Application.start/2 -> Accrue.Auth.Default.boot_check!/0 -> Accrue.Env.current/0"
    - "Accrue.Config safe env helper -> Accrue.Env.mix_env/0"
    - "Accrue.Application safe env helper -> Accrue.Env.mix_env/0"
---

<objective>
Remove the release-breaking eager build-tool environment lookup from the `accrue` package's auth
modules by promoting a single canonical environment resolver, and prove the fix with a
deterministic, release-shaped regression test.

Purpose: an adopter report (re-verified against HEAD in this planning session) shows that a host
deploying `accrue` as an OTP release dies at boot before the supervision tree starts, because the
default-argument form `Application.get_env(:accrue, :env, <build-tool env call>)` evaluates its
third argument eagerly and the build tool is not present in a release. The current downstream
workaround is to ship the build-tool application into a production release, which the host wants
to drop.

Output: `Accrue.Env` (canonical resolver), 6 converted auth call sites, 2 collapsed private
duplicates, a release-shaped regression test, and corrected prose.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@.planning/STATE.md
@accrue/lib/accrue/auth/default.ex
@accrue/lib/accrue/auth/mock.ex
@accrue/lib/accrue/config.ex
@accrue/lib/accrue/application.ex
</context>

<privacy_constraint>
The reporting party must not be identifiable anywhere in this repository. Do NOT write any project
name, company name, personal name, email address, repo name, or file path belonging to the
reporting host into code, comments, tests, test names, commit messages, CHANGELOG entries, or
planning documents. Refer to the source only as "an adopter report" or "a downstream host app",
and describe the workaround generically.
</privacy_constraint>

<live_observations>
Re-verified with grep at planning time (coordinates differ from the intake report — trust these):

- `accrue/lib/accrue/auth/default.ex` — eager sites at lines **47, 74, 83, 114, 127**; stale prose
  at line **24**.
- `accrue/lib/accrue/auth/mock.ex` — eager site at line **103** (inside `ensure_test_env!/0`).
- `accrue/lib/accrue/config.ex:1605-1611` — private `safe_mix_env/0` (try/rescue -> `:prod`).
- `accrue/lib/accrue/application.ex:237-243` — byte-identical private copy; call sites at
  lines **94** and **147**.

Semantics differ between the two existing shapes and MUST be preserved separately:
- Auth sites: configured `:accrue, :env` wins, build-tool env is the fallback.
- `safe_mix_env/0` (config/application): build-tool env only, `:prod` on failure — it does NOT
  consult `config :accrue, :env`. Collapsing these must not silently add config awareness.

Out of scope (verified NOT affected): `accrue_admin/lib/accrue_admin/router.ex:239` and the
`accrue_admin` dev modules evaluate their build-tool env inside macro bodies or at module-body
compile time, where the build tool is always present. Do not touch them. Do not touch
`scripts/ci/` or `.planning/phases/229-*`.

Toolchain note observed live: a bare `elixir`/`mix` invocation did not resolve a version manager
version in this environment. The executor must ensure `elixir --version` succeeds before running
any verify command (e.g. by exporting the version-manager variables for the pinned Elixir/OTP, or
running from a shell where the toolchain resolves). Do not modify the repo-root `.tool-versions`
file — it is untracked, in-flight, unrelated work.
</live_observations>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add canonical Accrue.Env resolver with precedence unit tests</name>
  <files>accrue/lib/accrue/env.ex, accrue/test/accrue/env_test.exs</files>
  <precondition>`elixir --version` succeeds in the shell used for verification (toolchain version resolves).</precondition>
  <behavior>
    - `Accrue.Env.current/0` returns the configured value when `config :accrue, :env` is set,
      without consulting the build tool at all.
    - `Accrue.Env.current/0` returns the build-tool environment when `:env` is unset.
    - `Accrue.Env.mix_env/0` returns the build-tool environment when it is available.
    - `Accrue.Env.mix_env/0` returns `:prod` instead of raising when the build tool is absent
      (rescue path; the release-shaped proof of this lands in Task 2).
    - Precedence is exactly today's: an explicitly configured value wins; the fallback is only
      consulted when `:env` is unset.
  </behavior>
  <action>
    Create `accrue/lib/accrue/env.ex` defining `Accrue.Env` with `@moduledoc false` (this is an
    internal seam, not public API — `lib/accrue/errors.ex` is the in-repo precedent for
    `@moduledoc false`).

    Define two functions, both `@doc false`, both with `@spec ... :: atom()`:

    1. `mix_env/0` — the canonical safe build-tool lookup. Body is exactly the behavior currently
       duplicated in `config.ex` and `application.ex`: call the build tool's env function inside a
       `try/rescue` that returns `:prod` on any raise. This is the ONLY place in `accrue/lib` that
       may reference the build-tool module.
       <!-- planner-discipline-allow: Mix.env -->
       Concretely: `try do Mix.env() rescue _ -> :prod end`.
    2. `current/0` — the config-aware resolver used by the auth modules. Implement it with
       `Application.fetch_env(:accrue, :env)`: on `{:ok, env}` return `env`; on `:error` return
       `mix_env()`. Do NOT use the default-argument form of `Application.get_env/3` — that is the
       exact defect being fixed, because arguments are evaluated before the call.

    Document in the moduledoc why the lazy form is mandatory: the build-tool application is not
    present in an OTP release, so any eager evaluation of its env function crashes the node at
    boot, before the supervision tree starts.

    Create `accrue/test/accrue/env_test.exs` (`async: false`, because it mutates application env)
    covering the behaviors above. Use `on_exit` to restore the original `:accrue, :env` value —
    capture it with `Application.fetch_env/2` and restore with `put_env`/`delete_env` so no state
    bleeds into other tests. Assert `current/0` returns `:staging` when `:env` is set to a value
    the build tool would never return (this proves config precedence), and assert `current/0`
    equals `mix_env()` when `:env` is deleted.
  </action>
  <verify>
    <automated>cd accrue && mix test test/accrue/env_test.exs</automated>
  </verify>
  <done>`Accrue.Env` exists with `current/0` and `mix_env/0`; `env_test.exs` passes; no other file changed yet.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Prove the release-shaped crash, then convert all call sites</name>
  <files>accrue/test/fixtures/release_boot_probe.exs, accrue/test/accrue/release_boot_regression_test.exs, accrue/lib/accrue/auth/default.ex, accrue/lib/accrue/auth/mock.ex, accrue/lib/accrue/config.ex, accrue/lib/accrue/application.ex</files>
  <behavior>
    In a VM where the build-tool module is genuinely undefined (release-shaped):
    - `Accrue.Env.mix_env/0` returns `:prod` without raising.
    - `Accrue.Env.current/0` returns `:prod` when `:env` is unset, without raising.
    - With `:env` set to `:dev`: `Accrue.Auth.Default.boot_check!/0` returns `:ok`;
      `current_user/1` returns the dev stub; `require_admin_plug/0` returns a pass-through
      function; `step_up_challenge/2` returns an auto-approval map; `verify_step_up/3` returns
      `:ok`; `Accrue.Auth.Mock.put_current_user/1` and `clear_current_user/0` do not raise.
    - With `:env` unset: `Accrue.Auth.Default.boot_check!/0` raises `Accrue.ConfigError` (the
      intended prod refuse-to-boot guard) and NOT `UndefinedFunctionError`. This distinction is
      the heart of the test — a crash from a missing build tool must never be mistaken for the
      intended config guard.
    - This test FAILS before the call-site conversion below and PASSES after.
  </behavior>
  <action>
    Write the test FIRST and observe it red against the unconverted auth modules, then convert.

    **(a) Probe fixture.** Create `accrue/test/fixtures/release_boot_probe.exs` — a standalone
    script run by a child OS process, not by ExUnit. `.exs` under `test/fixtures` is not picked up
    by `elixirc_paths` or the test glob, so it will not be compiled or auto-run. The script must:

    1. Make the build-tool module genuinely undefined, verified working in this environment:
       remove its ebin directory from the code path with `:code.del_path/1` (derive it via
       `:filename.dirname(:code.which(Mix))`), then `:code.purge/1`, `:code.delete/1`, `:code.purge/1`.
       Removing the path first is required — otherwise interactive code loading silently reloads
       the module on next call. Assert `Code.ensure_loaded?(Mix) == false` immediately after, and
       abort with a non-zero exit if it is still loaded, so the probe can never pass vacuously.
    2. Exercise every behavior listed above, using explicit `Application.put_env/delete_env` for
       the `:accrue, :env` cases.
    3. Print a distinct marker line per assertion group and a final `ALL_OK` line, then exit 0.
       Any raised error must escape (non-zero exit) — do not rescue broadly and swallow it. For
       the `Accrue.ConfigError` expectation, rescue only that struct and re-raise anything else.

    **(b) Regression test.** Create `accrue/test/accrue/release_boot_regression_test.exs`
    (`async: false`) that spawns the probe in a child OS process:
    - Resolve the executable with `System.find_executable("elixir")`; fail the test with an
      explicit message if it is `nil`.
    - Build code-path arguments from `Path.wildcard("_build/#{Mix.env()}/lib/*/ebin")` relative to
      `File.cwd!()`, expanded to absolute paths, each passed as a `-pa` argument pair.
    - Run `System.cmd(elixir, pa_args ++ [probe_path], stderr_to_stdout: true)`.
    - Assert the exit status is `0` and that stdout contains `ALL_OK`. On failure, include the
      captured output in the assertion message so a regression is diagnosable from CI logs alone.
    - Tag the test (e.g. `@moduletag :release_shape`) so it is greppable, but leave it in the
      default run — it is a merge-blocking gate per this project's executable-acceptance policy.

    Run this test now. It must fail with the child process crashing on an undefined build-tool
    function originating from the auth modules. Record that red observation in the SUMMARY.

    **(c) Convert the auth call sites.** In `accrue/lib/accrue/auth/default.ex`, replace the eager
    default-argument lookup at lines 47, 74, 83, 114, 127 with `Accrue.Env.current()`. In
    `accrue/lib/accrue/auth/mock.ex`, do the same at line 103 inside `ensure_test_env!/0`. Behavior
    at each site is otherwise unchanged — same branches, same returns, same raises.

    **(d) Collapse the duplicates.** In `accrue/lib/accrue/config.ex` (~line 1605) and
    `accrue/lib/accrue/application.ex` (~line 237), change each private helper body to delegate:
    `defp safe_mix_env, do: Accrue.Env.mix_env()`. Keep the private function name and arity so the
    existing call sites (`application.ex` lines 94 and 147, and the `config.ex` callers) are
    untouched. Do NOT switch these two helpers to the config-aware resolver — they intentionally
    do not consult `config :accrue, :env`, and changing that would alter observable warning
    behavior in hosts that set `:env`.

    After (c) and (d), no file under `accrue/lib` other than `env.ex` may reference the build-tool
    module.
  </action>
  <verify>
    <automated>cd accrue && mix test test/accrue/release_boot_regression_test.exs test/accrue/env_test.exs test/accrue/auth/mock_test.exs test/accrue/application_test.exs test/accrue/application_boot_guards_test.exs test/accrue/config_test.exs && test "$(grep -rl --include='*.ex' 'Mix\.env' lib | grep -v '^lib/accrue/env.ex$' | wc -l | tr -d ' ')" = "0"</automated>
  </verify>
  <done>Release-shaped regression test passes; all six auth sites and both private helpers route through `Accrue.Env`; `lib/accrue/env.ex` is the only lib file referencing the build-tool module.</done>
</task>

<task type="auto">
  <name>Task 3: Correct stale prose and green the full accrue package</name>
  <files>accrue/lib/accrue/auth/default.ex</files>
  <action>
    Update the `Accrue.Auth.Default` moduledoc "Test seam" paragraph at line 24, which currently
    quotes the eager default-argument lookup verbatim, to say that `boot_check!/0` reads the
    environment through the canonical internal resolver `Accrue.Env.current/0` and delegates to
    `do_boot_check!/1`. Add one sentence explaining that the resolver never evaluates the build
    tool when `:env` is configured and never raises when the build tool is absent, so the module is
    safe inside an OTP release.

    Then grep the repository for any remaining prose documenting the eager pattern — check
    `accrue/guides/`, `guides/`, `accrue/README.md`, and module docs under `accrue/lib` — and
    correct anything that describes the old shape. A planning-time sweep found no such prose
    outside `default.ex:24` and historical `.planning/` archives; do NOT rewrite `.planning/`
    archives or `.planning/research/` documents — they are historical records.

    Add a CHANGELOG entry under `accrue/CHANGELOG.md` only if the repo's release tooling expects
    hand-written entries; this repo uses Release Please with conventional commits, so prefer a
    `fix(accrue):` commit subject over a manual entry. The commit message must describe the defect
    generically with no reference to the reporting party.

    Run the package's aggregate gate (`mix test.all`) and fix any formatting, Credo (strict), or
    warnings-as-errors fallout introduced by the new module and tests. If a pre-existing unrelated
    failure appears (the PDF test is known-flaky in this repo), do not fix it here — report it in
    the SUMMARY and confirm it reproduces on a clean checkout.
  </action>
  <verify>
    <automated>cd accrue && mix test.all</automated>
  </verify>
  <done>Docstring describes the canonical resolver; `mix test.all` passes (format, strict Credo, warnings-as-errors compile, full suite) with no new failures.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| host release boot -> `Accrue.Application.start/2` | Host-controlled application environment is read before any supervisor starts; a raise here takes down the node. |
| host config -> `config :accrue, :env` | Host-supplied atom decides whether the dev-permissive auth adapter refuses to boot. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-dpd-01 | Denial of Service | `Accrue.Auth.Default.boot_check!/0` on the release boot path | high | mitigate | This is the reported defect. `Accrue.Env.mix_env/0` rescues to `:prod` and `current/0` never evaluates the build tool when `:env` is set; Task 2's release-shaped child-process test is the merge-blocking regression gate. |
| T-dpd-02 | Elevation of Privilege | `Accrue.Env.current/0` fallback value | high | mitigate | The absent-build-tool fallback is `:prod` (fail-closed), NOT a permissive env. A release with no `:env` configured therefore still trips the `Accrue.ConfigError` refuse-to-boot guard rather than silently serving the dev stub user with `role: :admin`. Task 2's probe asserts this branch raises `Accrue.ConfigError` explicitly. |
| T-dpd-03 | Elevation of Privilege | `Accrue.Auth.Mock.ensure_test_env!/0` | high | mitigate | Converting line 103 to the canonical resolver preserves the `:prod` refusal exactly; the probe exercises the Mock guard so the test-only adapter cannot become reachable in a release as a side effect of this change. |
| T-dpd-04 | Tampering | host-set `config :accrue, :env` | medium | accept | A host that sets `:env` to `:dev` in production already fully controls its own release config and could equally configure a permissive `:auth_adapter`. Precedence is unchanged by this plan; no new attack surface is introduced. |
| T-dpd-05 | Information Disclosure | child-process probe output in CI logs | low | accept | The probe prints only fixed marker strings and Accrue struct names — no secrets, no host identity, no customer data. |

No package-manager installs are introduced by this plan, so no package-legitimacy checkpoint applies.
</threat_model>

<verification>
- `cd accrue && mix test.all` passes.
- The release-shaped regression test fails when the auth call-site conversion is reverted (verified
  by the red observation recorded in Task 2).
- `grep -rl --include='*.ex' 'Mix\.env' accrue/lib` returns only `accrue/lib/accrue/env.ex`.
- No adopter-identifying string appears in any changed file or commit message.
</verification>

<success_criteria>
- Six auth call sites and two private helpers all route through `Accrue.Env`.
- Configured-`:env` precedence is byte-for-byte unchanged in behavior.
- An OTP release without the build-tool application boots the Accrue auth path without raising.
- A deterministic automated test — not a source-text assertion, not a human check — proves it.
</success_criteria>

<output>
Create `.planning/quick/260915-dpd-fix-eager-mix-env-0-evaluation-in-accrue/260915-dpd-SUMMARY.md` when done.
</output>
</content>
</invoke>
