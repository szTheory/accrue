---
phase: 08-install-polish-testing
plan: 03
subsystem: installer
tags: [elixir, mix-task, phoenix-router, webhook, sigra, oban, fingerprints]

requires:
  - phase: 08-install-polish-testing
    provides: "08-01 Wave 0 installer/generator contracts and 08-02 installer core"
provides:
  - "Safe installer patch builders for router webhook, admin mount, auth adapter, test support, and Oban snippets"
  - "End-to-end mix accrue.install orchestration across Options, Project, Templates, Fingerprints, Patches, config docs, and readiness reporting"
  - "mix accrue.gen.handler generator with fingerprinted no-clobber behavior"
affects: [08-install-polish-testing, installer, webhooks, auth, testing]

tech-stack:
  added: []
  patterns:
    - "Installer host mutations go through Accrue.Install.Patches structured patch plans"
    - "Handler generation uses Accrue.Install.Fingerprints and skips user-edited files"

key-files:
  created:
    - accrue/lib/accrue/install/patches.ex
    - accrue/lib/mix/tasks/accrue.gen.handler.ex
  modified:
    - accrue/lib/accrue/install/project.ex
    - accrue/lib/mix/tasks/accrue.install.ex
    - accrue/priv/accrue/templates/install/billing_handler.ex.eex

key-decisions:
  - "Router install snippets are route-scoped around :accrue_webhook_raw_body and never add a global Plug.Parsers raw-body reader."
  - "Admin wiring uses AccrueAdmin.Router.accrue_admin/2 plus host auth notes instead of copying admin LiveView routes into host apps."
  - "mix accrue.gen.handler treats any unmarked existing handler as user-owned and skips it, even when --force is present."

patterns-established:
  - "Patch builders return structured entries with name, path, snippet, and apply callback so manual and apply modes share one source."
  - "Installer reports name all subsystems involved in a run: Project, Templates, Fingerprints, and Patches."

requirements-completed: [INST-03, INST-04, INST-06, INST-08, INST-09, INST-10, AUTH-04, AUTH-05]

duration: 7min
completed: 2026-04-15T21:51:44Z
---

# Phase 08 Plan 03: Host Wiring and Handler Generator Summary

**Route-scoped webhook install wiring, protected admin/auth snippets, redacted orchestration reports, and no-clobber handler generation**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-15T21:44:43Z
- **Completed:** 2026-04-15T21:51:44Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Added `Accrue.Install.Patches` with router, admin, Sigra/default auth, test-support, and Oban patch/manual snippet builders.
- Wired `mix accrue.install` through project discovery, config validation/docs, template rendering, fingerprinted writes, patch application, auth guidance, and Stripe readiness reporting.
- Added `mix accrue.gen.handler` with strict options, template rendering, generated-file fingerprints, and no-clobber behavior for edited handlers.

## Task Commits

1. **Task 1: Add router, webhook, admin, auth, test-support, and Oban patch builders** - `2c28421` (feat)
2. **Task 2: Wire `mix accrue.install` to all installer subsystems** - `3767ff3` (feat)
3. **Task 3: Implement `mix accrue.gen.handler`** - `8d46e60` (feat)

## Files Created/Modified

- `accrue/lib/accrue/install/patches.ex` - Structured patch builders and exact manual snippets for router/webhook/admin/auth/test-support/Oban wiring.
- `accrue/lib/accrue/install/project.ex` - Optional dependency discovery now honors explicit `--admin` and `--sigra` choices and tracks Oban presence.
- `accrue/lib/mix/tasks/accrue.install.ex` - Orchestrates Options, Project, Templates, Fingerprints, Patches, config docs/validation, redaction, and final reporting.
- `accrue/lib/mix/tasks/accrue.gen.handler.ex` - Generator for host webhook handler scaffolds using fingerprint no-clobber semantics.
- `accrue/priv/accrue/templates/install/billing_handler.ex.eex` - Handler template now implements the public callback with an explicit side-effect customization branch.

