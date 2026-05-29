---
phase: 152
slug: close-v1-46-closure-gaps-since-warnings-verification-hex-pub
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 152 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
>
> **This phase introduces no new code paths.** The existing verification suite IS
> the validation. No Wave 0 test scaffolding is required — the CI gate scripts and
> `mix test`/`compile`/`dialyzer`/`credo` across the trio already exist and are the
> closure gate ("Three Zeros", per Phase 151 §D-03).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.17+) — built in, no install |
| **Config file** | per-package `test/test_helper.exs` (3 packages: `accrue`, `accrue_admin`, `accrue_portal`) |
| **Quick run command** | `mix compile --warnings-as-errors` (in the edited package) |
| **Full suite command** | `mix test --seed 0` (per package) + `scripts/ci/verify_*.sh` suite |
| **Estimated runtime** | ~2–5 min per package for `mix test`; seconds per verify script |

---

## Sampling Rate

- **After every task commit:** Run `mix compile --warnings-as-errors` in the touched package
- **After every plan wave:** Run `mix test --seed 0` for the touched package(s)
- **Before release PR merge:** Full "Three Zeros" gate green across the trio (test + dialyzer + credo + all `verify_*.sh`)
- **Max feedback latency:** ~30s (compile) / ~5 min (full per-package test)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| @since-fix (dunning.ex) | 01 | 1 | D-02 | — | N/A | compile | `cd accrue && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| @since-fix (funnel_chart.ex) | 01 | 1 | D-02 | — | N/A | compile | `cd accrue_admin && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| docs honesty gate | 01 | 1 | D-03 | — | N/A | script | `bash scripts/ci/verify_package_docs.sh` | ✅ | ⬜ pending |
| Three Zeros — tests | 02 | 1 | D-03 | — | N/A | suite | `mix test --seed 0` (×3 packages) | ✅ | ⬜ pending |
| Three Zeros — dialyzer/credo | 02 | 1 | D-03 | — | N/A | suite | `mix dialyzer` / `mix credo --strict` (×3) | ✅ | ⬜ pending |
| Three Zeros — adoption matrix | 02 | 1 | D-03 | — | N/A | script | `bash scripts/ci/verify_adoption_proof_matrix.sh` | ✅ | ⬜ pending |
| release-notes contract | 03 | 2 | D-04 | — | N/A | script | `bash scripts/ci/verify_release_notes_contract.sh` | ✅ | ⬜ pending |
| release PR scope/manifest | 03 | 2 | D-01/D-04 | T-152-01 | secrets never echoed; signing keys from env only | script | `bash scripts/ci/verify_release_contract.sh` + `verify_release_manifest_alignment.sh` + `verify_release_pr_scope.sh` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Known flake:** `PdfTest` in `accrue` — dodge with `--seed 0` (per project memory). Not a phase regression.

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new test files, fixtures, or
framework installs are needed — this is mechanical closure work over existing code and the
existing CI gate. ExUnit, ExCoveralls (wired in 151-03), and the `scripts/ci/verify_*.sh`
suite are already in place.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Release Please opens a single linked PR bumping all 3 packages to 1.3.0 | D-01, D-04 | Triggered by GitHub Actions on merge to main; not locally runnable | After merging conventional-commit work, confirm the Release Please PR shows `@version` 1.2.0→1.3.0 in all 3 `mix.exs`, manifest 1.2.0→1.3.0, and CHANGELOG entries |
| `mix hex.publish` + linked tags created on PR merge | D-04 | External (Hex.pm + GitHub release); irreversible | After release PR merge, confirm tags `accrue-v1.3.0`, `accrue_admin-v1.3.0`, `accrue_portal-v1.3.0` exist and all 3 packages are live on hex.pm |
| ExDoc renders "(since 1.3.0)" badge for fixed `@doc since:` items | D-02 | Visual ExDoc output | `cd accrue && mix docs` and confirm the badge renders (no literal `@since` junk text) |

---

## Validation Sign-Off

- [x] All tasks have an automated verify command or are explicitly Manual-Only (release-pipeline steps)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing infra)
- [x] No watch-mode flags
- [x] Feedback latency < 300s (compile fast-path; full suite under 5 min/package)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-29
