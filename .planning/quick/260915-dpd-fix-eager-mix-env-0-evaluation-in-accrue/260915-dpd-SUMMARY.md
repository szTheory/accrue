---
phase: quick-260915-dpd
plan: 01
subsystem: auth
tags: [elixir, otp-release, mix-env, config, boot]

requires: []
provides:
  - "Accrue.Env — canonical internal resolver for the build-tool environment lookup"
  - "Release-shaped regression test proving Accrue's auth boot path survives without the build-tool application"
affects: [accrue-auth, accrue-application, accrue-config, accrue-release-packaging]

actuals:
  tokens: 3200
  tasks: 3
  commits: 3
plan_head_before: 20f6695fdb08867f34e3fb59fb2e2c4776e6f47f

tech-stack:
  added: []
  patterns:
    - "Single internal seam (Accrue.Env) for any build-tool module reference in accrue/lib, enforced by a grep-based verify gate"
    - "Release-shaped regression testing via a child OS process with :code.del_path/1 removing a module from the code path, proving release behavior without a real release build"

key-files:
  created:
    - accrue/lib/accrue/env.ex
    - accrue/test/accrue/env_test.exs
    - accrue/test/fixtures/release_boot_probe.exs
    - accrue/test/accrue/release_boot_regression_test.exs
  modified:
    - accrue/lib/accrue/auth/default.ex
    - accrue/lib/accrue/auth/mock.ex
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/application.ex

key-decisions:
  - "Accrue.Env.current/0 uses Application.fetch_env/2 (not the default-argument form of get_env/3) so the build-tool fallback is only ever evaluated when :env is genuinely unset"
  - "Accrue.Env.mix_env/0 (config.ex/application.ex's collapsed safe_mix_env/0) intentionally does NOT consult config :accrue, :env — kept semantically distinct from current/0 per the plan's locked design decision, to avoid changing observable warning behavior in hosts that set :env"
  - "Moved the Accrue.Auth.Default moduledoc prose fix (originally scoped to Task 3) into the Task 2 commit, because Task 2's own verify command greps accrue/lib for any remaining Mix.env reference outside env.ex, and the stale doc-comment quote in default.ex would otherwise fail that grep before Task 3 ran"

patterns-established:
  - "Any future accrue/lib reference to the build-tool module must route through Accrue.Env; the grep gate `grep -rl --include='*.ex' 'Mix.env' accrue/lib` (only env.ex expected) is the standing check"

requirements-completed: [QT-260915-DPD]

coverage:
  - id: D1
    description: "Accrue.Env.current/0 and mix_env/0 exist with correct precedence (configured :env wins; fallback only when unset; fallback never raises)"
    requirement: "QT-260915-DPD"
    verification:
      - kind: unit
        ref: "accrue/test/accrue/env_test.exs#Accrue.EnvTest"
        status: pass
    human_judgment: false
  - id: D2
    description: "All six eager auth call sites and both private safe_mix_env/0 duplicates route through Accrue.Env; a release-shaped test proves the auth boot path no longer raises UndefinedFunctionError with the build-tool module absent, and still raises the intended Accrue.ConfigError refuse-to-boot guard"
    requirement: "QT-260915-DPD"
    verification:
      - kind: integration
        ref: "accrue/test/accrue/release_boot_regression_test.exs#auth boot path survives with the build-tool module undefined"
        status: pass
      - kind: unit
        ref: "accrue/test/accrue/auth/mock_test.exs, accrue/test/accrue/application_test.exs, accrue/test/accrue/application_boot_guards_test.exs, accrue/test/accrue/config_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "No remaining source file under accrue/lib other than env.ex references the build-tool module; stale moduledoc prose corrected; full accrue package gate (format, strict Credo, warnings-as-errors, full test suite) is green"
    requirement: "QT-260915-DPD"
    verification:
      - kind: other
        ref: "grep -rl --include='*.ex' 'Mix.env' accrue/lib -> only accrue/lib/accrue/env.ex"
        status: pass
      - kind: integration
        ref: "cd accrue && mix test.all"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-15
status: complete
---

# Quick Task 260915-dpd: Fix Eager `Mix.env()` Evaluation in Accrue Summary

**Replaced the release-breaking eager build-tool environment lookup in `accrue`'s auth boot path with a single canonical `Accrue.Env` resolver, proven by a child-process regression test that removes the build-tool module from the code path.**

