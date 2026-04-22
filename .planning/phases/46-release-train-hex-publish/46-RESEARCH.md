# Phase 46 — Technical Research

**Phase:** 46 — Release train & Hex publish  
**Question:** What do we need to know to plan REL-01 / REL-02 / REL-04 well?

## Summary

Accrue already ships **Release Please 17.6.0** on `main` via `.github/workflows/release-please.yml` with **linked-versions**, **combined PR**, **core-first** `publish-accrue` then **`needs.publish-accrue`** for `publish-accrue-admin`, **`ACCRUE_ADMIN_HEX_RELEASE=1`** on admin, and a **lockstep fallback** when only the core GitHub Release is detected but manifest versions match (lines 117–131). **REL-01** is largely “verify + document,” not greenfield automation.

The main **policy/implementation gap** is `.github/workflows/release-pr-automation.yml`: it runs on `pull_request` for `release-please--*` heads and calls `gh pr merge --merge --auto`, which can merge a release PR **without an explicit maintainer merge click** whenever branch protection allows (CONTEXT **D-06**, **D-09**). Planning should **narrow or remove** that automatic path and make **`RELEASING.md`** the single honest story.

**REL-02** (version + changelog + Hex alignment) is enforced today at publish time by `grep @version` in workflows; adding a **cheap pre-matrix CI script** comparing `.release-please-manifest.json` to both `mix.exs` `@version` values catches drift **before** merge. Lockstep also implies **`accrue_admin/mix.exs`** `accrue_dep/0` uses `~> #{@version}` matching `@version` when env is unset (path dep dev) — script can assert manifest `accrue` == `accrue_admin`.

**REL-04** (tags + Hex): `release-please.yml` derives tags `accrue-v{version}` / `accrue_admin-v{version}` from manifest paths; publish jobs checkout **`accrue_sha`** / **`accrue_admin_sha`** from outputs. Evidence belongs in **`46-VERIFICATION.md`** per **D-11–D-12** (index card + command blocks, links not log dumps).

**Partial publish** (**D-15–D-20**): Hex immutability means recovery is **retry admin**, **`mix hex.publish --revert`** only in short window for mistaken **core**, else **retire + forward-fix** — cite `https://hex.pm/docs/faq` in runbook bullets only (no SBOM scope per phase boundary).

## Release Please + Hex (repo facts)

| Artifact | Role |
|----------|------|
| `release-please-config.json` | `linked-versions` group `accrue-monorepo`; `separate-pull-requests: false`; `release-type: elixir` per package |
| `.release-please-manifest.json` | Numeric SSOT for RP outputs until merge |
| `release-please.yml` | `github-release` + `release-pr` on push `main`; conditional publish jobs; lockstep admin fallback |
| `publish-hex.yml` | Manual recovery: package + tag + `release_version` |
| `RELEASING.md` | Runbook; currently describes auto-merge on green — conflicts with **D-06** until reconciled |

## Risks / pitfalls

1. **Auto-merge + payments posture** — Treat as **process risk**, not supply-chain: fix workflow or branch rules so **human intent** precedes irreversible merge.
2. **Half-publish** — CI already orders admin after core; operators still need a **written** recovery ladder (retry → revert window → retire).
3. **Over-verification** — **D-13** forbids duplicating CI logs in phase verification; link runs and keep commands short.

## Validation Architecture

**Nyquist dimension 8 (feedback):** Phase execution is **docs + YAML + shell script + markdown evidence**. No new ExUnit modules are required; validation is **script exit 0** on every touched PR plus **optional** `mix test` only if executor edits Elixir (plans should avoid Elixir edits unless fixing a discovered bug).

| Dimension | Strategy |
|-----------|----------|
| Automated | `bash scripts/ci/verify_release_manifest_alignment.sh` on CI; local same command before push |
| Manual | Maintainer fills **`46-VERIFICATION.md`** after a real train (Hex + tags + PR links) — cannot automate Hex without secrets |
| Sampling | Run alignment script after any edit to manifest, `release-please-config.json`, either root `mix.exs`, or `verify_release_manifest_alignment.sh` |

**Wave 0:** Not applicable — existing `mix test` matrix already covers unrelated regressions; this phase adds **one bash script** and workflow wiring.

---

## RESEARCH COMPLETE
