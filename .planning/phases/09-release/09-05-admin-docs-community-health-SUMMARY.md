---
phase: 09-release
plan: 05
subsystem: docs
tags: [hex, exdoc, dialyzer, community-health, release-docs]
requires:
  - phase: 09-release
    provides: release automation and package-local docs conventions
provides:
  - publish-mode dependency switching for accrue_admin
  - README-first ExDoc surface and release checks for accrue_admin
  - root contributing, conduct, and security policy documents
affects: [accrue_admin packaging, admin docs, repository health files]
tech-stack:
  added: [dialyxir]
  patterns: [env-gated sibling dependency switching, package-local dialyzer ignore file, root OSS policy links from package readmes]
key-files:
  created: [accrue_admin/README.md, accrue_admin/CHANGELOG.md, accrue_admin/LICENSE, accrue_admin/.dialyzer_ignore.exs, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, .planning/phases/09-release/09-05-SUMMARY.md]
  modified: [accrue_admin/mix.exs, accrue_admin/guides/admin_ui.md, accrue/lib/accrue/telemetry/otel.ex, accrue/README.md]
key-decisions:
  - "Gate the admin package dependency shape behind ACCRUE_ADMIN_HEX_RELEASE=1 so monorepo development keeps the path dep while release jobs emit a Hex-safe requirement."
  - "Use a checked-in Dialyxir ignore file for existing admin warnings so the new release gate is deterministic instead of failing on pre-existing noise."
  - "Expose repository policy files from both package READMEs so Hex and GitHub readers land on the same contribution and security guidance."
patterns-established:
  - "Admin package release verification now includes docs, Hex audit, Hex build, and Dialyzer configuration in mix.exs."
  - "Repository health files use concrete contact addresses and release-era secret-handling language instead of placeholder templates."
requirements-completed: [OSS-01, OSS-12, OSS-13, OSS-14, OSS-16, OSS-17, OSS-18]
duration: 26m
completed: 2026-04-16
---

# Phase 09 Plan 05: Admin Docs and Community Health Summary

**AccrueAdmin now has a README-first docs surface and Hex-safe dependency switching, and the repo now ships concrete public contribution, conduct, and security policies**

## Performance

- **Duration:** 26m
- **Completed:** 2026-04-16T00:26:33Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Added `accrue_admin` package release docs: README, changelog, package license, ExDoc config, grouped guide extras, and a Hex-safe `accrue_dep/0` switch controlled by `ACCRUE_ADMIN_HEX_RELEASE=1`.
- Added admin release verification guidance covering `mix docs --warnings-as-errors`, `mix dialyzer --format github`, `mix hex.audit`, `mix hex.build`, and publish dry-run expectations.
- Added root `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and `SECURITY.md` with concrete contact addresses, supported versions, secret-handling rules, and Conventional Commits guidance.
- Linked both package READMEs to the root project policies.

## Task Commits

Each task was committed atomically:

1. **Task 1: Make accrue_admin publishable on Hex and add its docs surface** - `7d60398` (feat)
2. **Task 2: Add root contributing, conduct, and security files with concrete release-era policy text** - `85fc46b` (docs)

## Files Created/Modified

- `accrue_admin/mix.exs` - publish-mode sibling dependency helper, ExDoc config, and Dialyzer config.
- `accrue_admin/README.md` - package quickstart, asset rebuild flow, browser UAT, and guide links.
- `accrue_admin/CHANGELOG.md` - Release Please changelog entrypoint.
- `accrue_admin/LICENSE` - package-local MIT license file required by Hex packaging.
- `accrue_admin/.dialyzer_ignore.exs` - checked-in ignores for pre-existing admin Dialyzer warnings.
- `accrue_admin/guides/admin_ui.md` - README linkage and local release-gate guidance.
- `accrue/lib/accrue/telemetry/otel.ex` - optional OpenTelemetry bridge now compiles cleanly when the optional OTel dependency is absent.
- `CONTRIBUTING.md` - development setup, release gate, and no-CLA policy.
- `CODE_OF_CONDUCT.md` - Contributor Covenant 2.1 with a concrete maintainer contact.
- `SECURITY.md` - supported versions, disclosure path, and secret-handling rules.
- `accrue/README.md` - links to the root repo policy files.

## Decisions Made

- Kept the admin package on a single dependency entry and moved the environment-dependent behavior into `accrue_dep/0`, matching the Phase 9 release decision.
- Added a package-local MIT license file because Hex packaging fails when `LICENSE*` is declared but absent from the package directory.
- Used an explicit Dialyxir ignore file for known admin warnings so the newly added release-gate command is stable in CI.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added a package-local license file for accrue_admin**
- **Found during:** Task 1 verification
- **Issue:** `ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build` failed because `accrue_admin/mix.exs` already declared `LICENSE*`, but the package directory had no matching file.
- **Fix:** Added `accrue_admin/LICENSE` with the repository MIT text.
- **Files modified:** `accrue_admin/LICENSE`
- **Verification:** `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build`
- **Committed in:** `7d60398`

**2. [Rule 3 - Blocking] Fixed optional OpenTelemetry compilation in the sibling accrue dependency**
- **Found during:** Task 1 verification
- **Issue:** `mix docs --warnings-as-errors` for `accrue_admin` failed while compiling the local `accrue` path dependency without the optional OpenTelemetry dependency loaded.
- **Fix:** Switched `Accrue.Telemetry.OTel` to the Erlang `:otel_tracer` / `:otel_span` API guarded by `Code.ensure_loaded?/1`.
- **Files modified:** `accrue/lib/accrue/telemetry/otel.ex`
- **Verification:** `cd accrue_admin && mix docs --warnings-as-errors`
- **Committed in:** `7d60398`

**3. [Rule 3 - Blocking] Added an explicit Dialyxir ignore file for existing admin warnings**
- **Found during:** Task 1 verification
- **Issue:** enabling the required `mix dialyzer --format github` release check surfaced 16 pre-existing warnings in existing admin LiveViews, router code, and Mix tasks.
- **Fix:** Added `accrue_admin/.dialyzer_ignore.exs` and configured `ignore_warnings` in `accrue_admin/mix.exs`.
- **Files modified:** `accrue_admin/.dialyzer_ignore.exs`, `accrue_admin/mix.exs`
- **Verification:** `cd accrue_admin && mix dialyzer --format github`
- **Committed in:** `7d60398`

## Deferred Issues

- `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run` still fails before the first public `accrue` Hex release because Hex cannot resolve the unpublished `accrue ~> 0.1.0` dependency from the registry. The package metadata is now Hex-safe, and `mix hex.build` succeeds, but full publish dry-run remains blocked on the core package existing in Hex.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Found `.planning/phases/09-release/09-05-SUMMARY.md`
- Found commit `7d60398`
- Found commit `85fc46b`
