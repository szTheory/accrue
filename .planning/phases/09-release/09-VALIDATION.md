---
phase: 09
slug: release
status: complete
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-15
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + package-local Mix tasks + GitHub Actions workflow validation |
| **Config file** | `accrue/mix.exs`, `accrue_admin/mix.exs`, `.github/workflows/*.yml`, `release-please-config.json`, `.release-please-manifest.json` |
| **Quick run command** | `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix docs --warnings-as-errors && mix hex.audit` or `cd accrue_admin && mix format --check-formatted && mix compile --warnings-as-errors && mix docs --warnings-as-errors && mix hex.audit` for package-local docs/audit work |
| **Full suite command** | `cd accrue && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit` plus `cd accrue_admin && mix format --check-formatted && mix compile --warnings-as-errors && mix test --warnings-as-errors && mix credo --strict && mix dialyzer --format github && mix docs --warnings-as-errors && mix hex.audit`, then workflow lint/smoke checks |
| **Estimated runtime** | ~20-45 minutes for full CI-equivalent suite, depending on Dialyzer PLT cache |

---

## Sampling Rate

- **After every task commit:** Run the narrowest affected package command set, at minimum `mix compile --warnings-as-errors` or `mix docs --warnings-as-errors` in the touched package.
- **After every plan wave:** Run the full release-gate command set for both packages where locally possible.
- **Before `$gsd-verify-work`:** Full suite must be green, Release Please config must be dry-reviewed, Hex publish must be dry-run, and all docs/community files must exist.
- **Max feedback latency:** 45 minutes for full suite; under 5 minutes for docs-only or workflow-file smoke checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | OSS-02, OSS-03, OSS-04, OSS-05, OSS-06 | T-09-CI | CI does not skip required package/matrix checks for either package, including admin Dialyzer and retired-package audit | workflow smoke + GitHub Actions | `rg -n "cd accrue && mix format --check-formatted|cd accrue && mix compile --warnings-as-errors|cd accrue && mix test --warnings-as-errors|cd accrue && mix credo --strict|cd accrue && mix dialyzer --format github|cd accrue && mix docs --warnings-as-errors|cd accrue && mix hex.audit|cd accrue_admin && mix format --check-formatted|cd accrue_admin && mix compile --warnings-as-errors|cd accrue_admin && mix test --warnings-as-errors|cd accrue_admin && mix credo --strict|cd accrue_admin && mix dialyzer --format github|cd accrue_admin && mix docs --warnings-as-errors|cd accrue_admin && mix hex.audit|opentelemetry|sigra" .github/workflows/ci.yml` | yes | green |
| 09-02-01 | 02 | 1 | OSS-07, OSS-08 | T-09-REL | Release PR automation uses least-privilege permissions and path-scoped package config | workflow smoke + real Release Please PRs | `test -f release-please-config.json && test -f .release-please-manifest.json && rg -n "googleapis/release-please-action@v4|release-type|path" .github/workflows/release-please.yml release-please-config.json` | yes | green |
| 09-02-02 | 02 | 1 | OSS-09, OSS-10 | T-09-HEX | Hex publish requires `HEX_API_KEY`, publishes `accrue` before `accrue_admin`, and documents same-day ordering | docs smoke + real Hex publish | `rg -n "HEX_API_KEY|mix hex.publish --yes|accrue_admin|accrue" .github/workflows/publish-hex.yml && rg -n "same-day|runbook|1.0.0" -g "*.md"` | yes | green |
| 09-03-01 | 03 | 1 | OSS-01, OSS-12, OSS-13, OSS-14 | T-09-COMMUNITY | Public repo files avoid secrets and provide disclosure/reporting paths | docs smoke | `test -f CONTRIBUTING.md && test -f CODE_OF_CONDUCT.md && test -f SECURITY.md && rg -n "Conventional Commits|Contributor Covenant|supported versions|report" CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md` | yes | green |
| 09-04-01 | 04 | 1 | OSS-15, OSS-16, OSS-17, OSS-18 | T-09-DOCS | Docs build cleanly and expose quickstart, guide set, API stability, deprecation policy, and `llms.txt` | docs build + published HexDocs check | `cd accrue && mix docs --warnings-as-errors && test -f doc/llms.txt` | yes | green |
| 09-04-02 | 04 | 1 | OSS-16, OSS-17, OSS-18 | T-09-DOCS | Admin package has README, guide, docs config, generated `llms.txt`, and release-grade verification hooks for Dialyzer and retired-package audit | docs build + published HexDocs check | `cd accrue_admin && mix docs --warnings-as-errors && mix dialyzer --format github && mix hex.audit && test -f doc/llms.txt` | yes | green |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [x] `.github/workflows/release-please.yml` — Release Please workflow.
- [x] `.github/workflows/publish-hex.yml` — automated Hex publish workflow.
- [x] `release-please-config.json` — monorepo package config.
- [x] `.release-please-manifest.json` — per-path version manifest.
- [x] `accrue/README.md` and `accrue_admin/README.md` — package quickstarts.
- [x] `accrue/CHANGELOG.md` and `accrue_admin/CHANGELOG.md` — release-managed changelogs.
- [x] `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` — repo health files.
- [x] `accrue_admin/mix.exs` docs config — admin ExDoc output and `llms.txt`.
- [x] `accrue_admin/mix.exs` Dialyxir dependency and `dialyzer: [plt_local_path: "priv/plts"]` config.
- [x] `with_opentelemetry` CI matrix coverage.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Release Please opens correct package release PRs | OSS-07, OSS-08 | Requires GitHub event behavior and repository token configuration | Completed via PR #3 (`accrue` 0.1.2) and PR #4 (`accrue_admin` 0.1.2). |
| Same-day Hex publication | OSS-09, OSS-10 | Real publish requires protected Hex credentials and release tags | Completed on 2026-04-16; Hex reports `accrue` 0.1.2 and `accrue_admin` 0.1.2. |
| Maintainer contact and security disclosure endpoints | OSS-13, OSS-14 | Requires project-owner values not discoverable from code | Completed before public release using GitHub-based project contact/security paths. |

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 45 minutes
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
