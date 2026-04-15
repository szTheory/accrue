---
phase: 08-install-polish-testing
plan: 02
subsystem: installer
tags: [elixir, mix-task, igniter, eex, nimble-options, stripe, fingerprints]

requires:
  - phase: 08-install-polish-testing
    provides: "Wave 0 installer contract tests from 08-01"
provides:
  - "Executable mix accrue.install entrypoint with strict option parsing"
  - "Generated Billing facade, webhook handler, migration copy, and runtime Stripe config templates"
  - "Accrue-generated file fingerprint/no-clobber policy"
  - "Redacted Stripe test-mode readiness reporting"
affects: [08-install-polish-testing, installer, config, generated-files]

tech-stack:
  added: [igniter]
  patterns:
    - "Installer options live in Accrue.Install.Options and raise on unknown switches"
    - "Generated host files use # accrue:generated plus SHA-256 fingerprints"
    - "Install reports redact Stripe/API secret material before output"

key-files:
  created:
    - accrue/lib/accrue/install/options.ex
    - accrue/lib/accrue/install/project.ex
    - accrue/lib/accrue/install/templates.ex
    - accrue/lib/accrue/install/fingerprints.ex
    - accrue/lib/mix/tasks/accrue.install.ex
    - accrue/priv/accrue/templates/install/billing.ex.eex
    - accrue/priv/accrue/templates/install/billing_handler.ex.eex
    - accrue/priv/accrue/templates/install/runtime_config.exs.eex
    - accrue/priv/accrue/templates/install/revoke_accrue_events_writes.exs.eex
  modified:
    - accrue/mix.exs
    - accrue/mix.lock

key-decisions:
  - "Plan 08-02 uses the Wave 0 RED tests from 08-01 as the TDD red gate; this plan contributes the GREEN implementation commits."
  - "Generated-file overwrite safety is marker plus SHA-256 fingerprint based; edited generated files are skipped even when --force is present."
  - "Installer dry-run and readiness reports name env vars and key classes but redact raw sk_* and whsec_* values."

patterns-established:
  - "Host project discovery is isolated in Accrue.Install.Project before later router/admin/auth patching plans."
  - "EEx templates are rendered through Accrue.Install.Templates and written through Accrue.Install.Fingerprints."

requirements-completed: [INST-01, INST-02, INST-05, INST-07, INST-09, INST-10]

duration: 6min
completed: 2026-04-15T21:41:47Z
---

# Phase 08 Plan 02: Installer Core Summary

**Safe installer foundation with strict flags, fingerprinted generated files, and redacted Stripe test-mode runtime config**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-15T21:36:18Z
- **Completed:** 2026-04-15T21:41:47Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `:igniter` as the installer dependency and created `mix accrue.install` with strict parsing for all Phase 8 product-choice and automation flags.
- Added project discovery, config validation/docs access, EEx template rendering, migration copying, and generated-file no-clobber fingerprints.
- Added Billing facade, BillingHandler, runtime Stripe config, and REVOKE migration templates with redacted Stripe test-mode readiness reporting.

## Task Commits

1. **Task 1: Add installer dependency and strict option parsing** - `ccffbca` (feat)
2. **Task 2: Implement project discovery, config validation, templates, and fingerprints** - `1b153b8` (feat)

## Files Created/Modified

- `accrue/mix.exs` - Adds `{:igniter, "~> 0.7.9", runtime: false}`.
- `accrue/mix.lock` - Locks Igniter and transitive installer dependencies.
- `accrue/lib/mix/tasks/accrue.install.ex` - Installer entrypoint, loadpaths handling, report output, file writes, and config patching.
- `accrue/lib/accrue/install/options.ex` - Strict installer flag parser and normalized option struct.
- `accrue/lib/accrue/install/project.ex` - Phoenix host discovery for app module, router, repo, deps, migrations, runtime config, and billable schema.
- `accrue/lib/accrue/install/templates.ex` - EEx rendering, planned config validation, docs generation, and Stripe readiness reporting.
- `accrue/lib/accrue/install/fingerprints.ex` - `# accrue:generated` marker, SHA-256 fingerprinting, pristine/user-edited detection, write policy, and redaction helper.
- `accrue/priv/accrue/templates/install/billing.ex.eex` - Host-owned `MyApp.Billing` facade template.
- `accrue/priv/accrue/templates/install/billing_handler.ex.eex` - Host-owned webhook handler template.
- `accrue/priv/accrue/templates/install/runtime_config.exs.eex` - Runtime Stripe test-mode config snippet using env vars.
- `accrue/priv/accrue/templates/install/revoke_accrue_events_writes.exs.eex` - Host migration template for event-ledger write revocation.

