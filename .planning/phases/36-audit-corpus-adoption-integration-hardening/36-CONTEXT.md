# Phase 36: Audit corpus + adoption integration hardening — Context

**Gathered:** 2026-04-21  
**Status:** Ready for planning  
**Source:** [`v1.7-MILESTONE-AUDIT.md`](../../v1.7-MILESTONE-AUDIT.md), `/gsd-plan-milestone-gaps` closure plan

<domain>

## Phase boundary

Close **milestone-audit** gaps that are **not** new ADOPT product scope: **3-source traceability** (`requirements-completed` YAML on completed **32-**\* / **33-**\* plan summaries), **contributor clarity** when `scripts/ci/verify_package_docs.sh` and related gates span multiple ADOPT requirements, **dual-contract** maintenance (root `README.md`, `scripts/ci/verify_verify01_readme_contract.sh`, guides + host README), and **forward-coupling** notes so **Phases 34–35** respect **Copy SSOT**, route matrix, and Playwright contracts.

**Does not** reopen satisfied **ADOPT** functional checkboxes in `.planning/REQUIREMENTS.md`; Phases **32–33** remain the implementation owners for behavior.

Depends on **Phases 32–33** complete.

</domain>

<canonical_refs>

## Canonical references

- [`v1.7-MILESTONE-AUDIT.md`](../../v1.7-MILESTONE-AUDIT.md) — `gaps.integration`, `tech_debt`, Nyquist `missing_phases` context for 34–35 (informational).
- `scripts/ci/verify_package_docs.sh`, `scripts/ci/verify_verify01_readme_contract.sh`
- `.github/workflows/ci.yml` — stable job ids (ADOPT-06).
- `.planning/phases/32-adoption-discoverability-doc-graph/`, `.planning/phases/33-installer-host-contracts-ci-clarity/` — SUMMARY files to backfill.

</canonical_refs>