## Performance

- **Duration:** 4 min (first commit 09:56:01, last 09:59:51)
- **Started:** 2026-09-15T13:56:01Z
- **Completed:** 2026-09-15T13:59:51Z
- **Tasks:** 3 completed
- **Files modified:** 8

## Accomplishments
- Added `Accrue.Env` (`current/0`, `mix_env/0`) as the sole seam in `accrue/lib` that may reference the build-tool module, with precedence unit tests.
- Converted all six eager `Application.get_env(:accrue, :env, Mix.env())` call sites in `Accrue.Auth.Default` and `Accrue.Auth.Mock` to `Accrue.Env.current/0`, and collapsed the two byte-identical private `safe_mix_env/0` helpers in `config.ex` and `application.ex` to delegate to `Accrue.Env.mix_env/0` (preserving their distinct "does not consult `:accrue, :env`" semantics).
- Added a deterministic, release-shaped regression test (`test/accrue/release_boot_regression_test.exs` + `test/fixtures/release_boot_probe.exs`) that spawns a child `elixir` process with the build-tool module removed from the code path via `:code.del_path/1`, and observed it **fail red** against the unconverted code with the exact defect described in the adopter report before converting the call sites.
- Corrected the stale `Accrue.Auth.Default` moduledoc prose that quoted the old eager lookup verbatim.
- Ran the full package gate (`mix test.all`: format check, `credo --strict`, warnings-as-errors compile, full test suite) green with 0 failures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add canonical Accrue.Env resolver with precedence unit tests** - `2de4389b` (feat)
2. **Task 2: Prove the release-shaped crash, then convert all call sites** - `9eae363a` (fix) — includes the Task 3 moduledoc prose fix, moved here (see Deviations)
3. **Task 3: Correct stale prose and green the full accrue package** - `173607d9` (style) — the only remaining change was `mix format`'s reflow of a long `IO.puts` call in the new fixture

_Plan metadata commit intentionally NOT created here per the orchestrator's docs-commit instruction — the orchestrator handles the docs commit in a later step._

## Files Created/Modified
- `accrue/lib/accrue/env.ex` - Canonical `Accrue.Env` resolver (`current/0`, `mix_env/0`)
- `accrue/test/accrue/env_test.exs` - Precedence unit tests for `Accrue.Env`
- `accrue/test/fixtures/release_boot_probe.exs` - Standalone script run as a child OS process; removes the build-tool module from the code path and exercises the full auth surface
- `accrue/test/accrue/release_boot_regression_test.exs` - Spawns the probe, asserts exit 0 and `ALL_OK`
- `accrue/lib/accrue/auth/default.ex` - Six call sites converted to `Accrue.Env.current()`; moduledoc corrected
- `accrue/lib/accrue/auth/mock.ex` - `ensure_test_env!/0` converted to `Accrue.Env.current()`
- `accrue/lib/accrue/config.ex` - `safe_mix_env/0` collapsed to delegate to `Accrue.Env.mix_env()`
- `accrue/lib/accrue/application.ex` - `safe_mix_env/0` collapsed to delegate to `Accrue.Env.mix_env()`

## Decisions Made
- Used `Application.fetch_env/2` in `Accrue.Env.current/0` instead of the default-argument form of `Application.get_env/3` — the exact defect being fixed, since default arguments are evaluated eagerly before the call regardless of whether the configured value is present.
- Kept `Accrue.Env.mix_env/0` deliberately config-unaware (matches the plan's locked design decision) so `config.ex`/`application.ex` callers retain their existing "build-tool only, no config lookup" behavior.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Moved the Task 3 moduledoc prose fix into Task 2's commit**
- **Found during:** Task 2, running its own `<verify>` command
- **Issue:** Task 2's verify command includes `grep -rl --include='*.ex' 'Mix\.env' lib | grep -v env.ex`, expecting zero matches. The plan assigned the `Accrue.Auth.Default` moduledoc prose fix (which quotes `Application.get_env(:accrue, :env, Mix.env())` verbatim at line 24) to Task 3, but that left Task 2's own verify command failing after the call-site conversion, because the doc comment still contained the literal string.
- **Fix:** Rewrote the "Test seam" moduledoc paragraph now, in Task 2, using exactly the wording Task 3's `<action>` specified (describes `boot_check!/0` reading the environment through `Accrue.Env.current/0`, and explains the resolver never evaluates the build tool when `:env` is configured and never raises when it's absent). Task 3 then had no remaining prose work for this file — verified via a fresh grep of `accrue/guides`, `guides`, and `accrue/README.md` that found no other stale prose, and ran the full `mix test.all` gate.
- **Files modified:** `accrue/lib/accrue/auth/default.ex`
- **Verification:** `grep -rl --include='*.ex' 'Mix[.]env' accrue/lib` returns only `accrue/lib/accrue/env.ex` after this fix; the full Task 2 verify command suite (66 tests) passes.
- **Committed in:** `9eae363a` (Task 2 commit)

