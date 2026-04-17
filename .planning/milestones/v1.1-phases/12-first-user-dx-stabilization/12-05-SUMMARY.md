---
phase: 12-first-user-dx-stabilization
plan: 05
subsystem: accrue
tags:
  - dx
  - diagnostics
  - installer
dependency_graph:
  requires:
    - 12-03
  provides:
    - shared setup diagnostics across boot, runtime, and installer preflight
    - installer --check surface with stable DX codes
  affects:
    - accrue runtime boot failures
    - webhook misconfiguration responses
    - installer host-wiring checks
tech_stack:
  added:
    - Accrue.SetupDiagnostic
  patterns:
    - shared redacted diagnostic taxonomy
    - installer string-based preflight over host-owned router/config files
key_files:
  created:
    - accrue/lib/accrue/setup_diagnostic.ex
  modified:
    - accrue/lib/accrue/errors.ex
    - accrue/lib/accrue/config.ex
    - accrue/lib/accrue/repo.ex
    - accrue/lib/accrue/auth/default.ex
    - accrue/lib/accrue/webhook/plug.ex
    - accrue/lib/accrue/install/options.ex
    - accrue/lib/mix/tasks/accrue.install.ex
    - accrue/test/accrue/config_test.exs
    - accrue/test/accrue/auth_test.exs
    - accrue/test/accrue/webhook/plug_test.exs
    - accrue/test/mix/tasks/accrue_install_test.exs
    - accrue/test/mix/tasks/accrue_install_uat_test.exs
decisions:
  - Accrue.ConfigError now wraps Accrue.SetupDiagnostic for stable code-driven setup failures.
  - mix accrue.install --check reuses installer discovery and reports the same diagnostics used by boot/runtime paths.
metrics:
  duration: 5m
  completed_at: 2026-04-16T22:10:00Z
---

# Phase 12 Plan 05: Shared Setup Diagnostics Summary

Shared DX taxonomy for repo, migrations, webhook secrets, auth misuse, webhook raw-body failures, and installer preflight host-wiring checks.

## Completed Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Create the shared setup-diagnostic carrier and boot/runtime integrations | `47bc87c` | `accrue/lib/accrue/setup_diagnostic.ex`, `accrue/lib/accrue/errors.ex`, `accrue/lib/accrue/config.ex`, `accrue/lib/accrue/repo.ex`, `accrue/lib/accrue/auth/default.ex`, `accrue/lib/accrue/webhook/plug.ex`, `accrue/test/accrue/config_test.exs`, `accrue/test/accrue/auth_test.exs`, `accrue/test/accrue/webhook/plug_test.exs` |
| 2 | Add installer preflight wiring checks on the same diagnostic taxonomy | `d2f55a5` | `accrue/lib/accrue/install/options.ex`, `accrue/lib/mix/tasks/accrue.install.ex`, `accrue/test/mix/tasks/accrue_install_test.exs`, `accrue/test/mix/tasks/accrue_install_uat_test.exs` |

## What Changed

`Accrue.SetupDiagnostic` is now the shared carrier for first-hour setup failures. It defines the stable `ACCRUE-DX-*` codes, troubleshooting anchors, fix text, and redaction rules for `sk_*`, `whsec_*`, and `SECRET`/`KEY`-style assignments.

`Accrue.ConfigError` now formats wrapped diagnostics, `Accrue.Repo` emits the shared repo-config diagnostic, `Accrue.Config` emits shared diagnostics for missing webhook secrets and helper checks for pending migrations / Oban configuration, and `Accrue.Auth.Default` fails closed in production with the shared auth-adapter diagnostic.

`Accrue.Webhook.Plug` still returns generic `400` for bad signatures, but now returns a generic `500` for host setup mistakes like missing raw-body preservation while logging only the redacted shared diagnostic.

`mix accrue.install` gained a `--check` mode that inspects the discovered host router and config files for missing webhook mounts, missing raw-body reader wiring, browser/auth pipeline misuse, missing admin mount, missing host auth adapter wiring, and missing Oban configuration. The output prints the same codes and docs anchors used by the runtime diagnostics.

## Verification

- `cd accrue && mix test test/accrue/config_test.exs test/accrue/auth_test.exs test/accrue/webhook/plug_test.exs`
- `cd accrue && mix test test/mix/tasks/accrue_install_test.exs test/mix/tasks/accrue_install_uat_test.exs`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] Added `--check` parsing to installer options**
- **Found during:** Task 2
- **Issue:** `mix accrue.install --check` could not exist without updating `accrue/lib/accrue/install/options.ex`, which was not listed in the plan file set.
- **Fix:** Added the `:check` CLI flag and option struct field so the installer entrypoint can route into preflight mode.
- **Files modified:** `accrue/lib/accrue/install/options.ex`
- **Commit:** `d2f55a5`

## Auth Gates

None.

## Known Stubs

None.

## Self-Check: PASSED

- Found summary file: `.planning/phases/12-first-user-dx-stabilization/12-05-SUMMARY.md`
- Found commit: `47bc87c`
- Found commit: `d2f55a5`
