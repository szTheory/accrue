---
phase: 09-release
verified: 2026-04-16T01:45:29Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
---

# Phase 09: Release Verification Report

**Phase Goal:** `accrue` v1.0.0 and `accrue_admin` v1.0.0 ship same-day to Hex via automated Release Please, with a GitHub Actions matrix CI enforcing format, warnings-as-errors, Credo strict, Dialyzer, ExDoc, and hex.audit; a full ExDoc guide set (quickstart, config, testing, Sigra integration, custom processors, custom PDF adapter, brand customization, admin UI, webhook gotchas, upgrade); MIT license; CONTRIBUTING, CODE_OF_CONDUCT (Contributor Covenant 2.1), and SECURITY.md.
**Verified:** 2026-04-16T01:45:29Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Both packages fail release CI on format drift, warnings, failing tests, Credo strict issues, Dialyzer warnings, ExDoc warnings, or retired Hex packages. | ✓ VERIFIED | `.github/workflows/ci.yml` runs `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix credo --strict`, `mix dialyzer --format github`, `mix docs --warnings-as-errors`, and `mix hex.audit` for both packages at lines 110-148 and 167-204. |
| 2 | The release gate runs across the supported Elixir and OTP matrix. | ✓ VERIFIED | Matrix includes `1.17.3/27.0`, `1.18.0/27.0`, and `1.18.0/28.0` at `.github/workflows/ci.yml:39-71`. |
| 3 | Conditional compilation is exercised with and without Sigra and with and without OpenTelemetry. | ✓ VERIFIED | Matrix carries `sigra` and `opentelemetry` axes plus exported env vars `ACCRUE_CI_SIGRA` and `ACCRUE_CI_OPENTELEMETRY` at `.github/workflows/ci.yml:57-80`. |
| 4 | Conventional Commits on `main` can open per-package release PRs for both packages. | ✓ VERIFIED | `release-please.yml` runs on pushes to `main`, uses `googleapis/release-please-action@v4`, and points at manifest config files at `.github/workflows/release-please.yml:3-43`; config defines both `accrue` and `accrue_admin` packages in `release-please-config.json:5-18`. |
| 5 | Hex publication is gated on real Release Please outputs inside one workflow/job graph and happens in same-day order. | ✓ VERIFIED | Automated publish jobs depend on `needs.release.outputs.*`, publish `accrue` first, and gate `accrue_admin` on successful `publish-accrue` when both release together at `.github/workflows/release-please.yml:45-101`. |
| 6 | Release automation documents the exact bootstrap path to first public v1.0.0 for both packages. | ✓ VERIFIED | `RELEASING.md` documents the numbered same-day bootstrap, `Release-As: 1.0.0`, release PR review checks, secrets, publish order, and manual fallback at `RELEASING.md:5-68`. |
| 7 | The core package has a copy-pasteable quickstart and release-managed changelog surface. | ✓ VERIFIED | `accrue/README.md:5-26` gives the quickstart with `{:accrue, "~> 1.0.0"}`; `accrue/CHANGELOG.md` exists and is wired in `release-please-config.json:6-10`. |
| 8 | The core ExDoc site exposes README, guides, and generated `llms.txt`. | ✓ VERIFIED | `accrue/mix.exs:126-133` wires `README.md` plus all `guides/*.md` as ExDoc extras; `accrue/doc/llms.txt` exists with 329 lines. |
| 9 | Public API stability and deprecation expectations are stated in package docs. | ✓ VERIFIED | `accrue/README.md:35-39` names the supported facade surface and points removals through the upgrade/deprecation cycle. |
| 10 | The full guide set exists and is linked from package docs. | ✓ VERIFIED | Core README links quickstart, configuration, testing, Sigra, custom processors, custom PDF adapter, branding, webhook gotchas, and upgrade at `accrue/README.md:41-51`; all guide files exist and are substantive; admin guide exists at `accrue_admin/guides/admin_ui.md`. |
| 11 | The admin package can publish to Hex without retaining a local path dependency on `../accrue` when `ACCRUE_ADMIN_HEX_RELEASE=1` is set, and it ships README/changelog/docs/llms surfaces. | ✓ VERIFIED | `accrue_admin/mix.exs:59-74` switches from local path to `{:accrue, "~> #{@version}"}` when `ACCRUE_ADMIN_HEX_RELEASE=1`; `accrue_admin/README.md:5-37` documents the release dependency; `accrue_admin/doc/llms.txt` exists with 86 lines. |
| 12 | The repository root exposes MIT license, CONTRIBUTING, CODE_OF_CONDUCT, and SECURITY with non-placeholder content. | ✓ VERIFIED | `LICENSE` exists; `CONTRIBUTING.md:30-69` covers Conventional Commits and no CLA; `CODE_OF_CONDUCT.md:1-124` is Contributor Covenant 2.1; `SECURITY.md:14-38` defines private disclosure and secret handling. |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.github/workflows/ci.yml` | Unified release gate workflow for both packages | ✓ VERIFIED | `gsd-tools verify artifacts` passed; substantive matrix + full gate commands present. |
| `.github/workflows/release-please.yml` | Release Please workflow with least privilege and publish wiring | ✓ VERIFIED | `push`/`workflow_dispatch` only, least-privilege permissions, release outputs exported to publish jobs. |
| `.github/workflows/publish-hex.yml` | Manual recovery publish workflow | ✓ VERIFIED | `workflow_dispatch` with explicit `package`, `tag`, `release_version` inputs. |
| `release-please-config.json` | Root manifest package config | ✓ VERIFIED | Two package entries with `release-type: "elixir"` and package-local changelogs. |
| `.release-please-manifest.json` | Version manifest | ✓ VERIFIED | Seeds both packages from `0.1.0`. |
| `RELEASING.md` | Same-day v1.0.0 runbook | ✓ VERIFIED | Bootstrap, secret setup, automated path, and manual fallback documented. |
| `accrue/mix.exs` | Core package docs + packaging config | ✓ VERIFIED | ExDoc extras use `README.md` plus all guides; package ships `priv` and `guides`. |
| `accrue_admin/mix.exs` | Admin package release-safe dep + docs config | ✓ VERIFIED | Release env switch removes local path dependency; docs extras include README + admin guide. |
| `accrue/README.md` | Core quickstart and guide index | ✓ VERIFIED | Quickstart, API stability section, and guide links present. |
| `accrue_admin/README.md` | Admin quickstart and release notes | ✓ VERIFIED | Quickstart, host setup, release dependency note, and guide link present. |
| `CONTRIBUTING.md` | Contributing policy | ✓ VERIFIED | Non-placeholder, includes Conventional Commits and no CLA. |
| `CODE_OF_CONDUCT.md` | Conduct policy | ✓ VERIFIED | Full Contributor Covenant 2.1 text. |
| `SECURITY.md` | Vulnerability disclosure policy | ✓ VERIFIED | Private disclosure flow and secret handling present. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `.github/workflows/ci.yml` | `accrue/mix.exs` | core package release commands | ✓ WIRED | `gsd-tools verify key-links` passed; docs and release gate commands present. |
| `.github/workflows/ci.yml` | `accrue_admin/mix.exs` | admin package release commands | ✓ WIRED | `gsd-tools verify key-links` passed; admin release gate commands present. |
| `.github/workflows/release-please.yml` | `release-please-config.json` | `config-file` input | ✓ WIRED | `config-file: release-please-config.json` at `.github/workflows/release-please.yml:40-43`. |
| `.github/workflows/release-please.yml` | same workflow publish jobs | release outputs into publish jobs | ✓ WIRED | `needs.release.outputs.accrue_release_created` and `needs.release.outputs.accrue_admin_release_created` gate publish jobs at `.github/workflows/release-please.yml:45-101`. |
| `.github/workflows/publish-hex.yml` | `RELEASING.md` | manual recovery inputs | ✓ WIRED | Workflow inputs match runbook fallback at `.github/workflows/publish-hex.yml:3-20` and `RELEASING.md:52-68`. |
| `accrue/mix.exs` | `accrue/README.md` + guides | ExDoc extras | ✓ WIRED | `extras: ["README.md" | Path.wildcard("guides/*.md")]` at `accrue/mix.exs:126-133` covers `quickstart.md` and the rest of the guide set. |
| `accrue_admin/mix.exs` | publish-mode dependency docs | release dependency switch | ✓ WIRED | `ACCRUE_ADMIN_HEX_RELEASE` switch in `accrue_admin/mix.exs:68-74` matches README guidance at `accrue_admin/README.md:35-37`. |
| `accrue/mix.exs` | `doc/llms.txt` | `mix docs` output | ✓ WIRED (inference) | No explicit config line is required for ExDoc `llms.txt`; `mix docs --warnings-as-errors` is part of CI and `accrue/doc/llms.txt` plus `accrue_admin/doc/llms.txt` exist. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `.github/workflows/ci.yml` | N/A | Static workflow config | N/A | Not applicable - no runtime data rendering |
| `.github/workflows/release-please.yml` | Release outputs | `steps.release.outputs[...]` from Release Please action | Yes | ✓ FLOWING |
| `accrue/mix.exs` | ExDoc extras glob | `Path.wildcard("guides/*.md")` | Yes | ✓ FLOWING |
| `accrue_admin/mix.exs` | `accrue_dep/0` | `System.get_env("ACCRUE_ADMIN_HEX_RELEASE")` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core package release artifact builds with docs/assets included | `cd accrue && mix hex.build` | Built `accrue-0.1.0.tar`; package listing included `guides/...`, `priv/...`, `README.md`, `LICENSE`, `CHANGELOG.md` | ✓ PASS |
| Admin package release artifact builds in Hex-release mode | `cd accrue_admin && ACCRUE_ADMIN_HEX_RELEASE=1 mix hex.build` | Built `accrue_admin-0.1.0.tar`; package listing included `guides/admin_ui.md`, `priv/static/...`, `README.md`, `LICENSE`, `CHANGELOG.md` | ✓ PASS |
| Generated AI reference docs exist for both packages | `test -f accrue/doc/llms.txt && test -f accrue_admin/doc/llms.txt` | Both files present | ✓ PASS |
| Real Hex dry-run publish path | Prior local phase evidence | `accrue` dry-run reached expected local Hex auth prompt; `accrue_admin` dry-run stopped only because `accrue` was not yet on Hex, matching required publish order | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| OSS-01 | 09-03, 09-05 | Monorepo with sibling Mix projects, per-package changelogs, shared workflows | ✓ SATISFIED | `accrue/` and `accrue_admin/` coexist; both `CHANGELOG.md` files exist; workflows are shared under `.github/workflows/`. |
| OSS-02 | 09-01 | GitHub Actions CI release checks | ✓ SATISFIED | `.github/workflows/ci.yml:110-148,167-204`. |
| OSS-03 | 09-01 | Elixir/OTP version matrix in CI | ✓ SATISFIED | `.github/workflows/ci.yml:39-71`. |
| OSS-04 | 09-01 | Dialyzer PLT caching by OS/OTP/Elixir/mix.lock | ✓ SATISFIED | Split restore/save PLT caches at `.github/workflows/ci.yml:122-139,179-195`. |
| OSS-05 | 09-01 | CI includes `with_sigra` and `without_sigra` | ✓ SATISFIED | Sigra matrix cell and env wiring at `.github/workflows/ci.yml:57-79`. |
| OSS-06 | 09-01 | CI includes `with_opentelemetry` and `without_opentelemetry` | ✓ SATISFIED | OpenTelemetry matrix cell and env wiring at `.github/workflows/ci.yml:66-80`. |
| OSS-07 | 09-02, 09-06 | Release Please + Conventional Commits automation | ✓ SATISFIED | `release-please.yml:3-43`; `CONTRIBUTING.md:30-40`. |
| OSS-08 | 09-02, 09-06 | Per-package Release Please configs | ✓ SATISFIED | `release-please-config.json:5-18`; `.release-please-manifest.json:1-4`. |
| OSS-09 | 09-02, 09-06 | Hex publishing workflow with API token secret | ✓ SATISFIED | Automated publish in `release-please.yml:45-101`; recovery workflow in `publish-hex.yml:22-77`; secrets documented in `RELEASING.md:24-32`. |
| OSS-10 | 09-02, 09-06 | Same-day v1.0 release of both packages | ✓ SATISFIED | Ordered publish + runbook steps at `release-please.yml:45-101` and `RELEASING.md:5-22`. |
| OSS-12 | 09-05 | CONTRIBUTING with PRs welcome, Conventional Commits, no CLA | ✓ SATISFIED | `CONTRIBUTING.md:1-69`. |
| OSS-13 | 09-05 | Contributor Covenant 2.1 | ✓ SATISFIED | `CODE_OF_CONDUCT.md:1-124`. |
| OSS-14 | 09-05 | SECURITY.md with disclosure process | ✓ SATISFIED | `SECURITY.md:14-38`. |
| OSS-15 | 09-03, 09-04, 09-06 | Public API stability guarantee + deprecation policy | ✓ SATISFIED | `accrue/README.md:35-39`; upgrade guide exists and is included in docs. |
| OSS-16 | 09-03, 09-04, 09-05, 09-06 | Full ExDoc guide set | ✓ SATISFIED | All listed guide files exist; core README and admin README link the package guide surfaces. |
| OSS-17 | 09-03, 09-05, 09-06 | README with 30-second quickstart | ✓ SATISFIED | `accrue/README.md:5-26`; `accrue_admin/README.md:5-31`. |
| OSS-18 | 09-03, 09-05, 09-06 | `llms.txt` auto-generated via ExDoc | ✓ SATISFIED | `accrue/doc/llms.txt` and `accrue_admin/doc/llms.txt` exist; docs builds are part of CI gate. |

No orphaned Phase 9 requirements were found. All IDs claimed by plan frontmatter are mapped in `.planning/REQUIREMENTS.md`, and all Phase 9 requirement IDs in `.planning/REQUIREMENTS.md` are claimed by at least one Phase 09 plan.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME/placeholder or empty-implementation markers found in release workflows, docs, or policy files scanned for Phase 09. | ℹ️ Info | No blocking anti-patterns in phase scope |

### Gaps Summary

No repo-side gaps were found against the Phase 09 roadmap contract or the plan frontmatter must-haves.

The external release work is also complete as of 2026-04-16. `RELEASE_PLEASE_TOKEN` and `HEX_API_KEY` were configured, Release Please opened and merged PR #3 for `accrue` 0.1.2 and PR #4 for `accrue_admin` 0.1.2, and both packages published successfully to Hex. Main CI, Browser UAT, and Release Please completed successfully after both merges. Annotation sweeps found no warnings or errors, only the expected Browser UAT notice. Published HexDocs for both packages were checked after the docs hotfix and now show `~> 0.1.2` snippets with internal guide links.

---

_Verified: 2026-04-16T01:45:29Z_
_Verifier: Claude (gsd-verifier)_