**2. [Rule 3 - Blocking] `mix format` reflow of the probe fixture**
- **Found during:** Task 3, running `mix test.all`
- **Issue:** `mix format --check-formatted` (the first step of the `test.all` alias) failed because the new `test/fixtures/release_boot_probe.exs` had one `IO.puts(:stderr, "...")` call exceeding the formatter's line-length preference.
- **Fix:** Ran `mix format test/fixtures/release_boot_probe.exs`; no behavior change, purely a reflow.
- **Files modified:** `accrue/test/fixtures/release_boot_probe.exs`
- **Verification:** `mix test.all` (format, strict Credo, warnings-as-errors compile, full suite) subsequently passes with 0 failures.
- **Committed in:** `173607d9` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking issues that would otherwise have failed the plan's own verify commands)
**Impact on plan:** No scope creep. Both fixes were required for the plan's own verify commands to pass as written; the moduledoc content that landed matches Task 3's specified wording exactly, just one commit earlier than the plan's task numbering implied.

## Issues Encountered

**RED observation (Task 2, TDD requirement):** Before converting the auth call sites, ran the release-shaped regression test against the unconverted `default.ex`/`mock.ex` and observed it fail exactly as predicted:

```
1) test auth boot path survives with the build-tool module undefined (Accrue.ReleaseBootRegressionTest)
   test/accrue/release_boot_regression_test.exs:20
   release boot probe exited 1 (expected 0). Captured output:
   MARKER_MIX_UNDEFINED_OK
   MARKER_ENV_MIX_ENV_OK
   MARKER_ENV_CURRENT_UNSET_OK
   ** (UndefinedFunctionError) function Mix.env/0 is undefined (module Mix is not available). Make sure the module name is correct and has been specified in full (or that an alias has been defined)
       Mix.env()
       lib/accrue/auth/default.ex:47: Accrue.Auth.Default.boot_check!/0
       test/fixtures/release_boot_probe.exs:40: (file)
```

This confirms: (a) the probe genuinely removes the build-tool module (the first three markers print, proving `Accrue.Env.mix_env/0` and `current/0` — already converted in Task 1 — work fine against an absent build tool), and (b) the crash originates from the still-unconverted `default.ex:47` exactly as the adopter report described, not from some other cause. After the call-site conversion, the same test passes with `ALL_OK`.

**No pre-existing unrelated failures observed.** `mix test.all` ran the full suite (2060 tests + 70 properties, 11 excluded) with 0 failures on this run; the repo's documented known-flaky PDF test did not reproduce in this run and was not touched.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- No follow-on work required by this task. The `accrue` package's release-boot-time environment lookup is now safe for OTP releases; the downstream adopter's workaround (shipping the build-tool application into a production release) is no longer necessary, though this task did not modify any docs telling adopters to remove it (no such doc was found to reference).
- The grep-based invariant (`only env.ex may reference the build-tool module in accrue/lib`) is not wired into CI as a standing check beyond this task's manual verification — a future hardening phase could add it as a Credo custom check or a CI grep step if repeat regressions become a concern.

## Self-Check: PASSED

- FOUND: accrue/lib/accrue/env.ex
- FOUND: accrue/test/accrue/env_test.exs
- FOUND: accrue/test/fixtures/release_boot_probe.exs
- FOUND: accrue/test/accrue/release_boot_regression_test.exs
- FOUND commit: 2de4389b
- FOUND commit: 9eae363a
- FOUND commit: 173607d9

---
*Phase: quick-260915-dpd*
*Completed: 2026-09-15*
