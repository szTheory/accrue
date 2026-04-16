---
phase: 09-release
plan: 06
subsystem: release-readiness
tags: [release-gate, hex, dialyzer, docs, runbook]
requires:
  - phase: 09-release
    provides: release automation, docs, and package metadata
provides:
  - final local release-gate evidence for accrue and accrue_admin
  - zero-baseline Dialyzer release posture for both packages
  - package-local MIT license for accrue
  - minimum GitHub/Hex secret setup runbook
  - final release-order checkpoint for accrue then accrue_admin
  - fixed core Hex package file list including runtime assets and guides
affects: [accrue packaging, accrue_admin packaging, release docs, community policy docs]
tech-stack:
  added: []
  patterns: [warnings-as-release-blockers, package-local license files, Hex auth as human release prerequisite]
key-files:
  created: [accrue/LICENSE, accrue/.formatter.exs, accrue_admin/.formatter.exs, accrue_admin/.credo.exs, .planning/phases/09-release/09-06-SUMMARY.md]
  modified: [RELEASING.md, SECURITY.md, CODE_OF_CONDUCT.md, accrue/README.md, accrue/mix.exs, accrue_admin/mix.exs, .gitignore]
  deleted: [accrue_admin/.dialyzer_ignore.exs]
key-decisions:
  - "Treat compile warnings, Credo findings, and Dialyzer warnings as hard release blockers; do not ship with a warning baseline."
  - "Use GitHub identity `szTheory` and private GitHub security advisories instead of non-owned accrue.dev contact addresses."
  - "Publish order is `accrue` then `accrue_admin`, because the admin Hex dependency resolves `accrue ~> 0.1.0` in release mode."
patterns-established:
  - "Core package file lists must include `priv` runtime assets and `guides` docs extras because installed consumers and HexDocs rely on them."
  - "Generated ExDoc output, Hex tarballs, crash dumps, and package-local PLTs are ignored release-check artifacts."
  - "Admin Dialyzer includes `:mix` in the PLT instead of suppressing Mix task warnings."
requirements-completed: [OSS-07, OSS-08, OSS-09, OSS-10, OSS-15, OSS-16, OSS-17, OSS-18]
duration: 96m
completed: 2026-04-16
---

# Phase 09 Plan 06: Release Readiness Summary

**Release readiness is green for source, docs, audits, and package builds; the remaining publish dry-run blockers are external Hex setup and first-publish ordering**

## Performance

- **Duration:** 96m
- **Completed:** 2026-04-16T01:38:00Z
- **Tasks:** 3
- **Files modified:** release docs/policies, package metadata, Dialyzer cleanup, test isolation, and generated-artifact ignores

## Accomplishments

- Ran the full `accrue` release gate with warnings-as-errors: format, compile, tests, Credo, Dialyzer, docs, `llms.txt`, and Hex audit.
- Ran the full `accrue_admin` release gate with warnings-as-errors: format, compile, tests, Credo, Dialyzer, docs, `llms.txt`, and Hex audit.
- Removed the checked-in admin Dialyzer ignore baseline and fixed the remaining admin warnings so `mix dialyzer --format github` reports `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`.
- Fixed core Dialyzer warnings rather than suppressing them, including unreachable branches, missing schema/exception types, transaction specs, webhook ingestion typing, Oban middleware typing, and Inspect implementation typing.
- Added `accrue/LICENSE` so the core Hex package includes the declared MIT license file.
- Added minimum GitHub Actions secret setup instructions for `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY`.
- Replaced non-owned `accrue.dev` contact addresses with GitHub-based maintainer/security reporting through `szTheory` and private GitHub security advisories.
- Confirmed the runbook release order is `accrue` then `accrue_admin`.
- Ignored generated docs, Hex tarballs, crash dumps, and package-local PLTs.

## Verification Results

- `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit && test -f doc/llms.txt`
  - Passed after Dialyzer and test-isolation fixes.
  - Tests: 1063 tests, 0 failures.
  - Credo: no issues.
  - Dialyzer: total errors 0.
  - Docs: generated `doc/llms.txt`.
  - Hex audit: no retired packages.