## Verification

- `cd accrue && mix test --only install_patches test/mix/tasks/accrue_install_test.exs test/accrue/install/sigra_detection_test.exs` passed: 4 tests, 0 failures.
- `cd accrue && mix test --only install_orchestration test/mix/tasks/accrue_install_test.exs test/accrue/install/sigra_detection_test.exs` passed: 2 tests, 0 failures.
- `cd accrue && mix test --only install_stripe_test_mode test/mix/tasks/accrue_install_test.exs` passed: 2 tests, 0 failures.
- `cd accrue && mix test test/mix/tasks/accrue_gen_handler_test.exs` passed: 2 tests, 0 failures.
- `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_gen_handler_test.exs test/accrue/install/sigra_detection_test.exs` passed: 13 tests, 0 failures.
- All plan grep acceptance checks passed.

The test runs still emit the pre-existing OpenTelemetry exporter warning about missing `opentelemetry_exporter`; it does not fail these installer tests.

## Decisions Made

- `Accrue.Install.Patches` owns both apply-mode and manual-mode snippets so the installer does not drift between what it writes and what it tells users to paste.
- Fallback auth config avoids mentioning `Accrue.Integrations.Sigra` inside host `config/config.exs` when Sigra is absent; Sigra/community guidance is printed in installer output instead.
- The handler generator uses stdout reporting to match the install task and the Wave 0 capture contracts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept absent-Sigra fallback config free of Sigra module references**
- **Found during:** Task 1
- **Issue:** The fallback auth snippet initially mentioned `Accrue.Integrations.Sigra` in a comment, violating the no-Sigra fallback test.
- **Fix:** Moved Sigra/community guidance to installer report output and left fallback config with `Accrue.Auth.Default` only.
- **Files modified:** `accrue/lib/accrue/install/patches.ex`, `accrue/lib/mix/tasks/accrue.install.ex`
- **Verification:** Task 1 install patch tests passed.
- **Committed in:** `2c28421`, `3767ff3`

**2. [Rule 2 - Missing Critical] Added explicit Sigra fallback/community guidance to dry-run orchestration**
- **Found during:** Task 2
- **Issue:** Sigra dry-run output showed Sigra wiring but did not also tell users about `Accrue.Auth.Default` or community adapter paths.
- **Fix:** Added auth guidance output for both Sigra-detected and fallback installs.
- **Files modified:** `accrue/lib/mix/tasks/accrue.install.ex`
- **Verification:** Task 2 orchestration tests passed.
- **Committed in:** `3767ff3`

**3. [Rule 1 - Bug] Reported handler generator no-clobber output to stdout**
- **Found during:** Task 3
- **Issue:** The generator used `Mix.shell().info/1`, which the existing Wave 0 capture contract did not observe under `Mix.Shell.Process`.
- **Fix:** Switched generator reporting to direct stdout, matching the install task.
- **Files modified:** `accrue/lib/mix/tasks/accrue.gen.handler.ex`
- **Verification:** Handler generator tests passed.
- **Committed in:** `8d46e60`

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical guidance)
**Impact on plan:** All fixes preserved the intended install/generator scope and tightened the security and no-clobber contracts.

## Known Stubs

None. The handler template is intentionally host-editable scaffold output, and it does not block the generator goal.

## Threat Flags

None beyond the planned trust boundaries. New security-relevant surfaces are covered by the plan threat model: route-scoped webhook parsing, protected admin mounting guidance, secret redaction, and no-clobber handler writes.

## User Setup Required

None.

## Next Phase Readiness

Plan 08-04 can build public `Accrue.Test` helpers on top of the installer’s test-support snippet and the existing Fake Processor contracts.

## Self-Check: PASSED

- Verified all created and modified files exist.
- Verified task commits `2c28421`, `3767ff3`, and `8d46e60` exist in git history.

---
*Phase: 08-install-polish-testing*
*Completed: 2026-04-15*