## Decisions Made

- The existing Wave 0 tests from Plan 08-01 serve as the RED tests for these TDD tasks, so this plan only needed implementation commits.
- `--force` does not overwrite user-edited Accrue-generated files; it only permits overwriting unmarked files later if needed.
- Runtime config templates read secrets through `System.fetch_env!/1` and `System.get_env/1`; install reports only include env var names and redacted key classification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Tolerated unfetched fixture dependencies during loadpaths**
- **Found during:** Task 1
- **Issue:** `Mix.Task.run("loadpaths")` raised in temporary Phoenix-shaped fixtures because their deps were intentionally not fetched.
- **Fix:** Kept the required loadpaths call and continued only for the specific dependency-load failure so parser/report tests can execute.
- **Files modified:** `accrue/lib/mix/tasks/accrue.install.ex`
- **Verification:** `mix test --only install_options test/mix/tasks/accrue_install_test.exs`
- **Committed in:** `ccffbca`

**2. [Rule 2 - Missing Critical] Supplied required branding fields for planned config validation**
- **Found during:** Task 2
- **Issue:** `Accrue.Config.validate!/1` requires nested branding emails when validating a planned install config.
- **Fix:** Passed safe placeholder `from_email` and `support_email` values to install-time validation so installer config validation exercises the real schema.
- **Files modified:** `accrue/lib/accrue/install/templates.ex`
- **Verification:** `mix test --only install_templates test/mix/tasks/accrue_install_test.exs`
- **Committed in:** `1b153b8`

**3. [Rule 1 - Bug] Fixed generated module path handling**
- **Found during:** Task 2
- **Issue:** Template path generation attempted `Module.split/1` on string module names and initially produced the wrong host path shape.
- **Fix:** Split binary module names explicitly and map the full module path to `lib/my_app/billing.ex`.
- **Files modified:** `accrue/lib/accrue/install/templates.ex`
- **Verification:** `mix test --only install_templates test/mix/tasks/accrue_install_test.exs`
- **Committed in:** `1b153b8`

**Total deviations:** 3 auto-fixed (1 blocking issue, 1 missing critical validation input, 1 bug)
**Impact on plan:** All fixes were required for the planned installer behavior and stayed within the Phase 08-02 scope.

## Verification

- `cd accrue && mix test --only install_options test/mix/tasks/accrue_install_test.exs` passed: 1 test, 0 failures.
- `cd accrue && mix test --only install_templates test/mix/tasks/accrue_install_test.exs` passed: 2 tests, 0 failures.
- `cd accrue && mix test --only install_stripe_test_mode test/mix/tasks/accrue_install_test.exs` passed: 2 tests, 0 failures.
- All plan grep acceptance checks passed.

The test runs emit an existing OpenTelemetry exporter warning because `opentelemetry_exporter` is not installed; it did not fail the targeted tests.

## Known Stubs

None. The generated handler template includes a no-op example handler body as host-editable scaffold, not a runtime stub blocking this plan's installer-core goal.

## Threat Flags

None. New security-relevant installer surfaces are covered by the plan threat model: filesystem no-clobber and secret redaction.

## User Setup Required

None.

## Next Phase Readiness

Plan 08-03 can build on the installer entrypoint, discovery data, and fingerprinted writes to add router/admin/auth patching and full orchestration reporting.

## Self-Check: PASSED

- Verified all created installer modules and templates exist.
- Verified task commits `ccffbca` and `1b153b8` exist in git history.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