- `cd accrue_admin && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit && test -f doc/llms.txt`
  - Passed.
  - Tests: 73 tests, 0 failures.
  - Credo: no issues.
  - Dialyzer: total errors 0, skipped 0.
  - Docs: generated `doc/llms.txt`.
  - Hex audit: no retired packages.
- `test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md`
  - Passed.
- Workflow/runbook smoke check for `RELEASE_PLEASE_TOKEN`, `HEX_API_KEY`, Release Please outputs, `ACCRUE_ADMIN_HEX_RELEASE`, `Release-As: 1.0.0`, `same-day`, `llms.txt`, `szTheory`, and private GitHub security advisory wording
  - Passed.

## Hex Dry-Run Findings

- `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix docs --warnings-as-errors && mix hex.audit && mix hex.build && mix hex.publish --dry-run`
  - Package metadata and file collection now proceed, including the package-local `LICENSE`, `priv/...` runtime assets, and `guides/...` docs extras.
  - Stops because this machine has no authenticated Hex user: `No authenticated user found. Run mix hex.user auth`.
- `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build`
  - Passed and built `accrue_admin-0.1.0.tar`.
- `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.publish --dry-run`
  - Stops before publish dry-run because `accrue ~> 0.1.0` is not available from Hex yet.
  - This matches the required release order: publish `accrue` first, then `accrue_admin`.

## Human Release Checklist

Before a real release:

1. Add `RELEASE_PLEASE_TOKEN` under GitHub repository Actions secrets.
2. Add `HEX_API_KEY` under GitHub repository Actions secrets.
3. Confirm the Hex API key can publish both `accrue` and `accrue_admin`.
4. Publish `accrue` first.
5. Confirm `accrue` is available on Hex.
6. Publish `accrue_admin` with `ACCRUE_ADMIN_HEX_RELEASE=1`.

## Task Commits

09-06 final fixes are committed after this summary. Earlier Phase 09 plans were already committed:

1. `09-01` - `b3231b9`, `42b33ff`, `7e2aa6f`
2. `09-02` - `f676305`, `64dfbc2`, `500472c`
3. `09-03` - `6f308fa`, `173cfbd`, `a7696fe`
4. `09-04` - `7bb999d`, `fd1993e`, `82150c7`
5. `09-05` - `7d60398`, `85fc46b`, `b8078a7`

## Deviations from Plan

### Human Setup Blocker

`mix hex.publish --dry-run` cannot complete locally without Hex authentication. This is intentionally left as a human setup item because the user confirmed `HEX_API_KEY` is not configured yet.

### First-Publish Dependency Blocker

`accrue_admin` publish dry-run cannot resolve `accrue ~> 0.1.0` until `accrue` exists on Hex. The package build succeeds, and the runbook now explicitly documents `accrue` then `accrue_admin`.

### Warning Baseline Removed

Plan 09-05 introduced `accrue_admin/.dialyzer_ignore.exs` as a temporary deterministic gate. The user made warnings a hard release blocker, so 09-06 removed that baseline and fixed the warnings.

### Code Review Blocker Fixed

The mandatory code review found that `accrue/mix.exs` omitted `priv` and `guides` from `package.files`, which would publish an incomplete package. 09-06 updated the file list to `~w(lib priv guides mix.exs README* LICENSE* CHANGELOG*)`, reran `mix hex.build`, and confirmed the tarball includes installer templates, migrations, email/PDF templates, and guide extras.

## Deferred Issues

- Configure GitHub Actions secrets: `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY`.
- Authenticate Hex locally with `mix hex.user auth` only if local publish dry-runs need to be run outside CI.
- Run the real release only after `accrue` is published and visible on Hex.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- `accrue` release gate passed with warnings-as-errors.
- `accrue_admin` release gate passed with warnings-as-errors.
- `accrue_admin` Dialyzer reports zero warnings with no ignore file.
- `accrue` Hex build includes `priv` assets and `guides` extras, and publish dry-run reaches Hex authentication instead of package metadata failure.
- `accrue_admin` Hex build succeeds in `ACCRUE_ADMIN_HEX_RELEASE=1` mode.
- Code review report `.planning/phases/09-release/09-REVIEW.md` is clean after re-check.
- External publish blockers are recorded in this summary and `RELEASING.md`.
